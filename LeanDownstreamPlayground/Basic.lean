import Mathlib.Data.Nat.Prime.Basic

/-!
# Documentation cache experiment

This module imports a part of Mathlib, so that the documentation build has a
dependency closure of moderate size.
-/

namespace LeanDownstreamPlayground

/-- Two is a prime number. -/
theorem two_prime : Nat.Prime 2 := Nat.prime_two

/-- A prime number is at least two. -/
theorem two_le_of_prime {p : ℕ} (hp : Nat.Prime p) : 2 ≤ p := hp.two_le

end LeanDownstreamPlayground
