import Base
import ../date.bend as D
import ../period.bend as Per

def Readme.eq2(ok: Bool) -> String:
  match ok:
    case True{}:
      "ok"
    case False{}:
      "fail"

def Readme.eq(+y: U32, +m: U32, +d: U32) -> String:
  Readme.eq2(
    Bool.and(U32.is_eq(y, 2026), Bool.and(U32.is_eq(m, 2), U32.is_eq(d, 28)))
  )

def Readme.ymd(r: Result<&2, &2, D.Date.Error, D.Date>) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{D.Date{y, m, d}}:
      Readme.eq(y, m, d)

def Readme.ok(
  r: Result<&2, &2, Per.Period.Error, Per.Period>
) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{p}:
      Readme.ymd(Per.Period.add_to(p, D.Date{2026, 1, 31}))

def main() -> IO(Unit):
  IO.print(Readme.ok(Per.Period.from(0, 1, 0)))
