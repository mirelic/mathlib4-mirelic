/-
Copyright (c) 2015 Joe Hendrix. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joe Hendrix, Sebastian Ullrich

! This file was ported from Lean 3 source module data.bitvec.core
! leanprover-community/mathlib commit 1126441d6bccf98c81214a0780c73d499f6721fe
! Please do not edit these lines, except to modify the commit id
! if you have ported upstream changes.
-/
import Mathlib.Data.Vector.Basic
import Mathlib.Data.Nat.Pow
import Init.Data.Format.Basic
import Mathlib.Init.Data.Nat.Lemmas
/-!
# Basic operations on bitvectors

This is a work-in-progress, and contains additions to other theories.

This file was moved to mathlib from core Lean in the switch to Lean 3.20.0c.
It is not fully in compliance with mathlib style standards.
-/

/-- `Bitvec n` is a `Vector` of `Bool` with length `n`. -/
@[reducible]
def Bitvec (n : ℕ) :=
  Vector Bool n
#align bitvec Bitvec

namespace Bitvec

open Nat

open Vector

-- mathport name: «expr ++ₜ »
local infixl:65 "++ₜ" => Vector.append

/-- Create a zero bitvector -/
@[reducible]
protected def zero (n : ℕ) : Bitvec n :=
  replicate n false
#align bitvec.zero Bitvec.zero

/-- Create a bitvector of length `n` whose `n-1`st entry is 1 and other entries are 0. -/
@[reducible]
protected def one : ∀ n : ℕ, Bitvec n
  | 0 => nil
  | succ n => replicate n false++ₜtrue ::ᵥ nil
#align bitvec.one Bitvec.one

/-- Create a bitvector from another with a provably equal length. -/
protected def cong {a b : ℕ} (h : a = b) : Bitvec a → Bitvec b
  | ⟨x, p⟩ => ⟨x, h ▸ p⟩
#align bitvec.cong Bitvec.cong

/-- `Bitvec` specific version of `Vector.append` -/
def append {m n} : Bitvec m → Bitvec n → Bitvec (m + n) :=
  Vector.append
#align bitvec.append Bitvec.append

/-! ### Shift operations -/


section Shift

variable {n : ℕ}

/-- `shl x i` is the bitvector obtained by left-shifting `x` `i` times and padding with `false`.
If `x.length < i` then this will return the all-`false`s bitvector. -/
def shl (x : Bitvec n) (i : ℕ) : Bitvec n :=
  Bitvec.cong (by simp) <| drop i x++ₜreplicate (min n i) false
#align bitvec.shl Bitvec.shl

/-- `fill_shr x i fill` is the bitvector obtained by right-shifting `x` `i` times and then
padding with `fill : Bool`. If `x.length < i` then this will return the constant `fill`
bitvector. -/
def fillShr (x : Bitvec n) (i : ℕ) (fill : Bool) : Bitvec n :=
  Bitvec.cong
      (by
        by_cases i ≤ n
        · have h₁ := Nat.sub_le n i
          rw [min_eq_right h]
          rw [min_eq_left h₁, ← add_tsub_assoc_of_le h, Nat.add_comm, add_tsub_cancel_right]
        · have h₁ := le_of_not_ge h
          rw [min_eq_left h₁, tsub_eq_zero_iff_le.mpr h₁, zero_min, Nat.add_zero]) <|
    replicate (min n i) fill++ₜtake (n - i) x
#align bitvec.fill_shr Bitvec.fillShr

/-- unsigned shift right -/
def ushr (x : Bitvec n) (i : ℕ) : Bitvec n :=
  fillShr x i false
#align bitvec.ushr Bitvec.ushr

/-- signed shift right -/
def sshr : ∀ {m : ℕ}, Bitvec m → ℕ → Bitvec m
  | 0, _, _ => nil
  | succ _, x, i => head x ::ᵥ fillShr (tail x) i (head x)
#align bitvec.sshr Bitvec.sshr

end Shift

/-! ### Bitwise operations -/


section Bitwise

variable {n : ℕ}

-- porting note: added protected, since now this clashes with `_root_.not` (formerly `bnot`)
/-- bitwise not -/
protected def not (bv : Bitvec n) : Bitvec n :=
  map not bv
#align bitvec.not Bitvec.not

-- porting note: added protected, since now this clashes with `_root_.and` (formerly `band`)
/-- bitwise and -/
protected def and : Bitvec n → Bitvec n → Bitvec n :=
  map₂ and
#align bitvec.and Bitvec.and

-- porting note: added protected, since now this clashes with `_root_.or` (formerly `bor`)
/-- bitwise or -/
protected def or : Bitvec n → Bitvec n → Bitvec n :=
  map₂ or
#align bitvec.or Bitvec.or

-- porting note: added protected, since now this clashes with `_root_.xor` (formerly `bxor`)
/-- bitwise xor -/
protected def xor : Bitvec n → Bitvec n → Bitvec n :=
  map₂ xor
#align bitvec.xor Bitvec.xor

end Bitwise

/-! ### Arithmetic operators -/


section Arith

variable {n : ℕ}

/-- `xor3 x y c` is `((x XOR y) XOR c)`. -/
protected def xor3 (x y c : Bool) :=
  xor (xor x y) c
#align bitvec.xor3 Bitvec.xor3

/-- `carry x y c` is `x && y || x && c || y && c`. -/
protected def carry (x y c : Bool) :=
  x && y || x && c || y && c
#align bitvec.carry Bitvec.carry

/-- `neg x` is the two's complement of `x`. -/
protected def neg (x : Bitvec n) : Bitvec n :=
  let f y c := (y || c, xor y c)
  Prod.snd (mapAccumr f x false)
#align bitvec.neg Bitvec.neg

/-- Add with carry (no overflow) -/
def adc (x y : Bitvec n) (c : Bool) : Bitvec (n + 1) :=
  let f x y c := (Bitvec.carry x y c, Bitvec.xor3 x y c)
  let ⟨c, z⟩ := Vector.mapAccumr₂ f x y c
  c ::ᵥ z
#align bitvec.adc Bitvec.adc

/-- The sum of two bitvectors -/
protected def add (x y : Bitvec n) : Bitvec n :=
  tail (adc x y false)
#align bitvec.add Bitvec.add

/-- Subtract with borrow -/
def sbb (x y : Bitvec n) (b : Bool) : Bool × Bitvec n :=
  let f x y c := (Bitvec.carry (not x) y c, Bitvec.xor3 x y c)
  Vector.mapAccumr₂ f x y b
#align bitvec.sbb Bitvec.sbb

/-- The difference of two bitvectors -/
protected def sub (x y : Bitvec n) : Bitvec n :=
  Prod.snd (sbb x y false)
#align bitvec.sub Bitvec.sub

instance : Zero (Bitvec n) :=
  ⟨Bitvec.zero n⟩

instance : One (Bitvec n) :=
  ⟨Bitvec.one n⟩

instance : Add (Bitvec n) :=
  ⟨Bitvec.add⟩

instance : Sub (Bitvec n) :=
  ⟨Bitvec.sub⟩

instance : Neg (Bitvec n) :=
  ⟨Bitvec.neg⟩

/-- The product of two bitvectors -/
protected def mul (x y : Bitvec n) : Bitvec n :=
  let f r b := cond b (r + r + y) (r + r)
  (toList x).foldl f 0
#align bitvec.mul Bitvec.mul

instance : Mul (Bitvec n) :=
  ⟨Bitvec.mul⟩

end Arith

/-! ### Comparison operators -/


section Comparison

variable {n : ℕ}

/-- `uborrow x y` returns `true` iff the "subtract with borrow" operation on `x`, `y` and `false`
required a borrow. -/
def uborrow (x y : Bitvec n) : Bool :=
  Prod.fst (sbb x y false)
#align bitvec.uborrow Bitvec.uborrow

/-- unsigned less-than proposition -/
def Ult (x y : Bitvec n) : Prop :=
  uborrow x y
#align bitvec.ult Bitvec.Ult

/-- unsigned greater-than proposition -/
def Ugt (x y : Bitvec n) : Prop :=
  Ult y x
#align bitvec.ugt Bitvec.Ugt

/-- unsigned less-than-or-equal-to proposition -/
def Ule (x y : Bitvec n) : Prop :=
  ¬Ult y x
#align bitvec.ule Bitvec.Ule

/-- unsigned greater-than-or-equal-to proposition -/
def Uge (x y : Bitvec n) : Prop :=
  Ule y x
#align bitvec.uge Bitvec.Uge

/-- `sborrow x y` returns `true` iff `x < y` as two's complement integers -/
def sborrow : ∀ {n : ℕ}, Bitvec n → Bitvec n → Bool
  | 0, _, _ => false
  | succ _, x, y =>
    match (head x, head y) with
    | (true, false) => true
    | (false, true) => false
    | _ => uborrow (tail x) (tail y)
#align bitvec.sborrow Bitvec.sborrow

/-- signed less-than proposition -/
def Slt (x y : Bitvec n) : Prop :=
  sborrow x y
#align bitvec.slt Bitvec.Slt

/-- signed greater-than proposition -/
def Sgt (x y : Bitvec n) : Prop :=
  Slt y x
#align bitvec.sgt Bitvec.Sgt

/-- signed less-than-or-equal-to proposition -/
def Sle (x y : Bitvec n) : Prop :=
  ¬Slt y x
#align bitvec.sle Bitvec.Sle

/-- signed greater-than-or-equal-to proposition -/
def Sge (x y : Bitvec n) : Prop :=
  Sle y x
#align bitvec.sge Bitvec.Sge

end Comparison

/-! ### Conversion to `nat` and `int` -/


section Conversion

variable {α : Type}

/-- Create a bitvector from a `nat` -/
protected def ofNat : ∀ n : ℕ, Nat → Bitvec n
  | 0, _ => nil
  | succ n, x => Bitvec.ofNat n (x / 2)++ₜdecide (x % 2 = 1) ::ᵥ nil
#align bitvec.of_nat Bitvec.ofNat

/-- Create a bitvector in the two's complement representation from an `int` -/
protected def ofInt : ∀ n : ℕ, Int → Bitvec (succ n)
  | n, Int.ofNat m => false ::ᵥ Bitvec.ofNat n m
  | n, Int.negSucc m => true ::ᵥ (Bitvec.ofNat n m).not
#align bitvec.of_int Bitvec.ofInt

/-- `add_lsb r b` is `r + r + 1` if `b` is `true` and `r + r` otherwise. -/
def addLsb (r : ℕ) (b : Bool) :=
  r + r + cond b 1 0
#align bitvec.add_lsb Bitvec.addLsb

/-- Given a `List` of `Bool`s, return the `nat` they represent as a list of binary digits. -/
def bitsToNat (v : List Bool) : Nat :=
  v.foldl addLsb 0
#align bitvec.bits_to_nat Bitvec.bitsToNat

/-- Return the natural number encoded by the input bitvector -/
protected def toNat {n : Nat} (v : Bitvec n) : Nat :=
  bitsToNat (toList v)
#align bitvec.to_nat Bitvec.toNat

theorem bitsToNat_toList {n : ℕ} (x : Bitvec n) : Bitvec.toNat x = bitsToNat (Vector.toList x) :=
  rfl
#align bitvec.bits_to_nat_to_list Bitvec.bitsToNat_toList

attribute [local simp] Nat.add_comm Nat.add_assoc Nat.add_left_comm Nat.mul_comm Nat.mul_assoc

attribute [local simp] Nat.zero_add Nat.add_zero Nat.one_mul Nat.mul_one Nat.zero_mul Nat.mul_zero

-- mul_left_comm
theorem toNat_append {m : ℕ} (xs : Bitvec m) (b : Bool) :
    Bitvec.toNat (xs++ₜb ::ᵥ nil) = Bitvec.toNat xs * 2 + Bitvec.toNat (b ::ᵥ nil) := by
  cases' xs with xs P
  simp [bitsToNat_toList]; clear P
  unfold bitsToNat
  -- porting note: was `unfold List.foldl`, which now unfolds to an ugly match
  rw [List.foldl, List.foldl]
  -- generalize the accumulator of foldl
  generalize h : 0 = x
  conv in addLsb x b =>
    rw [← h]
  clear h
  simp
  induction' xs with x xs xs_ih generalizing x
  · simp
    unfold addLsb
    simp [Nat.mul_succ]
  · simp
    apply xs_ih
#align bitvec.to_nat_append Bitvec.toNat_append

-- Porting Note: the mathlib3port version of the proof was :
--  simp [bits_to_nat_to_list]
--  unfold bits_to_nat add_lsb List.foldl cond
--  simp [cond_to_bool_mod_two]
theorem bits_toNat_decide (n : ℕ) : Bitvec.toNat (decide (n % 2 = 1) ::ᵥ nil) = n % 2 := by
  simp [bitsToNat_toList]
  unfold bitsToNat addLsb List.foldl
  simp [Nat.cond_decide_mod_two, -Bool.cond_decide]
#align bitvec.bits_to_nat_to_bool Bitvec.bits_toNat_decide

theorem ofNat_succ {k n : ℕ} :
    Bitvec.ofNat (succ k) n = Bitvec.ofNat k (n / 2)++ₜdecide (n % 2 = 1) ::ᵥ nil :=
  rfl
#align bitvec.of_nat_succ Bitvec.ofNat_succ

theorem toNat_ofNat {k n : ℕ} : Bitvec.toNat (Bitvec.ofNat k n) = n % 2 ^ k := by
  induction' k with k ih generalizing n
  · simp [Nat.mod_one]
    rfl
  · rw [ofNat_succ, toNat_append, ih, bits_toNat_decide, mod_pow_succ, Nat.mul_comm]
#align bitvec.to_nat_of_nat Bitvec.toNat_ofNat

/-- Return the integer encoded by the input bitvector -/
protected def toInt : ∀ {n : Nat}, Bitvec n → Int
  | 0, _ => 0
  | succ _, v =>
    cond (head v) (Int.negSucc <| Bitvec.toNat <| Bitvec.not <| tail v)
      (Int.ofNat <| Bitvec.toNat <| tail v)
#align bitvec.to_int Bitvec.toInt

end Conversion

/-! ### Miscellaneous instances -/


private def repr {n : Nat} : Bitvec n → String
  | ⟨bs, _⟩ => "0b" ++ (bs.map fun b : Bool => if b then '1' else '0').asString

instance (n : Nat) : Repr (Bitvec n) where
  reprPrec (b : Bitvec n) _ := Std.Format.text (repr b)

end Bitvec

instance {n} {x y : Bitvec n} : Decidable (Bitvec.Ult x y) :=
  decEq _ _

instance {n} {x y : Bitvec n} : Decidable (Bitvec.Ugt x y) :=
  decEq _ _
