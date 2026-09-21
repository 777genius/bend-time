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

def DateTest.mon(name: String, w: D.Weekday) -> IO(Unit):
  match w:
    case D.Mon{}:
      IO.pure(Unit, Unit{})
    case _:
      IO.die(Unit, 1, name)

def DateTest.u32(
  name: String, r: Result<&2, &2, D.Date.Error, U32>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{n}:
      DateTest.ok(name, U32.is_eq(n, want))

def DateTest.u32_fail(
  name: String, r: Result<&2, &2, D.Date.Error, U32>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def DateTest.u32_ok(
  name: String, r: Result<&2, &2, D.Date.Error, U32>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.pure(Unit, Unit{})

def DateTest.inv(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  match r:
    case Fail{D.InvalidDate{yy, mm, dd}}:
      DateTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y), Bool.and(U32.is_eq(mm, m), U32.is_eq(dd, d))
        )
      )
    case _:
      IO.die(Unit, 1, name)

def DateTest.total(
  name: String, date: D.Date, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  match date:
    case D.Date{yy, mm, dd}:
      DateTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y), Bool.and(U32.is_eq(mm, m), U32.is_eq(dd, d))
        )
      )

def DateTest.wd(name: String, w: D.Weekday, want: U32) -> IO(Unit):
  DateTest.ok(name, U32.is_eq(D.Weekday.to_u32(w), want))

def DateTest.end_garb(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  DateTest.ymd(name, r, y, m, d)

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
    Unit <- DateTest.total("som", D.Date.start_of_month(D.Date{2026, 9, 18}), 2026, 9, 1)
    Unit <- DateTest.total("som1", D.Date.start_of_month(D.Date{2026, 9, 1}), 2026, 9, 1)
    Unit <- DateTest.ymd("eom_feb", D.Date.end_of_month(D.Date{2026, 2, 1}), 2026, 2, 28)
    Unit <- DateTest.ymd("eom_leap", D.Date.end_of_month(D.Date{2024, 2, 1}), 2024, 2, 29)
    Unit <- DateTest.ymd("eom_jan", D.Date.end_of_month(D.Date{2026, 1, 31}), 2026, 1, 31)
    Unit <- DateTest.end_garb(
      "eom_garb", D.Date.end_of_month(D.Date{2026, 2, 31}), 2026, 2, 28
    )
    Unit <- DateTest.end_garb(
      "eom_apr", D.Date.end_of_month(D.Date{2026, 4, 31}), 2026, 4, 30
    )
    Unit <- DateTest.total("soy", D.Date.start_of_year(D.Date{2026, 9, 18}), 2026, 1, 1)
    Unit <- DateTest.total("eoy", D.Date.end_of_year(D.Date{2026, 9, 18}), 2026, 12, 31)
    Unit <- DateTest.ymd("wd1", D.Date.with_day(D.Date{2026, 9, 18}, 1), 2026, 9, 1)
    Unit <- DateTest.ymd("wd18", D.Date.with_day(D.Date{2026, 9, 18}, 18), 2026, 9, 18)
    Unit <- DateTest.from_fail("wd_feb31", D.Date.with_day(D.Date{2026, 2, 1}, 31))
    Unit <- DateTest.from_fail("wd0", D.Date.with_day(D.Date{2026, 9, 18}, 0))
    Unit <- DateTest.from_fail("wd_apr31", D.Date.with_day(D.Date{2026, 4, 30}, 31))
    Unit <- DateTest.inv(
      "wm_jan31", D.Date.with_month(D.Date{2026, 1, 31}, 2), 2026, 2, 31
    )
    Unit <- DateTest.inv(
      "wm_may31", D.Date.with_month(D.Date{2026, 5, 31}, 4), 2026, 4, 31
    )
    Unit <- DateTest.from_fail("wm0", D.Date.with_month(D.Date{2026, 1, 15}, 0))
    Unit <- DateTest.from_fail("wm13", D.Date.with_month(D.Date{2026, 1, 15}, 13))
    Unit <- DateTest.from_fail("wy_leap", D.Date.with_year(D.Date{2024, 2, 29}, 2025))
    Unit <- DateTest.ymd("wy_2020", D.Date.with_year(D.Date{2024, 2, 29}, 2020), 2020, 2, 29)
    Unit <- DateTest.from_fail("wy0", D.Date.with_year(D.Date{2026, 9, 18}, 0))
    Unit <- DateTest.from_fail("wy10000", D.Date.with_year(D.Date{2026, 9, 18}, 10000))
    Unit <- DateTest.u32("dim_feb", D.Date.days_in_month(D.Date{2026, 2, 1}), 28)
    Unit <- DateTest.u32_fail("dim13", D.Date.days_in_month(D.Date{2026, 13, 1}))
    Unit <- DateTest.wd("tu_mon", D.Mon{}, 0)
    Unit <- DateTest.wd("tu_tue", D.Tue{}, 1)
    Unit <- DateTest.wd("tu_wed", D.Wed{}, 2)
    Unit <- DateTest.wd("tu_thu", D.Thu{}, 3)
    Unit <- DateTest.wd("tu_fri", D.Fri{}, 4)
    Unit <- DateTest.wd("tu_sat", D.Sat{}, 5)
    Unit <- DateTest.wd("tu_sun", D.Sun{}, 6)
    Unit <- DateTest.ymd(
      "next_mon", D.Date.next_weekday(D.Date{2026, 9, 18}, D.Mon{}), 2026, 9, 21
    )
    Unit <- DateTest.ymd(
      "next_fri", D.Date.next_weekday(D.Date{2026, 9, 18}, D.Fri{}), 2026, 9, 25
    )
    Unit <- DateTest.ymd(
      "nosa_fri",
      D.Date.next_or_same_weekday(D.Date{2026, 9, 18}, D.Fri{}),
      2026, 9, 18
    )
    Unit <- DateTest.ymd(
      "nosa_9999",
      D.Date.next_or_same_weekday(D.Date{9999, 12, 31}, D.Date.weekday(D.Date{9999, 12, 31})),
      9999, 12, 31
    )
    Unit <- DateTest.ymd(
      "prev_mon", D.Date.previous_weekday(D.Date{2026, 9, 18}, D.Mon{}), 2026, 9, 14
    )
    Unit <- DateTest.u32(
      "until0", D.Date.until_days(D.Date{2026, 9, 18}, D.Date{2026, 9, 18}), 0
    )
    Unit <- DateTest.u32(
      "until1", D.Date.until_days(D.Date{2026, 9, 18}, D.Date{2026, 9, 19}), 1
    )
    Unit <- DateTest.u32_fail(
      "until_rev", D.Date.until_days(D.Date{2026, 9, 19}, D.Date{2026, 9, 18})
    )
    Unit <- DateTest.u32_ok(
      "until_span", D.Date.until_days(D.Date{1, 1, 1}, D.Date{9999, 12, 31})
    )
    Unit <- DateTest.from_fail(
      "next_9999", D.Date.next_weekday(D.Date{9999, 12, 31}, D.Mon{})
    )
    Unit <- DateTest.ymd(
      "posa_y1",
      D.Date.previous_or_same_weekday(D.Date{1, 1, 1}, D.Mon{}),
      1, 1, 1
    )
    Unit <- DateTest.from_fail(
      "prev_y1_mon", D.Date.previous_weekday(D.Date{1, 1, 1}, D.Mon{})
    )
    Unit <- DateTest.from_fail(
      "prev_y1_sun", D.Date.previous_weekday(D.Date{1, 1, 1}, D.Sun{})
    )
    Unit <- DateTest.mon("wd_y1", D.Date.weekday(D.Date{1, 1, 1}))
    IO.print("ok")
