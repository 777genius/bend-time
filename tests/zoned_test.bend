import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/duration.bend as Dur
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import 0x9b6a4fc7ceea91864a75396e1b8365e5/period.bend as Per
import ../zone.bend as Z
import ../zoned.bend as Zd

def ZonedTest.ok(name: String, pass: Bool) -> IO(Unit):
  match pass:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, name)

def ZonedTest.unix_n(
  name: String, r: Result<&2, &2, I.Instant.Error, U32>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{n}:
      ZonedTest.ok(name, U32.is_eq(n, want))

def ZonedTest.unix_z(
  name: String, r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.unix_n(name, I.Instant.to_unix(Zd.ZonedDateTime.to_instant(zdt)), want)

def ZonedTest.hh(
  name: String, r: Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{DT.LocalDateTime{_, DT.TimeOfDay{h, _, _, _}}}:
      ZonedTest.ok(name, U32.is_eq(h, want))

def ZonedTest.ymd(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>,
  +y: U32, +m: U32, +d: U32, +h: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{DT.LocalDateTime{D.Date{yy, mm, dd}, DT.TimeOfDay{hh, _, _, _}}}:
      ZonedTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y),
          Bool.and(
            U32.is_eq(mm, m),
            Bool.and(U32.is_eq(dd, d), U32.is_eq(hh, h))
          )
        )
      )

def ZonedTest.local_h(
  name: String, r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>, want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.hh(name, Zd.ZonedDateTime.to_local(zdt), want)

def ZonedTest.local_ymd(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  +y: U32, +m: U32, +d: U32, +h: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.ymd(name, Zd.ZonedDateTime.to_local(zdt), y, m, d, h)

def ZonedTest.add_h(
  name: String,
  r: Result<&2, &2, I.Instant.Error, Zd.ZonedDateTime>,
  want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.hh(name, Zd.ZonedDateTime.to_local(zdt), want)

def ZonedTest.add_fail(
  name: String, r: Result<&2, &2, I.Instant.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def ZonedTest.per_fail(
  name: String, r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def ZonedTest.add_from(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  d: Dur.Duration,
  want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.add_h(name, Zd.ZonedDateTime.add(zdt, d), want)

def ZonedTest.sub_from(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  d: Dur.Duration,
  want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.add_h(name, Zd.ZonedDateTime.sub(zdt, d), want)

def ZonedTest.zero_id(
  name: String, r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{+zdt}:
      ZonedTest.add_h(name, Zd.ZonedDateTime.add(zdt, Dur.Duration.zero()), 15)

def ZonedTest.per_ymd(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  p: Result<&2, &2, Per.Period.Error, Per.Period>,
  +y: U32, +m: U32, +d: U32, +h: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      match p:
        case Fail{_}:
          IO.die(Unit, 1, name)
        case Done{per}:
          ZonedTest.local_ymd(
            name, Zd.ZonedDateTime.add_period(zdt, per), y, m, d, h
          )

def ZonedTest.per_max(
  name: String,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  p: Result<&2, &2, Per.Period.Error, Per.Period>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      match p:
        case Fail{_}:
          IO.die(Unit, 1, name)
        case Done{per}:
          ZonedTest.per_fail(name, Zd.ZonedDateTime.add_period(zdt, per))

def ZonedTest.sub_y1(
  name: String, r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.add_fail(name, Zd.ZonedDateTime.sub(zdt, Dur.Duration.from_secs(1)))

def ZonedTest.same2(name: String, got: Bool, want: Bool) -> IO(Unit):
  match got:
    case True{}:
      match want:
        case True{}:
          IO.pure(Unit, Unit{})
        case False{}:
          IO.die(Unit, 1, name)
    case False{}:
      match want:
        case False{}:
          IO.pure(Unit, Unit{})
        case True{}:
          IO.die(Unit, 1, name)

def ZonedTest.same(
  name: String,
  a: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  b: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  want: Bool
) -> IO(Unit):
  match a:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{+za}:
      match b:
        case Fail{_}:
          IO.die(Unit, 1, name)
        case Done{zb}:
          ZonedTest.same2(name, Zd.ZonedDateTime.same_instant(za, zb), want)

def ZonedTest.ldt.go(
  date: D.Date, r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>
) -> Result<&2, &2, DT.TimeOfDay.Error, DT.LocalDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{t}:
      Done{DT.LocalDateTime.from(date, t)}

def ZonedTest.ldt(
  +h: U32, +mi: U32, date: D.Date
) -> Result<&2, &2, DT.TimeOfDay.Error, DT.LocalDateTime>:
  ZonedTest.ldt.go(date, DT.TimeOfDay.from(h, mi, 0, DT.FracNone{}))

def ZonedTest.from_ldt(
  name: String,
  r: Result<&2, &2, DT.TimeOfDay.Error, DT.LocalDateTime>,
  z: Z.Zone,
  want: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{ldt}:
      ZonedTest.unix_z(name, Zd.ZonedDateTime.from_local(ldt, z), want)

def ZonedTest.from_ldt_z(
  name: String,
  r: Result<&2, &2, DT.TimeOfDay.Error, DT.LocalDateTime>,
  z: Z.Zone
) -> Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>:
  match r:
    case Fail{_}:
      Fail{Z.Invalid{}}
    case Done{ldt}:
      Zd.ZonedDateTime.from_local(ldt, z)

def ZonedTest.off_z(
  r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>
) -> Z.Zone:
  match r:
    case Fail{_}:
      Z.Zone.fixed(DT.OffsetZero{})
    case Done{off}:
      Z.Zone.fixed(off)

def ZonedTest.utc_i(
  r: Result<&2, &2, D.Date.Error, D.Date>, +sod: U32, +nanos: U32
) -> Result<&2, &2, I.Instant.Error, I.Instant>:
  match r:
    case Fail{_}:
      Fail{I.OutOfRange{}}
    case Done{d}:
      I.Instant.add(I.Instant.from_utc_date(d), Dur.Duration{0, sod, nanos})

def ZonedTest.ny_types() -> List<&2, Z.Zone.LocalType>:
  Con{
    Z.LocalType{DT.OffsetWest{5, 0}},
    Con{Z.LocalType{DT.OffsetWest{4, 0}}, Nil{}}
  }

def ZonedTest.ny_z.go(
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
            ZonedTest.ny_types(),
            Con{Z.Trans{i1, 1}, Con{Z.Trans{i2, 0}, Nil{}}},
            None{}
          )

def ZonedTest.ny_z() -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  ZonedTest.ny_z.go(
    ZonedTest.utc_i(D.Date.from(2026, 3, 8), 25200, 0),
    ZonedTest.utc_i(D.Date.from(2026, 11, 1), 21600, 0)
  )

def ZonedTest.from_gap.go(
  name: String, r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{Z.Gap{_}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZonedTest.from_gap(
  name: String,
  ldt_r: Result<&2, &2, DT.TimeOfDay.Error, DT.LocalDateTime>,
  z: Z.Zone
) -> IO(Unit):
  match ldt_r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{ldt}:
      ZonedTest.from_gap.go(name, Zd.ZonedDateTime.from_local(ldt, z))

def ZonedTest.from_fold.go(
  name: String, r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{Z.Fold{_}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZonedTest.from_fold(
  name: String,
  ldt_r: Result<&2, &2, DT.TimeOfDay.Error, DT.LocalDateTime>,
  z: Z.Zone
) -> IO(Unit):
  match ldt_r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{ldt}:
      ZonedTest.from_fold.go(name, Zd.ZonedDateTime.from_local(ldt, z))

def ZonedTest.from_i_off.eq(
  +name: String, +zdt: Zd.ZonedDateTime, eq: Bool
) -> IO(Unit):
  match eq:
    case False{}:
      IO.die(Unit, 1, name)
    case True{}:
      ZonedTest.ymd(
        name, Zd.ZonedDateTime.to_local(zdt), 2026, 11, 1, 1
      )

def ZonedTest.from_i_off.off(
  +name: String, +zdt: Zd.ZonedDateTime, want: DT.UtcOffset,
  r: Result<&2, &2, Z.Zone.Error, DT.UtcOffset>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      ZonedTest.from_i_off.eq(name, zdt, Z.Zone.off_eq(off, want))

def ZonedTest.from_i_off.ok(
  +name: String, +zdt: Zd.ZonedDateTime, want: DT.UtcOffset
) -> IO(Unit):
  ZonedTest.from_i_off.off(name, zdt, want, Zd.ZonedDateTime.to_offset(zdt))

def ZonedTest.from_i_off.map(
  name: String, want: DT.UtcOffset,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.from_i_off.ok(name, zdt, want)

def ZonedTest.from_i_off(
  name: String,
  i_r: Result<&2, &2, I.Instant.Error, I.Instant>,
  z: Z.Zone,
  want: DT.UtcOffset
) -> IO(Unit):
  match i_r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      ZonedTest.from_i_off.map(name, want, Zd.ZonedDateTime.from_instant(i, z))

def ZonedTest.after.eq(
  +name: String, +zdt: Zd.ZonedDateTime,
  +y: U32, +m: U32, +d: U32, +h: U32, eq: Bool
) -> IO(Unit):
  match eq:
    case False{}:
      IO.die(Unit, 1, name)
    case True{}:
      ZonedTest.ymd(name, Zd.ZonedDateTime.to_local(zdt), y, m, d, h)

def ZonedTest.after.off(
  +name: String, +zdt: Zd.ZonedDateTime,
  +y: U32, +m: U32, +d: U32, +h: U32, want: DT.UtcOffset,
  r: Result<&2, &2, Z.Zone.Error, DT.UtcOffset>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{off}:
      ZonedTest.after.eq(name, zdt, y, m, d, h, Z.Zone.off_eq(off, want))

def ZonedTest.after(
  +name: String, +zdt: Zd.ZonedDateTime,
  +y: U32, +m: U32, +d: U32, +h: U32, want: DT.UtcOffset
) -> IO(Unit):
  ZonedTest.after.off(
    name, zdt, y, m, d, h, want, Zd.ZonedDateTime.to_offset(zdt)
  )

def ZonedTest.add_dst.go(
  name: String, +y: U32, +m: U32, +d: U32, +h: U32, off: DT.UtcOffset,
  r: Result<&2, &2, I.Instant.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.after(name, zdt, y, m, d, h, off)

def ZonedTest.add_dst(
  name: String,
  start: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  dur: Dur.Duration,
  +y: U32, +m: U32, +d: U32, +h: U32, off: DT.UtcOffset
) -> IO(Unit):
  match start:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.add_dst.go(name, y, m, d, h, off, Zd.ZonedDateTime.add(zdt, dur))

def ZonedTest.sub_dst(
  name: String,
  start: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  dur: Dur.Duration,
  +y: U32, +m: U32, +d: U32, +h: U32, off: DT.UtcOffset
) -> IO(Unit):
  match start:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.add_dst.go(name, y, m, d, h, off, Zd.ZonedDateTime.sub(zdt, dur))

def ZonedTest.per_dst.go(
  name: String, +y: U32, +m: U32, +d: U32, +h: U32, off: DT.UtcOffset,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.after(name, zdt, y, m, d, h, off)

def ZonedTest.per_dst(
  name: String,
  start: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  p: Result<&2, &2, Per.Period.Error, Per.Period>,
  +y: U32, +m: U32, +d: U32, +h: U32, off: DT.UtcOffset
) -> IO(Unit):
  match start:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      match p:
        case Fail{_}:
          IO.die(Unit, 1, name)
        case Done{per}:
          ZonedTest.per_dst.go(
            name, y, m, d, h, off, Zd.ZonedDateTime.add_period(zdt, per)
          )

def ZonedTest.per_gap.go(
  name: String, r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{Z.Gap{_}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZonedTest.per_gap(
  name: String,
  start: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  p: Result<&2, &2, Per.Period.Error, Per.Period>
) -> IO(Unit):
  match start:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      match p:
        case Fail{_}:
          IO.die(Unit, 1, name)
        case Done{per}:
          ZonedTest.per_gap.go(name, Zd.ZonedDateTime.add_period(zdt, per))

def ZonedTest.per_fold.go(
  name: String, r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{Z.Fold{_}}:
      IO.pure(Unit, Unit{})
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{_}:
      IO.die(Unit, 1, name)

def ZonedTest.per_fold(
  name: String,
  start: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>,
  p: Result<&2, &2, Per.Period.Error, Per.Period>
) -> IO(Unit):
  match start:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      match p:
        case Fail{_}:
          IO.die(Unit, 1, name)
        case Done{per}:
          ZonedTest.per_fold.go(name, Zd.ZonedDateTime.add_period(zdt, per))

def ZonedTest.add_from_i.go(
  name: String, dur: Dur.Duration,
  +y: U32, +m: U32, +d: U32, +h: U32, off: DT.UtcOffset,
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{zdt}:
      ZonedTest.add_dst.go(name, y, m, d, h, off, Zd.ZonedDateTime.add(zdt, dur))

def ZonedTest.add_from_i(
  name: String,
  i_r: Result<&2, &2, I.Instant.Error, I.Instant>,
  z: Z.Zone,
  dur: Dur.Duration,
  +y: U32, +m: U32, +d: U32, +h: U32, off: DT.UtcOffset
) -> IO(Unit):
  match i_r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{i}:
      ZonedTest.add_from_i.go(
        name, dur, y, m, d, h, off, Zd.ZonedDateTime.from_instant(i, z)
      )

def ZonedTest.ny_arith(+z: Z.Zone) -> IO(Unit):
  do IO<Unit>:
    Unit <- ZonedTest.add_dst(
      "add2h",
      ZonedTest.from_ldt_z(
        "add2h", ZonedTest.ldt(1, 30, D.Date{2026, 3, 8}), z
      ),
      Dur.Duration.from_secs(7200),
      2026, 3, 8, 4, DT.OffsetWest{4, 0}
    )
    Unit <- ZonedTest.add_dst(
      "add30m",
      ZonedTest.from_ldt_z(
        "add30m", ZonedTest.ldt(1, 30, D.Date{2026, 3, 8}), z
      ),
      Dur.Duration.from_secs(1800),
      2026, 3, 8, 3, DT.OffsetWest{4, 0}
    )
    Unit <- ZonedTest.add_dst(
      "add1h",
      ZonedTest.from_ldt_z(
        "add1h", ZonedTest.ldt(1, 30, D.Date{2026, 3, 8}), z
      ),
      Dur.Duration.from_secs(3600),
      2026, 3, 8, 3, DT.OffsetWest{4, 0}
    )
    Unit <- ZonedTest.add_dst(
      "add24h",
      ZonedTest.from_ldt_z(
        "add24h", ZonedTest.ldt(1, 30, D.Date{2026, 3, 8}), z
      ),
      Dur.Duration.from_secs(86400),
      2026, 3, 9, 2, DT.OffsetWest{4, 0}
    )
    Unit <- ZonedTest.per_dst(
      "p1d",
      ZonedTest.from_ldt_z(
        "p1d", ZonedTest.ldt(1, 30, D.Date{2026, 3, 8}), z
      ),
      Per.Period.from(0, 0, 1),
      2026, 3, 9, 1, DT.OffsetWest{4, 0}
    )
    Unit <- ZonedTest.sub_dst(
      "sub2h",
      ZonedTest.from_ldt_z(
        "sub2h", ZonedTest.ldt(3, 30, D.Date{2026, 3, 8}), z
      ),
      Dur.Duration.from_secs(7200),
      2026, 3, 8, 0, DT.OffsetWest{5, 0}
    )
    Unit <- ZonedTest.add_dst(
      "add2h_fall",
      ZonedTest.from_ldt_z(
        "add2h_fall", ZonedTest.ldt(0, 30, D.Date{2026, 11, 1}), z
      ),
      Dur.Duration.from_secs(7200),
      2026, 11, 1, 1, DT.OffsetWest{5, 0}
    )
    Unit <- ZonedTest.add_from_i(
      "add1h_early",
      ZonedTest.utc_i(D.Date.from(2026, 11, 1), 19800, 0),
      z,
      Dur.Duration.from_secs(3600),
      2026, 11, 1, 1, DT.OffsetWest{5, 0}
    )
    Unit <- ZonedTest.per_dst(
      "p1m_est",
      ZonedTest.from_ldt_z(
        "p1m_est", ZonedTest.ldt(15, 30, D.Date{2026, 1, 31}), z
      ),
      Per.Period.from(0, 1, 0),
      2026, 2, 28, 15, DT.OffsetWest{5, 0}
    )
    Unit <- ZonedTest.per_gap(
      "p1d_gap",
      ZonedTest.from_ldt_z(
        "p1d_gap", ZonedTest.ldt(2, 30, D.Date{2026, 3, 7}), z
      ),
      Per.Period.from(0, 0, 1)
    )
    Unit <- ZonedTest.per_fold(
      "p1m_fold",
      ZonedTest.from_ldt_z(
        "p1m_fold", ZonedTest.ldt(1, 30, D.Date{2026, 10, 1}), z
      ),
      Per.Period.from(0, 1, 0)
    )
    Unit <- ZonedTest.per_dst(
      "p0d",
      ZonedTest.from_ldt_z(
        "p0d", ZonedTest.ldt(1, 30, D.Date{2026, 3, 8}), z
      ),
      Per.Period.from(0, 0, 0),
      2026, 3, 8, 1, DT.OffsetWest{5, 0}
    )
    IO.pure(Unit, Unit{})

def ZonedTest.ny_dst(
  name: String, r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{+z}:
      do IO<Unit>:
        Unit <- ZonedTest.from_gap(
          "gap_0230",
          ZonedTest.ldt(2, 30, D.Date{2026, 3, 8}),
          z
        )
        Unit <- ZonedTest.from_fold(
          "fold_0130",
          ZonedTest.ldt(1, 30, D.Date{2026, 11, 1}),
          z
        )
        Unit <- ZonedTest.from_i_off(
          "edt_0130",
          ZonedTest.utc_i(D.Date.from(2026, 11, 1), 19800, 0),
          z,
          DT.OffsetWest{4, 0}
        )
        Unit <- ZonedTest.from_i_off(
          "est_0130",
          ZonedTest.utc_i(D.Date.from(2026, 11, 1), 23400, 0),
          z,
          DT.OffsetWest{5, 0}
        )
        Unit <- ZonedTest.ny_arith(z)
        IO.pure(Unit, Unit{})

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- ZonedTest.from_ldt(
      "unix_1530",
      ZonedTest.ldt(15, 30, D.Date{2026, 9, 18}),
      ZonedTest.off_z(DT.UtcOffset.from(False{}, 3, 0)),
      1789734600
    )
    Unit <- ZonedTest.local_h(
      "from_i",
      Zd.ZonedDateTime.from_instant(
        I.Instant.from_unix(1789734600),
        ZonedTest.off_z(DT.UtcOffset.from(False{}, 3, 0))
      ),
      15
    )
    Unit <- ZonedTest.add_from(
      "add90",
      ZonedTest.from_ldt_z(
        "add90",
        ZonedTest.ldt(15, 30, D.Date{2026, 9, 18}),
        ZonedTest.off_z(DT.UtcOffset.from(False{}, 3, 0))
      ),
      Dur.Duration.from_secs(5400),
      17
    )
    Unit <- ZonedTest.sub_from(
      "sub90",
      ZonedTest.from_ldt_z(
        "sub90",
        ZonedTest.ldt(17, 0, D.Date{2026, 9, 18}),
        ZonedTest.off_z(DT.UtcOffset.from(False{}, 3, 0))
      ),
      Dur.Duration.from_secs(5400),
      15
    )
    Unit <- ZonedTest.zero_id(
      "add0",
      ZonedTest.from_ldt_z(
        "add0",
        ZonedTest.ldt(15, 30, D.Date{2026, 9, 18}),
        ZonedTest.off_z(DT.UtcOffset.from(False{}, 3, 0))
      )
    )
    Unit <- ZonedTest.sub_y1(
      "sub_y1",
      Zd.ZonedDateTime.from_local(
        DT.LocalDateTime.from(D.Date{1, 1, 1}, DT.TimeOfDay{0, 0, 0, DT.FracNone{}}),
        Z.Zone.fixed(DT.OffsetZero{})
      )
    )
    Unit <- ZonedTest.per_ymd(
      "p1m",
      ZonedTest.from_ldt_z(
        "p1m",
        ZonedTest.ldt(15, 30, D.Date{2026, 1, 31}),
        ZonedTest.off_z(DT.UtcOffset.from(False{}, 3, 0))
      ),
      Per.Period.from(0, 1, 0),
      2026, 2, 28, 15
    )
    Unit <- ZonedTest.per_max(
      "p1m_max",
      ZonedTest.from_ldt_z(
        "p1m_max",
        ZonedTest.ldt(0, 0, D.Date{9999, 12, 1}),
        Z.Zone.fixed(DT.OffsetZero{})
      ),
      Per.Period.from(0, 1, 0)
    )
    Unit <- ZonedTest.same(
      "same_i",
      Zd.ZonedDateTime.from_instant(
        I.Instant.from_unix(1789734600),
        ZonedTest.off_z(DT.UtcOffset.from(False{}, 3, 0))
      ),
      Zd.ZonedDateTime.from_instant(
        I.Instant.from_unix(1789734600),
        Z.Zone.fixed(DT.OffsetZero{})
      ),
      True{}
    )
    Unit <- ZonedTest.same(
      "diff_i",
      ZonedTest.from_ldt_z(
        "diff_a",
        ZonedTest.ldt(15, 30, D.Date{2026, 9, 18}),
        ZonedTest.off_z(DT.UtcOffset.from(False{}, 3, 0))
      ),
      ZonedTest.from_ldt_z(
        "diff_b",
        ZonedTest.ldt(16, 30, D.Date{2026, 9, 18}),
        ZonedTest.off_z(DT.UtcOffset.from(False{}, 3, 0))
      ),
      False{}
    )
    Unit <- ZonedTest.add_fail(
      "add_max",
      Zd.ZonedDateTime.add(
        Zd.ZonedDateTime{
          I.Instant.from_utc_date(D.Date{9999, 12, 31}),
          Z.Zone.fixed(DT.OffsetZero{})
        },
        Dur.Duration{1, 0, 0}
      )
    )
    Unit <- ZonedTest.ny_dst("ny_dst", ZonedTest.ny_z())
    IO.print("ok")
