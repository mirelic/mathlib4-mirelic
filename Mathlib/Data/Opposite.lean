/-
Copyright (c) 2018 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison, Reid Barton, Simon Hudon, Kenny Lau
-/
import Mathlib.Logic.Equiv.Defs

/-!
# Opposites

In this file we define a type synonym `Opposite α := α`, denoted by `αᵒᵖ` and two synonyms for the
identity map, `op : α → αᵒᵖ` and `unop : αᵒᵖ → α`. If `α` is a category, then `αᵒᵖ` is the opposite
category, with all arrows reversed.
-/


universe v u

-- morphism levels before object levels. See note [category_theory universes].
variable (α : Sort u)

/-- The type of objects of the opposite of `α`; used to define the opposite category.

  In order to avoid confusion between `α` and its opposite type, we
  set up the type of objects `Opposite α` using the following pattern,
  which will be repeated later for the morphisms.

  1. Define `Opposite α := α`.
  2. Define the isomorphisms `op : α → Opposite α`, `unop : Opposite α → α`.
  3. Make the definition `Opposite` irreducible.

  This has the following consequences.

  * `Opposite α` and `α` are distinct types in the elaborator, so you
    must use `op` and `unop` explicitly to convert between them.
  * Both `unop (op X) = X` and `op (unop X) = X` are definitional
    equalities. Notably, every object of the opposite category is
    definitionally of the form `op X`, which greatly simplifies the
    definition of the structure of the opposite category, for example.

  (Now that Lean 4 supports definitional eta equality for records, we could
  achieve the same goals using a structure with one field.)
-/
def Opposite : Sort u :=
  α
#align opposite Opposite

@[inherit_doc]
notation:max -- Use a high right binding power (like that of postfix ⁻¹) so that, for example,
-- `presheaf Cᵒᵖ` parses as `presheaf (Cᵒᵖ)` and not `(presheaf C)ᵒᵖ`.
α "ᵒᵖ" => Opposite α

namespace Opposite

variable {α}

/-- The canonical map `α → αᵒᵖ`. -/
-- Porting note: pp_nodot has not been implemented.
--@[pp_nodot]
def op : α → αᵒᵖ :=
  id

/-- The canonical map `αᵒᵖ → α`. -/
-- Porting note: pp_nodot has not been implemented.
--@[pp_nodot]
def unop : αᵒᵖ → α :=
  id

theorem op_injective : Function.Injective (op : α → αᵒᵖ) := fun _ _ => id

theorem unop_injective : Function.Injective (unop : αᵒᵖ → α) := fun _ _ => id
#align opposite.unop_injective Opposite.unop_injective

@[simp]
theorem op_unop (x : αᵒᵖ) : op (unop x) = x :=
  rfl

@[simp]
theorem unop_op (x : α) : unop (op x) = x :=
  rfl

-- We could prove these by `iff.rfl`, but that would make these eligible for `dsimp`. That would be
-- a bad idea because `opposite` is irreducible.
@[simp]
theorem op_inj_iff (x y : α) : op x = op y ↔ x = y :=
  op_injective.eq_iff

@[simp]
theorem unop_inj_iff (x y : αᵒᵖ) : unop x = unop y ↔ x = y :=
  unop_injective.eq_iff

/-- The type-level equivalence between a type and its opposite. -/
def equivToOpposite : α ≃ αᵒᵖ where
  toFun := op
  invFun := unop
  left_inv := unop_op
  right_inv := op_unop

@[simp]
theorem equivToOpposite_coe : (equivToOpposite : α → αᵒᵖ) = op :=
  rfl
#align opposite.equiv_to_opposite_coe Opposite.equivToOpposite_coe

@[simp]
theorem equivToOpposite_symm_coe : (equivToOpposite.symm : αᵒᵖ → α) = unop :=
  rfl
#align opposite.equiv_to_opposite_symm_coe Opposite.equivToOpposite_symm_coe

theorem op_eq_iff_eq_unop {x : α} {y} : op x = y ↔ x = unop y :=
  equivToOpposite.apply_eq_iff_eq_symm_apply

theorem unop_eq_iff_eq_op {x} {y : α} : unop x = y ↔ x = op y :=
  equivToOpposite.symm.apply_eq_iff_eq_symm_apply

instance [Inhabited α] : Inhabited αᵒᵖ :=
  ⟨op default⟩

/-- A recursor for `Opposite`. Use as `induction x using Opposite.rec`. -/
@[simp]
protected def rec {F : αᵒᵖ → Sort v} (h : ∀ X, F (op X)) : ∀ X, F X := fun X => h (unop X)

end Opposite
