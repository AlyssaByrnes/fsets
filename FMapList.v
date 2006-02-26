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

(** This file proposes an implementation of the non-dependant interface
 [FMapInterface.S] using lists of pairs ordered (increasing) with respect to
 left projection. *)

Require Import FSetInterface. 
Require Import FMapInterface.

Set Implicit Arguments.
Unset Strict Implicit.

(** Usual syntax for lists. *)
Notation "[]" := nil (at level 0).
Arguments Scope list [type_scope].

Module Raw (X:OrderedType).
  Module E := X.
  Module MX := OrderedTypeFacts X.
  Module PX := PairOrderedType X.
  Import MX. 
  Import PX. 

  Definition key := X.t.
  Definition t (elt:Set) := list (X.t * elt).

  Section Elt.
  Variable elt : Set.

(* Now in PairOrderedtype: 
  Definition eqk (p p':key*elt) := X.eq (fst p) (fst p').
  Definition eqke (p p':key*elt) := 
          X.eq (fst p) (fst p') /\ (snd p) = (snd p').
  Definition ltk (p p':key*elt) := X.lt (fst p) (fst p').
  Definition MapsTo (k:key)(e:elt):= InA eqke (k,e).
  Definition In k m := exists e:elt, MapsTo k e m.
*)

  Notation eqk := (eqk (elt:=elt)).   
  Notation eqke := (eqke (elt:=elt)).
  Notation ltk := (ltk (elt:=elt)).
  Notation MapsTo := (MapsTo (elt:=elt)).
  Notation In := (In (elt:=elt)).
  Notation Sort := (sort ltk).
  Notation Inf := (lelistA (ltk)).

    Definition empty : t elt := [].

    (** Specification of [empty] *)

    Definition Empty m := forall (a : key)(e:elt) , ~ MapsTo a e m.

    Lemma empty_1 : Empty empty.
    Proof.  
      unfold Empty,empty.
      intros a e.
      intro abs.
      inversion abs.
    Qed.
    Hint Resolve empty_1.

    Lemma empty_sorted : Sort empty.
    Proof. 
     unfold empty; auto.
    Qed.

    Definition is_empty (l : t elt) : bool := if l then true else false.

    (** Specification of [is_empty] *)

    Lemma is_empty_1 :forall m, Empty m -> is_empty m = true. 
    Proof.
      unfold Empty, PX.MapsTo.
      intros m.
      case m;auto.
      intros (k,e) l inlist.
      absurd (InA eqke (k, e) ((k, e) :: l));auto.
    Qed.

    Lemma is_empty_2 : forall m, is_empty m = true -> Empty m.
    Proof.  
      intros m.
      case m;auto.
      intros p l abs.
      inversion abs.
    Qed.


    Fixpoint mem (k : key) (s : t elt) {struct s} : bool :=
      match s with
	| [] => false
	| (k',_) :: l =>
          match X.compare k k' with
            | Lt _ => false
            | Eq _ => true
            | Gt _ => mem k l
          end
      end.
    
    (** Specification of [mem] *)

    Lemma mem_1 : forall m (Hm:Sort m) x, In x m -> mem x m = true.
    Proof.  
      intros m Hm x; generalize Hm; clear Hm.      
      functional induction mem x m;intros sorted belong1;trivial.
      
      inversion belong1. inversion H.
      
      absurd (In k ((k', e) :: l));try assumption.
      eapply Sort_Inf_NotIn with e;auto.

      apply H.
      elim (sort_inv sorted);auto.
      elim (In_inv belong1);auto.
      intro abs.
      absurd (X.eq k k');auto.
    Qed. 


    Lemma mem_2 : forall m (Hm:Sort m) x, mem x m = true -> In x m. 
    Proof.
      intros m Hm x; generalize Hm; clear Hm; unfold PX.In,PX.MapsTo.
      functional induction mem x m; intros sorted hyp;try ((inversion hyp);fail).
      exists e;eauto. 
      induction H; eauto.
      inversion_clear sorted; auto.
    Qed.


    Fixpoint find (k:key) (s: t elt) {struct s} : option elt :=
      match s with
	| [] => None
	| (k',x)::s' => 
	  match X.compare k k' with
	    | Lt _ => None
	    | Eq _ => Some x
	    | Gt _ => find k s'
	  end
      end.

    (** Specification of [find] *)

    Lemma find_2 :  forall m x e, find x m = Some e -> MapsTo x e m.
    Proof.
      intros m x. unfold PX.MapsTo.
      functional induction find x m;simpl;intros e' eqfind; inversion eqfind; auto.
    Qed.

    Lemma find_1 :  forall m (Hm:Sort m) x e, MapsTo x e m -> find x m = Some e. 
    Proof.
      intros m Hm x e; generalize Hm; clear Hm; unfold PX.MapsTo.
      functional induction find x m;simpl; subst; try clear H_eq_1.

      inversion 2.

      intros; elimtype False.
      inversion_clear H.
      absurd (X.eq k k'); auto.
      destruct H0; simpl in *; intuition. 
      assert (H2 := Sort_In_cons_1 Hm (InA_eqke_eqk H0)).
      compute in H2; intuition. 
      absurd (X.lt k k'); auto.
      
      intros.
      inversion_clear H.
      destruct H0; simpl in *; intuition congruence. 
      assert (H2 := Sort_In_cons_1 Hm (InA_eqke_eqk H0)).
      compute in H2; intuition.
      absurd (X.eq k k'); auto.
      
      intros.
      inversion_clear Hm; inversion_clear H0.
      absurd (X.eq k k'); auto.
      destruct H3; simpl in *; auto.
      eauto.
    Qed.


    Fixpoint add (k : key) (x : elt) (s : t elt) {struct s} : t elt :=
      match s with
	| [] => (k,x) :: []
	| (k',y) :: l =>
          match X.compare k k' with
            | Lt _ => (k,x)::s
            | Eq _ => (k,x)::l
            | Gt _ => (k',y) :: add k x l
          end
      end.


    (** Specification of [add] *)

    Lemma add_1 : forall m x y e, X.eq y x -> MapsTo y e (add x e m).
    Proof.
      intros m x y e; generalize y; clear y.
      unfold PX.MapsTo.
      functional induction add x e m;simpl;auto.
    Qed.

    Lemma add_2 : forall m x y e e', 
      ~ X.eq x y -> MapsTo y e m -> MapsTo y e (add x e' m).
    Proof.
      intros m x  y e e'. 
      generalize y e; clear y e; unfold PX.MapsTo.
      functional induction add x e' m;simpl;auto.
      intros y' e' eqky';  inversion_clear 1; destruct H0; simpl in *; intuition.
      elimtype False; eauto.

      intros y' e' eqky'; inversion_clear 1; intuition.
    Qed.
      
    Lemma add_3 : forall m x y e e',
      ~ X.eq x y -> MapsTo y e (add x e' m) -> MapsTo y e m.
    Proof.
      intros m x y e e'. generalize y e; clear y e; unfold PX.MapsTo.
      functional induction add x e' m;simpl;eauto.
      intros e' y' eqky' Hinlist.
      inversion Hinlist;eauto.
    Qed.

   Lemma add_Inf :
     forall (m : t elt) (x x':key)(e e':elt), Inf (x',e') m -> ltk (x',e') (x,e) -> Inf (x',e') (add x e m).
   Proof.
     induction m.  
     simpl; intuition.
     intros.
     destruct a as (x'',e'').
     inversion_clear H.
     compute in H0,H1.
     simpl; case (X.compare x x''); intuition.
  Qed.
  Hint Resolve add_Inf.

  Lemma add_sorted : forall m (Hm:Sort m) x e, Sort (add x e m).
  Proof.
   induction m.
   simpl; intuition.
   intros.
   destruct a as (x',e').
   simpl; case (X.compare x x'); intuition; inversion_clear Hm; auto.
   constructor; auto.
   apply Inf_eq with (x',e'); auto.
  Qed.  

  Fixpoint remove (k : key) (s : t elt) {struct s} : t elt :=
      match s with
	| [] => []
	| (k',x) :: l =>
          match X.compare k k' with
            | Lt _ => s
            | Eq _ => l
            | Gt _ => (k',x) :: remove k l
          end
      end.  


   (** Specification of [remove] *)

    Lemma remove_1 : forall m (Hm:Sort m) x y, X.eq y x -> ~ In y (remove x m).
      intros m Hm x y; generalize Hm; clear Hm.
    Proof.
      functional induction remove x m;simpl;intros;auto.
      
      red; inversion 1; inversion H1.

      subst.
      eapply Sort_Inf_NotIn with x.
      eauto.
      apply cons_leA;simpl.
      red; eapply MX.lt_eq;eauto.
      
      inversion_clear Hm.
      eapply Sort_Inf_NotIn with x. eauto. 
      eapply Inf_eq with (k',x) ;simpl;auto.
      intuition; eauto.

      inversion_clear Hm.
      assert (notin:~ In y (remove k l)). apply H;eauto.
      intros (x0,abs).
      inversion_clear abs; eauto. 
      destruct H3; simpl in *; subst.
      clear H_eq_1; order.
    Qed.
      
      
    Lemma remove_2 : forall m (Hm:Sort m) x y e, 
      ~ X.eq x y -> MapsTo y e m -> MapsTo y e (remove x m).
      intros m Hm x y e; generalize Hm; clear Hm; unfold PX.MapsTo.
    Proof.  
      functional induction remove x m;auto.
      intros sorted noteqky inlist.
      inversion_clear inlist; compute in H; intuition; elimtype False; eauto.

      intros sorted noteqky inlist.
      inversion_clear sorted; auto.
      inversion_clear inlist; auto.
    Qed.


    Lemma remove_3 : forall m (Hm:Sort m) x y e, MapsTo y e (remove x m) -> MapsTo y e m.
    Proof.
      intros m Hm x y e; generalize Hm; clear Hm; unfold PX.MapsTo.
      functional induction remove x m;auto.
      intros sorted inlist.
      inversion_clear sorted.
      inversion_clear inlist; auto.
    Qed.

   Lemma remove_Inf :
     forall (m : t elt) (Hm : Sort m)(x x':key)(e':elt), Inf (x',e') m -> Inf (x',e') (remove x m).
   Proof.
     induction m.  
     simpl; intuition.
     intros.
     destruct a as (x'',e'').
     inversion_clear H.
     compute in H0.
     simpl; case (X.compare x x''); intuition.
     inversion_clear Hm.
     eapply Inf_lt; eauto; auto.
  Qed.
  Hint Resolve remove_Inf.

  Lemma remove_sorted : forall m (Hm:Sort m) x, Sort (remove x m).
  Proof.
    induction m.
    simpl; intuition.
    intros.
    destruct a as (x',e').
    simpl; case (X.compare x x'); intuition; inversion_clear Hm; auto.
  Qed.  

  Definition elements (m: t elt) := m.

    Lemma elements_1 : forall m x e, 
        MapsTo x e m -> InA eqke (x,e) (elements m).
    Proof.
    auto.
    Qed.

    Lemma elements_2 : forall m x e, 
        InA eqke (x,e) (elements m) -> MapsTo x e m.
    Proof. 
    auto.
    Qed.

    Lemma elements_3 : forall m (Hm:Sort m),
       sort ltk (elements m). 
    Proof. 
    auto.
    Qed.

    Fixpoint fold (A:Set) (f:key -> elt -> A -> A) (m:t elt) {struct m} : A -> A :=
      fun acc => 
      match m with
	| [] => acc
	| (k,e)::m' => fold f m' (f k e acc)
      end.

    Lemma fold_1 : 
	forall m (A : Set) (i : A) (f : key -> elt -> A -> A),
        fold f m i = fold_left (fun a p => f (fst p) (snd p) a) (elements m) i.
     Proof. 
     intros; functional induction fold A f m i; auto.
     Qed.

     Fixpoint equal (cmp: elt -> elt -> bool)(m m' : t elt) { struct m } : bool := 
       match m, m' with 
        | [], [] => true
        | (x,e)::l, (x',e')::l' => 
            match X.compare x x' with 
             | Eq _ => cmp e e' && equal cmp l l'
             | _       => false
            end 
        | _, _ => false 
       end.

     Definition Equal cmp m m' := 
         (forall k, In k m <-> In k m') /\ 
         (forall k e e', MapsTo k e m -> MapsTo k e' m' -> cmp e e' = true).  

     (** Specification of [equal] *)

        Lemma equal_1 : forall m (Hm:Sort m) m' (Hm': Sort m') cmp, 
           Equal cmp m m' -> equal cmp m m' = true. 
        Proof. 
        intros m Hm m' Hm' cmp; generalize Hm Hm'; clear Hm Hm'.
        functional induction equal cmp m m'; simpl; auto; unfold Equal; intuition.

        destruct p as (k,e).
        destruct (H0 k).
        destruct H2.
        exists e; auto.
        inversion H2.

        destruct (H0 x).
        destruct H.
        exists e; auto.
        inversion H.

        subst; clear H_eq_3.
        destruct (H0 x).
        assert (In x ((x',e')::l')). 
          apply H; auto.
          exists e; auto.
        destruct (In_inv H3).
        absurd (X.lt x x'); eauto.
        inversion_clear Hm'.
        assert (Inf (x,e) l').
        eapply Inf_lt; eauto; auto. (* eauto n'est pas strictement plus fort que auto ??! *)
        elim (Sort_Inf_NotIn H5 H7 H4).
        
        subst.
        assert (cmp e e' = true).
          apply H2 with x; auto.
        rewrite H0; simpl.
       apply H; auto.
       inversion_clear Hm; auto.
       inversion_clear Hm'; auto.
       unfold Equal; intuition.
       destruct (H1 k).
       assert (In k ((x,e) ::l)).
         destruct H3 as (e'', hyp); exists e''; auto.
       destruct (In_inv (H4 H6)); auto.
       inversion_clear Hm.
       elim (Sort_Inf_NotIn H8 H9).
       destruct H3 as (e'', hyp); exists e''; auto.
       apply MapsTo_eq with k; eauto.
       destruct (H1 k).
       assert (In k ((x',e') ::l')).
         destruct H3 as (e'', hyp); exists e''; auto.
       destruct (In_inv (H5 H6)); auto.
       inversion_clear Hm'.
       elim (Sort_Inf_NotIn H8 H9).
       destruct H3 as (e'', hyp); exists e''; auto.
       apply MapsTo_eq with k; eauto.
       apply H2 with k; destruct (MX.eq_dec x k); auto.

        subst; clear H_eq_3.
        destruct (H0 x').
        assert (In x' ((x,e)::l)). 
          apply H2; auto.
          exists e'; auto.
        destruct (In_inv H3).
        absurd (X.lt x' x); eauto.
        inversion_clear Hm.
        assert (Inf (x',e') l).
        eapply Inf_lt; eauto; auto. (* eauto n'est pas strictement plus fort que auto ??! *)
        elim (Sort_Inf_NotIn H5 H7 H4).
     Qed.

      Lemma equal_2 : forall m (Hm:Sort m) m' (Hm:Sort m') cmp, 
         equal cmp m m' = true -> Equal cmp m m'.
      Proof.
       intros m Hm m' Hm' cmp; generalize Hm Hm'; clear Hm Hm'.
       functional induction equal cmp m m'; simpl; auto; unfold Equal; intuition; try discriminate; subst.
       inversion H0.

       destruct (andb_prop _ _ H0); clear H0.
       inversion_clear Hm; inversion_clear Hm'.
       destruct (H H0 H5 H3).
       destruct (In_inv H1).
       exists e'; eauto.
       destruct (H7 k).
       red.
       destruct (H10 H9) as (e'',hyp).
       exists e''; eauto.

       destruct (andb_prop _ _ H0); clear H0.
       inversion_clear Hm; inversion_clear Hm'.
       destruct (H H0 H5 H3).
       destruct (In_inv H1).
       exists e; eauto.
       destruct (H7 k).
       destruct (H11 H9) as (e'',hyp).
       exists e''; eauto.

       destruct (andb_prop _ _ H0); clear H0.
       inversion_clear Hm; inversion_clear Hm'.
       destruct (H H0 H6 H4).
       inversion_clear H1.
       destruct H10; simpl in *; subst.
       inversion_clear H2. 
       destruct H10; simpl in *; subst; auto.
       elim (Sort_Inf_NotIn H6 H7).
       exists e'0; apply MapsTo_eq with k; eauto.
       inversion_clear H2. 
       destruct H1; simpl in *; subst; auto.
       elim (Sort_Inf_NotIn H0 H5).
       exists e1; apply MapsTo_eq with k; eauto.
       apply H9 with k; eauto.
      Qed. 

      (* This lemma isn't part of the spec of [Equal], but is used in [FMapAVL] *)
      Lemma equal_cons :
       forall cmp l1 l2 x y, Sort (x::l1) -> Sort (y::l2) ->
 	eqk x y -> cmp (snd x) (snd y) = true -> 
 	(Equal cmp l1 l2 <-> Equal cmp (x :: l1) (y :: l2)).
      Proof.
      intros.
      inversion H; subst.
      inversion H0; subst.
      destruct x; destruct y; compute in H1, H2.
      split; intros.
      apply equal_2; auto.
      simpl.
      MX.compare.
      rewrite H2; simpl.
      apply equal_1; auto.
      apply equal_2; auto.
      generalize (equal_1 H H0 H3).
      simpl.
      MX.compare.
      rewrite H2; simpl; auto.
      Qed.

      Variable elt':Set.
      
      Fixpoint map (f:elt -> elt') (m:t elt) {struct m} : t elt' :=
	match m with
	  | [] => []
	  | (k,e)::m' => (k,f e) :: map f m'
	end.

      Fixpoint mapi (f: key -> elt -> elt') (m:t elt) {struct m} : t elt' :=
	match m with
	  | [] => []
	  | (k,e)::m' => (k,f k e) :: mapi f m'
	end.

      End Elt.
      Section Elt2. 
      (* For previous definitions to work with different [elt], especially [MapsTo]... *)
      
      Variable elt elt' : Set.

    (** Specification of [map] *)

      Lemma map_1 : forall (m:t elt)(x:key)(e:elt)(f:elt->elt'), 
        MapsTo x e m -> MapsTo x (f e) (map f m).
      Proof.
	intros m x e f.
	(* functional induction map elt elt' f m.  *) (* Marche pas ??? *)
        induction m.
        inversion 1.
        
        destruct a as (x',e').
        simpl. 
        inversion_clear 1.
        constructor 1.
        unfold eqke in *; simpl in *; intuition congruence.
        constructor 2.
        unfold MapsTo in *; auto.
      Qed.

      Lemma map_2 : forall (m:t elt)(x:key)(f:elt->elt'), 
        In x (map f m) -> In x m.
      Proof.
	intros m x f. 
        (* functional induction map elt elt' f m. *) (* Marche pas ??? *)
        induction m; simpl.
        intros (e,abs).
        inversion abs.
        
        destruct a as (x',e).
	intros hyp.
	inversion hyp. clear hyp.
	inversion H; subst; rename x0 into e'.
        exists e; constructor.
        unfold eqke in *; simpl in *; intuition.
        destruct IHm as (e'',hyp).
        exists e'; auto.
        exists e''.
        constructor 2; auto.
      Qed.

      Lemma map_lelistA : 
         forall (m: t elt)(x:key)(e:elt)(e':elt')(f:elt->elt'),
         lelistA (@ltk elt) (x,e) m -> 
         lelistA (@ltk elt') (x,e') (map f m).
      Proof. 
        induction m; simpl; auto.
        intros.
        destruct a as (x0,e0).
        inversion_clear H; auto.
      Qed.

      Hint Resolve map_lelistA.

      Lemma map_sorted : 
         forall (m: t elt)(Hm : sort (@ltk elt) m)(f:elt -> elt'), 
         sort (@ltk elt') (map f m).
      Proof.   
      induction m; simpl; auto.
      intros.
      destruct a as (x',e').
      inversion_clear Hm; eauto.
      Qed.      
      
 
    (** Specification of [mapi] *)

      Lemma mapi_1 : forall (m:t elt)(x:key)(e:elt)
        (f:key->elt->elt'), MapsTo x e m -> 
        exists y, X.eq y x /\ MapsTo x (f y e) (mapi f m).
      Proof.
	intros m x e f.
	(* functional induction mapi elt elt' f m. *) (* Marche pas ??? *)
        induction m.
        inversion 1.
        
        destruct a as (x',e').
        simpl. 
        inversion_clear 1.
        exists x'.
        destruct H0; simpl in *.
        split; auto.
        constructor 1.
        unfold eqke in *; simpl in *; intuition congruence.
        destruct IHm as (y, hyp); auto.
        exists y; intuition.
      Qed.  


      Lemma mapi_2 : forall (m:t elt)(x:key)
        (f:key->elt->elt'), In x (mapi f m) -> In x m.
      Proof.
	intros m x f. 
        (* functional induction mapi elt elt' f m. *) (* Marche pas ??? *)
        induction m; simpl.
        intros (e,abs).
        inversion abs.
        
        destruct a as (x',e).
	intros hyp.
	inversion hyp. clear hyp.
	inversion H; subst; rename x0 into e'.
        exists e; constructor.
        unfold eqke in *; simpl in *; intuition.
        destruct IHm as (e'',hyp).
        exists e'; auto.
        exists e''.
        constructor 2; auto.
      Qed.

      Lemma mapi_lelistA : 
         forall (m: t elt)(x:key)(e:elt)(f:key->elt->elt'),
         lelistA (@ltk elt) (x,e) m -> 
         lelistA (@ltk elt') (x,f x e) (mapi f m).
      Proof. 
        induction m; simpl; auto.
        intros.
        destruct a as (x',e').
        inversion_clear H; auto.
      Qed.

      Hint Resolve mapi_lelistA.

      Lemma mapi_sorted : 
         forall (m: t elt)(Hm : sort (@ltk elt) m)(f: key ->elt -> elt'), 
         sort (@ltk elt') (mapi f m).
      Proof.
      induction m; simpl; auto.
      intros.
      destruct a as (x',e').
      inversion_clear Hm; auto.
      Qed.

    End Elt2. 
    Section Elt3.

      Variable elt elt' elt'' : Set.
      Variable f : option elt -> option elt' -> option elt''.

      Definition option_cons (A:Set)(k:key)(o:option A)(l:list (key*A)) := 
         match o with 
           | Some e => (k,e)::l
           | None => l
         end.

      Fixpoint map2_l (m : t elt) : t elt'' := 
        match m with 
          | [] => [] 
          | (k,e)::l => option_cons k (f (Some e) None) (map2_l l)
        end. 

      Fixpoint map2_r (m' : t elt') : t elt'' := 
        match m' with 
          | [] => [] 
          | (k,e')::l' => option_cons k (f None (Some e')) (map2_r l')
        end. 

      Fixpoint map2 (m : t elt) : t elt' -> t elt'' :=
        match m with
          | [] => map2_r 
          | (k,e) :: l =>
            fix map2_aux (m' : t elt') : t elt'' :=
              match m' with
                | [] => map2_l m
                | (k',e') :: l' =>
                  match X.compare k k' with
                    | Lt _ => option_cons k (f (Some e) None) (map2 l m')
                    | Eq _ => option_cons k (f (Some e) (Some e')) (map2 l l')
                    | Gt _ => option_cons k' (f None (Some e')) (map2_aux l')
                  end
              end
        end.      

     Fixpoint combine (m : t elt) : t elt' -> t (option elt * option elt') :=
        match m with
          | [] => map (fun e' => (None,Some e'))
          | (k,e) :: l =>
            fix combine_aux (m' : t elt') : list (key * (option elt * option elt')) :=
              match m' with
                | [] => map (fun e => (Some e,None)) m
                | (k',e') :: l' =>
                  match X.compare k k' with
                    | Lt _ => (k,(Some e, None))::combine l m'
                    | Eq _ => (k,(Some e, Some e'))::combine l l'
                    | Gt _ => (k',(None,Some e'))::combine_aux l'
                  end
              end
        end. 

    Definition fold_right_pair (A B C:Set)(f: A -> B -> C -> C)(l:list (A*B))(i:C) := 
           List.fold_right (fun p => f (fst p) (snd p)) i l.

    Definition map2_alt m m' := 
      let m0 : t (option elt * option elt') := combine m m' in 
      let m1 : t (option elt'') := map (fun p => f (fst p) (snd p)) m0 in 
      fold_right_pair (option_cons (A:=elt'')) m1 nil.

    Lemma map2_alt_equiv : 
      forall m m', map2_alt m m' = map2 m m'.
    Proof.
    unfold map2_alt.
    induction m.
    simpl; auto; intros.
    (* map2_r *)
    induction m'; try destruct a; simpl; auto.
    rewrite IHm'; auto.
    (* fin map2_r *)
    induction m'; destruct a.
    simpl; f_equal.
    (* map2_l *)
    clear IHm.
    induction m; try destruct a; simpl; auto.
    rewrite IHm; auto.
    (* fin map2_l *)
    destruct a0.
    simpl.
    destruct (X.compare t0 t1); simpl; f_equal.
    apply IHm.
    apply IHm.
    apply IHm'.
    Qed.

   Lemma combine_lelistA : 
      forall (m: t elt)(m': t elt')(x:key)(e:elt)(e':elt')(e'':option elt * option elt'), 
        lelistA (@ltk elt) (x,e) m -> 
        lelistA (@ltk elt') (x,e') m' -> 
        lelistA (@ltk (option elt * option elt')) (x,e'') (combine m m').
    Proof.
    induction m. 
    intros.
    simpl.
    eapply map_lelistA; eauto.
    induction m'. 
    intros.
    destruct a.
    replace (combine ((t0, e0) :: m) []) with 
                 (map (fun e => (Some e,None (A:=elt'))) ((t0,e0)::m)); auto.
    eapply map_lelistA; eauto.
    intros.
    simpl.
    destruct a as (k,e0); destruct a0 as (k',e0').
    destruct (X.compare k k').
    inversion_clear H; auto.
    inversion_clear H; auto.
    inversion_clear H0; auto.
    Qed.
    Hint Resolve combine_lelistA.

    Lemma combine_sorted : 
      forall (m: t elt)(Hm : sort (@ltk elt) m)(m': t elt')(Hm' : sort (@ltk elt') m'), 
      sort (@ltk (option elt * option elt')) (combine m m').
    Proof.
    induction m. 
    intros; clear Hm.
    simpl.
    apply map_sorted; auto.
    induction m'. 
    intros; clear Hm'.
    destruct a.
    replace (combine ((t0, e) :: m) []) with 
                 (map (fun e => (Some e,None (A:=elt'))) ((t0,e)::m)); auto.
    apply map_sorted; auto.
    intros.
    simpl.
    destruct a as (k,e); destruct a0 as (k',e').
    destruct (X.compare k k').
    inversion_clear Hm.
    constructor; auto.
    eapply combine_lelistA with (e':=e'); eauto.
    inversion_clear Hm; inversion_clear Hm'.
    constructor; eauto.
    eapply combine_lelistA with (e':=e'); eauto.
    apply Inf_eq with (k',e'); auto.
    inversion_clear Hm; inversion_clear Hm'.
    constructor; auto.
    change (lelistA (ltk (elt:=option elt * option elt')) (k', (None, Some e'))
                     (combine ((k,e)::m) m')).
    eapply combine_lelistA with (e:=e); eauto.
    Qed.
    
    Lemma map2_sorted : 
      forall (m: t elt)(Hm : sort (@ltk elt) m)(m': t elt')(Hm' : sort (@ltk elt') m'), 
      sort (@ltk elt'') (map2 m m').
     Proof.
     intros.
     rewrite <- map2_alt_equiv.
     unfold map2_alt.
     assert (H0:=combine_sorted Hm Hm').
     set (l0:=combine m m') in *; clearbody l0.
     set (f':= fun p : option elt * option elt' => f (fst p) (snd p)).
     assert (H1:=map_sorted (elt' := option elt'') H0 f').
     set (l1:=map f' l0) in *; clearbody l1. 
     clear f' f H0 l0 Hm Hm' m m'.
     induction l1.
     simpl; auto.
     inversion_clear H1.
     destruct a; destruct o; auto.
     simpl.
     constructor; auto.
     clear IHl1.
     induction l1.
     simpl; auto.
     destruct a; destruct o; simpl; auto.
     inversion_clear H0; auto.
     inversion_clear H0.
     red in H1; simpl in H1.
     inversion_clear H.
     apply IHl1; auto.
     eapply Inf_lt; eauto.
     red; auto.
     Qed.
     
     Definition at_least_one (o:option elt)(o':option elt') := 
         match o, o' with 
           | None, None => None 
           | _, _  => Some (o,o')
         end.

    Lemma combine_1 : 
      forall (m: t elt)(Hm : sort (@ltk elt) m)(m': t elt')(Hm' : sort (@ltk elt') m') 
      (x:key), 
      find x (combine m m') = at_least_one (find x m) (find x m'). 
    Proof.
    induction m.
    intros.
    simpl.
    induction m'.
    intros; simpl; auto.
    simpl; destruct a.
    simpl; destruct (X.compare x t0); simpl; auto.
    inversion_clear Hm'; auto.
    induction m'.
    (* m' = [] *)
    intros; destruct a; simpl.
    destruct (X.compare x t0); simpl; auto.
    inversion_clear Hm; clear H0 l Hm' IHm t0.
    induction m; simpl; auto.
    inversion_clear H.
    destruct a.
    simpl; destruct (X.compare x t0); simpl; auto.
    (* m' <> [] *)
    intros.
    destruct a as (k,e); destruct a0 as (k',e'); simpl.
    inversion Hm; inversion Hm'; subst.
    destruct (X.compare k k'); simpl;
      destruct (X.compare x k); 
        MX.compare || destruct (X.compare x k'); simpl; auto.
    rewrite IHm; auto; simpl; MX.compare; auto.
    rewrite IHm; auto; simpl; MX.compare; auto.
    rewrite IHm; auto; simpl; MX.compare; auto.
    change ((find x (combine ((k, e) :: m) m')) = at_least_one None (find x m')).
    rewrite IHm'; auto. 
    simpl find; MX.compare; auto.
    change ((find x (combine ((k, e) :: m) m')) = Some (Some e, find x m')).
    rewrite IHm'; auto. 
    simpl find; MX.compare; auto.
    change ((find x (combine ((k, e) :: m) m')) = at_least_one (find x m) (find x m')).
    rewrite IHm'; auto. 
    simpl find; MX.compare; auto.
    Qed.

    Definition at_least_one_then_f (o:option elt)(o':option elt') := 
         match o, o' with 
           | None, None => None 
           | _, _  => f o o'
         end.

    Lemma map2_0 : 
      forall (m: t elt)(Hm : sort (@ltk elt) m)(m': t elt')(Hm' : sort (@ltk elt') m') 
      (x:key), 
      find x (map2 m m') = at_least_one_then_f (find x m) (find x m'). 
    Proof.
    intros.
    rewrite <- map2_alt_equiv.
    unfold map2_alt.
    assert (H:=combine_1 Hm Hm' x).
    assert (H2:=combine_sorted Hm Hm').
    set (f':= fun p : option elt * option elt' => f (fst p) (snd p)).
    set (m0 := combine m m') in *; clearbody m0.
    set (o:=find x m) in *; clearbody o. 
    set (o':=find x m') in *; clearbody o'.
    clear Hm Hm' m m'.
    generalize H; clear H.
    match goal with |- ?g => 
       assert (g /\ (find x m0 = None -> 
                           find x (fold_right_pair (option_cons (A:=elt'')) (map f' m0) []) 
                           = None)); 
       [ | intuition ] end.
    induction m0; simpl in *; intuition.
    destruct o; destruct o'; simpl in *; try discriminate; auto.
    destruct a as (k,(oo,oo')); simpl in *.
    inversion_clear H2.
    destruct (X.compare x k); simpl in *.
    (* x < k *)
    destruct (f' (oo,oo')); simpl.
    MX.compare.
    destruct o; destruct o'; simpl in *; try discriminate; auto.
    destruct (IHm0 H0) as (H2,_); apply H2; auto.
    rewrite <- H.
    case_eq (find x m0); intros; auto.
    assert (ltk (elt:=option elt * option elt') (x,(oo,oo')) (k,(oo,oo'))).
     red; auto.
    destruct (Sort_Inf_NotIn H0 (Inf_lt H4 H1)).
    exists p; apply find_2; eauto.
    (* x = k *)
    assert (at_least_one_then_f o o' = f oo oo').
      destruct o; destruct o'; simpl in *; inversion_clear H; auto.
    rewrite H2.
    unfold f'; simpl.
    destruct (f oo oo'); simpl.
    MX.compare; auto.
    destruct (IHm0 H0) as (_,H4); apply H4; auto.
    case_eq (find x m0); intros; auto.
    assert (eqk (elt:=option elt * option elt') (k,(oo,oo')) (x,(oo,oo'))).
     red; auto.
    destruct (Sort_Inf_NotIn H0 (Inf_eq (eqk_sym H5) H1)).
    exists p; apply find_2; eauto.
    (* k < x *)
    unfold f'; simpl.
    destruct (f oo oo'); simpl.
    MX.compare; auto.
    destruct (IHm0 H0) as (H3,_); apply H3; auto.
    destruct (IHm0 H0) as (H3,_); apply H3; auto.

    (* None -> None *)
    destruct a as (k,(oo,oo')).
    simpl.
    inversion_clear H2.
    destruct (X.compare x k).
    (* x < k *)
    unfold f'; simpl.
    destruct (f oo oo'); simpl.
    MX.compare; auto.
    destruct (IHm0 H0) as (_,H4); apply H4; auto.
    case_eq (find x m0); intros; auto.
    assert (ltk (elt:=option elt * option elt') (x,(oo,oo')) (k,(oo,oo'))).
     red; auto.
    destruct (Sort_Inf_NotIn H0 (Inf_lt H3 H1)).
    exists p; apply find_2; eauto.
    (* x = k *)
    discriminate.
    (* k < x *)
    unfold f'; simpl.
    destruct (f oo oo'); simpl.
    MX.compare; auto.
    destruct (IHm0 H0) as (_,H4); apply H4; auto.
    destruct (IHm0 H0) as (_,H4); apply H4; auto.
    Qed.

     (** Specification of [map2] *)
     Lemma map2_1 : forall (m: t elt)(Hm : sort (@ltk elt) m)
        (m': t elt')(Hm' : sort (@ltk elt') m')(x:key),
	In x m \/ In x m' -> 
        find x (map2 m m') = f (find x m) (find x m'). 
     Proof.
     intros.
     rewrite map2_0; auto.
     destruct H as [(e,H)|(e,H)].
     rewrite (find_1 Hm H).
     destruct (find x m'); simpl; auto.
     rewrite (find_1 Hm' H).
     destruct (find x m); simpl; auto.
     Qed.
     
     Lemma map2_2 : forall (m: t elt)(Hm : sort (@ltk elt) m)
        (m': t elt')(Hm' : sort (@ltk elt') m')(x:key), 
        In x (map2 m m') -> In x m \/ In x m'. 
     Proof.
     intros.
     destruct H as (e,H).
     generalize (map2_0 Hm Hm' x).
     rewrite (find_1 (map2_sorted Hm Hm') H).
     generalize (@find_2 _ m x).
     generalize (@find_2 _ m' x).
     destruct (find x m); 
       destruct (find x m'); simpl; intros.
     left; exists e0; auto. 
     left; exists e0; auto.
     right; exists e0; auto.
     discriminate.
     Qed.

   End Elt3.

End Raw.

Module Make (X: OrderedType) <: S with Module E := X.
  Module Raw := Raw X. 
  Module E := X.

  Definition key := X.t.

  Record slist (elt:Set) : Set :=  {this :> Raw.t elt; sorted : sort (@Raw.PX.ltk elt) this}.
  Definition t (elt:Set) := slist elt. 

 Section Elt. 
 Variable elt elt' elt'':Set. 

 Implicit Types m : t elt.

 Definition empty := Build_slist (Raw.empty_sorted elt).
 Definition is_empty m := Raw.is_empty m.(this).
 Definition add x e m := Build_slist (Raw.add_sorted m.(sorted) x e).
 Definition find x m := Raw.find x m.(this).
 Definition remove x m := Build_slist (Raw.remove_sorted m.(sorted) x). 
 Definition mem x m := Raw.mem x m.(this).
 Definition map f m : t elt' := Build_slist (Raw.map_sorted m.(sorted) f).
 Definition mapi f m : t elt' := Build_slist (Raw.mapi_sorted m.(sorted) f).
 Definition map2 f m (m':t elt') : t elt'' := 
     Build_slist (Raw.map2_sorted f m.(sorted) m'.(sorted)).
 Definition elements m := @Raw.elements elt m.(this).
 Definition fold A f m i := @Raw.fold elt A f m.(this) i.
 Definition equal cmp m m' := @Raw.equal elt cmp m.(this) m'.(this).

 Definition MapsTo x e m := Raw.PX.MapsTo x e m.(this).
 Definition In x m := Raw.PX.In x m.(this).
 Definition Empty m := Raw.Empty m.(this).
 Definition Equal cmp m m' := @Raw.Equal elt cmp m.(this) m'.(this).

 Definition eq_key := Raw.PX.eqk.
 Definition eq_key_elt := Raw.PX.eqke.
 Definition lt_key := Raw.PX.ltk.

 Definition MapsTo_1 m := @Raw.PX.MapsTo_eq elt m.(this).

 Definition mem_1 m := @Raw.mem_1 elt m.(this) m.(sorted).
 Definition mem_2 m := @Raw.mem_2 elt m.(this) m.(sorted).

 Definition empty_1 := @Raw.empty_1.

 Definition is_empty_1 m := @Raw.is_empty_1 elt m.(this).
 Definition is_empty_2 m := @Raw.is_empty_2 elt m.(this).

 Definition add_1 m := @Raw.add_1 elt m.(this).
 Definition add_2 m := @Raw.add_2 elt m.(this).
 Definition add_3 m := @Raw.add_3 elt m.(this).

 Definition remove_1 m := @Raw.remove_1 elt m.(this) m.(sorted).
 Definition remove_2 m := @Raw.remove_2 elt m.(this) m.(sorted).
 Definition remove_3 m := @Raw.remove_3 elt m.(this) m.(sorted).

 Definition find_1 m := @Raw.find_1 elt m.(this) m.(sorted).
 Definition find_2 m := @Raw.find_2 elt m.(this).

 Definition elements_1 m := @Raw.elements_1 elt m.(this). 
 Definition elements_2 m := @Raw.elements_2 elt m.(this). 
 Definition elements_3 m := @Raw.elements_3 elt m.(this) m.(sorted). 

 Definition fold_1 m := @Raw.fold_1 elt m.(this).

 Definition map_1 m := @Raw.map_1 elt elt' m.(this).
 Definition map_2 m := @Raw.map_2 elt elt' m.(this).

 Definition mapi_1 m := @Raw.mapi_1 elt elt' m.(this).
 Definition mapi_2 m := @Raw.mapi_2 elt elt' m.(this).

 Definition map2_1 m (m':t elt') x f := 
    @Raw.map2_1 elt elt' elt'' f m.(this) m.(sorted) m'.(this) m'.(sorted) x.
 Definition map2_2 m (m':t elt') x f := 
    @Raw.map2_2 elt elt' elt'' f m.(this) m.(sorted) m'.(this) m'.(sorted) x.

 Definition equal_1 m m' := @Raw.equal_1 elt m.(this) m.(sorted) m'.(this) m'.(sorted).
 Definition equal_2 m m' := @Raw.equal_2 elt m.(this) m.(sorted) m'.(this) m'.(sorted).

 End Elt.
End Make.

Module Make_ord (X: OrderedType)(D : OrderedType) <: 
    Sord with Module Data := D 
            with Module MapS.E := X.

  Module Data := D.
  Module MapS := Make(X). 
  Import MapS.

  Module MD := OrderedTypeFacts(D).
  Import MD.

  Definition t := MapS.t D.t. 

  Definition cmp e e' := match D.compare e e' with Eq _ => true | _ => false end.	

  Fixpoint eq_list (m m' : list (X.t * D.t)) { struct m } : Prop := 
       match m, m' with 
        | [], [] => True
        | (x,e)::l, (x',e')::l' => 
            match X.compare x x' with 
             | Eq _ => D.eq e e' /\ eq_list l l'
             | _       => False
            end 
        | _, _ => False
       end.

  Definition eq m m' := eq_list m.(this) m'.(this).

  Fixpoint lt_list (m m' : list (X.t * D.t)) {struct m} : Prop := match m, m' with 
    | [], [] => False
    | [], _  => True
    | _, []  => False
    | (x,e)::l, (x',e')::l' => 
        match X.compare x x' with 
          | Lt _ => True
          | Gt _ => False
          | Eq _ => D.lt e e' \/ (D.eq e e' /\ lt_list l l')
        end
    end.

  Definition lt m m' := lt_list m.(this) m'.(this).

  Lemma eq_equal : forall m m', eq m m' <-> equal cmp m m' = true.
  Proof.
  intros (l,Hl); induction l.
  intros (l',Hl'); unfold eq; simpl.
  destruct l'; unfold equal; simpl; intuition.
  intros (l',Hl'); unfold eq.
  destruct l'.
  destruct a; unfold equal; simpl; intuition.
  destruct a as (x,e).
  destruct p as (x',e').
  unfold equal; simpl. 
  destruct (X.compare x x'); simpl; intuition.
  unfold cmp at 1. 
  MD.compare; clear H; simpl.
  inversion_clear Hl.
  inversion_clear Hl'.
  destruct (IHl H (Build_slist H3)).
  unfold equal, eq in H5; simpl in H5; auto.
  destruct (andb_prop _ _ H); clear H.
  generalize H0; unfold cmp.
  MD.compare; auto; intro; discriminate.
  destruct (andb_prop _ _ H); clear H.
  inversion_clear Hl.
  inversion_clear Hl'.
  destruct (IHl H (Build_slist H3)).
  unfold equal, eq in H6; simpl in H6; auto.
 Qed.

  Lemma eq_1 : forall m m', Equal cmp m m' -> eq m m'.
  intros.
  generalize (@equal_1 D.t m m' cmp).
  generalize (@eq_equal m m').
  intuition.
  Qed.

  Lemma eq_2 : forall m m', eq m m' -> Equal cmp m m'.
  intros.
  generalize (@equal_2 D.t m m' cmp).
  generalize (@eq_equal m m').
  intuition.
  Qed.

  Lemma eq_refl : forall m : t, eq m m.
  Proof.
     intros (m,Hm); induction m; unfold eq; simpl; auto.
     destruct a.
     destruct (X.compare t0 t0); auto.
     apply (MapS.Raw.MX.lt_antirefl l); auto.
     split.
     apply D.eq_refl.
     inversion_clear Hm.
     apply (IHm H).
     apply (MapS.Raw.MX.lt_antirefl l); auto.
  Qed.

  Lemma  eq_sym : forall m1 m2 : t, eq m1 m2 -> eq m2 m1.
  Proof.
     intros (m,Hm); induction m; 
     intros (m', Hm'); destruct m'; unfold eq; simpl;
     try destruct a as (x,e); try destruct p as (x',e'); auto.
     destruct (X.compare x x'); MapS.Raw.MX.compare; intuition.
     inversion_clear Hm; inversion_clear Hm'.
     apply (IHm H0 (Build_slist H4)); auto.
  Qed.

  Lemma eq_trans : forall m1 m2 m3 : t, eq m1 m2 -> eq m2 m3 -> eq m1 m3.
     intros (m1,Hm1); induction m1; 
     intros (m2, Hm2); destruct m2; 
     intros (m3, Hm3); destruct m3; unfold eq; simpl; 
     try destruct a as (x,e); 
     try destruct p as (x',e'); 
     try destruct p0 as (x'',e''); try contradiction; auto.
     destruct (X.compare x x'); 
       destruct (X.compare x' x''); 
         MapS.Raw.MX.compare.
     intuition.
     eauto.
     inversion_clear Hm1; inversion_clear Hm2; inversion_clear Hm3.
     apply (IHm1 H1 (Build_slist H6) (Build_slist H8)); intuition.
   Qed.

  Lemma lt_trans : forall m1 m2 m3 : t, lt m1 m2 -> lt m2 m3 -> lt m1 m3.
  Proof.
     intros (m1,Hm1); induction m1; 
     intros (m2, Hm2); destruct m2; 
     intros (m3, Hm3); destruct m3; unfold lt; simpl; 
     try destruct a as (x,e); 
     try destruct p as (x',e'); 
     try destruct p0 as (x'',e''); try contradiction; auto.
     destruct (X.compare x x'); 
       destruct (X.compare x' x''); 
         MapS.Raw.MX.compare; auto.
    intuition; try solve [left; eauto].
    right.
    split; eauto.
     inversion_clear Hm1; inversion_clear Hm2; inversion_clear Hm3.
     apply (IHm1 H2 (Build_slist H6) (Build_slist H8)); intuition.
   Qed.

  Lemma lt_not_eq : forall m1 m2 : t, lt m1 m2 -> ~ eq m1 m2.
     intros (m1,Hm1); induction m1; 
     intros (m2, Hm2); destruct m2; unfold eq, lt; simpl; 
     try destruct a as (x,e); 
     try destruct p as (x',e'); try contradiction; auto.
     destruct (X.compare x x'); auto.
     intuition.
     absurd (D.lt e e'); eauto.
     inversion_clear Hm1; inversion_clear Hm2.
     apply (IHm1 H0 (Build_slist H5)); intuition.
   Qed.

  Definition compare : forall m1 m2, Compare lt eq m1 m2.
    intros (m1,Hm1); induction m1; 
    intros (m2, Hm2); destruct m2.
    apply Eq; unfold eq; simpl; auto.
    apply Lt; unfold lt; simpl; auto.
    apply Gt; unfold lt; simpl; auto. 
    destruct a as (x,e); destruct p as (x',e'). 
    destruct (X.compare x x').
    apply Lt; unfold lt; simpl; 
     destruct (X.compare x x'); auto; absurd (X.lt x x'); eauto.
    destruct (D.compare e e').
    apply Lt; unfold lt; simpl;
     destruct (X.compare x x'); auto; absurd (X.eq x x'); eauto.
    assert (Hm11 : sort (Raw.PX.ltk (elt:=D.t)) m1).
     inversion_clear Hm1; auto.
    assert (Hm22 : sort (Raw.PX.ltk (elt:=D.t)) m2).
     inversion_clear Hm2; auto.
    destruct (IHm1 Hm11 (Build_slist Hm22)).
    apply Lt; unfold lt; simpl; MapS.Raw.MX.compare; right; auto.
    apply Eq; unfold eq; simpl; MapS.Raw.MX.compare; auto.
    apply Gt; unfold lt; simpl; MapS.Raw.MX.compare; auto.
    apply Gt; unfold lt; simpl; MapS.Raw.MX.compare; auto.
    apply Gt; unfold lt; simpl; MapS.Raw.MX.compare; auto.
    Qed.

End Make_ord. 
