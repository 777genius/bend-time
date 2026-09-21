import Base
import ../date.bend as D
import ../week.bend as W

def WeekTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def WeekTest.fail(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def WeekTest.fail_w(
  name: String, r: Result<&2, &2, D.Date.Error, W.IsoWeek>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def WeekTest.ymd(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{D.Date{yy, mm, dd}}:
      WeekTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y), Bool.and(U32.is_eq(mm, m), U32.is_eq(dd, d))
        )
      )

def WeekTest.week(
  name: String, r: Result<&2, &2, D.Date.Error, W.IsoWeek>, +y: U32, +w: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{W.IsoWeek{yy, ww}}:
      WeekTest.ok(
        name, Bool.and(U32.is_eq(yy, y), U32.is_eq(ww, w))
      )

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- WeekTest.week("fd_2026", W.IsoWeek.from_date(D.Date{2026, 1, 1}), 2026, 1)
    Unit <- WeekTest.ymd("st_2026", W.IsoWeek.start(D.Date{2026, 1, 1}), 2025, 12, 29)
    Unit <- WeekTest.week("fd_1229", W.IsoWeek.from_date(D.Date{2025, 12, 29}), 2026, 1)
    Unit <- WeekTest.week("fd_1228", W.IsoWeek.from_date(D.Date{2025, 12, 28}), 2025, 52)
    Unit <- WeekTest.week("fd_1231", W.IsoWeek.from_date(D.Date{2026, 12, 31}), 2026, 53)
    Unit <- WeekTest.week("fd_2020", W.IsoWeek.from_date(D.Date{2020, 12, 31}), 2020, 53)
    Unit <- WeekTest.week("fd_2015", W.IsoWeek.from_date(D.Date{2015, 12, 31}), 2015, 53)
    Unit <- WeekTest.ymd("from_w1", W.IsoWeek.from(2026, 1, D.Mon{}), 2025, 12, 29)
    Unit <- WeekTest.ymd("from_w53", W.IsoWeek.from(2026, 53, D.Thu{}), 2026, 12, 31)
    Unit <- WeekTest.fail("from_2019_53", W.IsoWeek.from(2019, 53, D.Mon{}))
    Unit <- WeekTest.fail("from_w0", W.IsoWeek.from(2026, 0, D.Mon{}))
    Unit <- WeekTest.fail("from_w54", W.IsoWeek.from(2026, 54, D.Mon{}))
    Unit <- WeekTest.fail("from_y0", W.IsoWeek.from(0, 1, D.Mon{}))
    Unit <- WeekTest.week("fd_y1", W.IsoWeek.from_date(D.Date{1, 1, 1}), 1, 1)
    Unit <- WeekTest.ymd("st_y1", W.IsoWeek.start(D.Date{1, 1, 1}), 1, 1, 1)
    Unit <- WeekTest.ymd("from_y1", W.IsoWeek.from(1, 1, D.Mon{}), 1, 1, 1)
    Unit <- WeekTest.ymd("from_y1_sun", W.IsoWeek.from(1, 1, D.Sun{}), 1, 1, 7)
    Unit <- WeekTest.fail("from_9999_53_sun", W.IsoWeek.from(9999, 53, D.Sun{}))
    IO.print("ok")
