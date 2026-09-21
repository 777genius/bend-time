import Base
import ./date.bend as D
import ./duration.bend as Dur
import ./instant.bend as I

type TimeFrac is Data:
  FracNone{}
  Frac{digits: Nat, value: U32}

type TimeOfDay.Error is Data:
  InvalidTime{hour: U32, minute: U32, second: U32}

type TimeOfDay is Data:
  TimeOfDay{hour: U32, minute: U32, second: U32, frac: TimeFrac}

type UtcOffset.Error is Data:
  InvalidOffset{hour: U32, minute: U32}
  NegativeZero{}

type UtcOffset is Data:
  OffsetZero{}
  OffsetEast{hour: U32, minute: U32}
  OffsetWest{hour: U32, minute: U32}

type OffsetDateTime is Data:
  OffsetDateTime{date: D.Date, time: TimeOfDay, offset: UtcOffset}

type LocalDateTime is Data:
  LocalDateTime{date: D.Date, time: TimeOfDay}

def TimeOfDay.from.frac(+h: U32, +mi: U32, +s: U32, frac: TimeFrac, ok: Bool) ->
  Result<&2, &2, TimeOfDay.Error, TimeOfDay>:
  match ok:
    case False{}:
      Fail{InvalidTime{h, mi, s}}
    case True{}:
      Done{TimeOfDay{h, mi, s, frac}}

def TimeOfDay.from(
  +h: U32, +mi: U32, +s: U32, frac: TimeFrac
) -> Result<&2, &2, TimeOfDay.Error, TimeOfDay>:
  TimeOfDay.from.frac(
    h, mi, s, frac,
    Bool.and(
      U32.is_le(h, 23),
      Bool.and(U32.is_le(mi, 59), U32.is_le(s, 59))
    )
  )

def UtcOffset.from.zero(
  z: Bool, west: Bool, +h: U32, +mi: U32
) -> Result<&2, &2, UtcOffset.Error, UtcOffset>:
  match z west:
    case True{} True{}:
      Fail{NegativeZero{}}
    case True{} False{}:
      Done{OffsetZero{}}
    case False{} True{}:
      Done{OffsetWest{h, mi}}
    case False{} False{}:
      Done{OffsetEast{h, mi}}

def UtcOffset.from.range(
  west: Bool, +h: U32, +mi: U32, ok: Bool
) -> Result<&2, &2, UtcOffset.Error, UtcOffset>:
  match ok:
    case False{}:
      Fail{InvalidOffset{h, mi}}
    case True{}:
      UtcOffset.from.zero(
        Bool.and(U32.is_eq(h, 0), U32.is_eq(mi, 0)), west, h, mi
      )

def UtcOffset.from(
  west: Bool, +h: U32, +mi: U32
) -> Result<&2, &2, UtcOffset.Error, UtcOffset>:
  UtcOffset.from.range(
    west, h, mi, Bool.and(U32.is_le(h, 23), U32.is_le(mi, 59))
  )

def UtcOffset.zero() -> UtcOffset:
  OffsetZero{}

def Datetime.sod(+h: U32, +mi: U32, +s: U32) -> U32:
  U32.add(U32.add(U32.mul(h, 3600), U32.mul(mi, 60)), s)

def Datetime.off_sec(+h: U32, +mi: U32) -> U32:
  U32.add(U32.mul(h, 3600), U32.mul(mi, 60))

def Datetime.frac_nanos(frac: TimeFrac) -> U32:
  match frac:
    case FracNone{}:
      0
    case Frac{digits, value}:
      U32.mul(value, U32.pow(10, Nat.sub(9n, digits)))

def Datetime.utc_east2(
  days: U32, +local: U32, +off: U32, ge: Bool
) -> U32 & U32:
  match ge:
    case True{}:
      (days, U32.sub(local, off))
    case False{}:
      (U32.sub(days, 1), U32.sub(U32.add(local, 86400), off))

def Datetime.utc_east(days: U32, +local: U32, +off: U32) -> U32 & U32:
  Datetime.utc_east2(days, local, off, U32.is_ge(local, off))

def Datetime.utc_west2(
  days: U32, +local: U32, +off: U32, ge: Bool
) -> U32 & U32:
  match ge:
    case True{}:
      (U32.add(days, 1), U32.sub(U32.add(local, off), 86400))
    case False{}:
      (days, U32.add(local, off))

def Datetime.utc_west(days: U32, +local: U32, +off: U32) -> U32 & U32:
  Datetime.utc_west2(
    days, local, off, U32.is_ge(U32.add(local, off), 86400)
  )

def Datetime.apply_off(
  days: U32, local: U32, offset: UtcOffset
) -> U32 & U32:
  match offset:
    case OffsetZero{}:
      (days, local)
    case OffsetEast{h, mi}:
      Datetime.utc_east(days, local, Datetime.off_sec(h, mi))
    case OffsetWest{h, mi}:
      Datetime.utc_west(days, local, Datetime.off_sec(h, mi))

def Datetime.unapply_off(
  days: U32, utc: U32, offset: UtcOffset
) -> U32 & U32:
  match offset:
    case OffsetZero{}:
      (days, utc)
    case OffsetEast{h, mi}:
      Datetime.utc_west(days, utc, Datetime.off_sec(h, mi))
    case OffsetWest{h, mi}:
      Datetime.utc_east(days, utc, Datetime.off_sec(h, mi))

def Datetime.inst_of2(ds: U32 & U32, nanos: U32) -> I.Instant:
  (days, sod) = ds
  I.Instant{days, sod, nanos}

def Datetime.inst_of(
  date: D.Date, time: TimeOfDay, offset: UtcOffset
) -> I.Instant:
  match time:
    case TimeOfDay{h, mi, s, frac}:
      Datetime.inst_of2(
        Datetime.apply_off(D.Date.to_days(date), Datetime.sod(h, mi, s), offset),
        Datetime.frac_nanos(frac)
      )

def OffsetDateTime.to_instant(odt: OffsetDateTime) -> I.Instant:
  match odt:
    case OffsetDateTime{date, time, offset}:
      Datetime.inst_of(date, time, offset)

def OffsetDateTime.same_instant(
  +a: OffsetDateTime, +b: OffsetDateTime
) -> Bool:
  I.Instant.is_eq(OffsetDateTime.to_instant(a), OffsetDateTime.to_instant(b))

def OffsetDateTime.from(
  date: D.Date, time: TimeOfDay, offset: UtcOffset
) -> OffsetDateTime:
  OffsetDateTime{date, time, offset}

def OffsetDateTime.to_unix.map(
  r: Result<&2, &2, I.Instant.Error, U32>
) -> Result<&2, &2, D.Date.Error, U32>:
  match r:
    case Fail{_}:
      Fail{D.OutOfRange{}}
    case Done{n}:
      Done{n}

def OffsetDateTime.to_unix(
  odt: OffsetDateTime
) -> Result<&2, &2, D.Date.Error, U32>:
  OffsetDateTime.to_unix.map(I.Instant.to_unix(OffsetDateTime.to_instant(odt)))

def OffsetDateTime.from_instant.clock(
  offset: UtcOffset, date: D.Date, r: Result<&2, &2, TimeOfDay.Error, TimeOfDay>
) -> Result<&2, &2, D.Date.Error, OffsetDateTime>:
  match r:
    case Fail{_}:
      Fail{D.OutOfRange{}}
    case Done{t}:
      Done{OffsetDateTime.from(date, t, offset)}

def OffsetDateTime.from_instant.date(
  +sod: U32, offset: UtcOffset, r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, D.Date.Error, OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{date}:
      OffsetDateTime.from_instant.clock(
        offset, date,
        TimeOfDay.from(
          U32.div(sod, 3600),
          U32.div(U32.mod(sod, 3600), 60),
          U32.mod(sod, 60),
          FracNone{}
        )
      )

def OffsetDateTime.from_instant.pair(
  ds: U32 & U32, offset: UtcOffset
) -> Result<&2, &2, D.Date.Error, OffsetDateTime>:
  (days, sod) = ds
  OffsetDateTime.from_instant.date(sod, offset, D.Date.from_days(days))

def OffsetDateTime.from_instant(
  i: I.Instant, +offset: UtcOffset
) -> Result<&2, &2, D.Date.Error, OffsetDateTime>:
  match i:
    case I.Instant{days, sod, _}:
      OffsetDateTime.from_instant.pair(
        Datetime.unapply_off(days, sod, offset), offset
      )

def OffsetDateTime.from_instant_utc(
  i: I.Instant
) -> Result<&2, &2, D.Date.Error, OffsetDateTime>:
  OffsetDateTime.from_instant(i, OffsetZero{})

def OffsetDateTime.add.odt(
  r: Result<&2, &2, D.Date.Error, OffsetDateTime>
) -> Result<&2, &2, I.Instant.Error, OffsetDateTime>:
  match r:
    case Fail{_}:
      Fail{I.OutOfRange{}}
    case Done{o}:
      Done{o}

def OffsetDateTime.add.map(
  offset: UtcOffset, r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> Result<&2, &2, I.Instant.Error, OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{i}:
      OffsetDateTime.add.odt(OffsetDateTime.from_instant(i, offset))

def OffsetDateTime.add(
  +odt: OffsetDateTime, d: Dur.Duration
) -> Result<&2, &2, I.Instant.Error, OffsetDateTime>:
  match odt:
    case OffsetDateTime{_, _, +offset}:
      OffsetDateTime.add.map(
        offset, I.Instant.add(OffsetDateTime.to_instant(odt), d)
      )

def OffsetDateTime.sub(
  +odt: OffsetDateTime, d: Dur.Duration
) -> Result<&2, &2, I.Instant.Error, OffsetDateTime>:
  match odt:
    case OffsetDateTime{_, _, +offset}:
      OffsetDateTime.add.map(
        offset, I.Instant.sub(OffsetDateTime.to_instant(odt), d)
      )

def LocalDateTime.from(date: D.Date, time: TimeOfDay) -> LocalDateTime:
  LocalDateTime{date, time}

def LocalDateTime.at_offset(
  local: LocalDateTime, offset: UtcOffset
) -> OffsetDateTime:
  match local:
    case LocalDateTime{date, time}:
      OffsetDateTime.from(date, time, offset)

def OffsetDateTime.to_local(odt: OffsetDateTime) -> LocalDateTime:
  match odt:
    case OffsetDateTime{date, time, _}:
      LocalDateTime.from(date, time)

def OffsetDateTime.from_unix(
  secs: U32
) -> Result<&2, &2, D.Date.Error, OffsetDateTime>:
  OffsetDateTime.from_instant_utc(I.Instant.from_unix(secs))

