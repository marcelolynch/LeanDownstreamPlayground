import Mathlib.LinearAlgebra.Matrix.ConjTranspose

/-!
# Deprecation Advisory Demo

This module exists to exercise the *deprecation advisory* path of
downstream-reports' `bump-to-latest` action (the `apply-fixes` feature added in
[PR #41](https://github.com/leanprover-community/downstream-reports/pull/41)).

The example below uses `Matrix.star_mul`, which mathlib **deprecated on
2026-04-20** (PR
[#38307](https://github.com/leanprover-community/mathlib4/pull/38307)) in favour
of the root-namespace `StarMul.star_mul`. It survives only as a deprecated
alias:

```
@[deprecated (since := "2026-04-20")] protected alias star_mul := StarMul.star_mul
```

## What this demonstrates

* Pinned to **v4.30.0-rc2** (2026-04-18, *before* the deprecation), this builds
  with no warning. The next release, **v4.30.0** (2026-05-26), is *after* it —
  so a bump across that release window introduces the deprecation.
* Built against any mathlib **at or after** the deprecation commit, Lean emits

  ```
  warning: `Matrix.star_mul` has been deprecated: Use `StarMul.star_mul` instead
  ```

  The build still succeeds — a deprecation is a warning, not an error.

When the daily mathlib bump (`.github/workflows/lkg-bump.yml`) crosses that
commit, `hopscotch fix apply` (run because the workflow passes `apply-fixes:
true`) detects this advisory and rewrites `Matrix.star_mul` → `StarMul.star_mul`,
so the bump PR carries the source repair, not just the revision bump.

To re-point this demo at a different deprecation, swap the lemma below for any
other still-live deprecated alias and update the pin accordingly.
-/

/-- A use of `Matrix.star_mul`. The statement mirrors the lemma's own signature,
so it typechecks both before the deprecation (when it is a real theorem) and
after it (when it is a deprecated alias to `StarMul.star_mul`). -/
example {n α : Type*} [Fintype n] [NonUnitalNonAssocSemiring α] [StarRing α]
    (M N : Matrix n n α) : star (M * N) = star N * star M :=
  Matrix.star_mul M N
