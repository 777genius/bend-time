import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ./posix_tz.bend as Px

def Posix.wday.z(+d: U32, z: Bool) -> U32:
  match z:
    case True{}:
      6
    case False{}:
      U32.sub(d, 1)

def Posix.wday(+d: U32) -> U32:
  Posix.wday.z(d, U32.is_eq(d, 0))

def Posix.date_err(
  r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, Px.Posix.Error, D.Date>:
  match r:
    case Fail{_}:
      Fail{Px.OutOfRange{}}
    case Done{d}:
      Done{d}

def Posix.rule.tod.go(
  date: D.Date, r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>,
  off: DT.UtcOffset
) -> Result<&2, &2, Px.Posix.Error, I.Instant>:
  match r:
    case Fail{_}:
      Fail{Px.Invalid{}}
    case Done{t}:
      Done{
        DT.OffsetDateTime.to_instant(
          DT.LocalDateTime.at_offset(DT.LocalDateTime.from(date, t), off)
        )
      }

def Posix.rule.tod(
  date: D.Date, +hour: U32, off: DT.UtcOffset
) -> Result<&2, &2, Px.Posix.Error, I.Instant>:
  Posix.rule.tod.go(date, DT.TimeOfDay.from(hour, 0, 0, DT.FracNone{}), off)

def Posix.rule.tod_r(
  r: Result<&2, &2, Px.Posix.Error, D.Date>, +hour: U32, off: DT.UtcOffset
) -> Result<&2, &2, Px.Posix.Error, I.Instant>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{d}:
      Posix.rule.tod(d, hour, off)

def Posix.rule.last2(
  r: Result<&2, &2, D.Date.Error, D.Date>, w: D.Weekday
) -> Result<&2, &2, Px.Posix.Error, D.Date>:
  match r:
    case Fail{_}:
      Fail{Px.OutOfRange{}}
    case Done{eom}:
      Posix.date_err(D.Date.previous_or_same_weekday(eom, w))

def Posix.rule.last(
  r: Result<&2, &2, Px.Posix.Error, D.Date>, w: D.Weekday
) -> Result<&2, &2, Px.Posix.Error, D.Date>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{d}:
      Posix.rule.last2(D.Date.end_of_month(d), w)

def Posix.rule.nth2(
  r: Result<&2, &2, D.Date.Error, D.Date>, +n: U32
) -> Result<&2, &2, Px.Posix.Error, D.Date>:
  match r:
    case Fail{_}:
      Fail{Px.OutOfRange{}}
    case Done{d}:
      Posix.date_err(D.Date.add_days(d, U32.mul(7, U32.sub(n, 1))))

def Posix.rule.nth(
  r: Result<&2, &2, Px.Posix.Error, D.Date>, +n: U32, w: D.Weekday
) -> Result<&2, &2, Px.Posix.Error, D.Date>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{d}:
      Posix.rule.nth2(D.Date.next_or_same_weekday(d, w), n)

def Posix.rule.week(
  last: Bool, start: Result<&2, &2, Px.Posix.Error, D.Date>, w: D.Weekday, +n: U32
) -> Result<&2, &2, Px.Posix.Error, D.Date>:
  match last:
    case True{}:
      Posix.rule.last(start, w)
    case False{}:
      Posix.rule.nth(start, n, w)

def Posix.rule.date(
  +y: U32, +month: U32, +week: U32, +wday: U32
) -> Result<&2, &2, Px.Posix.Error, D.Date>:
  Posix.rule.week(
    U32.is_eq(week, 5),
    Posix.date_err(D.Date.from(y, month, 1)),
    D.Date.weekday.n(Posix.wday(wday)),
    week
  )

def Posix.rule_instant(
  +y: U32, rule: Px.Posix.Rule, off: DT.UtcOffset
) -> Result<&2, &2, Px.Posix.Error, I.Instant>:
  match rule:
    case Px.RuleM{+month, +week, +wday, +hour}:
      Posix.rule.tod_r(Posix.rule.date(y, month, week, wday), hour, off)

def Posix.at.north(
  +i: I.Instant, std: DT.UtcOffset, dst: DT.UtcOffset, +si: I.Instant,
  +ei: I.Instant, in_dst: Bool
) -> Result<&2, &2, Px.Posix.Error, DT.UtcOffset>:
  match in_dst:
    case True{}:
      Done{dst}
    case False{}:
      Done{std}

def Posix.at.range(
  +i: I.Instant, std: DT.UtcOffset, dst: DT.UtcOffset, +si: I.Instant,
  +ei: I.Instant, northern: Bool
) -> Result<&2, &2, Px.Posix.Error, DT.UtcOffset>:
  match northern:
    case True{}:
      Posix.at.north(
        i, std, dst, si, ei,
        Bool.and(Bool.not(I.Instant.is_lt(i, si)), I.Instant.is_lt(i, ei))
      )
    case False{}:
      Posix.at.north(
        i, std, dst, si, ei,
        Bool.or(I.Instant.is_lt(i, ei), Bool.not(I.Instant.is_lt(i, si)))
      )

def Posix.at.dst.go(
  +i: I.Instant, std: DT.UtcOffset, dst: DT.UtcOffset, +si: I.Instant,
  er: Result<&2, &2, Px.Posix.Error, I.Instant>
) -> Result<&2, &2, Px.Posix.Error, DT.UtcOffset>:
  match er:
    case Fail{e}:
      Fail{e}
    case Done{+ei}:
      Posix.at.range(i, std, dst, si, ei, I.Instant.is_lt(si, ei))

def Posix.at.dst(
  +i: I.Instant, +std: DT.UtcOffset, +dst: DT.UtcOffset,
  sr: Result<&2, &2, Px.Posix.Error, I.Instant>,
  +end: Px.Posix.Rule, +y: U32
) -> Result<&2, &2, Px.Posix.Error, DT.UtcOffset>:
  match sr:
    case Fail{e}:
      Fail{e}
    case Done{si}:
      Posix.at.dst.go(i, std, dst, si, Posix.rule_instant(y, end, dst))

def Posix.at.y(
  tz: Px.Posix.Tz, +i: I.Instant, +y: U32
) -> Result<&2, &2, Px.Posix.Error, DT.UtcOffset>:
  match tz:
    case Px.TzStd{off}:
      Done{off}
    case Px.TzDst{+std, +dst, +start, +end}:
      Posix.at.dst(i, std, dst, Posix.rule_instant(y, start, std), end, y)

def Posix.at.date(
  r: Result<&2, &2, D.Date.Error, D.Date>, tz: Px.Posix.Tz, +i: I.Instant
) -> Result<&2, &2, Px.Posix.Error, DT.UtcOffset>:
  match r:
    case Fail{_}:
      Fail{Px.OutOfRange{}}
    case Done{D.Date{+y, _, _}}:
      Posix.at.y(tz, i, y)

def Posix.at(
  +tz: Px.Posix.Tz, +i: I.Instant
) -> Result<&2, &2, Px.Posix.Error, DT.UtcOffset>:
  Posix.at.date(I.Instant.to_utc_date(i), tz, i)
