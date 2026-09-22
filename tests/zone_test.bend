import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/duration.bend as Dur
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ../zone.bend as Z
import ../posix_tz.bend as Px

def ZoneTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def ZoneTest.at_off(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, DT.UtcOffset>,
  want: DT.UtcOffset
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{got}:
      ZoneTest.ok(name, Z.Zone.off_eq(got, want))

def ZoneTest.id_eq(name: String, z: Z.Zone, want: String) -> IO(Unit):
  ZoneTest.ok(name, String.eq(Z.Zone.id(z), want))

def ZoneTest.unix_n(
  name: String, r: Result<&2, &2, D.Date.Error, U32>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{n}:
      ZoneTest.ok(name, U32.is_eq(n, want))

def ZoneTest.unix_at(
  name: String,
  r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>,
  local: DT.LocalDateTime
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      ZoneTest.unix_n(
        name,
        DT.OffsetDateTime.to_unix(DT.LocalDateTime.at_offset(local, off)),
        1789734600
      )

def ZoneTest.time(
  name: String, r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{t}:
      ZoneTest.unix_at(
        name,
        DT.UtcOffset.from(False{}, 3, 0),
        DT.LocalDateTime.from(D.Date{2026, 9, 18}, t)
      )

def ZoneTest.date(
  name: String, r: Result<&2, &2, D.Date.Error, D.Date>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      ZoneTest.time(name, DT.TimeOfDay.from(15, 30, 0, DT.FracNone{}))

def ZoneTest.from_fail(
  name: String, r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def ZoneTest.east1(
  name: String, r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      ZoneTest.from_fail(
        name, DT.OffsetDateTime.from_instant(I.Instant{0, 0, 0}, off)
      )

def ZoneTest.off_ok(
  name: String,
  r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>,
  zid: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      ZoneTest.id_eq(name, Z.Zone.fixed(off), zid)

def ZoneTest.inv(
  name: String, r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{Z.Invalid{}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZoneTest.utc_i(
  r: Result<&2, &2, D.Date.Error, D.Date>, +sod: U32, +nanos: U32
) -> Result<&2, &2, I.Instant.Error, I.Instant>:
  match r:
    case Fail{_}:
      Fail{I.OutOfRange{}}
    case Done{d}:
      I.Instant.add(I.Instant.from_utc_date(d), Dur.Duration{0, sod, nanos})

def ZoneTest.at_utc.i(
  name: String, z: Z.Zone, want: DT.UtcOffset,
  r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      ZoneTest.at_off(name, Z.Zone.at(z, i), want)

def ZoneTest.at_utc(
  name: String, +z: Z.Zone,
  y: U32, mo: U32, d: U32, sod: U32, nanos: U32, want: DT.UtcOffset
) -> IO(Unit):
  ZoneTest.at_utc.i(
    name, z, want, ZoneTest.utc_i(D.Date.from(y, mo, d), sod, nanos)
  )

def ZoneTest.ny_types() -> List<&2, Z.Zone.LocalType>:
  Con{
    Z.LocalType{DT.OffsetWest{5, 0}},
    Con{Z.LocalType{DT.OffsetWest{4, 0}}, Nil{}}
  }

def ZoneTest.ny_z.go(
  r1: Result<&2, &2, I.Instant.Error, I.Instant>,
  r2: Result<&2, &2, I.Instant.Error, I.Instant>
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r1:
    case Fail{_}:
      Fail{Z.OutOfRange{}}
    case Done{i1}:
      match r2:
        case Fail{_}:
          Fail{Z.OutOfRange{}}
        case Done{i2}:
          Z.Zone.from_rules(
            "America/New_York",
            ZoneTest.ny_types(),
            Con{Z.Trans{i1, 1}, Con{Z.Trans{i2, 0}, Nil{}}},
            None{}
          )

def ZoneTest.ny_z() -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  ZoneTest.ny_z.go(
    ZoneTest.utc_i(D.Date.from(2026, 3, 8), 25200, 0),
    ZoneTest.utc_i(D.Date.from(2026, 11, 1), 21600, 0)
  )

def ZoneTest.px_ny.go(
  r: Result<&2, &2, Px.Posix.Error, Px.Posix.Tz>
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{_}:
      Fail{Z.Invalid{}}
    case Done{tz}:
      Z.Zone.from_rules(
        "America/New_York", ZoneTest.ny_types(), Nil{}, Some{tz}
      )

def ZoneTest.px_ny() -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  ZoneTest.px_ny.go(Px.Posix.parse("EST5EDT,M3.2.0,M11.1.0"))

def ZoneTest.ny_suite(+z: Z.Zone) -> IO(Unit):
  do IO<Unit>:
    Unit <- ZoneTest.id_eq("ny_id", z, "America/New_York")
    Unit <- ZoneTest.at_utc(
      "ny_pre_s", z, 2026, 3, 8, 25199, 0, DT.OffsetWest{5, 0}
    )
    Unit <- ZoneTest.at_utc(
      "ny_pre_ns", z, 2026, 3, 8, 25199, 999999999, DT.OffsetWest{5, 0}
    )
    Unit <- ZoneTest.at_utc(
      "ny_spring", z, 2026, 3, 8, 25200, 0, DT.OffsetWest{4, 0}
    )
    Unit <- ZoneTest.at_utc(
      "ny_spring_ns", z, 2026, 3, 8, 25200, 1, DT.OffsetWest{4, 0}
    )
    Unit <- ZoneTest.at_utc(
      "ny_pre_f", z, 2026, 11, 1, 21599, 0, DT.OffsetWest{4, 0}
    )
    Unit <- ZoneTest.at_utc(
      "ny_fall", z, 2026, 11, 1, 21600, 0, DT.OffsetWest{5, 0}
    )
    Unit <- ZoneTest.at_utc(
      "ny_jan", z, 2026, 1, 15, 43200, 0, DT.OffsetWest{5, 0}
    )
    Unit <- ZoneTest.at_utc(
      "ny_jul", z, 2026, 7, 15, 43200, 0, DT.OffsetWest{4, 0}
    )
    Unit <- ZoneTest.at_utc(
      "ny_dec", z, 2026, 12, 15, 43200, 0, DT.OffsetWest{5, 0}
    )
    IO.pure(Unit, Unit{})

def ZoneTest.ldt.go(
  date: D.Date, r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>
) -> Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>:
  match r:
    case Fail{_}:
      Fail{Z.Invalid{}}
    case Done{t}:
      Done{DT.LocalDateTime.from(date, t)}

def ZoneTest.ldt.date(
  r: Result<&2, &2, D.Date.Error, D.Date>,
  +h: U32, +mi: U32, +s: U32, frac: DT.TimeFrac
) -> Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>:
  match r:
    case Fail{_}:
      Fail{Z.OutOfRange{}}
    case Done{d}:
      ZoneTest.ldt.go(d, DT.TimeOfDay.from(h, mi, s, frac))

def ZoneTest.ldt(
  +y: U32, +mo: U32, +d: U32, +h: U32, +mi: U32, +s: U32, frac: DT.TimeFrac
) -> Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>:
  ZoneTest.ldt.date(D.Date.from(y, mo, d), h, mi, s, frac)

def ZoneTest.res_i(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, I.Instant>,
  want: I.Instant
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      ZoneTest.ok(name, I.Instant.is_eq(i, want))

def ZoneTest.res_gap(
  name: String, r: Result<&2, &2, Z.Zone.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{Z.Gap{_}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZoneTest.res_fold(
  name: String, r: Result<&2, &2, Z.Zone.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{Z.Fold{_}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZoneTest.res3.ok(
  +name: String, +z: Z.Zone, +ldt: DT.LocalDateTime, +want: I.Instant
) -> IO(Unit):
  do IO<Unit>:
    Unit <- ZoneTest.res_i(
      String.append(name, "_r"), Z.Zone.resolve(z, ldt), want
    )
    Unit <- ZoneTest.res_i(
      String.append(name, "_e"), Z.Zone.resolve_earlier(z, ldt), want
    )
    Unit <- ZoneTest.res_i(
      String.append(name, "_l"), Z.Zone.resolve_later(z, ldt), want
    )
    IO.pure(Unit, Unit{})

def ZoneTest.res3(
  name: String, +z: Z.Zone,
  ldt_r: Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>,
  want_r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match ldt_r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{ldt}:
      match want_r:
        case Fail{_}:
          IO.die(Unit, 1, name)
        case Done{w}:
          ZoneTest.res3.ok(name, z, ldt, w)

def ZoneTest.gap3.ok(
  +name: String, +z: Z.Zone, +ldt: DT.LocalDateTime
) -> IO(Unit):
  do IO<Unit>:
    Unit <- ZoneTest.res_gap(String.append(name, "_r"), Z.Zone.resolve(z, ldt))
    Unit <- ZoneTest.res_gap(
      String.append(name, "_e"), Z.Zone.resolve_earlier(z, ldt)
    )
    Unit <- ZoneTest.res_gap(
      String.append(name, "_l"), Z.Zone.resolve_later(z, ldt)
    )
    IO.pure(Unit, Unit{})

def ZoneTest.gap3(
  name: String, +z: Z.Zone,
  ldt_r: Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>
) -> IO(Unit):
  match ldt_r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{ldt}:
      ZoneTest.gap3.ok(name, z, ldt)

def ZoneTest.fold3.ok(
  +name: String, +z: Z.Zone, +ldt: DT.LocalDateTime,
  +earlier: I.Instant, +later: I.Instant
) -> IO(Unit):
  do IO<Unit>:
    Unit <- ZoneTest.res_fold(String.append(name, "_r"), Z.Zone.resolve(z, ldt))
    Unit <- ZoneTest.res_i(
      String.append(name, "_e"), Z.Zone.resolve_earlier(z, ldt), earlier
    )
    Unit <- ZoneTest.res_i(
      String.append(name, "_l"), Z.Zone.resolve_later(z, ldt), later
    )
    IO.pure(Unit, Unit{})

def ZoneTest.fold3(
  name: String, +z: Z.Zone,
  ldt_r: Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>,
  e_r: Result<&2, &2, I.Instant.Error, I.Instant>,
  l_r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match ldt_r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{ldt}:
      match e_r:
        case Fail{_}:
          IO.die(Unit, 1, name)
        case Done{e}:
          match l_r:
            case Fail{_}:
              IO.die(Unit, 1, name)
            case Done{l}:
              ZoneTest.fold3.ok(name, z, ldt, e, l)

def ZoneTest.res_suite(+z: Z.Zone) -> IO(Unit):
  do IO<Unit>:
    Unit <- ZoneTest.res3(
      "r0130", z,
      ZoneTest.ldt(2026, 3, 8, 1, 30, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 3, 8), 23400, 0)
    )
    Unit <- ZoneTest.res3(
      "r0159", z,
      ZoneTest.ldt(2026, 3, 8, 1, 59, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 3, 8), 25140, 0)
    )
    Unit <- ZoneTest.gap3(
      "g0200", z, ZoneTest.ldt(2026, 3, 8, 2, 0, 0, DT.FracNone{})
    )
    Unit <- ZoneTest.gap3(
      "g0230", z, ZoneTest.ldt(2026, 3, 8, 2, 30, 0, DT.FracNone{})
    )
    Unit <- ZoneTest.gap3(
      "g0230ns", z, ZoneTest.ldt(2026, 3, 8, 2, 30, 0, DT.Frac{9n, 1})
    )
    Unit <- ZoneTest.res3(
      "r0300", z,
      ZoneTest.ldt(2026, 3, 8, 3, 0, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 3, 8), 25200, 0)
    )
    Unit <- ZoneTest.res3(
      "r0330", z,
      ZoneTest.ldt(2026, 3, 8, 3, 30, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 3, 8), 27000, 0)
    )
    Unit <- ZoneTest.res3(
      "r0059", z,
      ZoneTest.ldt(2026, 11, 1, 0, 59, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 17940, 0)
    )
    Unit <- ZoneTest.fold3(
      "f0100", z,
      ZoneTest.ldt(2026, 11, 1, 1, 0, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 18000, 0),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 21600, 0)
    )
    Unit <- ZoneTest.fold3(
      "f0130", z,
      ZoneTest.ldt(2026, 11, 1, 1, 30, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 19800, 0),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 23400, 0)
    )
    Unit <- ZoneTest.fold3(
      "f0130ns", z,
      ZoneTest.ldt(2026, 11, 1, 1, 30, 0, DT.Frac{9n, 1}),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 19800, 1),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 23400, 1)
    )
    Unit <- ZoneTest.fold3(
      "f0159", z,
      ZoneTest.ldt(2026, 11, 1, 1, 59, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 21540, 0),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 25140, 0)
    )
    Unit <- ZoneTest.res3(
      "r0200", z,
      ZoneTest.ldt(2026, 11, 1, 2, 0, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 25200, 0)
    )
    Unit <- ZoneTest.res3(
      "r0230", z,
      ZoneTest.ldt(2026, 11, 1, 2, 30, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 27000, 0)
    )
    Unit <- ZoneTest.res3(
      "rjul", z,
      ZoneTest.ldt(2026, 7, 1, 12, 0, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 7, 1), 57600, 0)
    )
    Unit <- ZoneTest.res3(
      "r918", z,
      ZoneTest.ldt(2026, 9, 18, 8, 30, 0, DT.FracNone{}),
      ZoneTest.utc_i(D.Date.from(2026, 9, 18), 45000, 0)
    )
    IO.pure(Unit, Unit{})

def ZoneTest.ny_all(+z: Z.Zone) -> IO(Unit):
  do IO<Unit>:
    Unit <- ZoneTest.ny_suite(z)
    Unit <- ZoneTest.res_suite(z)
    IO.pure(Unit, Unit{})

def ZoneTest.ny_run(
  r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, "ny_from")
    case Done{z}:
      ZoneTest.ny_all(z)

def ZoneTest.dup5.go(
  name: String, r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{z}:
      ZoneTest.res3(
        name, z,
        ZoneTest.ldt(2026, 7, 1, 12, 0, 0, DT.FracNone{}),
        ZoneTest.utc_i(D.Date.from(2026, 7, 1), 61200, 0)
      )

def ZoneTest.bad_ord.go(
  name: String,
  r1: Result<&2, &2, I.Instant.Error, I.Instant>,
  r2: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match r1:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i1}:
      match r2:
        case Fail{_}:
          IO.die(Unit, 1, name)
        case Done{i2}:
          ZoneTest.inv(
            name,
            Z.Zone.from_rules(
              "America/New_York",
              ZoneTest.ny_types(),
              Con{Z.Trans{i2, 0}, Con{Z.Trans{i1, 1}, Nil{}}},
              None{}
            )
          )

def ZoneTest.bad_eq.go(
  name: String, r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{+i}:
      ZoneTest.inv(
        name,
        Z.Zone.from_rules(
          "America/New_York",
          ZoneTest.ny_types(),
          Con{Z.Trans{i, 1}, Con{Z.Trans{i, 1}, Nil{}}},
          None{}
        )
      )

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- ZoneTest.at_off(
      "at_east3",
      Z.Zone.at(
        Z.Zone.fixed(DT.OffsetEast{3, 0}), I.Instant.from_unix(0)
      ),
      DT.OffsetEast{3, 0}
    )
    Unit <- ZoneTest.at_off(
      "at_z",
      Z.Zone.at(Z.Zone.fixed(DT.OffsetZero{}), I.Instant.from_unix(1)),
      DT.OffsetZero{}
    )
    Unit <- ZoneTest.ok(
      "eq_zz", Z.Zone.off_eq(DT.OffsetZero{}, DT.OffsetZero{})
    )
    Unit <- ZoneTest.ok(
      "eq_e3", Z.Zone.off_eq(DT.OffsetEast{3, 0}, DT.OffsetEast{3, 0})
    )
    Unit <- ZoneTest.ok(
      "neq_ew",
      Bool.not(Z.Zone.off_eq(DT.OffsetEast{3, 0}, DT.OffsetWest{3, 0}))
    )
    Unit <- ZoneTest.ok(
      "neq_mi",
      Bool.not(Z.Zone.off_eq(DT.OffsetEast{3, 0}, DT.OffsetEast{3, 30}))
    )
    Unit <- ZoneTest.date("unix_1530", D.Date.from(2026, 9, 18))
    Unit <- ZoneTest.id_eq("id_z", Z.Zone.fixed(DT.OffsetZero{}), "Z")
    Unit <- ZoneTest.off_ok(
      "id_e3", DT.UtcOffset.from(False{}, 3, 0), "Fixed/+03:00"
    )
    Unit <- ZoneTest.off_ok(
      "id_w5", DT.UtcOffset.from(True{}, 5, 0), "Fixed/-05:00"
    )
    Unit <- ZoneTest.off_ok(
      "id_e530", DT.UtcOffset.from(False{}, 5, 30), "Fixed/+05:30"
    )
    Unit <- ZoneTest.east1("y1_east1", DT.UtcOffset.from(False{}, 1, 0))
    Unit <- ZoneTest.inv(
      "empty_id",
      Z.Zone.from_rules(
        "",
        Con{Z.LocalType{DT.OffsetWest{5, 0}}, Nil{}},
        Nil{},
        None{}
      )
    )
    Unit <- ZoneTest.inv(
      "empty_types",
      Z.Zone.from_rules("America/New_York", Nil{}, Nil{}, None{})
    )
    Unit <- ZoneTest.bad_ord.go(
      "unsorted",
      ZoneTest.utc_i(D.Date.from(2026, 3, 8), 25200, 0),
      ZoneTest.utc_i(D.Date.from(2026, 11, 1), 21600, 0)
    )
    Unit <- ZoneTest.bad_eq.go(
      "dup_trans",
      ZoneTest.utc_i(D.Date.from(2026, 3, 8), 25200, 0)
    )
    Unit <- ZoneTest.ny_run(ZoneTest.ny_z())
    Unit <- ZoneTest.ny_run(ZoneTest.px_ny())
    Unit <- ZoneTest.dup5.go(
      "dup5",
      Z.Zone.from_rules(
        "dup5",
        Con{
          Z.LocalType{DT.OffsetWest{5, 0}},
          Con{Z.LocalType{DT.OffsetWest{5, 0}}, Nil{}}
        },
        Nil{},
        None{}
      )
    )
    IO.print("ok")
