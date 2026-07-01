/-
Copyright (c) 2026 Marcelo Lynch. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marcelo Lynch
-/
import Mathlib.LinearAlgebra.Matrix.ConjTranspose

/-!
# Un-fixable Regression Demo — declaration deprecation under `--iofail`

Uses `Matrix.star_mul`, a **declaration**-level `@[deprecated]` (deprecated
2026-04-21, [#38307](https://github.com/leanprover-community/mathlib4/pull/38307),
in favour of `StarMul.star_mul`).

## What this demonstrates

* Pinned to **v4.30.0-rc2** (2026-04-18, before the deprecation) this builds
  clean.
* Built against **v4.30.0** (2026-05-26) the reference to `Matrix.star_mul`
  emits a deprecation warning. downstream-reports runs the build with lake's
  `--iofail` (`build_args` inventory option), so that warning **fails** the
  build → a first-known-bad regression.

Unlike a `deprecated_module` import, a declaration `@[deprecated]` is **outside
hopscotch's autofix scope** — an import rewrite can't repair it. So the
regression is recorded with **no `proposedFix`**: the `track-incompatibility`
issue stands and the fix PR is a rev-bump only. This is the common real-world
case — a breaking change a human must fix (here, `Matrix.star_mul M N` →
`StarMul.star_mul M N`).
-/

example {n α : Type*} [Fintype n] [NonUnitalNonAssocSemiring α] [StarRing α]
    (M N : Matrix n n α) : star (M * N) = star N * star M :=
  Matrix.star_mul M N
