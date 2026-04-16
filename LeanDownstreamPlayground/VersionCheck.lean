import Std

/-!
# Mathlib Version Gate

Enforces a maximum allowed mathlib revision at **build time**.

## Usage

Change `firstBreakingVersion` to simulate downstream regressions:

- Set it **at or below** the revision currently in `lake-manifest.json` →
  `lake build` fails (simulates a regression first introduced by that version).
- Set it **above** the current revision →
  `lake build` succeeds.

`lake update` is never affected: it always resolves and writes the manifest,
but never compiles Lean files.
-/

/--
  First mathlib version known to break the build. Build fails if the resolved
  `rev` is this commit or any strictly newer one.
  Use a tag (e.g. `"v4.29.0"`) or a commit SHA; set to `"HEAD"` to always fail.
-/
private def firstBreakingVersion : String := "v4.29.0"

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

/-- Returns `true` if commit `b` is at or newer than commit `a`
    (i.e. `a` is an ancestor of `b`, including the case `a = b`).
    Tries the local `.lake/packages/mathlib` git clone first (no network),
    then falls back to the GitHub compare API. -/
private def isNewerThan (a b : String) : IO Bool := do
  -- Fast path: ask the local Lake clone, which is a full (non-shallow) git
  -- checkout so the entire ancestry graph is available without network access.
  --
  -- `isNewerThan a b` returns true when b is at or newer than a, matching the
  -- partial application `isNewerThan firstBreakingVersion` as an
  -- "at-or-past-the-limit" predicate.
  --
  -- `git merge-base --is-ancestor <ancestor> <descendant>` exits 0 when the
  -- first argument is a (non-strict) ancestor of the second, and 1 otherwise.
  -- We pass a as the candidate ancestor and b as the candidate descendant, so:
  --   exit 0  →  a is an ancestor of b (or a = b)  →  b is at or newer  →  true
  --   exit 1  →  b is strictly older than a         →  false
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
  -- The three-dot syntax `b...a` asks "what is the status of a relative to b?".
  -- base = b (rev), head = a (firstBreakingVersion).
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
  -- The URL is compare/{b}...{a}, so GitHub's base=b (rev) and
  -- head=a (firstBreakingVersion).
  -- "behind"    = firstBreakingVersion is behind rev → rev is newer → true
  -- "ahead"     = firstBreakingVersion is ahead of rev → rev is older → false
  -- "identical" = same commit → rev IS the breaking version → true
  if payload.contains "\"status\": \"behind\""    then return true
  if payload.contains "\"status\": \"ahead\""     then return false
  if payload.contains "\"status\": \"identical\"" then return true
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
  if ← isNewerThan firstBreakingVersion rev then
    throw <| IO.userError
      s!"VersionCheck: mathlib {rev} is at or newer than the first breaking version \
         {firstBreakingVersion}. Update firstBreakingVersion or pin an older revision."
