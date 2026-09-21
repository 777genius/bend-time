import Base
import ../date.bend as D
import ../datetime.bend as DT
import ../duration.bend as Dur
import ../instant.bend as I
import ../period.bend as Per

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

def LocalTest.ldt_h(
  name: String,
  r: Result<&2, &2, I.Instant.Error, DT.LocalDateTime>,
  +y: U32, +m: U32, +d: U32, +h: U32, +mi: U32, +s: U32, +ns: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{DT.LocalDateTime{D.Date{yy, mm, dd}, DT.TimeOfDay{hh, mmi, ss, frac}}}:
      LocalTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y),
          Bool.and(
            U32.is_eq(mm, m),
            Bool.and(
              U32.is_eq(dd, d),
              Bool.and(
                U32.is_eq(hh, h),
                Bool.and(
                  U32.is_eq(mmi, mi),
                  Bool.and(
                    U32.is_eq(ss, s),
                    U32.is_eq(DT.Datetime.frac_nanos(frac), ns)
                  )
                )
              )
            )
          )
        )
      )

def LocalTest.ldt_add(
  name: String,
  r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>,
  date: D.Date, d: Dur.Duration,
  +y: U32, +m: U32, +dd: U32, +h: U32, +mi: U32, +s: U32, +ns: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{t}:
      LocalTest.ldt_h(
        name, DT.LocalDateTime.add(DT.LocalDateTime.from(date, t), d),
        y, m, dd, h, mi, s, ns
      )

def LocalTest.ldt_fail_i(
  name: String, r: Result<&2, &2, I.Instant.Error, DT.LocalDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def LocalTest.ldt_sub(
  name: String,
  r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>,
  date: D.Date, d: Dur.Duration
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{t}:
      LocalTest.ldt_fail_i(
        name, DT.LocalDateTime.sub(DT.LocalDateTime.from(date, t), d)
      )

def LocalTest.until_z(
  name: String, r: Result<&2, &2, I.Instant.Error, Dur.Duration>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{d}:
      LocalTest.ok(name, Dur.Duration.is_eq(d, Dur.Duration.zero()))

def LocalTest.until_fail(
  name: String, r: Result<&2, &2, I.Instant.Error, Dur.Duration>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def LocalTest.until_same.go(
  name: String, +ldt: DT.LocalDateTime
) -> IO(Unit):
  LocalTest.until_z(name, DT.LocalDateTime.until(ldt, ldt))

def LocalTest.until_same(
  name: String,
  r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>,
  date: D.Date
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{t}:
      LocalTest.until_same.go(name, DT.LocalDateTime.from(date, t))

def LocalTest.until_back(
  name: String,
  r1: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>,
  r2: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>,
  +date: D.Date
) -> IO(Unit):
  match r1 r2:
    case Fail{_} _:
      IO.die(Unit, 1, name)
    case Done{_} Fail{_}:
      IO.die(Unit, 1, name)
    case Done{t1} Done{t2}:
      LocalTest.until_fail(
        name,
        DT.LocalDateTime.until(
          DT.LocalDateTime.from(date, t2), DT.LocalDateTime.from(date, t1)
        )
      )

def LocalTest.p_h(
  name: String,
  r: Result<&2, &2, D.Date.Error, DT.LocalDateTime>,
  +y: U32, +m: U32, +d: U32, +h: U32
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{DT.LocalDateTime{D.Date{yy, mm, dd}, DT.TimeOfDay{hh, _, _, _}}}:
      LocalTest.ok(
        name,
        Bool.and(
          U32.is_eq(yy, y),
          Bool.and(U32.is_eq(mm, m), Bool.and(U32.is_eq(dd, d), U32.is_eq(hh, h)))
        )
      )

def LocalTest.p_add(
  name: String,
  r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>,
  rp: Result<&2, &2, Per.Period.Error, Per.Period>,
  date: D.Date, +y: U32, +m: U32, +d: U32, +h: U32
) -> IO(Unit):
  match r rp:
    case Fail{_} _:
      IO.die(Unit, 1, name)
    case Done{_} Fail{_}:
      IO.die(Unit, 1, name)
    case Done{t} Done{p}:
      LocalTest.p_h(
        name, DT.LocalDateTime.add_period(DT.LocalDateTime.from(date, t), p),
        y, m, d, h
      )

def LocalTest.p_fail(
  name: String, r: Result<&2, &2, D.Date.Error, DT.LocalDateTime>
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.pure(Unit, Unit{})
    case Done{_}:
      IO.die(Unit, 1, name)

def LocalTest.p_fail_t(
  name: String,
  r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>,
  rp: Result<&2, &2, Per.Period.Error, Per.Period>,
  date: D.Date
) -> IO(Unit):
  match r rp:
    case Fail{_} _:
      IO.die(Unit, 1, name)
    case Done{_} Fail{_}:
      IO.die(Unit, 1, name)
    case Done{t} Done{p}:
      LocalTest.p_fail(
        name, DT.LocalDateTime.add_period(DT.LocalDateTime.from(date, t), p)
      )

def LocalTest.odt_p5(
  name: String, +got: DT.OffsetDateTime, same: Bool
) -> IO(Unit):
  match got:
    case DT.OffsetDateTime{D.Date{yy, mm, dd}, DT.TimeOfDay{hh, _, _, _}, _}:
      LocalTest.ok(
        name,
        Bool.and(
          same,
          Bool.and(
            U32.is_eq(yy, 2026),
            Bool.and(
              U32.is_eq(mm, 2),
              Bool.and(U32.is_eq(dd, 28), U32.is_eq(hh, 15))
            )
          )
        )
      )

def LocalTest.odt_p4(
  name: String, +got: DT.OffsetDateTime, +want: DT.OffsetDateTime
) -> IO(Unit):
  LocalTest.odt_p5(name, got, DT.OffsetDateTime.same_instant(got, want))

def LocalTest.odt_p3(
  name: String,
  r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>,
  t: DT.TimeOfDay, off: DT.UtcOffset
) -> IO(Unit):
  match r:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{odt}:
      LocalTest.odt_p4(
        name, odt, DT.OffsetDateTime.from(D.Date{2026, 2, 28}, t, off)
      )

def LocalTest.odt_p2(
  name: String, +t: DT.TimeOfDay, +off: DT.UtcOffset,
  rp: Result<&2, &2, Per.Period.Error, Per.Period>
) -> IO(Unit):
  match rp:
    case Fail{_}:
      IO.die(Unit, 1, name)
    case Done{p}:
      LocalTest.odt_p3(
        name,
        DT.OffsetDateTime.add_period(
          DT.OffsetDateTime.from(D.Date{2026, 1, 31}, t, off), p
        ),
        t, off
      )

def LocalTest.odt_p(
  name: String,
  r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>,
  ro: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>,
  rp: Result<&2, &2, Per.Period.Error, Per.Period>
) -> IO(Unit):
  match r ro:
    case Fail{_} _:
      IO.die(Unit, 1, name)
    case Done{_} Fail{_}:
      IO.die(Unit, 1, name)
    case Done{t} Done{off}:
      LocalTest.odt_p2(name, t, off, rp)

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
    Unit <- LocalTest.ldt_add(
      "ldt90", DT.TimeOfDay.from(12, 30, 0, DT.FracNone{}), D.Date{2026, 9, 18},
      Dur.Duration.from_secs(5400), 2026, 9, 18, 14, 0, 0, 0
    )
    Unit <- LocalTest.ldt_add(
      "ldt0", DT.TimeOfDay.from(12, 30, 0, DT.FracNone{}), D.Date{2026, 9, 18},
      Dur.Duration.zero(), 2026, 9, 18, 12, 30, 0, 0
    )
    Unit <- LocalTest.ldt_add(
      "ldt_nd", DT.TimeOfDay.from(23, 30, 0, DT.FracNone{}), D.Date{2026, 9, 18},
      Dur.Duration.from_secs(3600), 2026, 9, 19, 0, 30, 0, 0
    )
    Unit <- LocalTest.ldt_add(
      "ldt_ns", DT.TimeOfDay.from(23, 30, 0, DT.Frac{9n, 1}), D.Date{2026, 9, 18},
      Dur.Duration.from_secs(1), 2026, 9, 18, 23, 30, 1, 1
    )
    Unit <- LocalTest.ldt_sub(
      "ldt_y1", DT.TimeOfDay.from(0, 0, 0, DT.FracNone{}), D.Date{1, 1, 1},
      Dur.Duration.from_secs(1)
    )
    Unit <- LocalTest.until_same(
      "until0", DT.TimeOfDay.from(12, 30, 0, DT.FracNone{}), D.Date{2026, 9, 18}
    )
    Unit <- LocalTest.until_back(
      "until_rev",
      DT.TimeOfDay.from(12, 30, 0, DT.FracNone{}),
      DT.TimeOfDay.from(12, 31, 0, DT.FracNone{}),
      D.Date{2026, 9, 18}
    )
    Unit <- LocalTest.p_add(
      "p1m", DT.TimeOfDay.from(15, 30, 0, DT.FracNone{}), Per.Period.from(0, 1, 0),
      D.Date{2026, 1, 31}, 2026, 2, 28, 15
    )
    Unit <- LocalTest.ldt_add(
      "p1d_dur", DT.TimeOfDay.from(15, 30, 0, DT.FracNone{}), D.Date{2026, 1, 31},
      Dur.Duration{1, 0, 0}, 2026, 2, 1, 15, 30, 0, 0
    )
    Unit <- LocalTest.p_add(
      "p1d_per", DT.TimeOfDay.from(15, 30, 0, DT.FracNone{}), Per.Period.from(0, 0, 1),
      D.Date{2026, 1, 31}, 2026, 2, 1, 15
    )
    Unit <- LocalTest.p_fail_t(
      "p1m_max", DT.TimeOfDay.from(0, 0, 0, DT.FracNone{}), Per.Period.from(0, 1, 0),
      D.Date{9999, 12, 1}
    )
    Unit <- LocalTest.odt_p(
      "odt_p1m",
      DT.TimeOfDay.from(15, 30, 0, DT.FracNone{}),
      DT.UtcOffset.from(False{}, 3, 0),
      Per.Period.from(0, 1, 0)
    )
    IO.print("ok")
