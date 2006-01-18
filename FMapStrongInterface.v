(***********************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team    *)
(* <O___,, *        INRIA-Rocquencourt  &  LRI-CNRS-Orsay              *)
(*   \VV/  *************************************************************)
(*    //   *      This file is distributed under the terms of the      *)
(*         *       GNU Lesser General Public License Version 2.1       *)
(***********************************************************************)

(* Finite maps library.  
 * Authors: Pierre Courtieu and Pierre Letouzey 
 * Institutions: Cédric (CNAM) & PPS (Université Paris 7) *)

(* $Id$ *)

(** This file proposes an interface for finite maps *)

Require Export Bool.
Require Export List.
Require Export Sorting.
Require Export Setoid.
Set Implicit Arguments.
Unset Strict Implicit.

Require Import FSetInterface. 
Require Import FMapInterface. 

(** This file provides a interface for finite maps, with stronger requirements than 
      [FMapInterface]: maps with the same bindings should be equal in the sense 
      of Coq [=]. This additional property is stated in [equal_3]. Except from this, 
      [FMapStrongInterface.S] is a clone from [FMapInterface.S]. 

      NB: This interface can only be used with keys that belongs to an OrderedType 
      whose [eq] is Coq's [=]. These kind of OrderedType are named 
      UsualOrderedType. 
*)

Module Type UsualOrderedType.

  Parameter t : Set.

  Definition eq := @eq t.
  Parameter lt : t -> t -> Prop.

  Definition eq_refl := @refl_equal t.
  Definition eq_sym := @sym_eq t.
  Definition eq_trans := @trans_eq t.
 
  Axiom lt_trans : forall x y z : t, lt x y -> lt y z -> lt x z.
  Axiom lt_not_eq : forall x y : t, lt x y -> ~ x=y.

  Parameter compare : forall x y : t, Compare lt eq x y.
 
  Hint Immediate eq_sym.
  Hint Resolve eq_refl eq_trans lt_not_eq lt_trans.

End UsualOrderedType.

(* A UsualOrderedType is in particular an OrderedType *)
Module UOT_to_OT (U:UsualOrderedType) : OrderedType := U.


Module Type S.

  Parameter key : Set.

  (* unused afterwards, for compatibility with [FMapInterface.S] *)
  Definition keq := @eq key.  

  Parameter t : Set -> Set. (** the abstract type of maps *)
 
  Section Types. 

    Variable elt:Set.

    Parameter empty : t elt.
      (** The empty map. *)

    Parameter is_empty : t elt -> bool.
    (** Test whether a map is empty or not. *)

    Parameter add : key -> elt -> t elt -> t elt.
    (** [add x y m] returns a map containing the same bindings as [m], 
	plus a binding of [x] to [y]. If [x] was already bound in [m], 
	its previous binding disappears. *)

    Parameter find : key -> t elt -> option elt. 
    (** [find x m] returns the current binding of [x] in [m], 
	or raises [Not_found] if no such binding exists.
	NB: in Coq, the exception mechanism becomes a option type. *)

    Parameter remove : key -> t elt -> t elt.
    (** [remove x m] returns a map containing the same bindings as [m], 
	except for [x] which is unbound in the returned map. *)

    Parameter mem : key -> t elt -> bool.
    (** [mem x m] returns [true] if [m] contains a binding for [x], 
	and [false] otherwise. *)

    (** Coq comment: [iter] is useless in a purely functional world *)
    (** val iter : (key -> 'a -> unit) -> 'a t -> unit *)
    (** iter f m applies f to all bindings in map m. f receives the key as 
	first argument, and the associated value as second argument. 
	The bindings are passed to f in increasing order with respect to the 
	ordering over the type of the keys. Only current bindings are 
	presented to f: bindings hidden by more recent bindings are not 
	passed to f. *)

    Variable elt' : Set. 
    Variable elt'': Set.

    Parameter map : (elt -> elt') -> t elt -> t elt'.
    (** [map f m] returns a map with same domain as [m], where the associated 
	value a of all bindings of [m] has been replaced by the result of the
	application of [f] to [a]. The bindings are passed to [f] in 
	increasing order with respect to the ordering over the type of the 
	keys. *)

    Parameter mapi : (key -> elt -> elt') -> t elt -> t elt'.
    (** Same as [S.map], but the function receives as arguments both the 
	key and the associated value for each binding of the map. *)

    Parameter map2 : (option elt -> option elt' -> option elt'') -> t elt -> t elt' ->  t elt''.
    (** Not present in Ocaml. 
         [map f m m'] creates a new map whose bindings belong to the ones of either 
         [m] or [m']. The presence and value for a key [k] is determined by [f e e'] 
         where [e] and [e'] are the (optional) bindings of [k] in [m] and [m']. *)

    Parameter fold : forall A: Set, (key -> elt -> A -> A) -> t elt -> A -> A.
    (** [fold f m a] computes [(f kN dN ... (f k1 d1 a)...)], 
	where [k1] ... [kN] are the keys of all bindings in [m] 
	(in increasing order), and [d1] ... [dN] are the associated data. *)

    Parameter equal : (elt -> elt -> bool) -> t elt -> t elt -> bool.
    (** [equal cmp m1 m2] tests whether the maps [m1] and [m2] are equal, 
      that is, contain equal keys and associate them with equal data. 
      [cmp] is the equality predicate used to compare the data associated 
      with the keys. *)

    Section Spec. 
      
      Variable m m' m'' : t elt.
      Variable x y z : key.
      Variable e e' : elt.

      Parameter MapsTo : key -> elt -> t elt -> Prop.

      Definition In (k:key)(m: t elt) : Prop := exists e:elt, MapsTo k e m.

      Definition Empty m := forall (a : key)(e:elt) , ~ MapsTo a e m.

      Definition eq_key (p p':key*elt) := (fst p) = (fst p').
      
      Definition eq_key_elt (p p':key*elt) := 
          (fst p) = (fst p') /\ (snd p) = (snd p').

    (** Specification of [MapsTo] *)
      Parameter MapsTo_1 : x = y -> MapsTo x e m -> MapsTo y e m.
      
    (** Specification of [mem] *)
      Parameter mem_1 : In x m -> mem x m = true.
      Parameter mem_2 : mem x m = true -> In x m. 
      
    (** Specification of [empty] *)
      Parameter empty_1 : Empty empty.

    (** Specification of [is_empty] *)
      Parameter is_empty_1 : Empty m -> is_empty m = true. 
      Parameter is_empty_2 : is_empty m = true -> Empty m.
      
    (** Specification of [add] *)
      Parameter add_1 : y = x -> MapsTo y e (add x e m).
      Parameter add_2 : x <> y -> MapsTo y e m -> MapsTo y e (add x e' m).
      Parameter add_3 : x <> y -> MapsTo y e (add x e' m) -> MapsTo y e m.

    (** Specification of [remove] *)
      Parameter remove_1 : y = x -> ~ In y (remove x m).
      Parameter remove_2 : x <> y -> MapsTo y e m -> MapsTo y e (remove x m).
      Parameter remove_3 : MapsTo y e (remove x m) -> MapsTo y e m.

    (** Specification of [find] *)
      Parameter find_1 : MapsTo x e m -> find x m = Some e. 
      Parameter find_2 : find x m = Some e -> MapsTo x e m.

    (** Specification of [fold] *)  
      Parameter
	fold_1 :
	forall (A : Set) (i : A) (f : key -> elt -> A -> A),
	  exists l : list (key*elt),
            Unique eq_key l /\
            (forall (k:key)(x:elt), MapsTo k x m <-> InList eq_key_elt (k,x) l) 
            /\
            fold f m i = fold_right (fun p => f (fst p) (snd p)) i l.
 
   Definition Equal cmp m m' := 
         (forall k, In k m <-> In k m') /\ 
         (forall k e e', MapsTo k e m -> MapsTo k e' m' -> cmp e e' = true).  

   Variable cmp : elt -> elt -> bool. 

   (** Specification of [equal] *)
     Parameter equal_1 : Equal cmp m m' -> equal cmp m m' = true. 
     Parameter equal_2 : equal cmp m m' = true -> Equal cmp m m'.
     Parameter equal_3 : (forall e e', cmp e e' =true -> e=e') ->             
         equal cmp  m m' = true -> m = m'.


    End Spec. 
   End Types. 

    (** Specification of [map] *)
      Parameter map_1 : forall (elt elt':Set)(m: t elt)(x:key)(e:elt)(f:elt->elt'), 
        MapsTo x e m -> MapsTo x (f e) (map f m).
      Parameter map_2 : forall (elt elt':Set)(m: t elt)(x:key)(f:elt->elt'), 
        In x (map f m) -> In x m.
 
    (** Specification of [mapi] *)
      Parameter mapi_1 : forall (elt elt':Set)(m: t elt)(x:key)(e:elt)
        (f:key->elt->elt'), MapsTo x e m -> 
        exists y, y = x /\ MapsTo x (f y e) (mapi f m).
      (** NB: this awkward formulation could be simplified, 
            but would break the compatibility with [FMapInterface.S]. *)
      Parameter mapi_2 : forall (elt elt':Set)(m: t elt)(x:key)
        (f:key->elt->elt'), In x (mapi f m) -> In x m.

    (** Specification of [map2] *)
      Parameter map2_1 : forall (elt elt' elt'':Set)(m: t elt)(m': t elt')
	(x:key)(f:option elt->option elt'->option elt''), 
	In x m \/ In x m' -> 
        find x (map2 f m m') = f (find x m) (find x m').       

     Parameter map2_2 : forall (elt elt' elt'':Set)(m: t elt)(m': t elt')
	(x:key)(f:option elt->option elt'->option elt''), 
        In x (map2 f m m') -> In x m \/ In x m'.

  Notation "∅" := empty.
  Notation "a ∈ b" := (In a b) (at level 20).
  Notation "a ∉ b" := (~ a ∈ b) (at level 20).

  Hint Immediate MapsTo_1 mem_2 is_empty_2.
  
  Hint Resolve mem_1 is_empty_1 is_empty_2 add_1 add_2 add_3 remove_1
    remove_2 remove_3 find_1 find_2 fold_1 map_1 map_2 mapi_1 mapi_2. 

End S.

(* A strong map is in particular a regular map *)
Module ForgetStrong (Map:S) : FMapInterface.S := Map.
