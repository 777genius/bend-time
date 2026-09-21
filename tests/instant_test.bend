import Base
import ../date.bend as D
import ../datetime.bend as DT
import ../duration.bend as Dur
import ../instant.bend as I

def InstantTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def InstantTest.unix_ok(
  name: String, r: Result<&2, &2, I.Instant.Error, U32>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{n}:
      InstantTest.ok(name, U32.is_eq(n, want))

def InstantTest.unix_fail(
  name: String, r: Result<&2, &2, I.Instant.Error, U32>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def InstantTest.ymd(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{D.Date{yy, mm, dd}}:
      InstantTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y), Bool.and(U32.is_eq(mm, m), U32.is_eq(dd, d))
        )
      )

def InstantTest.from_date_unix(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{date}:
      InstantTest.unix_ok(
        name, I.Instant.to_unix(I.Instant.from_utc_date(date)), want
      )

def InstantTest.from_date_unix_fail(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{date}:
      InstantTest.unix_fail(
        name, I.Instant.to_unix(I.Instant.from_utc_date(date))
      )

def InstantTest.sod(name: String, i: I.Instant, want: U32) -> IO(Unit):
  match i:
    case I.Instant{_, sod, _}:
      InstantTest.ok(name, U32.is_eq(sod, want))

def InstantTest.utc_ok(
  name: String, r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.pure(Unit, Unit{})

def InstantTest.add_unix2(
  name: String, r: Result<&2, &2, I.Instant.Error, I.Instant>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{j}:
      InstantTest.unix_ok(name, I.Instant.to_unix(j), want)

def InstantTest.add_unix(
  name: String, i: I.Instant, d: Dur.Duration, want: U32
) -> IO(Unit):
  InstantTest.add_unix2(name, I.Instant.add(i, d), want)

def InstantTest.add_then_unix_fail2(
  name: String, r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{j}:
      InstantTest.unix_fail(name, I.Instant.to_unix(j))

def InstantTest.add_then_unix_fail(name: String, i: I.Instant, d: Dur.Duration) -> IO(Unit):
  InstantTest.add_then_unix_fail2(name, I.Instant.add(i, d))

def InstantTest.add_fail2(
  name: String, r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def InstantTest.add_fail(name: String, i: I.Instant, d: Dur.Duration) -> IO(Unit):
  InstantTest.add_fail2(name, I.Instant.add(i, d))

def InstantTest.max_add(
  name: String, r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      InstantTest.add_fail(name, i, Dur.Duration.from_secs(1))

def InstantTest.from_fail(
  name: String, r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def InstantTest.parts(
  name: String, i: I.Instant, +days: U32, +sod: U32, +ns: U32
) -> IO(Unit):
  match i:
    case I.Instant{d, s, n}:
      InstantTest.ok(
        name,
        Bool.and(
          U32.is_eq(d, days),
          Bool.and(U32.is_eq(s, sod), U32.is_eq(n, ns))
        )
      )

def InstantTest.until_zero(
  name: String, r: Result<&2, &2, I.Instant.Error, Dur.Duration>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{d}:
      InstantTest.ok(name, Dur.Duration.is_eq(d, Dur.Duration.zero()))

def InstantTest.until_fail(
  name: String, r: Result<&2, &2, I.Instant.Error, Dur.Duration>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- InstantTest.from_date_unix("unix0", D.Date.from(1970, 1, 1), 0)
    Unit <- InstantTest.from_date_unix(
      "unix2026", D.Date.from(2026, 9, 18), 1789689600
    )
    Unit <- InstantTest.from_date_unix_fail("unix1900", D.Date.from(1900, 1, 1))
    Unit <- InstantTest.ymd(
      "from0", I.Instant.to_utc_date(I.Instant.from_unix(0)), 1970, 1, 1
    )
    Unit <- InstantTest.ymd(
      "from2026",
      I.Instant.to_utc_date(I.Instant.from_unix(1789689600)),
      2026, 9, 18
    )
    Unit <- InstantTest.unix_ok(
      "max", I.Instant.to_unix(I.Instant.from_unix(4294967295)), 4294967295
    )
    Unit <- InstantTest.unix_ok(
      "t1230", I.Instant.to_unix(I.Instant.from_unix(1789734600)), 1789734600
    )
    Unit <- InstantTest.sod("sod1230", I.Instant.from_unix(1789734600), 45000)
    Unit <- InstantTest.unix_fail(
      "y1unix", I.Instant.to_unix(I.Instant.from_utc_date(D.Date{1, 1, 1}))
    )
    Unit <- InstantTest.utc_ok(
      "y1odt",
      DT.OffsetDateTime.from_instant_utc(I.Instant.from_utc_date(D.Date{1, 1, 1}))
    )
    Unit <- InstantTest.add_unix(
      "add1d", I.Instant.from_unix(0), Dur.Duration.from_secs(86400), 86400
    )
    Unit <- InstantTest.add_then_unix_fail(
      "y1add", I.Instant.from_utc_date(D.Date{1, 1, 1}), Dur.Duration.from_secs(1)
    )
    Unit <- InstantTest.until_zero(
      "until0", I.Instant.until(I.Instant.from_unix(0), I.Instant.from_unix(0))
    )
    Unit <- InstantTest.until_fail(
      "until_back", I.Instant.until(I.Instant.from_unix(1), I.Instant.from_unix(0))
    )
    Unit <- InstantTest.ok(
      "lt01", I.Instant.is_lt(I.Instant.from_unix(0), I.Instant.from_unix(1))
    )
    Unit <- InstantTest.ok(
      "gt10", I.Instant.is_gt(I.Instant.from_unix(1), I.Instant.from_unix(0))
    )
    Unit <- InstantTest.from_fail("badsod", I.Instant.from(719468, 86400, 0))
    Unit <- InstantTest.max_add(
      "max1", I.Instant.from(D.Date.to_days(D.Date{9999, 12, 31}), 86399, 0)
    )
    Unit <- InstantTest.parts(
      "tr_min", I.Instant.trunc_min(I.Instant{0, 125, 7}), 0, 120, 0
    )
    Unit <- InstantTest.parts(
      "tr_min0", I.Instant.trunc_min(I.Instant{0, 120, 0}), 0, 120, 0
    )
    Unit <- InstantTest.parts(
      "tr_hour", I.Instant.trunc_hour(I.Instant{0, 3661, 0}), 0, 3600, 0
    )
    Unit <- InstantTest.parts(
      "tr_day", I.Instant.trunc_day(I.Instant{0, 1, 0}), 0, 0, 0
    )
    Unit <- InstantTest.parts(
      "tr_y1", I.Instant.trunc_day(I.Instant{306, 1, 0}), 306, 0, 0
    )
    IO.print("ok")
