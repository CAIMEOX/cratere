enum SumTag {
  Left
  Right
} derive(Eq)

pub fn run_sum[T](self : SumTag, l : T, r : T) -> T {
  match self {
    Left => l
    Right => r
  }
}

enum HExp {
  Var(Var)
  App(HExp, HExp)
  Lam(Var, HExp)
  Asc(HExp, HTyp)
  Lit(Int)
  Plus(HExp, HExp)
  Inj(SumTag, HExp)
  Case(HExp, (Var, HExp), (Var, HExp))
  NonEmptyHole(HExp)
  Hole
}

type! TypeError String

pub fn synthesis(self : HExp, ctx : Context) -> HTyp!TypeError {
  match self {
    Asc(e, typ) => {
      e.check!(ctx, typ)
      typ
    }
    Var(x) =>
      match ctx.lookup(x) {
        Some(typ) => typ
        None => raise TypeError("Variable not found in context")
      }
    App(e1, e2) => {
      let t1 = e1.synthesis!(ctx)
      match t1.matched_arrow() {
        Some((tl, tr)) => {
          e2.check!(ctx, tl)
          tr
        }
        None =>
          raise TypeError("Expected arrow type, but found " + t1.to_string())
      }
    }
    Lit(_n) => Num
    Plus(e1, e2) => {
      e1.check!(ctx, Num)
      e2.check!(ctx, Num)
      Num
    }
    NonEmptyHole(e) => {
      e.synthesis!(ctx) |> ignore
      Hole
    }
    Hole => Hole
    _ => raise TypeError("Can not synthesize type")
  }
}

pub fn synthesis_(self : HExp, ctx : Context) -> HTyp!ActionError {
  try {
    self.synthesis!(ctx)
  } catch {
    TypeError(x) => raise ActionError("TypeError: " + x)
  }
}

pub fn check(self : HExp, ctx : Context, typ : HTyp) -> Unit!TypeError {
  match self {
    Lam(var, e) =>
      match typ.matched_arrow() {
        Some((tl, tr)) => e.check!(extend(ctx, var, tl), tr)
        None =>
          raise TypeError("Expected arrow type, but found " + typ.to_string())
      }
    Inj(tag, e) =>
      match typ.matched_sum() {
        Some((l, r)) => e.check!(ctx, tag.run_sum(l, r))
        None =>
          raise TypeError("Expected sum type, but found " + typ.to_string())
      }
    Case(e, (x1, e1), (x2, e2)) => {
      let ts = e.synthesis!(ctx)
      match ts.matched_sum() {
        Some((l, r)) => {
          e1.check!(ctx.extend(x1, l), typ)
          e2.check!(ctx.extend(x2, r), typ)
        }
        None =>
          raise TypeError("Expected sum type, but found " + ts.to_string())
      }
    }
    _ => {
      // Subsumption
      let t = self.synthesis!(ctx)
      if t.inconsistent(typ) {
        raise TypeError(
          "Expected " + typ.to_string() + ", but found " + t.to_string(),
        )
      }
    }
  }
}

pub fn check_(self : HExp, ctx : Context, typ : HTyp) -> Unit!ActionError {
  try {
    self.check!(ctx, typ)
  } catch {
    TypeError(x) => raise ActionError("TypeError: " + x)
  }
}

pub fn is_complete(self : HExp) -> Bool {
  match self {
    Var(_) | Lit(_) => true
    App(e1, e2) => e1.is_complete() && e2.is_complete()
    Lam(_, e) => e.is_complete()
    Asc(e, t) => e.is_complete() && t.is_complete()
    Plus(e1, e2) => e1.is_complete() && e2.is_complete()
    Inj(_, e) => e.is_complete()
    Case(e, (_, e1), (_, e2)) =>
      e.is_complete() && e1.is_complete() && e2.is_complete()
    NonEmptyHole(_) | Hole => false
  }
}
