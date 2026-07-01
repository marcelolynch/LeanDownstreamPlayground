/-
Copyright (c) 2026 Marcelo Lynch. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Marcelo Lynch
-/
import Mathlib.Tactic.Linter.DeprecatedModule

/-!
# Empty-shim Demo — import removal

Imports `Mathlib.Data.List.SplitOn`, which mathlib turned into an **empty**
`deprecated_module` shim ("Upstreamed to core", since 2026-02-26): the file
re-exports nothing — its contents moved into Lean core.

## What this demonstrates

Building against any recent mathlib, the import resolves through the shim and
`linter.deprecated.module` warns (the build stays green). hopscotch records a
`deprecatedImports` advisory whose replacement set is **empty** (`newModules =
[]`), because the shim re-exports nothing.

So `hopscotch fix apply` **deletes** the import line rather than rewriting it —
a distinct fix *shape* from the `Order.Bounded`/`HomotopyInvarianceTopCat`
rewrites. The correct migration for a downstream is simply to drop the import
(anything it needs now lives in core).
-/
