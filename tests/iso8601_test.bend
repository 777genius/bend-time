import Base
import ../duration.bend as Dur
import ../period.bend as Per
import ../iso8601.bend as Iso

def IsoTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def IsoTest.show_d(name: String, d: Dur.Duration, want: String) -> IO(Unit):
  IsoTest.ok(name, String.eq(Iso.Iso8601.show_duration(d), want))

def IsoTest.show_dr(
  name: String, r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>, want: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{d}:
      IsoTest.show_d(name, d, want)

def IsoTest.show_p(
  name: String, r: Result<&2, &2, Per.Period.Error, Per.Period>, want: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{p}:
      IsoTest.ok(name, String.eq(Iso.Iso8601.show_period(p), want))

def IsoTest.dur_eq(
  name: String, r: Result<&2, &2, Iso.Iso8601.Error, Dur.Duration>, want: Dur.Duration
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{d}:
      IsoTest.ok(name, Dur.Duration.is_eq(d, want))

def IsoTest.dur_from(
  name: String,
  r: Result<&2, &2, Iso.Iso8601.Error, Dur.Duration>,
  w: Result<&2, &2, Dur.Duration.Error, Dur.Duration>
) -> IO(Unit):
  match w:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{want}:
      IsoTest.dur_eq(name, r, want)

def IsoTest.sod(
  name: String,
  r: Result<&2, &2, Iso.Iso8601.Error, Dur.Duration>,
  +days: U32, +sod: U32, +nanos: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{Dur.Duration{dd, ss, nn}}:
      IsoTest.ok(
        name,
        Bool.and(
          U32.is_eq(dd, days),
          Bool.and(U32.is_eq(ss, sod), U32.is_eq(nn, nanos))
        )
      )

def IsoTest.dur_fail(
  name: String, r: Result<&2, &2, Iso.Iso8601.Error, Dur.Duration>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def IsoTest.dur_extra(
  name: String, r: Result<&2, &2, Iso.Iso8601.Error, Dur.Duration>
) -> IO(Unit):
  match r:
    case Fail{Iso.Extra{_, _}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def IsoTest.ymd(
  name: String, r: Result<&2, &2, Iso.Iso8601.Error, Per.Period>, +y: U32, +m: U32, +d: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{Per.Period{yy, mm, dd}}:
      IsoTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y), Bool.and(U32.is_eq(mm, m), U32.is_eq(dd, d))
        )
      )

def IsoTest.per_from(
  name: String,
  r: Result<&2, &2, Iso.Iso8601.Error, Per.Period>,
  w: Result<&2, &2, Per.Period.Error, Per.Period>
) -> IO(Unit):
  match r w:
    case Fail{_} _:
      IO.die(Unit, 1, name)
    case Done{_} Fail{_}:
      IO.die(Unit, 1, name)
    case Done{Per.Period{y1, m1, d1}} Done{Per.Period{y2, m2, d2}}:
      IsoTest.ok(
        name,
        Bool.and(
          U32.is_eq(y1, y2), Bool.and(U32.is_eq(m1, m2), U32.is_eq(d1, d2))
        )
      )

def IsoTest.per_fail(
  name: String, r: Result<&2, &2, Iso.Iso8601.Error, Per.Period>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def IsoTest.round_d(+name: String, +d: Dur.Duration) -> IO(Unit):
  IsoTest.dur_eq(name, Iso.Iso8601.read_duration(Iso.Iso8601.show_duration(d)), d)

def IsoTest.round_dr(
  name: String, r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{d}:
      IsoTest.round_d(name, d)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IsoTest.show_d("show_90m", Dur.Duration.from_secs(5400), "PT1H30M")
    Unit <- IsoTest.show_d("show_zero", Dur.Duration.zero(), "PT0S")
    Unit <- IsoTest.show_d("show_1d", Dur.Duration.from_days(1), "P1D")
    Unit <- IsoTest.show_dr(
      "show_1d1s",
      Dur.Duration.add(Dur.Duration.from_days(1), Dur.Duration.from_secs(1)),
      "P1DT1S"
    )
    Unit <- IsoTest.show_dr("show_1h", Dur.Duration.from_hms(1, 0, 0), "PT1H")
    Unit <- IsoTest.show_d("show_ns", Dur.Duration{0, 0, 1}, "PT0.000000001S")
    Unit <- IsoTest.show_d("show_ms", Dur.Duration{0, 0, 1000000}, "PT0.001S")
    Unit <- IsoTest.show_p("show_13m", Per.Period.from(0, 13, 0), "P1Y1M")
    Unit <- IsoTest.show_p("show_p0", Per.Period.from(0, 0, 0), "P0D")
    Unit <- IsoTest.show_p("show_1y", Per.Period.from(1, 0, 0), "P1Y")
    Unit <- IsoTest.dur_from(
      "read_90m", Iso.Iso8601.read_duration("PT90M"), Dur.Duration.from_mins(90)
    )
    Unit <- IsoTest.dur_eq(
      "read_0h", Iso.Iso8601.read_duration("PT0H"), Dur.Duration.zero()
    )
    Unit <- IsoTest.sod("read_1d0h", Iso.Iso8601.read_duration("P1DT0H"), 1, 0, 0)
    Unit <- IsoTest.sod("read_1d24h", Iso.Iso8601.read_duration("P1DT24H"), 2, 0, 0)
    Unit <- IsoTest.sod("read_1s0", Iso.Iso8601.read_duration("PT1.0S"), 0, 1, 0)
    Unit <- IsoTest.dur_fail("dur_y", Iso.Iso8601.read_duration("P1Y"))
    Unit <- IsoTest.dur_fail("dur_m", Iso.Iso8601.read_duration("P1M"))
    Unit <- IsoTest.dur_fail("dur_w", Iso.Iso8601.read_duration("P1W"))
    Unit <- IsoTest.dur_fail("dur_mix", Iso.Iso8601.read_duration("P1Y2M3DT4H"))
    Unit <- IsoTest.per_fail("per_mix", Iso.Iso8601.read_period("P1Y2M3DT4H"))
    Unit <- IsoTest.dur_fail("low", Iso.Iso8601.read_duration("pt1h"))
    Unit <- IsoTest.dur_fail("p_only", Iso.Iso8601.read_duration("P"))
    Unit <- IsoTest.dur_fail("pt_only", Iso.Iso8601.read_duration("PT"))
    Unit <- IsoTest.dur_fail("empty", Iso.Iso8601.read_duration(""))
    Unit <- IsoTest.dur_fail("neg", Iso.Iso8601.read_duration("P-1D"))
    Unit <- IsoTest.dur_extra("space", Iso.Iso8601.read_duration("PT1H "))
    Unit <- IsoTest.dur_fail("p1dt", Iso.Iso8601.read_duration("P1DT"))
    Unit <- IsoTest.dur_fail("pd", Iso.Iso8601.read_duration("PD"))
    Unit <- IsoTest.dur_fail("d2", Iso.Iso8601.read_duration("P1D1D"))
    Unit <- IsoTest.dur_fail("s_h", Iso.Iso8601.read_duration("PT1S1H"))
    Unit <- IsoTest.dur_fail("frac_d", Iso.Iso8601.read_duration("P1.5D"))
    Unit <- IsoTest.dur_fail("frac_h", Iso.Iso8601.read_duration("PT1.5H"))
    Unit <- IsoTest.dur_fail("frac10", Iso.Iso8601.read_duration("PT1.0000000000S"))
    Unit <- IsoTest.ymd("p1y000", Iso.Iso8601.read_period("P1Y0M0D"), 1, 0, 0)
    Unit <- IsoTest.ymd("p1w", Iso.Iso8601.read_period("P1W"), 0, 0, 7)
    Unit <- IsoTest.ymd("p1w3d", Iso.Iso8601.read_period("P1W3D"), 0, 0, 10)
    Unit <- IsoTest.per_from(
      "p13m", Iso.Iso8601.read_period("P13M"), Per.Period.from(1, 1, 0)
    )
    Unit <- IsoTest.ymd("p0d", Iso.Iso8601.read_period("P0D"), 0, 0, 0)
    Unit <- IsoTest.round_d("rt_zero", Dur.Duration.zero())
    Unit <- IsoTest.round_d("rt_90m", Dur.Duration.from_secs(5400))
    Unit <- IsoTest.round_d("rt_1d", Dur.Duration.from_days(1))
    Unit <- IsoTest.round_d("rt_ns", Dur.Duration{0, 0, 1})
    Unit <- IsoTest.round_d("rt_ms", Dur.Duration{0, 0, 1000000})
    Unit <- IsoTest.round_dr(
      "rt_1d1s",
      Dur.Duration.add(Dur.Duration.from_days(1), Dur.Duration.from_secs(1))
    )
    IO.print("ok")
