import Std

/-!
# Mathlib Version Gate

Enforces a maximum allowed mathlib revision at **build time**.

## Usage

Change `maxMathlibVersion` to simulate downstream regressions:

- Set it **below** the revision currently in `lake-manifest.json` →
  `lake build` fails (simulates a regression introduced by a newer mathlib).
- Set it **at or above** the current revision →
  `lake build` succeeds.

`lake update` is never affected: it always resolves and writes the manifest,
but never compiles Lean files.
-/

/--
  Maximum mathlib version allowed. Build fails if the resolved `rev` is strictly newer.
  Use "HEAD" to always succeed, but also a tag or a commit SHA.
-/
private def maxMathlibVersion : String := "v4.29.0"

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

/-- Returns `true` if commit `a` is strictly newer than commit `b`.
    Tries the local `.lake/packages/mathlib` git clone first (no network),
    then falls back to the GitHub compare API. -/
private def isNewerThan (a b : String) : IO Bool := do
  if a = b then return false

  -- Fast path: ask the local Lake clone, which is a full (non-shallow) git
  -- checkout so the entire ancestry graph is available without network access.
  --
  -- `isNewerThan a b` returns true when b is newer than a, matching the partial
  -- application `isNewerThan maxMathlibVersion` as an "exceeds the limit" predicate.
  --
  -- `git merge-base --is-ancestor <ancestor> <descendant>` exits 0 when the
  -- first argument is a (non-strict) ancestor of the second, and 1 otherwise.
  -- We pass a as the candidate ancestor and b as the candidate descendant, so:
  --   exit 0  →  a is an ancestor of b  →  b is newer than a  →  true
  --   exit 1  →  b is not newer than a  →  false
  --
  -- Any other exit code (e.g. 128, "unknown revision") means one of the refs
  -- could not be resolved in the local clone — e.g. `a` is a tag that was
  -- created after the last `lake update`. In that case we fall through to the
  -- API rather than throwing, so the check still works offline-first.
  let localResult ← IO.Process.output {
    cmd  := "git"
    args := #["-C", ".lake/packages/mathlib", "merge-base", "--is-ancestor", a, b]
  }
  if localResult.exitCode = 0 then return true
  if localResult.exitCode = 1 then return false

  -- Slow path: the local clone could not resolve one of the refs; fall back to
  -- the GitHub compare API.
  --
  -- The three-dot syntax `b...a` asks "what is the status of a relative to b?",
  -- so "behind" means a has commits that b does not (a is newer than b).
  let url :=
    s!"https://api.github.com/repos/leanprover-community/mathlib4/compare/{b}...{a}"

  let token? ← IO.getEnv "GITHUB_TOKEN"
  let authHeader := match token? with
    | some token => #["-H", s!"Authorization: Bearer {token}"]
    | none       => #[]

  let result ← IO.Process.output {
    cmd := "curl"
    args := #["-s",
              "-H", "Accept: application/vnd.github+json",
              "-H", "X-GitHub-Api-Version: 2022-11-28"]
            ++ authHeader
            ++ #[url]
  }

  if result.exitCode ≠ 0 then
    throw <| IO.userError s!"curl failed:\n{result.stderr}"

  let payload := result.stdout
  -- The URL is compare/{b}...{a}, so GitHub's base=b and head=a.
  -- "behind" = head (a) is behind base (b) → b is newer than a → true
  -- "ahead"  = head (a) is ahead of base (b) → a is newer than b → false
  if payload.contains "\"status\": \"behind\""    then return true
  if payload.contains "\"status\": \"ahead\""     then return false
  if payload.contains "\"status\": \"identical\"" then return false
  -- "diverged" means the two commits are on branches that split from a common
  -- ancestor, so there is no total ordering between them.
  if payload.contains "\"status\": \"diverged\""  then
    throw <| IO.userError
      s!"VersionCheck: commits {a} and {b} have diverged; no total ordering"
  throw <| IO.userError s!"Error parsing response {url}: {payload}"


/-- Extracts mathlib's `rev` from the raw text of `lake-manifest.json`.
    Relies only on the stable JSON key ordering that Lake always writes. -/
private def findMathlibRev (manifest : String) : Option String := do
  let _ :: afterMathlib :: _ :=
    manifest.splitOn "\"url\": \"https://github.com/leanprover-community/mathlib4\""
    | none
  let _ :: afterRev :: _ := afterMathlib.splitOn "\"rev\": \""  | none
  let rev :: _            := afterRev.splitOn "\""               | none
  return rev

-- ---------------------------------------------------------------------------
-- Build-time check (runs during `lake build`, not at runtime)
-- ---------------------------------------------------------------------------

#eval show IO Unit from do
  let manifest ← IO.FS.readFile "lake-manifest.json"
  let some rev := findMathlibRev manifest
    | throw <| IO.userError
        "VersionCheck: could not locate mathlib rev in lake-manifest.json"
  if ← isNewerThan maxMathlibVersion rev then
    throw <| IO.userError
      s!"VersionCheck: mathlib {rev} exceeds the maximum allowed version \
         {maxMathlibVersion}. Update maxMathlibVersion or pin an older revision."
