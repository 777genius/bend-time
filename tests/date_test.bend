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

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- DateTest.ymd("d2026", D.Date.from(2026, 9, 18), 2026, 9, 18)
    Unit <- DateTest.from_fail("feb30", D.Date.from(2026, 2, 30))
    Unit <- DateTest.from_fail("feb29_1900", D.Date.from(1900, 2, 29))
    Unit <- DateTest.from_ok("feb29_2000", D.Date.from(2000, 2, 29))
    Unit <- DateTest.ok("leap_2000", D.Date.leap(2000))
    Unit <- DateTest.ok("leap_1900", Bool.not(D.Date.leap(1900)))
    IO.print("ok")
