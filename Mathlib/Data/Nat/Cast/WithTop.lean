/-
Copyright (c) 2014 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro

! This file was ported from Lean 3 source module data.nat.cast.with_top
! leanprover-community/mathlib commit ee0c179cd3c8a45aa5bffbf1b41d8dbede452865
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.Algebra.Order.Monoid.WithTop
import Mathlib.Data.Nat.Basic

/-!
# Lemma about the coercion `ℕ → WithBot ℕ`.

An orphaned lemma about casting from `ℕ` to `WithBot ℕ`,
exiled here to minimize imports to `data.rat.order` for porting purposes.
-/


theorem Nat.cast_withTop (n : ℕ) :  Nat.cast n = WithTop.some n :=
  rfl
#align nat.cast_with_top Nat.cast_withTop

theorem Nat.cast_withBot (n : ℕ) : Nat.cast n = WithBot.some n :=
  rfl
#align nat.cast_with_bot Nat.cast_withBot
