import Base
import ../date.bend as D
import ../period.bend as Per

def PeriodTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def PeriodTest.ymd(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{D.Date{yy, mm, dd}}:
      PeriodTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y), Bool.and(U32.is_eq(mm, m), U32.is_eq(dd, d))
        )
      )

def PeriodTest.fail(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def PeriodTest.add(
  name: String, r: Result<&2, &2, Per.Period.Error, Per.Period>, date: D.Date, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{p}:
      PeriodTest.ymd(name, Per.Period.add_to(p, date), y, m, d)

def PeriodTest.add_fail(
  name: String, r: Result<&2, &2, Per.Period.Error, Per.Period>, date: D.Date
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{p}:
      PeriodTest.fail(name, Per.Period.add_to(p, date))

def PeriodTest.norm(
  name: String,
  r1: Result<&2, &2, Per.Period.Error, Per.Period>,
  r2: Result<&2, &2, Per.Period.Error, Per.Period>
) -> IO(Unit):
  match r1 r2:
    case Fail{_} _:
      IO.die(Unit, 1, name)
    case Done{_} Fail{_}:
      IO.die(Unit, 1, name)
    case Done{Per.Period{y1, m1, d1}} Done{Per.Period{y2, m2, d2}}:
      PeriodTest.ok(
        name,
        Bool.and(
          U32.is_eq(y1, y2), Bool.and(U32.is_eq(m1, m2), U32.is_eq(d1, d2))
        )
      )

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- PeriodTest.add(
      "jan31", Per.Period.from(0, 1, 0), D.Date{2026, 1, 31}, 2026, 2, 28
    )
    Unit <- PeriodTest.add(
      "feb29y", Per.Period.from(1, 0, 0), D.Date{2024, 2, 29}, 2025, 2, 28
    )
    Unit <- PeriodTest.add(
      "jan31d", Per.Period.from(0, 1, 1), D.Date{2026, 1, 31}, 2026, 3, 1
    )
    Unit <- PeriodTest.add(
      "feb29_2000", Per.Period.from(1, 0, 0), D.Date{2000, 2, 29}, 2001, 2, 28
    )
    Unit <- PeriodTest.add_fail(
      "maxd", Per.Period.from(0, 0, 1), D.Date{9999, 12, 31}
    )
    Unit <- PeriodTest.add(
      "m13", Per.Period.from(0, 13, 0), D.Date{2026, 1, 15}, 2027, 2, 15
    )
    Unit <- PeriodTest.norm(
      "norm", Per.Period.from(0, 13, 0), Per.Period.from(1, 1, 0)
    )
    IO.print("ok")
