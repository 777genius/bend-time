import Base

type Date.Error is Data:
  InvalidDate{year: U32, month: U32, day: U32}
  OutOfRange{}

type Date is Data:
  Date{year: U32, month: U32, day: U32}

def Date.leap.100(+y: U32, d100: Bool) -> Bool:
  match d100:
    case False{}:
      True{}
    case True{}:
      U32.is_eq(U32.mod(y, 400), 0)

def Date.leap.4(+y: U32, d4: Bool) -> Bool:
  match d4:
    case False{}:
      False{}
    case True{}:
      Date.leap.100(y, U32.is_eq(U32.mod(y, 100), 0))

def Date.leap(+y: U32) -> Bool:
  Date.leap.4(y, U32.is_eq(U32.mod(y, 4), 0))

def Date.dim.feb(leap: Bool) -> U32:
  match leap:
    case True{}:
      29
    case False{}:
      28

def Date.is_31(+m: U32) -> Bool:
  Bool.or(
    U32.is_eq(m, 1),
    Bool.or(
      U32.is_eq(m, 3),
      Bool.or(
        U32.is_eq(m, 5),
        Bool.or(
          U32.is_eq(m, 7),
          Bool.or(
            U32.is_eq(m, 8),
            Bool.or(U32.is_eq(m, 10), U32.is_eq(m, 12))
          )
        )
      )
    )
  )

def Date.is_30(+m: U32) -> Bool:
  Bool.or(
    U32.is_eq(m, 4),
    Bool.or(U32.is_eq(m, 6), Bool.or(U32.is_eq(m, 9), U32.is_eq(m, 11)))
  )

def Date.dim.rest3(m: U32, d30: Bool) -> Maybe<&2, U32>:
  match d30:
    case True{}:
      Some{30}
    case False{}:
      None{}

def Date.dim.rest2(+m: U32, d31: Bool) -> Maybe<&2, U32>:
  match d31:
    case True{}:
      Some{31}
    case False{}:
      Date.dim.rest3(m, Date.is_30(m))

def Date.dim.rest(+m: U32) -> Maybe<&2, U32>:
  Date.dim.rest2(m, Date.is_31(m))

def Date.dim.m(+m: U32, leap: Bool, feb: Bool) -> Maybe<&2, U32>:
  match feb:
    case True{}:
      Some{Date.dim.feb(leap)}
    case False{}:
      Date.dim.rest(m)

def Date.dim(+m: U32, leap: Bool) -> Maybe<&2, U32>:
  Date.dim.m(m, leap, U32.is_eq(m, 2))

def Date.from.day2(
  +y: U32, +m: U32, +d: U32, ok: Bool
) -> Result<&2, &2, Date.Error, Date>:
  match ok:
    case False{}:
      Fail{InvalidDate{y, m, d}}
    case True{}:
      Done{Date{y, m, d}}

def Date.from.day(
  +y: U32, +m: U32, +d: U32, dim: U32
) -> Result<&2, &2, Date.Error, Date>:
  Date.from.day2(
    y, m, d, Bool.and(U32.is_ge(d, 1), U32.is_le(d, dim))
  )

def Date.from.dim(
  +y: U32, +m: U32, +d: U32, dim: Maybe<&2, U32>
) -> Result<&2, &2, Date.Error, Date>:
  match dim:
    case None{}:
      Fail{InvalidDate{y, m, d}}
    case Some{n}:
      Date.from.day(y, m, d, n)

def Date.from.y(
  +y: U32, +m: U32, +d: U32, ok: Bool
) -> Result<&2, &2, Date.Error, Date>:
  match ok:
    case False{}:
      Fail{InvalidDate{y, m, d}}
    case True{}:
      Date.from.dim(y, m, d, Date.dim(m, Date.leap(y)))

def Date.from(
  +y: U32, +m: U32, +d: U32
) -> Result<&2, &2, Date.Error, Date>:
  Date.from.y(y, m, d, Bool.and(U32.is_ge(y, 1), U32.is_le(y, 9999)))

def Date.dim_of.go(dim: Maybe<&2, U32>) -> Result<&2, &2, Date.Error, U32>:
  match dim:
    case None{}:
      Fail{OutOfRange{}}
    case Some{+n}:
      Done{n}

def Date.dim_of(+y: U32, +m: U32) -> Result<&2, &2, Date.Error, U32>:
  Date.dim_of.go(Date.dim(m, Date.leap(y)))

def Date.days_in_month(date: Date) -> Result<&2, &2, Date.Error, U32>:
  match date:
    case Date{+y, +m, _}:
      Date.dim_of(y, m)

def Date.end_of_month.go(
  +y: U32, +m: U32, r: Result<&2, &2, Date.Error, U32>
) -> Result<&2, &2, Date.Error, Date>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{dim}:
      Done{Date{y, m, dim}}

def Date.end_of_month(date: Date) -> Result<&2, &2, Date.Error, Date>:
  match date:
    case Date{+y, +m, _}:
      Date.end_of_month.go(y, m, Date.dim_of(y, m))

def Date.start_of_month(date: Date) -> Date:
  match date:
    case Date{y, m, _}:
      Date{y, m, 1}

def Date.start_of_year(date: Date) -> Date:
  match date:
    case Date{y, _, _}:
      Date{y, 1, 1}

def Date.end_of_year(date: Date) -> Date:
  match date:
    case Date{y, _, _}:
      Date{y, 12, 31}

def Date.with_day(date: Date, d: U32) -> Result<&2, &2, Date.Error, Date>:
  match date:
    case Date{+y, +m, _}:
      Date.from(y, m, d)

def Date.with_month(date: Date, m: U32) -> Result<&2, &2, Date.Error, Date>:
  match date:
    case Date{+y, _, +d}:
      Date.from(y, m, d)

def Date.with_year(date: Date, y: U32) -> Result<&2, &2, Date.Error, Date>:
  match date:
    case Date{_, +m, +d}:
      Date.from(y, m, d)

def Date.y_adj(y: U32, jf: Bool) -> U32:
  match jf:
    case True{}:
      U32.sub(y, 1)
    case False{}:
      y

def Date.mp(m: U32, jf: Bool) -> U32:
  match jf:
    case True{}:
      U32.add(m, 9)
    case False{}:
      U32.sub(m, 3)

def Date.doy(+m: U32, +d: U32, jf: Bool) -> U32:
  U32.sub(U32.add(U32.div(U32.add(U32.mul(153, Date.mp(m, jf)), 2), 5), d), 1)

def Date.to_days.era(+era: U32, +yoe: U32, doy: U32) -> U32:
  U32.add(
    U32.mul(era, 146097),
    U32.add(
      U32.sub(
        U32.add(U32.mul(yoe, 365), U32.div(yoe, 4)),
        U32.div(yoe, 100)
      ),
      doy
    )
  )

def Date.to_days.yoe(+ya: U32, doy: U32) -> U32:
  Date.to_days.era(
    U32.div(ya, 400),
    U32.sub(ya, U32.mul(U32.div(ya, 400), 400)),
    doy
  )

def Date.to_days.parts(+y: U32, +m: U32, +d: U32) -> U32:
  Date.to_days.yoe(Date.y_adj(y, U32.is_le(m, 2)), Date.doy(m, d, U32.is_le(m, 2)))

def Date.to_days(date: Date) -> U32:
  match date:
    case Date{y, m, d}:
      Date.to_days.parts(y, m, d)

def Date.is_eq(a: Date, b: Date) -> Bool:
  match a b:
    case Date{+y1, +m1, +d1} Date{+y2, +m2, +d2}:
      Bool.and(
        U32.is_eq(y1, y2),
        Bool.and(U32.is_eq(m1, m2), U32.is_eq(d1, d2))
      )

def Date.is_lt(a: Date, b: Date) -> Bool:
  U32.is_lt(Date.to_days(a), Date.to_days(b))

def Date.is_gt(a: Date, b: Date) -> Bool:
  Date.is_lt(b, a)

def Date.is_le(a: Date, b: Date) -> Bool:
  Bool.not(Date.is_lt(b, a))

def Date.is_ge(a: Date, b: Date) -> Bool:
  Bool.not(Date.is_lt(a, b))

def Date.from_days.doe(+z: U32, era: U32) -> U32:
  U32.sub(z, U32.mul(era, 146097))

def Date.from_days.yoe(+doe: U32) -> U32:
  U32.div(
    U32.sub(
      U32.add(U32.sub(doe, U32.div(doe, 1460)), U32.div(doe, 36524)),
      U32.div(doe, 146096)
    ),
    365
  )

def Date.from_days.doy(+doe: U32, +yoe: U32) -> U32:
  U32.sub(
    doe,
    U32.sub(
      U32.add(U32.mul(365, yoe), U32.div(yoe, 4)),
      U32.div(yoe, 100)
    )
  )

def Date.from_days.mp(+doy: U32) -> U32:
  U32.div(U32.add(U32.mul(5, doy), 2), 153)

def Date.from_days.day(+doy: U32, +mp: U32) -> U32:
  U32.add(U32.sub(doy, U32.div(U32.add(U32.mul(153, mp), 2), 5)), 1)

def Date.from_days.month(+mp: U32, lt: Bool) -> U32:
  match lt:
    case True{}:
      U32.add(mp, 3)
    case False{}:
      U32.sub(mp, 9)

def Date.from_days.year(+y: U32, jan: Bool) -> U32:
  match jan:
    case True{}:
      U32.add(y, 1)
    case False{}:
      y

def Date.from_days.parts(+z: U32) -> Result<&2, &2, Date.Error, Date>:
  +era = U32.div(z, 146097)
  +doe = Date.from_days.doe(z, era)
  +yoe = Date.from_days.yoe(doe)
  +doy = Date.from_days.doy(doe, yoe)
  +mp = Date.from_days.mp(doy)
  +m = Date.from_days.month(mp, U32.is_lt(mp, 10))
  Date.from(
    Date.from_days.year(U32.add(yoe, U32.mul(era, 400)), U32.is_le(m, 2)),
    m,
    Date.from_days.day(doy, mp)
  )

def Date.from_days(z: U32) -> Result<&2, &2, Date.Error, Date>:
  Date.from_days.parts(z)

type Weekday is Data:
  Mon{}
  Tue{}
  Wed{}
  Thu{}
  Fri{}
  Sat{}
  Sun{}

def Date.weekday.n6(+n: U32, is6: Bool) -> Weekday:
  match is6:
    case True{}:
      Sun{}
    case False{}:
      Sat{}

def Date.weekday.n5(+n: U32, is5: Bool) -> Weekday:
  match is5:
    case True{}:
      Sat{}
    case False{}:
      Date.weekday.n6(n, U32.is_eq(n, 6))

def Date.weekday.n4(+n: U32, is4: Bool) -> Weekday:
  match is4:
    case True{}:
      Fri{}
    case False{}:
      Date.weekday.n5(n, U32.is_eq(n, 5))

def Date.weekday.n3(+n: U32, is3: Bool) -> Weekday:
  match is3:
    case True{}:
      Thu{}
    case False{}:
      Date.weekday.n4(n, U32.is_eq(n, 4))

def Date.weekday.n2(+n: U32, is2: Bool) -> Weekday:
  match is2:
    case True{}:
      Wed{}
    case False{}:
      Date.weekday.n3(n, U32.is_eq(n, 3))

def Date.weekday.n1(+n: U32, is1: Bool) -> Weekday:
  match is1:
    case True{}:
      Tue{}
    case False{}:
      Date.weekday.n2(n, U32.is_eq(n, 2))

def Date.weekday.n(+n: U32) -> Weekday:
  Date.weekday.n1(n, U32.is_eq(n, 1))

def Date.weekday.zero(+n: U32, z: Bool) -> Weekday:
  match z:
    case True{}:
      Mon{}
    case False{}:
      Date.weekday.n(n)

def Date.weekday(date: Date) -> Weekday:
  +n = U32.mod(U32.add(Date.to_days(date), 2), 7)
  Date.weekday.zero(n, U32.is_eq(n, 0))

def Date.add_ov(+z: U32, n: U32, ok: Bool) -> Result<&2, &2, Date.Error, Date>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Date.from_days(U32.add(z, n))

def Date.add_days(+date: Date, +n: U32) -> Result<&2, &2, Date.Error, Date>:
  +z = Date.to_days(date)
  Date.add_ov(z, n, U32.is_le(n, U32.sub(U32.not(0), z)))

def Date.sub_ov(+z: U32, n: U32, ok: Bool) -> Result<&2, &2, Date.Error, Date>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Date.from_days(U32.sub(z, n))

def Date.sub_days(+date: Date, +n: U32) -> Result<&2, &2, Date.Error, Date>:
  +z = Date.to_days(date)
  Date.sub_ov(z, n, U32.is_ge(z, n))

def Weekday.to_u32(w: Weekday) -> U32:
  match w:
    case Mon{}:
      0
    case Tue{}:
      1
    case Wed{}:
      2
    case Thu{}:
      3
    case Fri{}:
      4
    case Sat{}:
      5
    case Sun{}:
      6

def Weekday.fwd.gap(+cur: U32, +tgt: U32, gt: Bool) -> U32:
  match gt:
    case True{}:
      U32.sub(tgt, cur)
    case False{}:
      U32.sub(U32.add(tgt, 7), cur)

def Weekday.fwd.eq(+cur: U32, +tgt: U32, eq: Bool) -> U32:
  match eq:
    case True{}:
      7
    case False{}:
      Weekday.fwd.gap(cur, tgt, U32.is_gt(tgt, cur))

def Weekday.fwd(+cur: U32, +tgt: U32) -> U32:
  Weekday.fwd.eq(cur, tgt, U32.is_eq(tgt, cur))

def Date.next_weekday(
  +d: Date, w: Weekday
) -> Result<&2, &2, Date.Error, Date>:
  Date.add_days(
    d, Weekday.fwd(Weekday.to_u32(Date.weekday(d)), Weekday.to_u32(w))
  )

def Date.previous_weekday(
  +d: Date, w: Weekday
) -> Result<&2, &2, Date.Error, Date>:
  Date.sub_days(
    d, Weekday.fwd(Weekday.to_u32(w), Weekday.to_u32(Date.weekday(d)))
  )

def Date.next_or_same.go(
  +d: Date, w: Weekday, eq: Bool
) -> Result<&2, &2, Date.Error, Date>:
  match eq:
    case True{}:
      Done{d}
    case False{}:
      Date.next_weekday(d, w)

def Date.next_or_same_weekday(
  +d: Date, +w: Weekday
) -> Result<&2, &2, Date.Error, Date>:
  Date.next_or_same.go(
    d, w, U32.is_eq(Weekday.to_u32(Date.weekday(d)), Weekday.to_u32(w))
  )

def Date.previous_or_same.go(
  +d: Date, w: Weekday, eq: Bool
) -> Result<&2, &2, Date.Error, Date>:
  match eq:
    case True{}:
      Done{d}
    case False{}:
      Date.previous_weekday(d, w)

def Date.previous_or_same_weekday(
  +d: Date, +w: Weekday
) -> Result<&2, &2, Date.Error, Date>:
  Date.previous_or_same.go(
    d, w, U32.is_eq(Weekday.to_u32(Date.weekday(d)), Weekday.to_u32(w))
  )

def Date.until_days.go(
  +zs: U32, +ze: U32, lt: Bool
) -> Result<&2, &2, Date.Error, U32>:
  match lt:
    case True{}:
      Fail{OutOfRange{}}
    case False{}:
      Done{U32.sub(ze, zs)}

def Date.until_days(
  start: Date, end: Date
) -> Result<&2, &2, Date.Error, U32>:
  +zs = Date.to_days(start)
  +ze = Date.to_days(end)
  Date.until_days.go(zs, ze, U32.is_lt(ze, zs))

