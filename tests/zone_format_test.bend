import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/duration.bend as Dur
import 0x9b6a4fc7ceea91864a75396e1b8365e5/format.bend as F
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ../zone.bend as Z
import ../zoned.bend as Zd
import ../zone_format.bend as Zf
import ../tzif.bend as Tf
import ./tzif/moscow.bend as Mc
import 0x888714bde93f46c139372bb9fdc57a19/bytes.bend as B
import 0x888714bde93f46c139372bb9fdc57a19/hex.bend as Hx

def ZfTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def ZfTest.show_eq(
  name: String, r: Result<&2, &2, Zf.ZoneFormat.Error, String>, want: String
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{s}:
      ZfTest.ok(name, String.eq(s, want))

def ZfTest.read_ok(
  name: String,
  r: Result<&2, &2, Zf.ZoneFormat.Error, Zd.ZonedDateTime>,
  want: I.Instant
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZfTest.ok(name, I.Instant.is_eq(Zd.ZonedDateTime.to_instant(zdt), want))

def ZfTest.read_i(
  name: String, text: String, +z: Z.Zone,
  wr: Result<&2, &2, I.Instant.Error, I.Instant>
) -> IO(Unit):
  match wr:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      ZfTest.read_ok(name, Zf.ZoneFormat.read(text, z), i)

def ZfTest.show_after.go(
  name: String, want: String,
  r: Result<&2, &2, Zf.ZoneFormat.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZfTest.show_eq(name, Zf.ZoneFormat.show(zdt), want)

def ZfTest.show_after(
  name: String, text: String, +z: Z.Zone, want: String
) -> IO(Unit):
  ZfTest.show_after.go(name, want, Zf.ZoneFormat.read(text, z))

def ZfTest.inv(
  name: String,
  r: Result<&2, &2, Zf.ZoneFormat.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{Zf.Invalid{}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZfTest.mis(
  name: String,
  r: Result<&2, &2, Zf.ZoneFormat.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{Zf.Mismatch{}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZfTest.eof(
  name: String,
  r: Result<&2, &2, Zf.ZoneFormat.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{Zf.Eof{_}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZfTest.extra(
  name: String,
  r: Result<&2, &2, Zf.ZoneFormat.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{Zf.Extra{_, _}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZfTest.cat(
  xs: List<&2, U32>, ys: List<&2, U32>
) -> List<&2, U32>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      Con{h, ZfTest.cat(t, ys)}

def ZfTest.hexes.cat(
  xs: List<&2, U32>, r: Result<&2, &2, Hx.Hex.Error, B.Bytes>
) -> Result<&2, &2, Z.Zone.Error, List<&2, U32>>:
  match r:
    case Fail{_}:
      Fail{Z.Invalid{}}
    case Done{B.Bytes{data}}:
      Done{ZfTest.cat(xs, data)}

def ZfTest.hexes.go(
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
          ZfTest.hexes.go(t, ZfTest.hexes.cat(xs, Hx.Hex.decode(h)), id)

def ZfTest.utc_i(
  r: Result<&2, &2, D.Date.Error, D.Date>, +sod: U32
) -> Result<&2, &2, I.Instant.Error, I.Instant>:
  match r:
    case Fail{_}:
      Fail{I.OutOfRange{}}
    case Done{d}:
      I.Instant.add(I.Instant.from_utc_date(d), Dur.Duration{0, sod, 0})

def ZfTest.from_i(
  z: Z.Zone, r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>:
  match r:
    case Fail{_}:
      Fail{Z.OutOfRange{}}
    case Done{i}:
      Zd.ZonedDateTime.from_instant(i, z)

def ZfTest.ny_z.go(
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
            Con{
              Z.LocalType{DT.OffsetWest{5, 0}},
              Con{Z.LocalType{DT.OffsetWest{4, 0}}, Nil{}}
            },
            Con{Z.Trans{i1, 1}, Con{Z.Trans{i2, 0}, Nil{}}},
            None{}
          )

def ZfTest.ny_z() -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  ZfTest.ny_z.go(
    ZfTest.utc_i(D.Date.from(2026, 3, 8), 25200),
    ZfTest.utc_i(D.Date.from(2026, 11, 1), 21600)
  )

def ZfTest.show_zdt(
  name: String, want: String,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZfTest.show_eq(name, Zf.ZoneFormat.show(zdt), want)

def ZfTest.round.got(
  name: String, +zdt: Zd.ZonedDateTime, +z: Z.Zone,
  r: Result<&2, &2, Zf.ZoneFormat.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{+got}:
      ZfTest.ok(
        name,
        Bool.and(
          Zd.ZonedDateTime.same_instant(zdt, got),
          String.eq(Z.Zone.id(Zd.ZonedDateTime.zone(got)), Z.Zone.id(z))
        )
      )

def ZfTest.round.s(
  name: String, +zdt: Zd.ZonedDateTime, +z: Z.Zone,
  r: Result<&2, &2, Zf.ZoneFormat.Error, String>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{s}:
      ZfTest.round.got(name, zdt, z, Zf.ZoneFormat.read(s, z))

def ZfTest.round(
  name: String, +z: Z.Zone,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{+zdt}:
      ZfTest.round.s(name, zdt, z, Zf.ZoneFormat.show(zdt))

def ZfTest.msk_run(
  r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, "msk")
    case Done{+z}:
      do IO<Unit>:
        Unit <- ZfTest.show_zdt(
          "msk_show",
          "2026-09-18T15:30:00+03:00[Europe/Moscow]",
          ZfTest.from_i(z, ZfTest.utc_i(D.Date.from(2026, 9, 18), 45000))
        )
        Unit <- ZfTest.round(
          "msk_rt", z,
          ZfTest.from_i(z, ZfTest.utc_i(D.Date.from(2026, 9, 18), 45000))
        )
        IO.pure(Unit, Unit{})

def ZfTest.ny_run(
  r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, "ny")
    case Done{+z}:
      do IO<Unit>:
        Unit <- ZfTest.show_zdt(
          "fold_e",
          "2026-11-01T01:30:00-04:00[America/New_York]",
          ZfTest.from_i(z, ZfTest.utc_i(D.Date.from(2026, 11, 1), 19800))
        )
        Unit <- ZfTest.show_zdt(
          "fold_l",
          "2026-11-01T01:30:00-05:00[America/New_York]",
          ZfTest.from_i(z, ZfTest.utc_i(D.Date.from(2026, 11, 1), 23400))
        )
        Unit <- ZfTest.read_i(
          "read_e",
          "2026-11-01T01:30:00-04:00[America/New_York]", z,
          ZfTest.utc_i(D.Date.from(2026, 11, 1), 19800)
        )
        Unit <- ZfTest.read_i(
          "read_l",
          "2026-11-01T01:30:00-05:00[America/New_York]", z,
          ZfTest.utc_i(D.Date.from(2026, 11, 1), 23400)
        )
        Unit <- ZfTest.inv(
          "gap",
          Zf.ZoneFormat.read(
            "2026-03-08T02:30:00-05:00[America/New_York]", z
          )
        )
        Unit <- ZfTest.inv(
          "z_ny",
          Zf.ZoneFormat.read("2026-09-18T12:30:00Z[America/New_York]", z)
        )
        IO.pure(Unit, Unit{})

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- ZfTest.show_zdt(
      "z_show",
      "2026-09-18T12:30:00Z[Z]",
      ZfTest.from_i(
        Z.Zone.fixed(DT.OffsetZero{}),
        ZfTest.utc_i(D.Date.from(2026, 9, 18), 45000)
      )
    )
    Unit <- ZfTest.show_zdt(
      "fix3",
      "2026-09-18T15:30:00+03:00[Fixed/+03:00]",
      ZfTest.from_i(
        Z.Zone.fixed(DT.OffsetEast{3, 0}),
        ZfTest.utc_i(D.Date.from(2026, 9, 18), 45000)
      )
    )
    Unit <- ZfTest.inv(
      "no_suffix",
      Zf.ZoneFormat.read("2026-09-18T12:30:00Z", Z.Zone.fixed(DT.OffsetZero{}))
    )
    Unit <- ZfTest.eof(
      "no_rb",
      Zf.ZoneFormat.read(
        "2026-09-18T12:30:00Z[Z", Z.Zone.fixed(DT.OffsetZero{})
      )
    )
    Unit <- ZfTest.mis(
      "mis_id",
      Zf.ZoneFormat.read(
        "2026-09-18T12:30:00Z[UTC]", Z.Zone.fixed(DT.OffsetZero{})
      )
    )
    Unit <- ZfTest.extra(
      "space",
      Zf.ZoneFormat.read(
        "2026-09-18T12:30:00Z [Z]", Z.Zone.fixed(DT.OffsetZero{})
      )
    )
    Unit <- ZfTest.round(
      "zz_rt", Z.Zone.fixed(DT.OffsetZero{}),
      ZfTest.from_i(
        Z.Zone.fixed(DT.OffsetZero{}),
        ZfTest.utc_i(D.Date.from(2026, 9, 18), 45000)
      )
    )
    Unit <- ZfTest.show_after(
      "plus0",
      "2026-09-18T12:30:00+00:00[Z]",
      Z.Zone.fixed(DT.OffsetZero{}),
      "2026-09-18T12:30:00Z[Z]"
    )
    Unit <- ZfTest.show_after(
      "zz_rd",
      "2026-09-18T12:30:00Z[Z]",
      Z.Zone.fixed(DT.OffsetZero{}),
      "2026-09-18T12:30:00Z[Z]"
    )
    Unit <- ZfTest.msk_run(
      ZfTest.hexes.go(Mc.Moscow.chunks(), Done{Nil{}}, "Europe/Moscow")
    )
    Unit <- ZfTest.ny_run(ZfTest.ny_z())
    Unit <- ZfTest.ok(
      "fmt_still",
      String.eq(
        F.Format.show(
          DT.OffsetDateTime.from(
            D.Date{2026, 9, 18}, DT.TimeOfDay{12, 30, 0, DT.FracNone{}},
            DT.OffsetZero{}
          )
        ),
        "2026-09-18T12:30:00Z"
      )
    )
    IO.print("ok")
