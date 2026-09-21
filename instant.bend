import Base
import ./date.bend as D
import ./duration.bend as Dur

type Instant.Error is Data:
  OutOfRange{}

type Instant is Data:
  Instant{days: U32, sod: U32, nanos: U32}

def Instant.epoch_days() -> U32:
  719468

def Instant.unix_fit(+udays: U32, +sod: U32) -> Bool:
  Bool.or(
    U32.is_lt(udays, 49710),
    Bool.and(U32.is_eq(udays, 49710), U32.is_le(sod, 23295))
  )

def Instant.to_unix.add(
  +udays: U32, +sod: U32, ok: Bool
) -> Result<&2, &2, Instant.Error, U32>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Done{U32.add(U32.mul(udays, 86400), sod)}

def Instant.to_unix.d(
  +udays: U32, +sod: U32
) -> Result<&2, &2, Instant.Error, U32>:
  Instant.to_unix.add(udays, sod, Instant.unix_fit(udays, sod))

def Instant.to_unix.ge(
  +days: U32, +sod: U32, ok: Bool
) -> Result<&2, &2, Instant.Error, U32>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Instant.to_unix.d(U32.sub(days, Instant.epoch_days()), sod)

def Instant.to_unix(i: Instant) -> Result<&2, &2, Instant.Error, U32>:
  match i:
    case Instant{+days, +sod, _}:
      Instant.to_unix.ge(days, sod, U32.is_ge(days, Instant.epoch_days()))

def Instant.from_unix(+secs: U32) -> Instant:
  Instant{
    U32.add(U32.div(secs, 86400), Instant.epoch_days()),
    U32.mod(secs, 86400),
    0
  }

def Instant.from_utc_date(d: D.Date) -> Instant:
  Instant{D.Date.to_days(d), 0, 0}

def Instant.to_utc_date(i: Instant) -> Result<&2, &2, D.Date.Error, D.Date>:
  match i:
    case Instant{days, _, _}:
      D.Date.from_days(days)

def Instant.is_eq(a: Instant, b: Instant) -> Bool:
  match a b:
    case Instant{+d1, +s1, +n1} Instant{+d2, +s2, +n2}:
      Bool.and(
        U32.is_eq(d1, d2),
        Bool.and(U32.is_eq(s1, s2), U32.is_eq(n1, n2))
      )

def Instant.is_lt.n(+n1: U32, +n2: U32, eq_s: Bool, slt: Bool) -> Bool:
  match eq_s:
    case False{}:
      slt
    case True{}:
      U32.is_lt(n1, n2)

def Instant.is_lt.s(
  +s1: U32, +n1: U32, +s2: U32, +n2: U32, eq_d: Bool, dlt: Bool
) -> Bool:
  match eq_d:
    case False{}:
      dlt
    case True{}:
      Instant.is_lt.n(n1, n2, U32.is_eq(s1, s2), U32.is_lt(s1, s2))

def Instant.is_lt(a: Instant, b: Instant) -> Bool:
  match a b:
    case Instant{+d1, +s1, +n1} Instant{+d2, +s2, +n2}:
      Instant.is_lt.s(s1, n1, s2, n2, U32.is_eq(d1, d2), U32.is_lt(d1, d2))

def Instant.is_gt(a: Instant, b: Instant) -> Bool:
  Instant.is_lt(b, a)

def Instant.is_le(a: Instant, b: Instant) -> Bool:
  Bool.not(Instant.is_lt(b, a))

def Instant.is_ge(a: Instant, b: Instant) -> Bool:
  Bool.not(Instant.is_lt(a, b))

def Instant.from.date(
  +days: U32, +sod: U32, +nanos: U32, r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, Instant.Error, Instant>:
  match r:
    case Fail{_}:
      Fail{OutOfRange{}}
    case Done{_}:
      Done{Instant{days, sod, nanos}}

def Instant.from.rng(
  +days: U32, +sod: U32, +nanos: U32, ok: Bool
) -> Result<&2, &2, Instant.Error, Instant>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Instant.from.date(days, sod, nanos, D.Date.from_days(days))

def Instant.from(
  +days: U32, +sod: U32, +nanos: U32
) -> Result<&2, &2, Instant.Error, Instant>:
  Instant.from.rng(
    days, sod, nanos,
    Bool.and(U32.is_le(sod, 86399), U32.is_le(nanos, 999999999))
  )

def Instant.of_dur.map(
  r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>
) -> Result<&2, &2, Instant.Error, Instant>:
  match r:
    case Fail{_}:
      Fail{OutOfRange{}}
    case Done{Dur.Duration{days, sod, nanos}}:
      Instant.from(days, sod, nanos)

def Instant.as_dur(i: Instant) -> Dur.Duration:
  match i:
    case Instant{days, sod, nanos}:
      Dur.Duration{days, sod, nanos}

def Instant.add(
  i: Instant, d: Dur.Duration
) -> Result<&2, &2, Instant.Error, Instant>:
  Instant.of_dur.map(Dur.Duration.add(Instant.as_dur(i), d))

def Instant.sub(
  i: Instant, d: Dur.Duration
) -> Result<&2, &2, Instant.Error, Instant>:
  Instant.of_dur.map(Dur.Duration.sub(Instant.as_dur(i), d))

def Instant.until.map(
  r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>
) -> Result<&2, &2, Instant.Error, Dur.Duration>:
  match r:
    case Fail{_}:
      Fail{OutOfRange{}}
    case Done{d}:
      Done{d}

def Instant.until.ord(
  start: Instant, end: Instant, lt: Bool
) -> Result<&2, &2, Instant.Error, Dur.Duration>:
  match lt:
    case True{}:
      Fail{OutOfRange{}}
    case False{}:
      Instant.until.map(
        Dur.Duration.sub(Instant.as_dur(end), Instant.as_dur(start))
      )

def Instant.until(
  +start: Instant, +end: Instant
) -> Result<&2, &2, Instant.Error, Dur.Duration>:
  Instant.until.ord(start, end, Instant.is_lt(end, start))
