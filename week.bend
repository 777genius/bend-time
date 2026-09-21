import Base
import ./date.bend as D

type IsoWeek is Data:
  IsoWeek{year: U32, week: U32}

def IsoWeek.start(d: D.Date) -> Result<&2, &2, D.Date.Error, D.Date>:
  D.Date.previous_or_same_weekday(d, D.Mon{})

def IsoWeek.from_date.week(
  +d: D.Date, +year: U32, r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, D.Date.Error, IsoWeek>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{mon1}:
      Done{
        IsoWeek{
          year,
          U32.add(
            1, U32.div(U32.sub(D.Date.to_days(d), D.Date.to_days(mon1)), 7)
          )
        }
      }

def IsoWeek.from_date.mon1(
  +d: D.Date, +year: U32, r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, D.Date.Error, IsoWeek>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{jan4}:
      IsoWeek.from_date.week(d, year, IsoWeek.start(jan4))

def IsoWeek.from_date.year(
  +d: D.Date, r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, D.Date.Error, IsoWeek>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{D.Date{+y, _, _}}:
      IsoWeek.from_date.mon1(d, y, D.Date.from(y, 1, 4))

def IsoWeek.from_date.thu(
  +d: D.Date, r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, D.Date.Error, IsoWeek>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{mon}:
      IsoWeek.from_date.year(d, D.Date.add_days(mon, 3))

def IsoWeek.from_date(+d: D.Date) -> Result<&2, &2, D.Date.Error, IsoWeek>:
  IsoWeek.from_date.thu(d, IsoWeek.start(d))

def IsoWeek.from.ok(
  got: D.Date, eq: Bool
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match eq:
    case True{}:
      Done{got}
    case False{}:
      Fail{D.OutOfRange{}}

def IsoWeek.from.eq(
  +year: U32, +week: U32, +got: D.Date,
  r: Result<&2, &2, D.Date.Error, IsoWeek>
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{IsoWeek{+y2, +w2}}:
      IsoWeek.from.ok(
        got, Bool.and(U32.is_eq(y2, year), U32.is_eq(w2, week))
      )

def IsoWeek.from.chk(
  +year: U32, +week: U32, r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{+got}:
      IsoWeek.from.eq(year, week, got, IsoWeek.from_date(got))

def IsoWeek.from.add(
  +year: U32, +week: U32, weekday: D.Weekday, mon1: D.Date
) -> Result<&2, &2, D.Date.Error, D.Date>:
  IsoWeek.from.chk(
    year, week,
    D.Date.add_days(
      mon1,
      U32.add(U32.mul(U32.sub(week, 1), 7), D.Weekday.to_u32(weekday))
    )
  )

def IsoWeek.from.le(
  +year: U32, +week: U32, weekday: D.Weekday, mon1: D.Date, ok: Bool
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match ok:
    case False{}:
      Fail{D.OutOfRange{}}
    case True{}:
      IsoWeek.from.add(year, week, weekday, mon1)

def IsoWeek.from.mon1(
  +year: U32, +week: U32, weekday: D.Weekday,
  r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{mon1}:
      IsoWeek.from.le(
        year, week, weekday, mon1,
        U32.is_le(U32.sub(week, 1), U32.div(U32.not(0), 7))
      )

def IsoWeek.from.jan4(
  +year: U32, +week: U32, weekday: D.Weekday,
  r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{jan4}:
      IsoWeek.from.mon1(year, week, weekday, IsoWeek.start(jan4))

def IsoWeek.from.hi(
  +year: U32, +week: U32, weekday: D.Weekday, hi: Bool
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match hi:
    case True{}:
      Fail{D.OutOfRange{}}
    case False{}:
      IsoWeek.from.jan4(year, week, weekday, D.Date.from(year, 1, 4))

def IsoWeek.from.ge(
  +year: U32, +week: U32, weekday: D.Weekday, z: Bool
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match z:
    case True{}:
      Fail{D.OutOfRange{}}
    case False{}:
      IsoWeek.from.hi(year, week, weekday, U32.is_ge(week, 54))

def IsoWeek.from(
  +year: U32, +week: U32, weekday: D.Weekday
) -> Result<&2, &2, D.Date.Error, D.Date>:
  IsoWeek.from.ge(year, week, weekday, U32.is_eq(week, 0))
