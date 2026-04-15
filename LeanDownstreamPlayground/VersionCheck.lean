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
private def maxMathlibVersion : String := "HEAD"

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

/-- Returns `true` if commit `a` is strictly newer than commit `b`
    using the GitHub compare API. -/
private def isNewerThan (a b : String) : IO Bool := do
  if a = b then return false

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
  if payload.contains "\"status\": \"behind\""    then return true  -- a is newer than b
  if payload.contains "\"status\": \"ahead\""     then return false -- a is older than b
  if payload.contains "\"status\": \"identical\"" then return false
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
