typealias Var = String

struct Context {
  ctx : @immut/sorted_map.T[Var, HTyp]
}

pub fn Context::empty() -> Context {
  { ctx: @immut/sorted_map.empty() }
}

pub fn extend(self : Context, var : Var, typ : HTyp) -> Context {
  match self.ctx[var] {
    Some(_) => self
    None => { ctx: self.ctx.insert(var, typ) }
  }
}

pub fn lookup(self : Context, var : Var) -> HTyp? {
  self.ctx[var]
}
