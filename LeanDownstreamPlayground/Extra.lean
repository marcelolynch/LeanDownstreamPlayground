import LeanDownstreamPlayground.Basic

/-!
# Extra module for the documentation cache experiment

This module exists in one run and is removed in the next, so that the prune
step of docgen-action has a stale module to remove.
-/

namespace LeanDownstreamPlayground

/-- Two is at most three. -/
theorem two_le_three : (2 : ℕ) ≤ 3 := Nat.le_succ 2

end LeanDownstreamPlayground
