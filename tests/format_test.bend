import Base
import ../date.bend as D
import ../datetime.bend as DT
import ../format.bend as F

def TimeTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def TimeTest.read_fail(
  name: String, r: Result<&2, &2, F.Format.Error, DT.OffsetDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def TimeTest.date_read_fail(
  name: String, r: Result<&2, &2, F.Format.Error, D.Date>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def TimeTest.show_done(
  name: String, r: Result<&2, &2, F.Format.Error, DT.OffsetDateTime>, want: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{odt}:
      TimeTest.ok(name, String.eq(F.Format.show(odt), want))

def TimeTest.date_show(
  name: String, r: Result<&2, &2, F.Format.Error, D.Date>, want: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{d}:
      TimeTest.ok(name, String.eq(F.Format.show_date(d), want))

def TimeTest.unix_n(
  name: String, want: U32, r: Result<&2, &2, D.Date.Error, U32>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{n}:
      TimeTest.ok(name, U32.is_eq(n, want))

def TimeTest.unix_z(
  name: String,
  r: Result<&2, &2, F.Format.Error, DT.OffsetDateTime>,
  want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{odt}:
      TimeTest.unix_n(name, want, DT.OffsetDateTime.to_unix(odt))

def TimeTest.same2(
  +name: String, a: DT.OffsetDateTime,
  r: Result<&2, &2, F.Format.Error, DT.OffsetDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{b}:
      TimeTest.ok(name, DT.OffsetDateTime.same_instant(a, b))

def TimeTest.same(
  +name: String,
  r1: Result<&2, &2, F.Format.Error, DT.OffsetDateTime>,
  r2: Result<&2, &2, F.Format.Error, DT.OffsetDateTime>
) -> IO(Unit):
  match r1:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{a}:
      TimeTest.same2(name, a, r2)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- TimeTest.date_show(
      "read_date", F.Format.read_date("2026-09-18"), "2026-09-18"
    )
    Unit <- TimeTest.show_done(
      "show_z",
      F.Format.read("2026-09-18T12:30:00Z"),
      "2026-09-18T12:30:00Z"
    )
    Unit <- TimeTest.show_done(
      "show_plus0",
      F.Format.read("2026-09-18T12:30:00+00:00"),
      "2026-09-18T12:30:00Z"
    )
    Unit <- TimeTest.show_done(
      "show_east",
      F.Format.read("2026-09-18T15:30:00+03:00"),
      "2026-09-18T15:30:00+03:00"
    )
    Unit <- TimeTest.same(
      "same_instant",
      F.Format.read("2026-09-18T15:30:00+03:00"),
      F.Format.read("2026-09-18T12:30:00Z")
    )
    Unit <- TimeTest.read_fail(
      "neg_zero", F.Format.read("2026-09-18T12:30:00-00:00")
    )
    Unit <- TimeTest.read_fail(
      "space_T", F.Format.read("2026-09-18 12:30:00Z")
    )
    Unit <- TimeTest.read_fail(
      "no_off", F.Format.read("2026-09-18T12:30:00")
    )
    Unit <- TimeTest.read_fail(
      "sec60", F.Format.read("2026-09-18T12:30:60Z")
    )
    Unit <- TimeTest.read_fail(
      "frac10", F.Format.read("2026-09-18T12:30:00.1234567890Z")
    )
    Unit <- TimeTest.date_read_fail("bad_date", F.Format.read_date("2026-02-30"))
    Unit <- TimeTest.unix_z("unix_z", F.Format.read("2026-09-18T12:30:00Z"), 1789734600)
    Unit <- TimeTest.unix_z(
      "unix_off", F.Format.read("2026-09-18T15:30:00+03:00"), 1789734600
    )
    IO.print("ok")
