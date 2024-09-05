enum HTyp {
  Num
  Arrow(HTyp, HTyp)
  Sum(HTyp, HTyp)
  Hole
}

pub fn op_equal(self : HTyp, other : HTyp) -> Bool {
  match (self, other) {
    (Arrow(t1, t2), Arrow(t3, t4)) => t1.op_equal(t3) && t2.op_equal(t4)
    (Sum(t1, t2), Sum(t3, t4)) => t1.op_equal(t3) && t2.op_equal(t4)
    (Num, Num) => true
    (Hole, Hole) => true
    _ => false
  }
}

pub fn consistent(self : HTyp, other : HTyp) -> Bool {
  match (self, other) {
    (Hole, _) => true
    (_, Hole) => true
    (Arrow(t1, t2), Arrow(t3, t4)) => t1.consistent(t3) && t2.consistent(t4)
    (Sum(t1, t2), Sum(t3, t4)) => t1.consistent(t3) && t2.consistent(t4)
    _ => self == other
  }
}

pub fn inconsistent(self : HTyp, other : HTyp) -> Bool {
  self.consistent(other).not()
}

pub fn matched_arrow(self : HTyp) -> (HTyp, HTyp)? {
  match self {
    Arrow(t1, t2) => Some((t1, t2))
    Hole => Some((Hole, Hole))
    _ => None
  }
}

pub fn can_match_arrow(self : HTyp) -> Bool {
  self.matched_arrow().is_empty().not()
}

pub fn matched_sum(self : HTyp) -> (HTyp, HTyp)? {
  match self {
    Sum(t1, t2) => Some((t1, t2))
    Hole => Some((Hole, Hole))
    _ => None
  }
}

pub fn can_match_sum(self : HTyp) -> Bool {
  self.matched_sum().is_empty().not()
}

/// No holes inside the type
pub fn is_complete(self : HTyp) -> Bool {
  match self {
    Num => true
    Arrow(t1, t2) => t1.is_complete() && t2.is_complete()
    Sum(t1, t2) => t1.is_complete() && t2.is_complete()
    Hole => false
  }
}

pub fn to_string(self : HTyp) -> String {
  match self {
    Num => "Num".to_string()
    Arrow(t1, t2) => "(" + t1.to_string() + " -> " + t2.to_string() + ")"
    Sum(t1, t2) => "(" + t1.to_string() + " + " + t2.to_string() + ")"
    Hole => "?".to_string()
  }
}
