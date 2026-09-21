import Base
import ../date.bend as D

def DateTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def DateTest.from_ok(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.pure(Unit, Unit{})

def DateTest.from_fail(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def DateTest.ymd(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{D.Date{yy, mm, dd}}:
      DateTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y), Bool.and(U32.is_eq(mm, m), U32.is_eq(dd, d))
        )
      )

def DateTest.thu(name: String, w: D.Weekday) -> IO(Unit):
  match w:
    case D.Thu{}:
      IO.pure(Unit, Unit{})
    case _:
      IO.die(Unit, 1, name)

def DateTest.fri(name: String, w: D.Weekday) -> IO(Unit):
  match w:
    case D.Fri{}:
      IO.pure(Unit, Unit{})
    case _:
      IO.die(Unit, 1, name)

def DateTest.round(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{date}:
      DateTest.ymd(name, D.Date.from_days(D.Date.to_days(date)), y, m, d)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- DateTest.ymd("d2026", D.Date.from(2026, 9, 18), 2026, 9, 18)
    Unit <- DateTest.from_fail("feb30", D.Date.from(2026, 2, 30))
    Unit <- DateTest.from_fail("feb29_1900", D.Date.from(1900, 2, 29))
    Unit <- DateTest.from_ok("feb29_2000", D.Date.from(2000, 2, 29))
    Unit <- DateTest.ok("leap_2000", D.Date.leap(2000))
    Unit <- DateTest.ok("leap_1900", Bool.not(D.Date.leap(1900)))
    Unit <- DateTest.round("rt_1", D.Date.from(1, 1, 1), 1, 1, 1)
    Unit <- DateTest.round("rt_1970", D.Date.from(1970, 1, 1), 1970, 1, 1)
    Unit <- DateTest.round("rt_2000", D.Date.from(2000, 2, 29), 2000, 2, 29)
    Unit <- DateTest.round("rt_2026", D.Date.from(2026, 9, 18), 2026, 9, 18)
    Unit <- DateTest.round("rt_9999", D.Date.from(9999, 12, 31), 9999, 12, 31)
    Unit <- DateTest.ymd("add1", D.Date.add_days(D.Date{2026, 9, 18}, 1), 2026, 9, 19)
    Unit <- DateTest.ymd("sub18", D.Date.sub_days(D.Date{2026, 9, 18}, 18), 2026, 8, 31)
    Unit <- DateTest.thu("thu", D.Date.weekday(D.Date{1970, 1, 1}))
    Unit <- DateTest.fri("fri", D.Date.weekday(D.Date{2026, 9, 18}))
    Unit <- DateTest.ok(
      "lt1970", D.Date.is_lt(D.Date{1970, 1, 1}, D.Date{1970, 1, 2})
    )
    IO.print("ok")
