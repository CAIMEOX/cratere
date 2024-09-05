enum Direction {
  Child(UInt)
  Parent
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

enum Action {
  Move(Direction)
  Construct(Shape)
  Delete
  Finish
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

pub fn run_action(self : ZExp, act : Action) -> ZExp!ActionError {
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
        (Parent, CaseL(e, (x, CursorHExp(l)), r)) => CursorHExp(Case(e, (x, l), r))
        (Parent, CaseR(e, l, (x, CursorHExp(r)))) => CursorHExp(Case(e, l, (x, r)))
        // NeHole
        (Child(1), CursorHExp(NonEmptyHole(e))) => NonEmptyHole(CursorHExp(e))
        (Parent, NonEmptyHole(CursorHExp(e))) => CursorHExp(NonEmptyHole(e))
        _ => raise ActionError("Invalid action")
      }
    _ => raise ActionError("Invalid action")
  }
}
