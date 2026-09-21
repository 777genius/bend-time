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
    IO.print("ok")
