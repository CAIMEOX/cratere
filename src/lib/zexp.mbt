enum ZExp {
  CursorHExp(HExp)
  ValAsc(ZExp, HTyp)
  TypAsc(HExp, ZTyp)
  Lam(Var, ZExp)
  LeftApp(ZExp, HExp)
  RightApp(HExp, ZExp)
  LeftPlus(ZExp, HExp)
  RightPlus(HExp, ZExp)
  Inj(SumTag, ZExp)
  Case0(ZExp, (Var, HExp), (Var, HExp))
  CaseL(HExp, (Var, ZExp), (Var, HExp))
  CaseR(HExp, (Var, HExp), (Var, ZExp))
  NonEmptyHole(ZExp)
}

pub fn erase(self : ZExp) -> HExp {
  match self {
    CursorHExp(h) => h
    ValAsc(ze, ht) => Asc(ze.erase(), ht)
    TypAsc(he, zt) => Asc(he, zt.erase())
    Lam(x, ze) => Lam(x, ze.erase())
    LeftApp(ze, he) => App(ze.erase(), he)
    RightApp(he, ze) => App(he, ze.erase())
    LeftPlus(ze, he) => Plus(ze.erase(), he)
    RightPlus(he, ze) => Plus(he, ze.erase())
    Inj(t, ze) => Inj(t, ze.erase())
    Case0(ze, (x1, he1), (x2, he2)) => Case(ze.erase(), (x1, he1), (x2, he2))
    CaseL(he, (x, ze1), (y, he2)) => Case(he, (x, ze1.erase()), (y, he2))
    CaseR(he, (x, he1), (y, ze2)) => Case(he, (x, he1), (y, ze2.erase()))
    NonEmptyHole(ze) => NonEmptyHole(ze.erase())
  }
}
