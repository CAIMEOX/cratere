enum Direction {
  Child(UInt)
  Parent
}

pub fn to_string(self : Direction) -> String {
  match self {
    Child(i) => "child(\{i})"
    Parent => "parent"
  }
}

enum Shape {
  ArrowS
  AscS
  NumS
  SumS
  VarS(Var)
  LamS(Var)
  AppS
  LitS(Int)
  PlusS
  InjS(SumTag)
  CaseS(Var, Var)
  NeHole
}

pub fn to_string(self : Shape) -> String {
  match self {
    ArrowS => "arrow"
    AscS => "asc"
    NumS => "num"
    SumS => "sum"
    VarS(x) => "var(\{x})"
    LamS(x) => "lam(\{x})"
    AppS => "app"
    LitS(n) => "lit(\{n})"
    PlusS => "plus"
    InjS(t) => "inj(\{t})"
    CaseS(x, y) => "case(\{x}, \{y})"
    NeHole => "non-empty-hole"
  }
}

enum Action {
  Move(Direction)
  Construct(Shape)
  Delete
  Finish
}

pub fn to_string(self : Action) -> String {
  match self {
    Move(d) => "move \{d}"
    Construct(s) => "construct \{s}"
    Delete => "delete"
    Finish => "finish"
  }
}

type! ActionError String

pub fn run_action(self : ZTyp, act : Action) -> ZTyp!ActionError {
  match (act, self) {
    // Move
    (Move(Child(1)), CursorHTyp(Arrow(tl, tr))) => LeftArrow(CursorHTyp(tl), tr)
    (Move(Child(2)), CursorHTyp(Arrow(tl, tr))) =>
      RightArrow(tl, CursorHTyp(tr))
    (Move(Child(1)), CursorHTyp(Sum(tl, tr))) => LeftSum(CursorHTyp(tl), tr)
    (Move(Child(2)), CursorHTyp(Sum(tl, tr))) => RightSum(tl, CursorHTyp(tr))
    (Move(Parent), LeftArrow(CursorHTyp(tl), tr)) => CursorHTyp(Arrow(tl, tr))
    (Move(Parent), RightArrow(tl, CursorHTyp(tr))) => CursorHTyp(Arrow(tl, tr))
    (Move(Parent), LeftSum(CursorHTyp(tl), tr)) => CursorHTyp(Sum(tl, tr))
    (Move(Parent), RightSum(tl, CursorHTyp(tr))) => CursorHTyp(Sum(tl, tr))
    // Construct
    (Construct(ArrowS), CursorHTyp(t)) => RightArrow(t, CursorHTyp(Hole))
    (Construct(NumS), CursorHTyp(Hole)) => CursorHTyp(Num)
    (Construct(SumS), CursorHTyp(t)) => RightSum(t, CursorHTyp(Hole))
    // Del
    (Delete, CursorHTyp(_)) => CursorHTyp(Hole)
    // Zipper
    (x, LeftArrow(tl, tr)) => LeftArrow(tl.run_action!(x), tr)
    (x, RightArrow(tl, tr)) => RightArrow(tl, tr.run_action!(x))
    (x, LeftSum(tl, tr)) => LeftSum(tl.run_action!(x), tr)
    (x, RightSum(tl, tr)) => RightSum(tl, tr.run_action!(x))
    _ => raise ActionError("Invalid action")
  }
}

pub fn run_move(self : ZExp, act : Action) -> ZExp!ActionError {
  match act {
    Move(direction) =>
      match (direction, self) {
        // Asc
        (Child(1), CursorHExp(Asc(e, t))) => ValAsc(CursorHExp(e), t)
        (Child(2), CursorHExp(Asc(e, t))) => TypAsc(e, CursorHTyp(t))
        (Parent, ValAsc(CursorHExp(e), t)) => CursorHExp(Asc(e, t))
        (Parent, TypAsc(e, CursorHTyp(t))) => CursorHExp(Asc(e, t))
        // Lam
        (Child(1), CursorHExp(Lam(x, e))) => Lam(x, CursorHExp(e))
        (Parent, Lam(x, CursorHExp(e))) => CursorHExp(Lam(x, e))
        // App
        (Child(1), CursorHExp(App(e1, e2))) => LeftApp(CursorHExp(e1), e2)
        (Child(2), CursorHExp(App(e1, e2))) => RightApp(e1, CursorHExp(e2))
        (Parent, LeftApp(CursorHExp(e1), e2)) => CursorHExp(App(e1, e2))
        (Parent, RightApp(e1, CursorHExp(e2))) => CursorHExp(App(e1, e2))
        // Plus
        (Child(1), CursorHExp(Plus(e1, e2))) => LeftPlus(CursorHExp(e1), e2)
        (Child(2), CursorHExp(Plus(e1, e2))) => RightPlus(e1, CursorHExp(e2))
        (Parent, LeftPlus(CursorHExp(e1), e2)) => CursorHExp(Plus(e1, e2))
        (Parent, RightPlus(e1, CursorHExp(e2))) => CursorHExp(Plus(e1, e2))
        // Injection
        (Child(1), CursorHExp(Inj(t, e))) => Inj(t, CursorHExp(e))
        (Parent, Inj(t, CursorHExp(e))) => CursorHExp(Inj(t, e))
        // Case
        (Child(1), CursorHExp(Case(e, l, r))) => Case0(CursorHExp(e), l, r)
        (Child(2), CursorHExp(Case(e, (x, l), r))) =>
          CaseL(e, (x, CursorHExp(l)), r)
        (Child(3), CursorHExp(Case(e, l, (x, r)))) =>
          CaseR(e, l, (x, CursorHExp(r)))
        (Parent, Case0(CursorHExp(e), l, r)) => CursorHExp(Case(e, l, r))
        (Parent, CaseL(e, (x, CursorHExp(l)), r)) =>
          CursorHExp(Case(e, (x, l), r))
        (Parent, CaseR(e, l, (x, CursorHExp(r)))) =>
          CursorHExp(Case(e, l, (x, r)))
        // NeHole
        (Child(1), CursorHExp(NonEmptyHole(e))) => NonEmptyHole(CursorHExp(e))
        (Parent, NonEmptyHole(CursorHExp(e))) => CursorHExp(NonEmptyHole(e))
        _ => raise ActionError("Invalid action")
      }
    _ => raise ActionError("Invalid action")
  }
}

pub fn synthesis_action(
  self : Action,
  ctx : Context,
  zt : (ZExp, HTyp)
) -> (ZExp, HTyp)!ActionError {
  let (ze, ty) = zt
  try {
    (ze.run_move!(self), ty)
  } catch {
    ActionError(_) =>
      match (self, zt) {
        (Delete, (CursorHExp(_), _)) => (CursorHExp(Hole), Hole)
        (Construct(AscS), (CursorHExp(e), typ)) =>
          (TypAsc(e, CursorHTyp(typ)), typ)
        (Construct(VarS(x)), (CursorHExp(Hole), Hole)) =>
          match ctx.lookup(x) {
            Some(t) => (CursorHExp(Var(x)), t)
            None => raise ActionError("Variable \{x} not found in context")
          }
        (Construct(LamS(x)), (CursorHExp(Hole), Hole)) =>
          (
            TypAsc(Lam(x, Hole), LeftArrow(CursorHTyp(Hole), Hole)),
            Arrow(Hole, Hole),
          )
        (Construct(AppS), (CursorHExp(e), ty)) =>
          match ty.matched_arrow() {
            Some((_, ty2)) => (RightApp(e, CursorHExp(Hole)), ty2)
            None => (RightApp(NonEmptyHole(e), CursorHExp(Hole)), Hole)
          }
        (Construct(LitS(n)), (CursorHExp(Hole), Hole)) =>
          (CursorHExp(Lit(n)), Num)
        (Construct(PlusS), (CursorHExp(e), ty)) =>
          if ty.consistent(Num) {
            (RightPlus(e, CursorHExp(Hole)), Num)
          } else {
            (RightPlus(NonEmptyHole(e), CursorHExp(Hole)), Hole)
          }
        (Construct(InjS(tag)), (CursorHExp(Hole), Hole)) =>
          (
            TypAsc(Inj(tag, Hole), LeftSum(CursorHTyp(Hole), Hole)),
            Sum(Hole, Hole),
          )
        (Construct(CaseS(x, y)), (CursorHExp(e), ty)) =>
          match ty.matched_sum() {
            Some(_) => (CaseL(e, (x, CursorHExp(Hole)), (y, Hole)), Hole)
            None =>
              (Case0(NonEmptyHole(CursorHExp(e)), (x, Hole), (y, Hole)), Hole)
          }
        (Construct(NeHole), (CursorHExp(e), ty)) =>
          (NonEmptyHole(CursorHExp(e)), ty)
        (Finish, (CursorHExp(NonEmptyHole(e)), Hole)) =>
          (CursorHExp(e), e.synthesis_!(ctx))
        // Zipper
        (x, (ValAsc(ze, ty), _)) =>
          (ValAsc(x.check_action!(ctx, ze, ty), ty), ty)
        (x, (TypAsc(ze, zt), _)) => {
          let zty1 = zt.run_action!(x)
          let ty1 = zty1.erase()
          try {
            ze.check!(ctx, ty1)
            (TypAsc(ze, zty1), ty1)
          } catch {
            TypeError(e) => raise ActionError("Type Error: " + e)
          }
        }
        (x, (LeftApp(ze, e), _)) => {
          let zee = ze.erase()
          let ty2 = zee.synthesis_!(ctx)
          let (e1, ty3) = synthesis_action!(x, ctx, (ze, ty2))
          match ty3.matched_arrow() {
            Some((ty4, ty5)) => {
              e.check_!(ctx, ty4)
              (LeftApp(e1, e), ty5)
            }
            None => raise ActionError("Expected arrow type")
          }
        }
        (x, (RightApp(edot, ebar), _)) => {
          let ty2 = edot.synthesis_!(ctx)
          match ty2.matched_arrow() {
            Some((ty3, ty4)) => {
              let ebar1 = check_action!(x, ctx, ebar, ty3)
              (RightApp(edot, ebar1), ty4)
            }
            None => raise ActionError("Expected arrow type")
          }
        }
        (x, (LeftPlus(ebar, edot), _)) =>
          (LeftPlus(check_action!(x, ctx, ebar, Num), edot), Num)
        (x, (RightPlus(edot, ebar), _)) =>
          (RightPlus(edot, check_action!(x, ctx, ebar, Num)), Num)
        (x, (NonEmptyHole(ebar), _)) => {
          let ebare = ebar.erase()
          let ty = ebare.synthesis_!(ctx)
          (synthesis_action!(x, ctx, (ebar, ty)).0 |> NonEmptyHole, Hole)
        }
        _ => raise ActionError("Invalid action")
      }
  }
}

pub fn check_post_action(
  self : Action,
  ctx : Context,
  ze : ZExp,
  ty : HTyp
) -> ZExp!ActionError {
  fn subsumption() -> ZExp!ActionError {
    let e = ze.erase()
    let ty1 = e.synthesis_!(ctx)
    let (ze1, ty11) = synthesis_action!(self, ctx, (ze, ty1))
    if ty.consistent(ty11) {
      ze1
    } else {
      raise ActionError("Subsumption error")
    }
  }

  match (self, ze, ty) {
    (Delete, CursorHExp(_), _) => CursorHExp(Hole)
    (Construct(AscS), CursorHExp(e), ty) => TypAsc(e, CursorHTyp(ty))
    (Construct(LamS(x)), CursorHExp(Hole), ty) =>
      match ty.matched_arrow() {
        Some(_) => Lam(x, ze)
        None =>
          NonEmptyHole(TypAsc(Lam(x, Hole), LeftArrow(CursorHTyp(Hole), Hole)))
      }
    (Construct(InjS(tag)), CursorHExp(Hole), ty) =>
      match ty.matched_sum() {
        Some(_) => Inj(tag, ze)
        None =>
          NonEmptyHole(TypAsc(Inj(tag, Hole), LeftSum(CursorHTyp(Hole), Hole)))
      }
    (Construct(CaseS(x, y)), CursorHExp(_), _) =>
      Case0(CursorHExp(Hole), (x, Hole), (y, Hole))
    (Finish, CursorHExp(NonEmptyHole(e)), _) => {
      e.check_!(ctx, ty)
      CursorHExp(e)
    }
    // Zipper
    (act, Lam(x, ze), ty) =>
      match ty.matched_arrow() {
        Some((ty1, ty2)) => {
          let ctx1 = ctx.extend(x, ty1)
          let ze2 = act.check_action!(ctx1, ze, ty2)
          Lam(x, ze2)
        }
        None => raise ActionError("Expected arrow type")
      }
    (act, Inj(tag, ze), ty) =>
      match ty.matched_sum() {
        Some((ty1, ty2)) =>
          Inj(Left, act.check_action!(ctx, ze, run_sum(tag, ty1, ty2)))
        None => raise ActionError("Expected sum type")
      }
    (act, Case0(ze, (x, e1), (y, e2)), ty) => {
      let e0 = ze.erase()
      let ty0 = e0.synthesis_!(ctx)
      let (ze1, ty01) = synthesis_action!(act, ctx, (ze, ty0))
      match ty01.matched_sum() {
        Some((ty1, ty2)) => {
          e1.check_!(ctx.extend(x, ty1), ty)
          e2.check_!(ctx.extend(y, ty2), ty)
          Case0(ze1, (x, e1), (y, e2))
        }
        None => raise ActionError("Expected sum type")
      }
    }
    (act, CaseL(e0, (x, e1), (y, ze2)), ty) => {
      let ty0 = e0.synthesis_!(ctx)
      match ty0.matched_sum() {
        Some((ty1, _)) => {
          let ze11 = act.check_action!(ctx.extend(x, ty1), e1, ty)
          CaseL(e0, (x, ze11), (y, ze2))
        }
        None => raise ActionError("Expected sum type")
      }
    }
    (act, CaseR(e0, (x, ze1), (y, e2)), ty) => {
      let ty0 = e0.synthesis_!(ctx)
      match ty0.matched_sum() {
        Some((_, ty2)) => {
          let ze21 = act.check_action!(ctx.extend(y, ty2), e2, ty)
          CaseR(e0, (x, ze1), (y, ze21))
        }
        None => raise ActionError("Expected sum type")
      }
    }
    (Construct(VarS(x)), CursorHExp(Hole), ty) => {
      let c = match ctx.lookup(x) {
        Some(typ) => inconsistent(typ, ty)
        None => false
      }
      if c {
        NonEmptyHole(CursorHExp(Var(x)))
      } else {
        subsumption!()
      }
    }
    (Construct(LitS(n)), CursorHExp(Hole), ty) =>
      if ty.inconsistent(Num) {
        NonEmptyHole(CursorHExp(Lit(n)))
      } else {
        subsumption!()
      }
    // Subsumption
    _ => subsumption!()
  }
}

pub fn check_action(
  self : Action,
  ctx : Context,
  ze : ZExp,
  ty : HTyp
) -> ZExp!ActionError {
  match self {
    Move(_) =>
      try {
        ze.run_move!(self)
      } catch {
        ActionError(_) => self.check_post_action!(ctx, ze, ty)
      }
    _ => self.check_post_action!(ctx, ze, ty)
  }
}

pub fn perform_action(
  actions : Array[Action],
  ~ctx : Context = Context::empty()
) -> Unit!ActionError {
  let mut exp : (ZExp, HTyp) = (CursorHExp(Hole), Hole)
  for i = 0; i < actions.length(); i = i + 1 {
    exp = actions[i].synthesis_action!(ctx, exp)
    println("\{actions[i]}: \{exp.0}")
  }
}

test "" {
  let actions = [
    Construct(LamS("x")),
    Construct(NumS),
    Move(Parent),
    Move(Child(2)),
    Construct(NumS),
    Move(Parent),
    Move(Parent),
    Move(Child(1)),
    Move(Child(1)),
    Construct(VarS("x")),
    Construct(PlusS),
    Construct(LitS(1)),
  ]
  perform_action!(actions)
}

test "" {
  let ctx = Context::empty().extend("incr", Arrow(Num, Num))
  let actions = [
    Construct(VarS("incr")),
    Construct(AppS),
    Construct(VarS("incr")),
    Construct(AppS),
    Construct(LitS(3)),
    Move(Parent),
    Move(Parent),
    Finish,
  ]
  perform_action!(actions, ~ctx)
}
