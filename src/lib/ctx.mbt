typealias Var = String

struct Context {
  ctx : @immut/hashmap.T[Var, HTyp]
}

pub fn empty() -> Context {
  { ctx: @immut/hashmap.new() }
}

pub fn extend(self : Context, var : Var, typ : HTyp) -> Context {
  match self.ctx[var] {
    Some(_) => self
    None => { ctx: self.ctx.add(var, typ) }
  }
}

pub fn lookup(self : Context, var : Var) -> HTyp? {
  self.ctx[var]
}
