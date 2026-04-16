# LeanDownstreamPlayground

A downstream Lean 4 / Mathlib project used to simulate regression scenarios for [downstream-reports](https://github.com/leanprover-community/downstream-reports).

It models a real downstream that depends on Mathlib and can break when Mathlib advances past a certain point. The build itself is the test: `lake build` will just fail at or past a designated revision.

## How it works

`LeanDownstreamPlayground/VersionCheck.lean` enforces a **build-time Mathlib version ceiling** via a `#eval` block that runs during `lake build`:

1. Reads `lake-manifest.json` to find the currently resolved Mathlib commit.
2. Uses git to compare API to determine ordering relative to `firstBreakingVersion`.
3. **Fails the build** if the resolved commit is strictly newer than the ceiling.

### Simulating a regression

1) Update `lakefile.toml` to use an arbitrary version of `mathlib` (via `rev`). 
2) Call `lake update` to fetch the latest history for the repository in `.lake` (important to avoid GitHub API calls).
3) If you want the build to fail (downstream broken), set a `firstBreakingVersion` equal or older than the `rev` you picked. If you want the build to succeed, set `firstBreakingVersion` newer than the `rev`.

### GitHub token

`VersionCheck` may call the GitHub API via `curl` if it can't find the data it needs in the repository that is cloned at `.lake`. Set `GITHUB_TOKEN` in your environment (or as a repository secret in CI) to avoid rate limits:

```bash
export GITHUB_TOKEN=$(gh auth token)
```