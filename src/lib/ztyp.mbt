enum ZTyp {
  CursorHTyp(HTyp)
  LeftArrow(ZTyp, HTyp)
  RightArrow(HTyp, ZTyp)
  LeftSum(ZTyp, HTyp)
  RightSum(HTyp, ZTyp)
}

pub fn erase(self : ZTyp) -> HTyp {
  match self {
    CursorHTyp(t) => t
    LeftArrow(t1, t2) => Arrow(t1.erase(), t2)
    RightArrow(t1, t2) => Arrow(t1, t2.erase())
    LeftSum(t1, t2) => Sum(t1.erase(), t2)
    RightSum(t1, t2) => Sum(t1, t2.erase())
  }
}
