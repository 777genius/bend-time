import Base
import ../duration.bend as Dur

def DurTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def DurTest.eq(
  name: String, r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>, want: Dur.Duration
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{d}:
      DurTest.ok(name, Dur.Duration.is_eq(d, want))

def DurTest.fail(
  name: String, r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def DurTest.secs(
  name: String, r: Result<&2, &2, Dur.Duration.Error, U32>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{n}:
      DurTest.ok(name, U32.is_eq(n, want))

def DurTest.sod(name: String, d: Dur.Duration, +days: U32, +sod: U32) -> IO(Unit):
  match d:
    case Dur.Duration{dd, ss, _}:
      DurTest.ok(
        name, Bool.and(U32.is_eq(dd, days), U32.is_eq(ss, sod))
      )

def DurTest.hms(
  name: String, r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>, +days: U32, +sod: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{d}:
      DurTest.sod(name, d, days, sod)

def DurTest.units(
  name: String, r: Result<&2, &2, Dur.Duration.Error, Dur.Duration.Hms>, +h: U32, +mi: U32, +s: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{Dur.Hms{hh, mm, ss}}:
      DurTest.ok(
        name,
        Bool.and(
          U32.is_eq(hh, h), Bool.and(U32.is_eq(mm, mi), U32.is_eq(ss, s))
        )
      )

def DurTest.units_fail(
  name: String, r: Result<&2, &2, Dur.Duration.Error, Dur.Duration.Hms>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def DurTest.units_from(
  name: String,
  r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>,
  +h: U32, +mi: U32, +s: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{d}:
      DurTest.units(name, Dur.Duration.to_hms(d), h, mi, s)

def DurTest.both(
  name: String,
  r1: Result<&2, &2, Dur.Duration.Error, Dur.Duration>,
  r2: Result<&2, &2, Dur.Duration.Error, Dur.Duration>
) -> IO(Unit):
  match r1 r2:
    case Fail{_} _:
      IO.die(Unit, 1, name)
    case Done{_} Fail{_}:
      IO.die(Unit, 1, name)
    case Done{a} Done{b}:
      DurTest.ok(name, Dur.Duration.is_eq(a, b))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- DurTest.ok(
      "zero", Dur.Duration.is_eq(Dur.Duration.from_secs(0), Dur.Duration.zero())
    )
    Unit <- DurTest.secs(
      "max", Dur.Duration.to_secs(Dur.Duration.from_secs(4294967295)), 4294967295
    )
    Unit <- DurTest.sod("m90", Dur.Duration.from_secs(5400), 0, 5400)
    Unit <- DurTest.hms("h24", Dur.Duration.from_hms(24, 0, 0), 1, 0)
    Unit <- DurTest.hms("h90", Dur.Duration.from_hms(90, 0, 0), 3, 64800)
    Unit <- DurTest.fail("mi60", Dur.Duration.from_hms(0, 60, 0))
    Unit <- DurTest.eq(
      "add1",
      Dur.Duration.add(Dur.Duration.from_secs(1), Dur.Duration.from_secs(1)),
      Dur.Duration.from_secs(2)
    )
    Unit <- DurTest.fail(
      "sub21", Dur.Duration.sub(Dur.Duration.from_secs(1), Dur.Duration.from_secs(2))
    )
    Unit <- DurTest.sod("fd0", Dur.Duration.from_days(0), 0, 0)
    Unit <- DurTest.sod("fh0", Dur.Duration.zero(), 0, 0)
    Unit <- DurTest.hms("fm0", Dur.Duration.from_mins(0), 0, 0)
    Unit <- DurTest.hms("fh0r", Dur.Duration.from_hours(0), 0, 0)
    Unit <- DurTest.hms("fm90", Dur.Duration.from_mins(90), 0, 5400)
    Unit <- DurTest.both(
      "fm60", Dur.Duration.from_mins(60), Dur.Duration.from_hours(1)
    )
    Unit <- DurTest.hms("fh24", Dur.Duration.from_hours(24), 1, 0)
    Unit <- DurTest.hms("fh90", Dur.Duration.from_hours(90), 3, 64800)
    Unit <- DurTest.fail("fh_ov", Dur.Duration.from_hours(1193047))
    Unit <- DurTest.fail("fm_ov", Dur.Duration.from_mins(71582789))
    Unit <- DurTest.units("th90", Dur.Duration.to_hms(Dur.Duration.from_secs(5400)), 1, 30, 0)
    Unit <- DurTest.units_from("th_h90", Dur.Duration.from_hours(90), 90, 0, 0)
    Unit <- DurTest.units("th_d1", Dur.Duration.to_hms(Dur.Duration.from_days(1)), 24, 0, 0)
    Unit <- DurTest.units(
      "th_cap", Dur.Duration.to_hms(Dur.Duration.from_days(178956970)), 4294967280, 0, 0
    )
    Unit <- DurTest.units_fail(
      "th_ov", Dur.Duration.to_hms(Dur.Duration.from_days(178956971))
    )
    Unit <- DurTest.units("th_ns", Dur.Duration.to_hms(Dur.Duration{0, 0, 1}), 0, 0, 0)
    IO.print("ok")
