# LeanDownstreamPlayground

A downstream Lean 4 / Mathlib project used to simulate regression scenarios for [hopscotch-reports](https://github.com/leanprover-community/hopscotch-reports).

It models a real downstream that depends on Mathlib and can break when Mathlib advances past a certain point. The build itself is the test: a failing `lake build` is the intended signal.

## How it works

`LeanDownstreamPlayground/VersionCheck.lean` enforces a **build-time Mathlib version ceiling** via a `#eval` block that runs during `lake build`:

1. Reads `lake-manifest.json` to find the currently resolved Mathlib commit.
2. Calls the GitHub compare API to determine ordering relative to `maxMathlibVersion`.
3. **Fails the build** if the resolved commit is strictly newer than the ceiling.

### Simulating a regression

| Goal | Action |
|------|--------|
| Build fails (downstream broken) | Set `maxMathlibVersion` **below** the `rev` in `lake-manifest.json` |
| Build passes (downstream healthy) | Set `maxMathlibVersion` **at or above** the `rev` in `lake-manifest.json` |

`lake update` is never affected — it resolves and writes the manifest but never compiles Lean files.

### GitHub token

`VersionCheck` calls the GitHub API via `curl`. Set `GITHUB_TOKEN` in your environment (or as a repository secret in CI) to avoid rate limits:

```bash
export GITHUB_TOKEN=ghp_...
lake build
```

## Usage

```bash
lake build   # builds and runs the version check
lake update  # bumps Mathlib in lake-manifest.json (no compilation)
```

## CI

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `lean_action_ci.yml` | push / PR | Runs `lake build`; publishes docs to GitHub Pages |
| `update.yml` | manual (`workflow_dispatch`) | Bumps Mathlib, opens a PR on success or an issue on failure |
| `create-release.yml` | push to main touching `lean-toolchain` | Auto-tags a release |

To enable scheduled Mathlib updates, uncomment the `cron:` line in `.github/workflows/update.yml`.

## GitHub repository setup

Before the CI workflows work correctly, configure the repository:

1. **Settings → Actions → General** — enable *Allow GitHub Actions to create and approve pull requests*.
2. **Settings → Pages → Source** — set to *GitHub Actions*.
