import Base

type Date.Error is Data:
  InvalidDate{year: U32, month: U32, day: U32}

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
