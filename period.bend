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
