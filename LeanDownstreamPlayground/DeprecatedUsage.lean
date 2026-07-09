/-
Copyright (c) 2026 Marcelo Lynch. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marcelo Lynch
-/
import Mathlib.AlgebraicTopology.SingularHomology.HomotopyInvarianceTopCat
import Mathlib.Order.Bounded

/-!
# Multi-deprecation demo

Imports **two** modules mathlib turned into `deprecated_module` shims:

* `…SingularHomology.HomotopyInvarianceTopCat` — renamed → `…HomotopyInvariance`
  (a clean re-export).
* `Mathlib.Order.Bounded` — in-place shim → `Mathlib.Order.Bounds.Defs`
  (code-carrying, so a `[partial]` rewrite).

Pinned to **v4.30.0-rc1** both are real content, so this builds clean. Bumping to
**v4.30.0** (where both are live shims) yields two `deprecatedImports` advisories,
and `hopscotch fix apply` rewrites **both** imports in a single pass — exercising
multi-fix handling.
-/
