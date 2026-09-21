import Base
import ./date.bend as D

type Period.Error is Data:
  OutOfRange{}

type Period is Data:
  Period{years: U32, months: U32, days: U32}

def Period.from.y(
  +years: U32, +extra: U32, +months: U32, +days: U32, ok: Bool
) -> Result<&2, &2, Period.Error, Period>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Done{Period{U32.add(years, extra), months, days}}

def Period.from(
  +years: U32, +months: U32, +days: U32
) -> Result<&2, &2, Period.Error, Period>:
  +extra = U32.div(months, 12)
  Period.from.y(
    years, extra, U32.mod(months, 12), days,
    U32.is_le(extra, U32.sub(U32.not(0), years))
  )

def Period.add_to.days(
  r: Result<&2, &2, D.Date.Error, D.Date>, pd: U32
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{date}:
      D.Date.add_days(date, pd)

def Period.add_to.from(
  +y: U32, +m: U32, +d: U32, +pd: U32
) -> Result<&2, &2, D.Date.Error, D.Date>:
  Period.add_to.days(D.Date.from(y, m, d), pd)

def Period.add_to.day(
  +y: U32, +m: U32, +d: U32, +pd: U32, +dim: U32, le: Bool
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match le:
    case True{}:
      Period.add_to.from(y, m, d, pd)
    case False{}:
      Period.add_to.from(y, m, dim, pd)

def Period.add_to.dim(
  +y: U32, +m: U32, +d: U32, +pd: U32, dimr: Maybe<&2, U32>
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match dimr:
    case None{}:
      Fail{D.OutOfRange{}}
    case Some{+dim}:
      Period.add_to.day(y, m, d, pd, dim, U32.is_le(d, dim))

def Period.add_to.y3(
  +y: U32, +m: U32, +d: U32, +pd: U32, ok: Bool
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match ok:
    case False{}:
      Fail{D.OutOfRange{}}
    case True{}:
      Period.add_to.dim(y, m, d, pd, D.Date.dim(m, D.Date.leap(y)))

def Period.add_to.y2(
  +y: U32, +m: U32, +d: U32, +pd: U32
) -> Result<&2, &2, D.Date.Error, D.Date>:
  Period.add_to.y3(y, m, d, pd, Bool.and(U32.is_ge(y, 1), U32.is_le(y, 9999)))

def Period.add_to.mc(
  +y: U32, +m: U32, +d: U32, +pd: U32, ge: Bool
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match ge:
    case False{}:
      Period.add_to.y2(y, m, d, pd)
    case True{}:
      Period.add_to.y2(U32.add(y, 1), U32.sub(m, 12), d, pd)

def Period.add_to.ya(
  +dy: U32, +py: U32, +dm: U32, +pm: U32, +dd: U32, +pd: U32, ok: Bool
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match ok:
    case False{}:
      Fail{D.OutOfRange{}}
    case True{}:
      +y = U32.add(dy, py)
      +m = U32.add(dm, pm)
      Period.add_to.mc(y, m, dd, pd, U32.is_gt(m, 12))

def Period.add_to.go(
  date: D.Date, p: Period
) -> Result<&2, &2, D.Date.Error, D.Date>:
  match date p:
    case D.Date{+dy, +dm, +dd} Period{+py, +pm, +pd}:
      Period.add_to.ya(
        dy, py, dm, pm, dd, pd, U32.is_le(py, U32.sub(U32.not(0), dy))
      )

def Period.add_to(
  p: Period, date: D.Date
) -> Result<&2, &2, D.Date.Error, D.Date>:
  Period.add_to.go(date, p)

def Period.emonth(+y: U32, +m: U32) -> U32:
  U32.add(U32.mul(y, 12), m)

def Period.between.ms.from(
  +end: D.Date, +tm: U32, r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, Period.Error, Period>:
  match r:
    case Fail{_}:
      Fail{OutOfRange{}}
    case Done{start2}:
      Period.from(
        U32.div(tm, 12),
        U32.mod(tm, 12),
        U32.sub(D.Date.to_days(end), D.Date.to_days(start2))
      )

def Period.between.ms.add(
  +start: D.Date, +end: D.Date, +tm: U32,
  rp: Result<&2, &2, Period.Error, Period>
) -> Result<&2, &2, Period.Error, Period>:
  match rp:
    case Fail{_}:
      Fail{OutOfRange{}}
    case Done{pM}:
      Period.between.ms.from(end, tm, Period.add_to(pM, start))

def Period.between.ms(
  +start: D.Date, +end: D.Date, +tm: U32
) -> Result<&2, &2, Period.Error, Period>:
  Period.between.ms.add(start, end, tm, Period.from(0, tm, 0))

def Period.between.day(
  start: D.Date, end: D.Date, sm: U32, em: U32, borrow: Bool
) -> Result<&2, &2, Period.Error, Period>:
  match borrow:
    case True{}:
      Period.between.ms(start, end, U32.sub(U32.sub(em, sm), 1))
    case False{}:
      Period.between.ms(start, end, U32.sub(em, sm))

def Period.between.go(
  +start: D.Date, +end: D.Date
) -> Result<&2, &2, Period.Error, Period>:
  match start end:
    case D.Date{+sy, +sm, +sd} D.Date{+ey, +em, +ed}:
      Period.between.day(
        start, end,
        Period.emonth(sy, sm), Period.emonth(ey, em),
        U32.is_lt(ed, sd)
      )

def Period.between.ord(
  start: D.Date, end: D.Date, lt: Bool
) -> Result<&2, &2, Period.Error, Period>:
  match lt:
    case True{}:
      Fail{OutOfRange{}}
    case False{}:
      Period.between.go(start, end)

def Period.between(
  +start: D.Date, +end: D.Date
) -> Result<&2, &2, Period.Error, Period>:
  Period.between.ord(start, end, D.Date.is_lt(end, start))
