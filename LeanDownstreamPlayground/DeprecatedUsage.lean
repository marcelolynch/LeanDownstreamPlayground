/-
Copyright (c) 2026 Marcelo Lynch. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marcelo Lynch
-/
import Mathlib.AlgebraicTopology.SingularHomology.HomotopyInvarianceTopCat

/-!
# Module Deprecation Demo

This module exercises the *module-deprecation* path of hopscotch's automated
fixes (the `apply-fixes` feature added in downstream-reports
[PR #41](https://github.com/leanprover-community/downstream-reports/pull/41)),
as consumed by `.github/workflows/lkg-bump.yml`.

It imports `Mathlib.AlgebraicTopology.SingularHomology.HomotopyInvarianceTopCat`,
which mathlib renamed to `…SingularHomology.HomotopyInvariance`
([#37658](https://github.com/leanprover-community/mathlib4/pull/37658), 2026-04-17)
and then re-added as a `deprecated_module` shim
([#37877](https://github.com/leanprover-community/mathlib4/pull/37877), 2026-04-21):

```
public import Mathlib.AlgebraicTopology.SingularHomology.HomotopyInvariance
deprecated_module (since := "2026-04-10")
```

## What this demonstrates

* Pinned to **v4.30.0-rc1** (2026-04-04, before the rename), the module is real
  content, so this imports cleanly with no warning.
* Built against **v4.30.0** (2026-05-26) or master, the import resolves through
  the live shim and Lean's `linter.deprecated.module` fires
  (`…HomotopyInvarianceTopCat has been deprecated`). The build still succeeds.

Unlike a declaration-level `@[deprecated]` (which hopscotch does not rewrite),
this is exactly the `deprecated_module` case hopscotch's autofix handles: a bump
to a commit where the shim is live records a `deprecatedImports` advisory, and
`hopscotch fix apply` rewrites the import to
`…SingularHomology.HomotopyInvariance`, so the bump PR carries the migration.
-/
