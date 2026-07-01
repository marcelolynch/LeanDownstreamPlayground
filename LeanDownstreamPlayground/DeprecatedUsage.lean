/-
Copyright (c) 2026 Marcelo Lynch. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marcelo Lynch
-/
import Mathlib.Order.Bounded

/-!
# Module Deprecation Demo — warnings-as-error (`--iofail`)

Imports `Mathlib.Order.Bounded`, which mathlib deprecated **in place** on
2026-04-17 ([#38146](https://github.com/leanprover-community/mathlib4/pull/38146)):
the file became a `deprecated_module` shim in a single commit — no removal gap —
re-exporting `Mathlib.Order.Bounds.Defs`.

## What this demonstrates

* Pinned to **v4.30.0-rc1** (2026-04-04, before the deprecation) the module is
  real content, so this builds clean.
* The next release, **v4.30.0-rc2** (2026-04-18), is *after* the in-place
  deprecation, so the import resolves through the shim and
  `linter.deprecated.module` fires.

downstream-reports runs this build with lake's **`--iofail`** (via the
`build_args` inventory option), so the deprecation *warning* **fails** the build.
Because the module is present (a shim) at that boundary, hopscotch promotes the
import from a green-build *advisory* to a **`proposedFix`** at the deprecating
commit (scenario 8) — a first-known-bad regression whose fix (`import
Mathlib.Order.Bounded` → `Mathlib.Order.Bounds.Defs`) is carried on the
`track-incompatibility` path, not the LKG advisory path.
-/
