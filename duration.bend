import Base

type Duration.Error is Data:
  OutOfRange{}

type Duration is Data:
  Duration{days: U32, sod: U32, nanos: U32}

def Duration.zero() -> Duration:
  Duration{0, 0, 0}

def Duration.fit(+days: U32, +sod: U32) -> Bool:
  Bool.or(
    U32.is_lt(days, 49710),
    Bool.and(U32.is_eq(days, 49710), U32.is_le(sod, 23295))
  )

def Duration.to_secs.add(
  +days: U32, +sod: U32, ok: Bool
) -> Result<&2, &2, Duration.Error, U32>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Done{U32.add(U32.mul(days, 86400), sod)}

def Duration.to_secs(d: Duration) -> Result<&2, &2, Duration.Error, U32>:
  match d:
    case Duration{+days, +sod, _}:
      Duration.to_secs.add(days, sod, Duration.fit(days, sod))

def Duration.from_secs(+secs: U32) -> Duration:
  Duration{U32.div(secs, 86400), U32.mod(secs, 86400), 0}

def Duration.from_hms.s2(
  +sec: U32, +s: U32, ok: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Done{Duration.from_secs(U32.add(sec, s))}

def Duration.from_hms.s(
  +sec: U32, +s: U32
) -> Result<&2, &2, Duration.Error, Duration>:
  Duration.from_hms.s2(sec, s, U32.is_le(s, U32.sub(U32.not(0), sec)))

def Duration.from_hms.hm2(
  +hsec: U32, +msec: U32, +s: U32, ok: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Duration.from_hms.s(U32.add(hsec, msec), s)

def Duration.from_hms.hm(
  +hsec: U32, +mi: U32, +s: U32
) -> Result<&2, &2, Duration.Error, Duration>:
  +msec = U32.mul(mi, 60)
  Duration.from_hms.hm2(
    hsec, msec, s, U32.is_le(msec, U32.sub(U32.not(0), hsec))
  )

def Duration.from_hms.h(
  +h: U32, +mi: U32, +s: U32, ok: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Duration.from_hms.hm(U32.mul(h, 3600), mi, s)

def Duration.from_hms.r(
  +h: U32, +mi: U32, +s: U32, ok: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Duration.from_hms.h(
        h, mi, s, U32.is_le(h, U32.div(U32.not(0), 3600))
      )

def Duration.from_hms(
  +h: U32, +mi: U32, +s: U32
) -> Result<&2, &2, Duration.Error, Duration>:
  Duration.from_hms.r(
    h, mi, s, Bool.and(U32.is_le(mi, 59), U32.is_le(s, 59))
  )

def Duration.is_eq(a: Duration, b: Duration) -> Bool:
  match a b:
    case Duration{+d1, +s1, +n1} Duration{+d2, +s2, +n2}:
      Bool.and(
        U32.is_eq(d1, d2),
        Bool.and(U32.is_eq(s1, s2), U32.is_eq(n1, n2))
      )

def Duration.is_lt.n(+n1: U32, +n2: U32, eq_s: Bool, slt: Bool) -> Bool:
  match eq_s:
    case False{}:
      slt
    case True{}:
      U32.is_lt(n1, n2)

def Duration.is_lt.s(
  +s1: U32, +n1: U32, +s2: U32, +n2: U32, eq_d: Bool, dlt: Bool
) -> Bool:
  match eq_d:
    case False{}:
      dlt
    case True{}:
      Duration.is_lt.n(n1, n2, U32.is_eq(s1, s2), U32.is_lt(s1, s2))

def Duration.is_lt(a: Duration, b: Duration) -> Bool:
  match a b:
    case Duration{+d1, +s1, +n1} Duration{+d2, +s2, +n2}:
      Duration.is_lt.s(
        s1, n1, s2, n2, U32.is_eq(d1, d2), U32.is_lt(d1, d2)
      )

def Duration.is_gt(a: Duration, b: Duration) -> Bool:
  Duration.is_lt(b, a)

def Duration.is_le(a: Duration, b: Duration) -> Bool:
  Bool.not(Duration.is_lt(b, a))

def Duration.is_ge(a: Duration, b: Duration) -> Bool:
  Bool.not(Duration.is_lt(a, b))

def Duration.add.days(
  +d1: U32, +d2: U32, +sod: U32, +nanos: U32, carry: U32, ok: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Done{Duration{U32.add(U32.add(d1, d2), carry), sod, nanos}}

def Duration.add.sod2(
  +d1: U32, +d2: U32, +sod: U32, +nanos: U32, ge: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match ge:
    case False{}:
      Duration.add.days(
        d1, d2, sod, nanos, 0, U32.is_le(d2, U32.sub(U32.not(0), d1))
      )
    case True{}:
      Duration.add.days(
        d1, d2, U32.sub(sod, 86400), nanos, 1,
        U32.is_le(U32.add(d2, 1), U32.sub(U32.not(0), d1))
      )

def Duration.add.sod(
  +d1: U32, +d2: U32, +s1: U32, +s2: U32, +nanos: U32, nc: U32
) -> Result<&2, &2, Duration.Error, Duration>:
  +sod = U32.add(U32.add(s1, s2), nc)
  Duration.add.sod2(d1, d2, sod, nanos, U32.is_ge(sod, 86400))

def Duration.add.n2(
  +d1: U32, +d2: U32, +s1: U32, +s2: U32, +ns: U32, ge: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match ge:
    case False{}:
      Duration.add.sod(d1, d2, s1, s2, ns, 0)
    case True{}:
      Duration.add.sod(d1, d2, s1, s2, U32.sub(ns, 1000000000), 1)

def Duration.add.n(
  +d1: U32, +d2: U32, +s1: U32, +s2: U32, +n1: U32, +n2: U32
) -> Result<&2, &2, Duration.Error, Duration>:
  +ns = U32.add(n1, n2)
  Duration.add.n2(d1, d2, s1, s2, ns, U32.is_ge(ns, 1000000000))

def Duration.add(
  a: Duration, b: Duration
) -> Result<&2, &2, Duration.Error, Duration>:
  match a b:
    case Duration{d1, s1, n1} Duration{d2, s2, n2}:
      Duration.add.n(d1, d2, s1, s2, n1, n2)

def Duration.sub.days(
  +days: U32, +sod: U32, +nanos: U32, +b_days: U32, ok: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match ok:
    case False{}:
      Fail{OutOfRange{}}
    case True{}:
      Done{Duration{U32.sub(days, b_days), sod, nanos}}

def Duration.sub.s2(
  +days: U32, +sod: U32, +nanos: U32, +b_days: U32, +b_sod: U32, borrow: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match borrow:
    case False{}:
      Duration.sub.days(days, U32.sub(sod, b_sod), nanos, b_days, U32.is_ge(days, b_days))
    case True{}:
      Duration.sub.days(
        U32.sub(days, 1), U32.sub(U32.add(sod, 86400), b_sod), nanos, b_days,
        U32.is_ge(days, U32.add(b_days, 1))
      )

def Duration.sub.s(
  +days: U32, +sod: U32, +nanos: U32, +b_days: U32, +b_sod: U32
) -> Result<&2, &2, Duration.Error, Duration>:
  Duration.sub.s2(days, sod, nanos, b_days, b_sod, U32.is_lt(sod, b_sod))

def Duration.sub.n2(
  +days: U32, +sod: U32, +n1: U32, +b_days: U32, +b_sod: U32, +b_n: U32, borrow: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match borrow:
    case False{}:
      Duration.sub.s(days, sod, U32.sub(n1, b_n), b_days, b_sod)
    case True{}:
      Duration.sub.s(
        days, sod, U32.sub(U32.add(n1, 1000000000), b_n), b_days, b_sod
      )

def Duration.sub.n0(
  +days: U32, +n1: U32, +b_days: U32, +b_sod: U32, +b_n: U32, zdays: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match zdays:
    case True{}:
      Fail{OutOfRange{}}
    case False{}:
      Duration.sub.s(
        U32.sub(days, 1), 86399, U32.sub(U32.add(n1, 1000000000), b_n),
        b_days, b_sod
      )

def Duration.sub.n2b(
  +days: U32, +sod: U32, +n1: U32, +b_days: U32, +b_sod: U32, +b_n: U32, borrow: Bool, z: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match borrow z:
    case True{} True{}:
      Duration.sub.n0(days, n1, b_days, b_sod, b_n, U32.is_eq(days, 0))
    case True{} False{}:
      Duration.sub.n2(days, U32.sub(sod, 1), n1, b_days, b_sod, b_n, True{})
    case False{} True{}:
      Duration.sub.n2(days, sod, n1, b_days, b_sod, b_n, False{})
    case False{} False{}:
      Duration.sub.n2(days, sod, n1, b_days, b_sod, b_n, False{})

def Duration.sub.n(
  +days: U32, +sod: U32, +n1: U32, +b_days: U32, +b_sod: U32, +b_n: U32
) -> Result<&2, &2, Duration.Error, Duration>:
  +borrow = U32.is_lt(n1, b_n)
  Duration.sub.n2b(days, sod, n1, b_days, b_sod, b_n, borrow, U32.is_eq(sod, 0))

def Duration.sub.go(a: Duration, b: Duration) -> Result<&2, &2, Duration.Error, Duration>:
  match a b:
    case Duration{d1, s1, n1} Duration{d2, s2, n2}:
      Duration.sub.n(d1, s1, n1, d2, s2, n2)

def Duration.sub.lt(
  a: Duration, b: Duration, lt: Bool
) -> Result<&2, &2, Duration.Error, Duration>:
  match lt:
    case True{}:
      Fail{OutOfRange{}}
    case False{}:
      Duration.sub.go(a, b)

def Duration.sub(
  +a: Duration, +b: Duration
) -> Result<&2, &2, Duration.Error, Duration>:
  Duration.sub.lt(a, b, Duration.is_lt(a, b))
