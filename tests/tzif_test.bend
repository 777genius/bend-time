import Base
import 0x888714bde93f46c139372bb9fdc57a19/bytes.bend as B
import 0x888714bde93f46c139372bb9fdc57a19/hex.bend as Hx
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/duration.bend as Dur
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ../tzif.bend as Tf
import ../zone.bend as Z
import ./tzif/ny.bend as Ny
import ./tzif/moscow.bend as Mc
import ./tzif/tokyo.bend as Tk

def TzifTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def TzifTest.inv(
  name: String, r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{Z.Invalid{}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def TzifTest.uns(
  name: String, r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{Z.Unsupported{}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def TzifTest.cat(
  xs: List<&2, U32>, ys: List<&2, U32>
) -> List<&2, U32>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      Con{h, TzifTest.cat(t, ys)}

def TzifTest.hexes.cat(
  xs: List<&2, U32>, r: Result<&2, &2, Hx.Hex.Error, B.Bytes>
) -> Result<&2, &2, Z.Zone.Error, List<&2, U32>>:
  match r:
    case Fail{_}:
      Fail{Z.Invalid{}}
    case Done{B.Bytes{data}}:
      Done{TzifTest.cat(xs, data)}

def TzifTest.hexes.go(
  chunks: List<&2, String>,
  acc: Result<&2, &2, Z.Zone.Error, List<&2, U32>>,
  +id: String
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match chunks:
    case Nil{}:
      match acc:
        case Fail{e}:
          Fail{e}
        case Done{xs}:
          Tf.Zone.from_tzif(id, B.Bytes{xs})
    case Con{h, t}:
      match acc:
        case Fail{e}:
          Fail{e}
        case Done{xs}:
          TzifTest.hexes.go(t, TzifTest.hexes.cat(xs, Hx.Hex.decode(h)), id)

def TzifTest.load_chunks(
  chunks: List<&2, String>, +id: String
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  TzifTest.hexes.go(chunks, Done{Nil{}}, id)

def TzifTest.load_ny(
  +id: String
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  TzifTest.load_chunks(Ny.Ny.chunks(), id)

def TzifTest.load.go(
  id: String, r: Result<&2, &2, Hx.Hex.Error, B.Bytes>
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{_}:
      Fail{Z.Invalid{}}
    case Done{b}:
      Tf.Zone.from_tzif(id, b)

def TzifTest.load(
  id: String, hex: String
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  TzifTest.load.go(id, Hx.Hex.decode(hex))

def TzifTest.id_ok(
  name: String, r: Result<&2, &2, Z.Zone.Error, Z.Zone>, want: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{z}:
      TzifTest.ok(name, String.eq(Z.Zone.id(z), want))

def TzifTest.at_off(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, DT.UtcOffset>,
  want: DT.UtcOffset
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{got}:
      TzifTest.ok(name, Z.Zone.off_eq(got, want))

def TzifTest.utc_i(
  r: Result<&2, &2, D.Date.Error, D.Date>, +sod: U32, +nanos: U32
) -> Result<&2, &2, I.Instant.Error, I.Instant>:
  match r:
    case Fail{_}:
      Fail{I.OutOfRange{}}
    case Done{d}:
      I.Instant.add(I.Instant.from_utc_date(d), Dur.Duration{0, sod, nanos})

def TzifTest.at_utc.i(
  name: String, z: Z.Zone, want: DT.UtcOffset,
  r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      TzifTest.at_off(name, Z.Zone.at(z, i), want)

def TzifTest.at_utc(
  name: String, +z: Z.Zone,
  y: U32, mo: U32, d: U32, sod: U32, nanos: U32, want: DT.UtcOffset
) -> IO(Unit):
  TzifTest.at_utc.i(
    name, z, want, TzifTest.utc_i(D.Date.from(y, mo, d), sod, nanos)
  )

def TzifTest.ldt.go(
  date: D.Date, r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>
) -> Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>:
  match r:
    case Fail{_}:
      Fail{Z.Invalid{}}
    case Done{t}:
      Done{DT.LocalDateTime.from(date, t)}

def TzifTest.ldt.date(
  r: Result<&2, &2, D.Date.Error, D.Date>,
  +h: U32, +mi: U32, +s: U32, frac: DT.TimeFrac
) -> Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>:
  match r:
    case Fail{_}:
      Fail{Z.OutOfRange{}}
    case Done{d}:
      TzifTest.ldt.go(d, DT.TimeOfDay.from(h, mi, s, frac))

def TzifTest.ldt(
  +y: U32, +mo: U32, +d: U32, +h: U32, +mi: U32, +s: U32, frac: DT.TimeFrac
) -> Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>:
  TzifTest.ldt.date(D.Date.from(y, mo, d), h, mi, s, frac)

def TzifTest.res_gap(
  name: String, r: Result<&2, &2, Z.Zone.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{Z.Gap{_}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def TzifTest.res_fold(
  name: String, r: Result<&2, &2, Z.Zone.Error, I.Instant>
) -> IO(Unit):
  match r:
    case Fail{Z.Fold{_}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def TzifTest.res_i(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, I.Instant>,
  want: I.Instant
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      TzifTest.ok(name, I.Instant.is_eq(i, want))

def TzifTest.res3.ok(
  +name: String, +z: Z.Zone, +ldt: DT.LocalDateTime, +want: I.Instant
) -> IO(Unit):
  do IO<Unit>:
    Unit <- TzifTest.res_i(
      String.append(name, "_r"), Z.Zone.resolve(z, ldt), want
    )
    Unit <- TzifTest.res_i(
      String.append(name, "_e"), Z.Zone.resolve_earlier(z, ldt), want
    )
    Unit <- TzifTest.res_i(
      String.append(name, "_l"), Z.Zone.resolve_later(z, ldt), want
    )
    IO.pure(Unit, Unit{})

def TzifTest.res3(
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
          TzifTest.res3.ok(name, z, ldt, w)

def TzifTest.gap3.ok(
  +name: String, +z: Z.Zone, +ldt: DT.LocalDateTime
) -> IO(Unit):
  do IO<Unit>:
    Unit <- TzifTest.res_gap(String.append(name, "_r"), Z.Zone.resolve(z, ldt))
    Unit <- TzifTest.res_gap(
      String.append(name, "_e"), Z.Zone.resolve_earlier(z, ldt)
    )
    Unit <- TzifTest.res_gap(
      String.append(name, "_l"), Z.Zone.resolve_later(z, ldt)
    )
    IO.pure(Unit, Unit{})

def TzifTest.gap3(
  name: String, +z: Z.Zone,
  ldt_r: Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>
) -> IO(Unit):
  match ldt_r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{ldt}:
      TzifTest.gap3.ok(name, z, ldt)

def TzifTest.fold3.ok(
  +name: String, +z: Z.Zone, +ldt: DT.LocalDateTime,
  +earlier: I.Instant, +later: I.Instant
) -> IO(Unit):
  do IO<Unit>:
    Unit <- TzifTest.res_fold(String.append(name, "_r"), Z.Zone.resolve(z, ldt))
    Unit <- TzifTest.res_i(
      String.append(name, "_e"), Z.Zone.resolve_earlier(z, ldt), earlier
    )
    Unit <- TzifTest.res_i(
      String.append(name, "_l"), Z.Zone.resolve_later(z, ldt), later
    )
    IO.pure(Unit, Unit{})

def TzifTest.fold3(
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
              TzifTest.fold3.ok(name, z, ldt, e, l)

def TzifTest.ny_at(+z: Z.Zone) -> IO(Unit):
  do IO<Unit>:
    Unit <- TzifTest.at_utc(
      "ny_pre_s", z, 2026, 3, 8, 25199, 0, DT.OffsetWest{5, 0}
    )
    Unit <- TzifTest.at_utc(
      "ny_pre_ns", z, 2026, 3, 8, 25199, 999999999, DT.OffsetWest{5, 0}
    )
    Unit <- TzifTest.at_utc(
      "ny_spring", z, 2026, 3, 8, 25200, 0, DT.OffsetWest{4, 0}
    )
    Unit <- TzifTest.at_utc(
      "ny_spring_ns", z, 2026, 3, 8, 25200, 1, DT.OffsetWest{4, 0}
    )
    Unit <- TzifTest.at_utc(
      "ny_pre_f", z, 2026, 11, 1, 21599, 0, DT.OffsetWest{4, 0}
    )
    Unit <- TzifTest.at_utc(
      "ny_fall", z, 2026, 11, 1, 21600, 0, DT.OffsetWest{5, 0}
    )
    Unit <- TzifTest.at_utc(
      "ny_jan", z, 2026, 1, 15, 43200, 0, DT.OffsetWest{5, 0}
    )
    Unit <- TzifTest.at_utc(
      "ny_jul", z, 2026, 7, 15, 43200, 0, DT.OffsetWest{4, 0}
    )
    Unit <- TzifTest.at_utc(
      "ny_dec", z, 2026, 12, 15, 43200, 0, DT.OffsetWest{5, 0}
    )
    Unit <- TzifTest.res3(
      "r0130", z,
      TzifTest.ldt(2026, 3, 8, 1, 30, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 3, 8), 23400, 0)
    )
    Unit <- TzifTest.res3(
      "r0159", z,
      TzifTest.ldt(2026, 3, 8, 1, 59, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 3, 8), 25140, 0)
    )
    Unit <- TzifTest.gap3(
      "g0200", z, TzifTest.ldt(2026, 3, 8, 2, 0, 0, DT.FracNone{})
    )
    Unit <- TzifTest.gap3(
      "g0230", z, TzifTest.ldt(2026, 3, 8, 2, 30, 0, DT.FracNone{})
    )
    Unit <- TzifTest.gap3(
      "g0230ns", z, TzifTest.ldt(2026, 3, 8, 2, 30, 0, DT.Frac{9n, 1})
    )
    Unit <- TzifTest.res3(
      "r0300", z,
      TzifTest.ldt(2026, 3, 8, 3, 0, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 3, 8), 25200, 0)
    )
    Unit <- TzifTest.res3(
      "r0330", z,
      TzifTest.ldt(2026, 3, 8, 3, 30, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 3, 8), 27000, 0)
    )
    Unit <- TzifTest.res3(
      "r0059", z,
      TzifTest.ldt(2026, 11, 1, 0, 59, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 17940, 0)
    )
    Unit <- TzifTest.fold3(
      "f0100", z,
      TzifTest.ldt(2026, 11, 1, 1, 0, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 18000, 0),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 21600, 0)
    )
    Unit <- TzifTest.fold3(
      "f0130", z,
      TzifTest.ldt(2026, 11, 1, 1, 30, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 19800, 0),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 23400, 0)
    )
    Unit <- TzifTest.fold3(
      "f0130ns", z,
      TzifTest.ldt(2026, 11, 1, 1, 30, 0, DT.Frac{9n, 1}),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 19800, 1),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 23400, 1)
    )
    Unit <- TzifTest.fold3(
      "f0159", z,
      TzifTest.ldt(2026, 11, 1, 1, 59, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 21540, 0),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 25140, 0)
    )
    Unit <- TzifTest.res3(
      "r0200", z,
      TzifTest.ldt(2026, 11, 1, 2, 0, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 25200, 0)
    )
    Unit <- TzifTest.res3(
      "r0230", z,
      TzifTest.ldt(2026, 11, 1, 2, 30, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 11, 1), 27000, 0)
    )
    Unit <- TzifTest.res3(
      "rjul", z,
      TzifTest.ldt(2026, 7, 1, 12, 0, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 7, 1), 57600, 0)
    )
    Unit <- TzifTest.res3(
      "r918", z,
      TzifTest.ldt(2026, 9, 18, 8, 30, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 9, 18), 45000, 0)
    )
    IO.pure(Unit, Unit{})

def TzifTest.unix_n(
  name: String, r: Result<&2, &2, I.Instant.Error, U32>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{n}:
      TzifTest.ok(name, U32.is_eq(n, want))

def TzifTest.unix_i(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, I.Instant>,
  want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      TzifTest.unix_n(name, I.Instant.to_unix(i), want)

def TzifTest.city.unix(
  name: String, +z: Z.Zone,
  ldt_r: Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>
) -> IO(Unit):
  match ldt_r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{ldt}:
      TzifTest.unix_i(name, Z.Zone.resolve(z, ldt), 1789734600)

def TzifTest.city(
  +name: String, +z: Z.Zone, want_id: String, +lh: U32, +eh: U32
) -> IO(Unit):
  do IO<Unit>:
    Unit <- TzifTest.ok(
      String.append(name, "_id"), String.eq(Z.Zone.id(z), want_id)
    )
    Unit <- TzifTest.at_utc(
      String.append(name, "_at"), z, 2026, 9, 18, 45000, 0, DT.OffsetEast{eh, 0}
    )
    Unit <- TzifTest.res3(
      String.append(name, "_loc"), z,
      TzifTest.ldt(2026, 9, 18, lh, 30, 0, DT.FracNone{}),
      TzifTest.utc_i(D.Date.from(2026, 9, 18), 45000, 0)
    )
    Unit <- TzifTest.city.unix(
      String.append(name, "_unix"), z,
      TzifTest.ldt(2026, 9, 18, lh, 30, 0, DT.FracNone{})
    )
    IO.pure(Unit, Unit{})

def TzifTest.city_run(
  name: String, r: Result<&2, &2, Z.Zone.Error, Z.Zone>,
  want_id: String, +lh: U32, +eh: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{z}:
      TzifTest.city(name, z, want_id, lh, eh)

def TzifTest.ny_run(
  r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, "ny_tzif")
    case Done{+z}:
      do IO<Unit>:
        Unit <- TzifTest.ok("ny_id", String.eq(Z.Zone.id(z), "America/New_York"))
        Unit <- TzifTest.ny_at(z)
        IO.pure(Unit, Unit{})

def TzifTest.kol_at(
  name: String, r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{z}:
      TzifTest.at_off(
        name, Z.Zone.at(z, I.Instant.from_unix(0)), DT.OffsetEast{5, 30}
      )

def TzifTest.drop_ok(
  name: String, r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{z}:
      TzifTest.at_off(
        name, Z.Zone.at(z, I.Instant.from_unix(0)), DT.OffsetZero{}
      )

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- TzifTest.inv(
      "bad_magic",
      TzifTest.load(
        "x",
        "545a494632000000000000000000000000000000000000000000000000000000000000000000000000000000"
      )
    )
    Unit <- TzifTest.inv("trunc", TzifTest.load("x", "545a6966"))
    Unit <- TzifTest.uns(
      "v1",
      TzifTest.load(
        "x",
        "545a6966000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
      )
    )
    Unit <- TzifTest.uns(
      "ver4",
      TzifTest.load(
        "x",
        "545a696634000000000000000000000000000000000000000000000000000000000000000000000000000000"
      )
    )
    Unit <- TzifTest.inv(
      "cap",
      TzifTest.load(
        "x",
        "545a69663200000000000000000000000000000000000000000000000000000000000fa10000000000000000"
      )
    )
    Unit <- TzifTest.inv(
      "empty_id",
      TzifTest.load(
        "",
        "545a696632000000000000000000000000000000000000000000000000000000000000000000000000000000545a69663200000000000000000000000000000000000000000000000000000000000000000000010000000100004d58000000"
      )
    )
    Unit <- TzifTest.uns(
      "sec30",
      TzifTest.load(
        "x",
        "545a696632000000000000000000000000000000000000000000000000000000000000000000000000000000545a6966320000000000000000000000000000000000000000000000000000000000000000000001000000010000001e000000"
      )
    )
    Unit <- TzifTest.kol_at(
      "kol530",
      TzifTest.load(
        "Asia/Kolkata",
        "545a696632000000000000000000000000000000000000000000000000000000000000000000000000000000545a69663200000000000000000000000000000000000000000000000000000000000000000000010000000100004d58000000"
      )
    )
    Unit <- TzifTest.drop_ok(
      "drop_hi",
      TzifTest.load(
        "drop",
        "545a696632000000000000000000000000000000000000000000000000000000000000000000000000000000545a69663200000000000000000000000000000000000000000000000000000000000002000000010000000100000001000000000000000000000000000000000000000000"
      )
    )
    Unit <- TzifTest.ny_run(TzifTest.load_ny("America/New_York"))
    Unit <- TzifTest.city_run(
      "msk",
      TzifTest.load_chunks(Mc.Moscow.chunks(), "Europe/Moscow"),
      "Europe/Moscow", 15, 3
    )
    Unit <- TzifTest.city_run(
      "tyo",
      TzifTest.load_chunks(Tk.Tokyo.chunks(), "Asia/Tokyo"),
      "Asia/Tokyo", 21, 9
    )
    Unit <- TzifTest.city_run(
      "alias",
      TzifTest.load_chunks(Mc.Moscow.chunks(), "not-a-zone"),
      "not-a-zone", 15, 3
    )
    IO.print("ok")
