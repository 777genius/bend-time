import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/duration.bend as Dur
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ../posix_tz.bend as Px
import ../posix_at.bend as Pa
import ../zone.bend as Z

def PosixTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def PosixTest.inv(
  name: String, r: Result<&2, &2, Px.Posix.Error, Px.Posix.Tz>
) -> IO(Unit):
  match r:
    case Fail{Px.Invalid{}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def PosixTest.uns(
  name: String, r: Result<&2, &2, Px.Posix.Error, Px.Posix.Tz>
) -> IO(Unit):
  match r:
    case Fail{Px.Unsupported{}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def PosixTest.parse_ok(
  name: String, r: Result<&2, &2, Px.Posix.Error, Px.Posix.Tz>
) -> IO(Unit):
  match r:
    case Fail{Px.Invalid{}}:
      IO.die(Unit, 1, String.append(name, "_inv"))
    case Fail{Px.Unsupported{}}:
      IO.die(Unit, 1, String.append(name, "_uns"))
    case Fail{_}:
      IO.die(Unit, 1, String.append(name, "_fail"))
    case Done{_}:
      IO.pure(Unit, Unit{})

def PosixTest.utc_i(
  r: Result<&2, &2, D.Date.Error, D.Date>, +sod: U32
) -> Result<&2, &2, I.Instant.Error, I.Instant>:
  match r:
    case Fail{_}:
      Fail{I.OutOfRange{}}
    case Done{d}:
      I.Instant.add(I.Instant.from_utc_date(d), Dur.Duration{0, sod, 0})

def PosixTest.at_off(
  name: String,
  r: Result<&2, &2, Px.Posix.Error, DT.UtcOffset>,
  want: DT.UtcOffset
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{got}:
      PosixTest.ok(name, Z.Zone.off_eq(got, want))

def PosixTest.at_utc.go(
  name: String, tz: Px.Posix.Tz, want: DT.UtcOffset,
  r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      PosixTest.at_off(name, Pa.Posix.at(tz, i), want)

def PosixTest.at_utc(
  name: String, tz: Px.Posix.Tz, y: U32, mo: U32, d: U32, sod: U32,
  want: DT.UtcOffset
) -> IO(Unit):
  PosixTest.at_utc.go(name, tz, want, PosixTest.utc_i(D.Date.from(y, mo, d), sod))

def PosixTest.tz_at(
  name: String, r: Result<&2, &2, Px.Posix.Error, Px.Posix.Tz>,
  y: U32, mo: U32, d: U32, sod: U32, want: DT.UtcOffset
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{tz}:
      PosixTest.at_utc(name, tz, y, mo, d, sod, want)

def PosixTest.ny_at(
  r: Result<&2, &2, Px.Posix.Error, Px.Posix.Tz>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, "ny_parse")
    case Done{+tz}:
      do IO<Unit>:
        Unit <- PosixTest.at_utc(
          "ny_pre_s", tz, 2026, 3, 8, 25199, DT.OffsetWest{5, 0}
        )
        Unit <- PosixTest.at_utc(
          "ny_spring", tz, 2026, 3, 8, 25200, DT.OffsetWest{4, 0}
        )
        Unit <- PosixTest.at_utc(
          "ny_pre_f", tz, 2026, 11, 1, 21599, DT.OffsetWest{4, 0}
        )
        Unit <- PosixTest.at_utc(
          "ny_fall", tz, 2026, 11, 1, 21600, DT.OffsetWest{5, 0}
        )
        Unit <- PosixTest.at_utc(
          "ny_jan", tz, 2026, 1, 15, 43200, DT.OffsetWest{5, 0}
        )
        Unit <- PosixTest.at_utc(
          "ny_jul", tz, 2026, 7, 15, 43200, DT.OffsetWest{4, 0}
        )
        IO.pure(Unit, Unit{})

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- PosixTest.parse_ok("est5", Px.Posix.parse("EST5"))
    Unit <- PosixTest.parse_ok("est5edt", Px.Posix.parse("EST5EDT,M3.2.0,M11.1.0"))
    Unit <- PosixTest.ny_at(Px.Posix.parse("EST5EDT,M3.2.0,M11.1.0"))
    Unit <- PosixTest.ny_at(Px.Posix.parse("EST5EDT,M3.2.0/2,M11.1.0/2"))
    Unit <- PosixTest.tz_at(
      "cet_s", Px.Posix.parse("CET-1CEST,M3.5.0,M10.5.0/3"),
      2026, 3, 29, 3600, DT.OffsetEast{2, 0}
    )
    Unit <- PosixTest.tz_at(
      "cet_f", Px.Posix.parse("CET-1CEST,M3.5.0,M10.5.0/3"),
      2026, 10, 25, 3600, DT.OffsetEast{1, 0}
    )
    Unit <- PosixTest.tz_at(
      "est5", Px.Posix.parse("EST5"), 2026, 7, 15, 43200, DT.OffsetWest{5, 0}
    )
    Unit <- PosixTest.parse_ok("zero", Px.Posix.parse("<+00>0"))
    Unit <- PosixTest.tz_at(
      "south_d", Px.Posix.parse("EST5EDT,M11.1.0,M3.2.0"),
      2026, 12, 15, 43200, DT.OffsetWest{4, 0}
    )
    Unit <- PosixTest.tz_at(
      "south_s", Px.Posix.parse("EST5EDT,M11.1.0,M3.2.0"),
      2026, 7, 15, 43200, DT.OffsetWest{5, 0}
    )
    Unit <- PosixTest.inv("miss_end", Px.Posix.parse("EST5EDT,M3.2.0"))
    Unit <- PosixTest.inv("m13", Px.Posix.parse("EST5EDT,M13.1.0,M11.1.0"))
    Unit <- PosixTest.inv("m30", Px.Posix.parse("EST5EDT,M3.0.0,M11.1.0"))
    Unit <- PosixTest.inv("m36", Px.Posix.parse("EST5EDT,M3.6.0,M11.1.0"))
    Unit <- PosixTest.inv("m327", Px.Posix.parse("EST5EDT,M3.2.7,M11.1.0"))
    Unit <- PosixTest.inv("lower", Px.Posix.parse("est5edt,M3.2.0,M11.1.0"))
    Unit <- PosixTest.uns("h167", Px.Posix.parse("EST5EDT,M3.2.0/167,M11.1.0"))
    Unit <- PosixTest.uns("h230", Px.Posix.parse("EST5EDT,M3.2.0/2:30,M11.1.0"))
    Unit <- PosixTest.uns("colon", Px.Posix.parse("EST:30"))
    Unit <- PosixTest.uns("j100", Px.Posix.parse("EST5EDT,J100,M11.1.0"))
    Unit <- PosixTest.inv("extra", Px.Posix.parse("EST5EDT,M3.2.0,M11.1.0,extra"))
    Unit <- PosixTest.inv("empty", Px.Posix.parse(""))
    IO.print("ok")
