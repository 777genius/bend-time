import Base
import ./date.bend as D

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

type Datetime.Key is Data:
  InstKey{days: U32, sod: U32, nanos: U32}

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

def Datetime.key_of2(ds: U32 & U32, nanos: U32) -> Datetime.Key:
  (days, sod) = ds
  InstKey{days, sod, nanos}

def Datetime.key_of(
  date: D.Date, time: TimeOfDay, offset: UtcOffset
) -> Datetime.Key:
  match time:
    case TimeOfDay{h, mi, s, frac}:
      Datetime.key_of2(
        Datetime.apply_off(D.Date.to_days(date), Datetime.sod(h, mi, s), offset),
        Datetime.frac_nanos(frac)
      )

def OffsetDateTime.to_key(odt: OffsetDateTime) -> Datetime.Key:
  match odt:
    case OffsetDateTime{date, time, offset}:
      Datetime.key_of(date, time, offset)

def Datetime.key_eq(a: Datetime.Key, b: Datetime.Key) -> Bool:
  match a b:
    case InstKey{+d1, +s1, +n1} InstKey{+d2, +s2, +n2}:
      Bool.and(
        U32.is_eq(d1, d2),
        Bool.and(U32.is_eq(s1, s2), U32.is_eq(n1, n2))
      )

def OffsetDateTime.same_instant(
  a: OffsetDateTime, b: OffsetDateTime
) -> Bool:
  Datetime.key_eq(OffsetDateTime.to_key(a), OffsetDateTime.to_key(b))

def OffsetDateTime.from(
  date: D.Date, time: TimeOfDay, offset: UtcOffset
) -> OffsetDateTime:
  OffsetDateTime{date, time, offset}
