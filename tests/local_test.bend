import Base
import ../date.bend as D
import ../datetime.bend as DT
import ../duration.bend as Dur
import ../instant.bend as I

def LocalTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def LocalTest.unix_n(
  name: String, r: Result<&2, &2, D.Date.Error, U32>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{n}:
      LocalTest.ok(name, U32.is_eq(n, want))

def LocalTest.done(
  name: String, r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.pure(Unit, Unit{})

def LocalTest.fail(
  name: String, r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def LocalTest.ymd(
  name: String, r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>, +y: U32, +m: U32, +d: U32, +h: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{DT.OffsetDateTime{D.Date{yy, mm, dd}, DT.TimeOfDay{hh, _, _, _}, _}}:
      LocalTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y),
          Bool.and(
            U32.is_eq(mm, m),
            Bool.and(U32.is_eq(dd, d), U32.is_eq(hh, h))
          )
        )
      )

def LocalTest.round(
  name: String, r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>, want: I.Instant
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{odt}:
      LocalTest.ok(name, I.Instant.is_eq(DT.OffsetDateTime.to_instant(odt), want))

def LocalTest.off(
  name: String, r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>, i: I.Instant, +y: U32, +m: U32, +d: U32, +h: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      LocalTest.ymd(name, DT.OffsetDateTime.from_instant(i, off), y, m, d, h)

def LocalTest.off_round(
  name: String, r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>, +i: I.Instant
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      LocalTest.round(name, DT.OffsetDateTime.from_instant(i, off), i)

def LocalTest.off_fail(
  name: String, r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>, i: I.Instant
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      LocalTest.fail(name, DT.OffsetDateTime.from_instant(i, off))

def LocalTest.unix_at(
  name: String,
  r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>,
  local: DT.LocalDateTime
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      LocalTest.unix_n(
        name, DT.OffsetDateTime.to_unix(DT.LocalDateTime.at_offset(local, off)), 1789723800
      )

def LocalTest.time(
  name: String, r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{t}:
      LocalTest.unix_at(
        name,
        DT.UtcOffset.from(False{}, 3, 0),
        DT.LocalDateTime.from(D.Date{2026, 9, 18}, t)
      )

def LocalTest.add1c(
  name: String, r: Result<&2, &2, I.Instant.Error, DT.OffsetDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{o2}:
      LocalTest.unix_n(
        name, DT.OffsetDateTime.to_unix(o2), 1789734601
      )

def LocalTest.add1b(
  name: String, r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{odt}:
      LocalTest.add1c(name, DT.OffsetDateTime.add(odt, Dur.Duration.from_secs(1)))

def LocalTest.add1(
  name: String, r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      LocalTest.add1b(
        name, DT.OffsetDateTime.from_instant(I.Instant.from_unix(1789734600), off)
      )

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- LocalTest.ymd(
      "z1230",
      DT.OffsetDateTime.from_instant(I.Instant.from_unix(1789734600), DT.OffsetZero{}),
      2026, 9, 18, 12
    )
    Unit <- LocalTest.off(
      "e1530", DT.UtcOffset.from(False{}, 3, 0), I.Instant.from_unix(1789734600),
      2026, 9, 18, 15
    )
    Unit <- LocalTest.off_round(
      "round3", DT.UtcOffset.from(False{}, 3, 0), I.Instant.from_unix(1789734600)
    )
    Unit <- LocalTest.done(
      "y1e",
      DT.OffsetDateTime.from_instant(
        I.Instant.from_utc_date(D.Date{1, 1, 1}), DT.OffsetZero{}
      )
    )
    Unit <- LocalTest.off(
      "y1p3", DT.UtcOffset.from(False{}, 3, 0), I.Instant.from_utc_date(D.Date{1, 1, 1}),
      1, 1, 1, 3
    )
    Unit <- LocalTest.off_fail(
      "y1w", DT.UtcOffset.from(True{}, 1, 0), I.Instant.from_utc_date(D.Date{1, 1, 1})
    )
    Unit <- LocalTest.off(
      "west", DT.UtcOffset.from(True{}, 1, 0), I.Instant.from_unix(1789689600),
      2026, 9, 17, 23
    )
    Unit <- LocalTest.time("at03", DT.TimeOfDay.from(12, 30, 0, DT.FracNone{}))
    Unit <- LocalTest.add1("add1", DT.UtcOffset.from(False{}, 3, 0))
    IO.print("ok")
