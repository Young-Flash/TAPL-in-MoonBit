///|
fn is_numerical(self : Term) -> Bool {
  match self {
    Zero(_) => true
    Succ(_, t1) => t1.is_numerical()
    _ => false
  }
}

///|
fn is_val(self : Term) -> Bool {
  match self {
    True(_) => true
    False(_) => true
    Abs(_) => true
    Unit(_) => true
    Record(_, lts) => lts.all(fn(lt) { lt.1.is_val() })
    Tag(_, _, t1, _) => t1.is_val()
    String(_) => true
    Double(_) => true
    TAbs(_) => true
    Pack(_, _, t2, _) => t2.is_val()
    _ => self.is_numerical()
  }
}

///|
suberror NoRuleApplies

///|
fn eval1(self : Term, ctx : Context) -> Term raise NoRuleApplies {
  match self {
    True(_) => raise NoRuleApplies
    False(_) => raise NoRuleApplies
    If(info, t1, t2, t3) =>
      if t1.is_val() {
        match t1 {
          True(_) => t2
          False(_) => t3
          _ => raise NoRuleApplies
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        If(info, t1_prime, t2, t3)
      }
    Zero(_) => raise NoRuleApplies
    Succ(info, t1) =>
      if t1.is_val() {
        raise NoRuleApplies
      } else {
        let t1_prime = t1.eval1(ctx)
        Succ(info, t1_prime)
      }
    Pred(info, t1) =>
      if t1.is_val() {
        match t1 {
          Zero(_) => Zero(UNKNOWN)
          Succ(_, t11) =>
            if t11.is_numerical() {
              t11
            } else {
              raise NoRuleApplies
            }
          _ => raise NoRuleApplies
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        Pred(info, t1_prime)
      }
    IsZero(info, t1) =>
      if t1.is_val() {
        match t1 {
          Zero(_) => True(UNKNOWN)
          Succ(_, t11) =>
            if t11.is_numerical() {
              False(UNKNOWN)
            } else {
              raise NoRuleApplies
            }
          _ => raise NoRuleApplies
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        IsZero(info, t1_prime)
      }
    Var(_, x, _) =>
      match ctx.get_binding(x) {
        TmAbb(t, _) => t
        _ => raise NoRuleApplies
      }
    Abs(_) => raise NoRuleApplies
    App(info, t1, t2) =>
      if t1.is_val() {
        if t2.is_val() {
          match t1 {
            Abs(_, _, _, t12) => t12.subst_top(t2)
            _ => raise NoRuleApplies
          }
        } else {
          let t2_prime = t2.eval1(ctx)
          App(info, t1, t2_prime)
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        App(info, t1_prime, t2)
      }
    Unit(_) => raise NoRuleApplies
    Ascribe(info, t1, ty1) =>
      if t1.is_val() {
        t1
      } else {
        let t1_prime = t1.eval1(ctx)
        Ascribe(info, t1_prime, ty1)
      }
    Record(info, lts) =>
      loop (lts, @immut/list.Nil) {
        (Nil, _) => raise NoRuleApplies
        (Cons((l, t), rest), acc) =>
          if t.is_val() {
            continue (rest, Cons((l, t), acc))
          } else {
            let t_prime = t.eval1(ctx)
            break Record(info, acc.rev_concat(Cons((l, t_prime), rest)))
          }
      }
    Proj(info, t1, l) =>
      if t1.is_val() {
        match t1 {
          Record(_, lts) =>
            match lts.lookup(l) {
              None => raise NoRuleApplies
              Some(t) => t
            }
          _ => raise NoRuleApplies
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        Proj(info, t1_prime, l)
      }
    Tag(info, l, t1, ty) =>
      if t1.is_val() {
        raise NoRuleApplies
      } else {
        let t1_prime = t1.eval1(ctx)
        Tag(info, l, t1_prime, ty)
      }
    Case(info, t1, cases) =>
      if t1.is_val() {
        match t1 {
          Tag(_, l, t11, _) =>
            match cases.lookup(l) {
              None => raise NoRuleApplies
              Some((_, t)) => t.subst_top(t11)
            }
          _ => raise NoRuleApplies
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        Case(info, t1_prime, cases)
      }
    String(_) => raise NoRuleApplies
    Double(_) => raise NoRuleApplies
    Timesdouble(info, t1, t2) =>
      if t1.is_val() {
        if t2.is_val() {
          match (t1, t2) {
            (Double(_, d1), Double(_, d2)) => Double(UNKNOWN, d1 * d2)
            _ => raise NoRuleApplies
          }
        } else {
          let t2_prime = t2.eval1(ctx)
          Timesdouble(info, t1, t2_prime)
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        Timesdouble(info, t1_prime, t2)
      }
    Fix(info, t1) =>
      if t1.is_val() {
        match t1 {
          Abs(_, _, _, t12) => t12.subst_top(self)
          _ => raise NoRuleApplies
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        Fix(info, t1_prime)
      }
    TAbs(_) => raise NoRuleApplies
    TApp(info, t1, ty2) =>
      if t1.is_val() {
        match t1 {
          TAbs(_, _, _, t12) => t12.subst_ty_top(ty2)
          _ => raise NoRuleApplies
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        TApp(info, t1_prime, ty2)
      }
    Pack(info, ty1, t2, ty3) =>
      if t2.is_val() {
        raise NoRuleApplies
      } else {
        let t2_prime = t2.eval1(ctx)
        Pack(info, ty1, t2_prime, ty3)
      }
    Unpack(info, x1, x2, t1, t2) =>
      if t1.is_val() {
        match t1 {
          Pack(_, ty11, t12, _) => t2.subst_top(t12.shift(1)).subst_ty_top(ty11)
          _ => raise NoRuleApplies
        }
      } else {
        let t1_prime = t1.eval1(ctx)
        Unpack(info, x1, x2, t1_prime, t2)
      }
  }
}

///|
fn eval(self : Term, ctx : Context) -> Term {
  loop self {
    t =>
      try {
        continue t.eval1(ctx)
      } catch {
        NoRuleApplies => break t
      }
  }
}

///|
fn Type::promote(self : Type, ctx : Context) -> Type raise NoRuleApplies {
  match self {
    Var(x, _) =>
      match ctx.get_binding(x) {
        TyVar(ty) => ty
        _ => raise NoRuleApplies
      }
    _ => raise NoRuleApplies
  }
}

///|
fn Type::lcst(self : Type, ctx : Context) -> Type {
  let ty = self.simplify(ctx)
  ty.promote(ctx).lcst(ctx) catch {
    NoRuleApplies => ty
  }
}

///|
fn Type::compute(self : Type, ctx : Context) -> Type raise NoRuleApplies {
  match self {
    Bool => raise NoRuleApplies
    Nat => raise NoRuleApplies
    Arr(_) => raise NoRuleApplies
    Var(x, _) =>
      match ctx.get_binding(x) {
        TyAbb(ty) => ty
        TyVar(_) => raise NoRuleApplies
        _ => panic()
      }
    Id(_) => raise NoRuleApplies
    Unit => raise NoRuleApplies
    Record(_) => raise NoRuleApplies
    Variant(_) => raise NoRuleApplies
    String => raise NoRuleApplies
    Double => raise NoRuleApplies
    All(_) => raise NoRuleApplies
    Some(_) => raise NoRuleApplies
    Top => raise NoRuleApplies
  }
}

///|
fn Type::simplify(self : Type, ctx : Context) -> Type {
  loop self {
    ty =>
      try {
        continue ty.compute(ctx)
      } catch {
        NoRuleApplies => break ty
      }
  }
}

///|
fn Type::equiv(self : Type, other : Type, ctx : Context) -> Bool {
  let ty1 = self.simplify(ctx)
  let ty2 = other.simplify(ctx)
  match (ty1, ty2) {
    (Bool, Bool) => true
    (Nat, Nat) => true
    (Arr(ty11, ty12), Arr(ty21, ty22)) =>
      ty21.equiv(ty11, ctx) && ty12.equiv(ty22, ctx)
    (Var(x1, _), Var(x2, _)) => x1 == x2
    (Id(b1), Id(b2)) => b1 == b2
    (Unit, Unit) => true
    (Record(ltys1), Record(ltys2)) =>
      ltys1
      .zip(ltys2)
      .map_or(false, fn(l) {
        l.all(fn(p) { p.0.0 == p.1.0 && p.0.1.equiv(p.1.1, ctx) })
      })
    (Variant(ltys1), Variant(ltys2)) =>
      ltys1
      .zip(ltys2)
      .map_or(false, fn(l) {
        l.all(fn(p) { p.0.0 == p.1.0 && p.0.1.equiv(p.1.1, ctx) })
      })
    (String, String) => true
    (Double, Double) => true
    (All(x1, ty11, ty12), All(_, ty21, ty22)) => {
      let ctx1 = ctx.add_binding(x1, TyVar(ty21))
      ty21.equiv(ty11, ctx) && ty12.equiv(ty22, ctx1)
    }
    (Some(x1, ty11, ty12), Some(_, ty21, ty22)) => {
      let ctx1 = ctx.add_binding(x1, TyVar(ty11))
      ty11.equiv(ty21, ctx) && ty12.equiv(ty22, ctx1)
    }
    (Top, Top) => true
    _ => false
  }
}

///|
fn Type::subtype_of(self : Type, other : Type, ctx : Context) -> Bool {
  if self.equiv(other, ctx) {
    true
  } else {
    let ty1 = self.simplify(ctx)
    let ty2 = other.simplify(ctx)
    match (ty1, ty2) {
      (_, Top) => true
      (Var(_), _) => (try? ty1.promote(ctx)).unwrap().subtype_of(ty2, ctx)
      (Arr(ty11, ty12), Arr(ty21, ty22)) =>
        ty21.subtype_of(ty11, ctx) && ty12.subtype_of(ty22, ctx)
      (Record(ltys1), Record(ltys2)) =>
        ltys2.all(fn(lt) {
          match ltys1.lookup(lt.0) {
            None => false
            Some(t1) => t1.subtype_of(lt.1, ctx)
          }
        })
      (Variant(ltys1), Variant(ltys2)) =>
        ltys1.all(fn(lt) {
          match ltys2.lookup(lt.0) {
            None => false
            Some(t2) => lt.1.subtype_of(t2, ctx)
          }
        })
      (All(x1, ty11, ty12), All(_, ty21, ty22)) =>
        ty21.subtype_of(ty11, ctx) &&
        ty12.subtype_of(ty22, ctx.add_binding(x1, TyVar(ty21)))
      (Some(x1, ty11, ty12), Some(_, ty21, ty22)) =>
        ty11.subtype_of(ty21, ctx) &&
        ty12.subtype_of(ty22, ctx.add_binding(x1, TyVar(ty11)))
      _ => false
    }
  }
}

///|
fn Type::join(self : Type, other : Type, ctx : Context) -> Type {
  if self.subtype_of(other, ctx) {
    other
  } else if other.subtype_of(self, ctx) {
    self
  } else {
    let ty1 = self.simplify(ctx)
    let ty2 = self.simplify(ctx)
    match (ty1, ty2) {
      (Arr(ty11, ty12), Arr(ty21, ty22)) =>
        Arr(ty11.meet(ty21, ctx), ty12.join(ty22, ctx)) catch {
          NoRuleApplies => Top
        }
      (Record(ltys1), Record(ltys2)) => {
        let labels1 = ltys1.map(fn(lty) { lty.0 })
        let labels2 = ltys2.map(fn(lty) { lty.0 })
        let common_labels = labels1.filter(fn(l) { labels2.contains(l) })
        let common_ltys = common_labels.map(fn(l) {
          let ty1 = ltys1.lookup(l).unwrap()
          let ty2 = ltys2.lookup(l).unwrap()
          (l, ty1.join(ty2, ctx))
        })
        Record(common_ltys)
      }
      (Variant(ltys1), Variant(ltys2)) => {
        let labels1 = ltys1.map(fn(lty) { lty.0 })
        let labels2 = ltys2.map(fn(lty) { lty.0 })
        let all_labels = labels1.concat(
          labels2.filter(fn(l) { not(labels1.contains(l)) }),
        )
        let all_ltys = loop (all_labels, @immut/list.Nil) {
          (Nil, acc) => break acc.rev()
          (Cons(l, rest), acc) => {
            let ty = match (ltys1.lookup(l), ltys2.lookup(l)) {
              (Some(ty1), Some(ty2)) => ty1.join(ty2, ctx)
              (Some(ty1), None) => ty1
              (None, Some(ty2)) => ty2
              (None, None) => panic()
            }
            continue (rest, Cons((l, ty), acc))
          }
        }
        Variant(all_ltys)
      }
      (All(x1, ty11, ty12), All(_, ty21, ty22)) =>
        try {
          let ty1 = ty11.meet(ty21, ctx)
          All(x1, ty1, ty12.join(ty22, ctx.add_binding(x1, TyVar(ty1))))
        } catch {
          NoRuleApplies => Top
        }
      (Some(x1, ty11, ty12), Some(_, ty21, ty22)) => {
        let ty1 = ty11.join(ty21, ctx)
        Some(x1, ty1, ty12.join(ty22, ctx.add_binding(x1, TyVar(ty1))))
      }
      _ => Top
    }
  }
}

///|
fn Type::meet(
  self : Type,
  other : Type,
  ctx : Context
) -> Type raise NoRuleApplies {
  if self.subtype_of(other, ctx) {
    self
  } else if other.subtype_of(self, ctx) {
    other
  } else {
    let ty1 = self.simplify(ctx)
    let ty2 = self.simplify(ctx)
    match (ty1, ty2) {
      (Arr(ty11, ty12), Arr(ty21, ty22)) =>
        Arr(ty11.join(ty21, ctx), ty12.meet(ty22, ctx))
      (Record(ltys1), Record(ltys2)) => {
        let labels1 = ltys1.map(fn(lty) { lty.0 })
        let labels2 = ltys2.map(fn(lty) { lty.0 })
        let all_labels = labels1.concat(
          labels2.filter(fn(l) { not(labels1.contains(l)) }),
        )
        let all_ltys = loop (all_labels, @immut/list.Nil) {
          (Nil, acc) => break acc.rev()
          (Cons(l, rest), acc) => {
            let ty = match (ltys1.lookup(l), ltys2.lookup(l)) {
              (Some(ty1), Some(ty2)) => ty1.meet(ty2, ctx)
              (Some(ty1), None) => ty1
              (None, Some(ty2)) => ty2
              (None, None) => panic()
            }
            continue (rest, Cons((l, ty), acc))
          }
        }
        Record(all_ltys)
      }
      (Variant(ltys1), Variant(ltys2)) => {
        let labels1 = ltys1.map(fn(lty) { lty.0 })
        let labels2 = ltys2.map(fn(lty) { lty.0 })
        let common_labels = labels1.filter(fn(l) { labels2.contains(l) })
        let common_ltys = loop (common_labels, @immut/list.Nil) {
          (Nil, acc) => break acc.rev()
          (Cons(l, rest), acc) => {
            let ty1 = ltys1.lookup(l).unwrap()
            let ty2 = ltys2.lookup(l).unwrap()
            continue (rest, Cons((l, ty1.meet(ty2, ctx)), acc))
          }
        }
        Variant(common_ltys)
      }
      (All(x1, ty11, ty12), All(_, ty21, ty22)) => {
        let ty1 = ty11.join(ty21, ctx)
        All(x1, ty1, ty12.meet(ty22, ctx.add_binding(x1, TyVar(ty1))))
      }
      (Some(x1, ty11, ty12), Some(_, ty21, ty22)) => {
        let ty1 = ty11.meet(ty21, ctx)
        Some(x1, ty1, ty12.meet(ty22, ctx.add_binding(x1, TyVar(ty1))))
      }
      _ => raise NoRuleApplies
    }
  }
}

///|
fn derive_type(self : Term, ctx : Context) -> Type raise {
  match self {
    True(_) => Bool
    False(_) => Bool
    If(info, t1, t2, t3) =>
      if t1.derive_type(ctx).subtype_of(Bool, ctx) {
        let ty2 = t2.derive_type(ctx)
        let ty3 = t3.derive_type(ctx)
        ty2.join(ty3, ctx)
      } else {
        error_info("guard of conditional not a boolean", info~)
      }
    Zero(_) => Nat
    Succ(info, t1) =>
      if t1.derive_type(ctx).subtype_of(Nat, ctx) {
        Nat
      } else {
        error_info("argument of succ is not a number", info~)
      }
    Pred(info, t1) =>
      if t1.derive_type(ctx).subtype_of(Nat, ctx) {
        Nat
      } else {
        error_info("argument of pred is not a number", info~)
      }
    IsZero(info, t1) =>
      if t1.derive_type(ctx).subtype_of(Nat, ctx) {
        Bool
      } else {
        error_info("argument of iszero is not a number", info~)
      }
    Var(_, x, _) => ctx.get_type(x)
    Abs(_, x, ty1, t2) => {
      let ctx1 = ctx.add_binding(x, Var(ty1))
      let ty2 = t2.derive_type(ctx1).shift(-1)
      Arr(ty1, ty2)
    }
    App(info, t1, t2) => {
      let ty1 = t1.derive_type(ctx)
      let ty2 = t2.derive_type(ctx)
      match ty1.lcst(ctx) {
        Arr(ty11, ty12) =>
          if ty2.subtype_of(ty11, ctx) {
            ty12
          } else {
            error_info("parameter type mismatch", info~)
          }
        _ => error_info("arrow type expected", info~)
      }
    }
    Unit(_) => Unit
    Ascribe(info, t1, ty2) =>
      if t1.derive_type(ctx).subtype_of(ty2, ctx) {
        ty2
      } else {
        error_info("body of as-term does not have the expected type", info~)
      }
    Record(info, lts) =>
      loop (lts, @immut/list.Nil) {
        (Nil, acc) => break Record(acc.rev())
        (Cons((l, t), rest), acc) =>
          if acc.lookup(l).is_empty() {
            continue (rest, Cons((l, t.derive_type(ctx)), acc))
          } else {
            error_info("duplicate label \{l} is not allowed", info~)
          }
      }
    Proj(info, t1, l) =>
      match t1.derive_type(ctx).lcst(ctx) {
        Record(ltys) =>
          match ltys.lookup(l) {
            None => error_info("label \{l} not found", info~)
            Some(ty) => ty
          }
        _ => error_info("record type expected", info~)
      }
    Tag(info, l, t1, ty) =>
      match ty.lcst(ctx) {
        Variant(ltys) =>
          match ltys.lookup(l) {
            None => error_info("label \{l} not found", info~)
            Some(ann_ty) =>
              if t1.derive_type(ctx).subtype_of(ann_ty, ctx) {
                ty
              } else {
                error_info("variant does not have the expected type", info~)
              }
          }
        _ => error_info("annotation is not a variant type", info~)
      }
    Case(info, t1, cases) =>
      match t1.derive_type(ctx).lcst(ctx) {
        Variant(ltys) => {
          for case in cases {
            if ltys.lookup(case.0).is_empty() {
              error_info("label \{case.0} not in type", info~)
            }
          }
          let case_tys = loop (cases, @immut/list.Nil) {
            (Nil, acc) => break acc.rev()
            (Cons((l, (x, t)), rest), acc) => {
              let ty = ltys.lookup(l).unwrap()
              let ctx1 = ctx.add_binding(x, Var(ty))
              continue (rest, Cons(t.derive_type(ctx1).shift(-1), acc))
            }
          }
          let ty1 = case_tys.unsafe_head()
          case_tys.fold(init=ty1, fn(ty1, ty2) { ty1.join(ty2, ctx) })
        }
        _ => error_info("variant type expected", info~)
      }
    String(_) => String
    Double(_) => Double
    Timesdouble(info, t1, t2) =>
      if t1.derive_type(ctx).subtype_of(Double, ctx) &&
        t2.derive_type(ctx).subtype_of(Double, ctx) {
        Double
      } else {
        error_info("argument of timesdouble is not a decimal number", info~)
      }
    Fix(info, t1) =>
      match t1.derive_type(ctx).lcst(ctx) {
        Arr(t11, t12) =>
          if t12.subtype_of(t11, ctx) {
            t12
          } else {
            error_info("result of body not compatible with domain", info~)
          }
        _ => error_info("arrow type expected", info~)
      }
    TAbs(_, x, ty1, t2) => {
      let ctx1 = ctx.add_binding(x, TyVar(ty1))
      let ty2 = t2.derive_type(ctx1)
      All(x, ty1, ty2)
    }
    TApp(info, t1, ty2) => {
      let ty1 = t1.derive_type(ctx)
      match ty1.lcst(ctx) {
        All(_, ty11, ty12) =>
          if not(ty2.subtype_of(ty11, ctx)) {
            error_info("type parameter bound mismatch", info~)
          } else {
            ty12.subst_top(ty2)
          }
        _ => error_info("universal type expected", info~)
      }
    }
    Pack(info, ty1, t2, ty3) => {
      let ty2 = t2.derive_type(ctx)
      match ty3.lcst(ctx) {
        Some(_, ty31, ty32) =>
          if not(ty1.subtype_of(ty31, ctx)) {
            error_info("hidden type not a subtype of bound", info~)
          } else {
            let ty2_expect = ty32.subst_top(ty1)
            if ty2.subtype_of(ty2_expect, ctx) {
              ty3
            } else {
              error_info("does not match the declared type", info~)
            }
          }
        _ => error_info("existential type expected", info~)
      }
    }
    Unpack(info, x1, x2, t1, t2) => {
      let ty1 = t1.derive_type(ctx)
      match ty1.lcst(ctx) {
        Some(_, ty11, ty12) => {
          let ctx1 = ctx.add_binding(x1, TyVar(ty11))
          let ctx2 = ctx1.add_binding(x2, Var(ty12))
          t2.derive_type(ctx2).shift(-2)
        }
        _ => error_info("existential type expected", info~)
      }
    }
  }
}

///|
fn Binding::eval(self : Binding, ctx : Context) -> Binding {
  match self {
    Name => Name
    TmAbb(t, ty_opt) => {
      let t_prime = t.eval(ctx)
      TmAbb(t_prime, ty_opt)
    }
    Var(ty) => Var(ty)
    TyAbb(ty) => TyAbb(ty)
    TyVar(ty) => TyVar(ty)
  }
}

///|
fn Binding::derive_type(
  self : Binding,
  ctx : Context,
  info : Info
) -> Binding raise {
  match self {
    Name => Name
    TmAbb(t, None) => {
      let ty = t.derive_type(ctx)
      TmAbb(t, Some(ty))
    }
    TmAbb(t, Some(ty)) =>
      if t.derive_type(ctx).subtype_of(ty, ctx) {
        TmAbb(t, Some(ty))
      } else {
        error_info("type of binding does not match declared type", info~)
      }
    Var(ty) => Var(ty)
    TyAbb(ty) => TyAbb(ty)
    TyVar(ty) => TyVar(ty)
  }
}
