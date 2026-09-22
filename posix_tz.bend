import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT

type Posix.Error is Data:
  Invalid{}
  Unsupported{}
  OutOfRange{}

type Posix.Rule is Data:
  RuleM{month: U32, week: U32, wday: U32, hour: U32}

type Posix.Tz is Data:
  TzStd{off: DT.UtcOffset}
  TzDst{
    std: DT.UtcOffset,
    dst: DT.UtcOffset,
    start: Posix.Rule,
    end: Posix.Rule
  }

type Posix.NameP is Data:
  NameP{rest: String, off: Nat}

type Posix.OffP is Data:
  OffP{off: DT.UtcOffset, rest: String, offn: Nat}

type Posix.RuleP is Data:
  RuleP{rule: Posix.Rule, rest: String, offn: Nat}

type Posix.NumP is Data:
  NumP{n: U32, rest: String, offn: Nat}

def Posix.eqc(+a: Char, +b: Char) -> Bool:
  U32.is_eq(Char.to_u32(a), Char.to_u32(b))

def Posix.alpha(+c: Char) -> Bool:
  Bool.and(U32.is_ge(Char.to_u32(c), 65), U32.is_le(Char.to_u32(c), 90))

def Posix.digit(+c: Char) -> Bool:
  Bool.and(U32.is_ge(Char.to_u32(c), 48), U32.is_le(Char.to_u32(c), 57))

def Posix.dval(+c: Char) -> U32:
  U32.sub(Char.to_u32(c), 48)

def Posix.dst_default.west(+h: U32, z: Bool) -> Result<&2, &2, Posix.Error, DT.UtcOffset>:
  match z:
    case True{}:
      Done{DT.OffsetZero{}}
    case False{}:
      Done{DT.OffsetWest{U32.sub(h, 1), 0}}

def Posix.dst_default.east(+h: U32, ok: Bool) -> Result<&2, &2, Posix.Error, DT.UtcOffset>:
  match ok:
    case True{}:
      Done{DT.OffsetEast{U32.add(h, 1), 0}}
    case False{}:
      Fail{Unsupported{}}

def Posix.dst_default.east0(
  +h: U32, z: Bool
) -> Result<&2, &2, Posix.Error, DT.UtcOffset>:
  match z:
    case False{}:
      Fail{Unsupported{}}
    case True{}:
      Posix.dst_default.east(h, U32.is_lt(h, 23))

def Posix.dst_default.west0(
  +h: U32, z: Bool
) -> Result<&2, &2, Posix.Error, DT.UtcOffset>:
  match z:
    case False{}:
      Fail{Unsupported{}}
    case True{}:
      Posix.dst_default.west(h, U32.is_eq(h, 1))

def Posix.dst_default(
  std: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, DT.UtcOffset>:
  match std:
    case DT.OffsetZero{}:
      Done{DT.OffsetEast{1, 0}}
    case DT.OffsetEast{+h, +mi}:
      Posix.dst_default.east0(h, U32.is_eq(mi, 0))
    case DT.OffsetWest{+h, +mi}:
      Posix.dst_default.west0(h, U32.is_eq(mi, 0))


def Posix.parse.num.end(
  saw: Bool, s: String, offn: Nat, acc: U32
) -> Result<&2, &2, Posix.Error, Posix.NumP>:
  match saw:
    case False{}:
      Fail{Invalid{}}
    case True{}:
      Done{NumP{acc, s, offn}}

def Posix.parse.num.go(
  +s: String, offn: Nat, acc: U32, saw: Bool, z: Bool, +c: Char
) -> Result<&2, &2, Posix.Error, Posix.NumP>:
  match s:
    case SNil{}:
      match z:
        case False{}:
          Posix.parse.num.end(saw, SCon{c, SNil{}}, offn, acc)
        case True{}:
          Posix.parse.num.end(
            True{}, SNil{}, offn, U32.add(U32.mul(acc, 10), Posix.dval(c))
          )
    case SCon{c2, t}:
      match z:
        case False{}:
          Posix.parse.num.end(saw, SCon{c, s}, offn, acc)
        case True{}:
          Posix.parse.num.go(
            t, 1n+offn, U32.add(U32.mul(acc, 10), Posix.dval(c)), True{},
            Posix.digit(c2), c2
          )

def Posix.parse.num(
  +s: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.NumP>:
  match s:
    case SNil{}:
      Fail{Invalid{}}
    case SCon{+c, t}:
      Posix.parse.num.go(t, 1n+offn, 0, False{}, Posix.digit(c), c)

def Posix.parse.name.ok3(
  q: Nat, s: String, off: Nat
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  match q:
    case 0n:
      Fail{Invalid{}}
    case 1n+_:
      Done{NameP{s, off}}

def Posix.parse.name.ok2(
  p: Nat, s: String, off: Nat
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  match p:
    case 0n:
      Fail{Invalid{}}
    case 1n+q:
      Posix.parse.name.ok3(q, s, off)

def Posix.parse.name.ok(
  n: Nat, s: String, off: Nat
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  match n:
    case 0n:
      Fail{Invalid{}}
    case 1n+p:
      Posix.parse.name.ok2(p, s, off)

def Posix.parse.name.fin(
  n: Nat, s: String, off: Nat
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  Posix.parse.name.ok(n, s, off)

def Posix.parse.q.go(
  +s: String, n: Nat, off: Nat, gt: Bool, +c: Char
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  match s:
    case SNil{}:
      match gt:
        case True{}:
          Posix.parse.name.fin(n, s, off)
        case False{}:
          Fail{Invalid{}}
    case SCon{c2, t}:
      match gt:
        case True{}:
          Posix.parse.name.fin(n, s, off)
        case False{}:
          Posix.parse.q.go(t, 1n+n, 1n+off, Posix.eqc(c2, '>'), c2)

def Posix.parse.q.start(
  +s: String, off: Nat
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  match s:
    case SNil{}:
      Fail{Invalid{}}
    case SCon{+c, t}:
      Posix.parse.q.go(t, 0n, 1n+off, Posix.eqc(c, '>'), c)

def Posix.parse.name.go(
  +s: String, n: Nat, off: Nat, z: Bool, +c: Char
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  match s:
    case SNil{}:
      match z:
        case False{}:
          Posix.parse.name.fin(n, SCon{c, SNil{}}, off)
        case True{}:
          Posix.parse.name.fin(1n+n, SNil{}, 1n+off)
    case SCon{c2, t}:
      match z:
        case False{}:
          Posix.parse.name.fin(n, SCon{c, s}, off)
        case True{}:
          Posix.parse.name.go(t, 1n+n, 1n+off, Posix.alpha(c2), c2)

def Posix.parse.name.q(
  q: Bool, t: String, off: Nat, +c: Char
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  match q:
    case True{}:
      Posix.parse.q.start(t, off)
    case False{}:
      Posix.parse.name.go(t, 0n, off, Posix.alpha(c), c)

def Posix.parse.name.head(
  +s: String, off: Nat
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  match s:
    case SNil{}:
      Fail{Invalid{}}
    case SCon{+c, t}:
      Posix.parse.name.q(Posix.eqc(c, '<'), t, 1n+off, c)

def Posix.parse.name(
  s: String, off: Nat
) -> Result<&2, &2, Posix.Error, Posix.NameP>:
  Posix.parse.name.head(s, off)

def Posix.parse.off.map(
  r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>
) -> Result<&2, &2, Posix.Error, DT.UtcOffset>:
  match r:
    case Fail{_}:
      Fail{Invalid{}}
    case Done{o}:
      Done{o}

def Posix.parse.off.signed(
  east: Bool, +h: U32
) -> Result<&2, &2, Posix.Error, DT.UtcOffset>:
  match east:
    case True{}:
      Posix.parse.off.map(DT.UtcOffset.from(False{}, h, 0))
    case False{}:
      Posix.parse.off.map(DT.UtcOffset.from(True{}, h, 0))

def Posix.parse.off.mk(
  east: Bool, +h: U32, z: Bool
) -> Result<&2, &2, Posix.Error, DT.UtcOffset>:
  match z:
    case True{}:
      Done{DT.OffsetZero{}}
    case False{}:
      Posix.parse.off.signed(east, h)

def Posix.parse.off.hi(
  east: Bool, +h: U32, ok: Bool
) -> Result<&2, &2, Posix.Error, DT.UtcOffset>:
  match ok:
    case False{}:
      Fail{Invalid{}}
    case True{}:
      Posix.parse.off.mk(east, h, U32.is_eq(h, 0))

def Posix.parse.off.pack.r(
  r: Result<&2, &2, Posix.Error, DT.UtcOffset>, s: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{o}:
      Done{OffP{o, s, offn}}

def Posix.parse.off.pack(
  east: Bool, +h: U32, s: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  Posix.parse.off.pack.r(Posix.parse.off.hi(east, h, U32.is_le(h, 23)), s, offn)

def Posix.parse.hours.colon(
  +s: String, offn: Nat, east: Bool, +h: U32, colon: Bool
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  match colon:
    case True{}:
      Fail{Unsupported{}}
    case False{}:
      Posix.parse.off.pack(east, h, s, offn)

def Posix.parse.hours.d(
  dig: Bool, +s: String, t: String, offn: Nat, east: Bool, +h: U32, +c: Char
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  match dig:
    case True{}:
      Posix.parse.hours.colon(
        t, 1n+offn, east, U32.add(U32.mul(h, 10), Posix.dval(c)), False{}
      )
    case False{}:
      Posix.parse.hours.colon(s, offn, east, h, Posix.eqc(c, ':'))

def Posix.parse.hours.more(
  +s: String, offn: Nat, east: Bool, +h: U32
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  match s:
    case SNil{}:
      Posix.parse.off.pack(east, h, s, offn)
    case SCon{+c, t}:
      Posix.parse.hours.d(Posix.digit(c), s, t, offn, east, h, c)

def Posix.parse.hours.lead(
  dig: Bool, colon: Bool, t: String, offn: Nat, east: Bool, +c: Char
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  match dig:
    case True{}:
      Posix.parse.hours.more(t, 1n+offn, east, Posix.dval(c))
    case False{}:
      match colon:
        case True{}:
          Fail{Unsupported{}}
        case False{}:
          Fail{Invalid{}}

def Posix.parse.hours(
  s: String, offn: Nat, east: Bool
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  match s:
    case SNil{}:
      Fail{Invalid{}}
    case SCon{+c, t}:
      Posix.parse.hours.lead(Posix.digit(c), Posix.eqc(c, ':'), t, offn, east, c)

def Posix.parse.sign.plus(
  plus: Bool, +s: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  match plus:
    case True{}:
      match s:
        case SNil{}:
          Fail{Invalid{}}
        case SCon{_, t}:
          Posix.parse.hours(t, 1n+offn, False{})
    case False{}:
      Posix.parse.hours(s, offn, False{})

def Posix.parse.sign.m(
  minus: Bool, +s: String, t: String, offn: Nat, +c: Char
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  match minus:
    case True{}:
      Posix.parse.hours(t, 1n+offn, True{})
    case False{}:
      Posix.parse.sign.plus(Posix.eqc(c, '+'), s, offn)

def Posix.parse.sign(
  +s: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  match s:
    case SNil{}:
      Fail{Invalid{}}
    case SCon{+c, t}:
      Posix.parse.sign.m(Posix.eqc(c, '-'), s, t, offn, c)

def Posix.parse.offset(
  s: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.OffP>:
  Posix.parse.sign(s, offn)

def Posix.parse.dot.c(
  is_dot: Bool, n: U32, t: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.NumP>:
  match is_dot:
    case True{}:
      Done{NumP{n, t, 1n+offn}}
    case False{}:
      Fail{Invalid{}}

def Posix.parse.dot(
  r: Result<&2, &2, Posix.Error, Posix.NumP>
) -> Result<&2, &2, Posix.Error, Posix.NumP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{NumP{n, rest, offn}}:
      match rest:
        case SCon{+c, t}:
          Posix.parse.dot.c(Posix.eqc(c, '.'), n, t, offn)
        case SNil{}:
          Fail{Invalid{}}

def Posix.parse.range(
  +n: U32, +lo: U32, +hi: U32, ok: Bool
) -> Result<&2, &2, Posix.Error, U32>:
  match ok:
    case True{}:
      Done{n}
    case False{}:
      Fail{Invalid{}}

def Posix.parse.bound(
  +n: U32, +lo: U32, +hi: U32
) -> Result<&2, &2, Posix.Error, U32>:
  Posix.parse.range(
    n, lo, hi, Bool.and(U32.is_ge(n, lo), U32.is_le(n, hi))
  )

def Posix.parse.hour.ok(
  ok: Bool, +h: U32, s: String, offn: Nat, +month: U32, +week: U32, +wday: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match ok:
    case True{}:
      Done{RuleP{RuleM{month, week, wday, h}, s, offn}}
    case False{}:
      Fail{Unsupported{}}

def Posix.parse.hour.col(
  colon: Bool, +s: String, offn: Nat, +h: U32, +month: U32, +week: U32,
  +wday: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match colon:
    case True{}:
      Fail{Unsupported{}}
    case False{}:
      Posix.parse.hour.ok(U32.is_le(h, 23), h, s, offn, month, week, wday)

def Posix.parse.hour.colon(
  +s: String, offn: Nat, +h: U32, +month: U32, +week: U32, +wday: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match s:
    case SCon{+c, _}:
      Posix.parse.hour.col(Posix.eqc(c, ':'), s, offn, h, month, week, wday)
    case SNil{}:
      Posix.parse.hour.ok(U32.is_le(h, 23), h, s, offn, month, week, wday)

def Posix.parse.hour.num(
  r: Result<&2, &2, Posix.Error, Posix.NumP>,
  +month: U32, +week: U32, +wday: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{NumP{h, rest, offn}}:
      Posix.parse.hour.colon(rest, offn, h, month, week, wday)

def Posix.parse.slash.c(
  slash: Bool, +s: String, t: String, offn: Nat, +month: U32, +week: U32,
  +wday: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match slash:
    case True{}:
      Posix.parse.hour.num(Posix.parse.num(t, 1n+offn), month, week, wday)
    case False{}:
      Done{RuleP{RuleM{month, week, wday, 2}, s, offn}}

def Posix.parse.slash(
  +s: String, offn: Nat, +month: U32, +week: U32, +wday: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match s:
    case SCon{+c, t}:
      Posix.parse.slash.c(Posix.eqc(c, '/'), s, t, offn, month, week, wday)
    case SNil{}:
      Done{RuleP{RuleM{month, week, wday, 2}, s, offn}}

def Posix.parse.wday.go(
  r: Result<&2, &2, Posix.Error, U32>, rest: String, offn: Nat, +month: U32,
  +week: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{wday}:
      Posix.parse.slash(rest, offn, month, week, wday)

def Posix.parse.wday(
  r: Result<&2, &2, Posix.Error, Posix.NumP>, +month: U32, +week: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{NumP{d, rest, offn}}:
      Posix.parse.wday.go(Posix.parse.bound(d, 0, 6), rest, offn, month, week)

def Posix.parse.dot_then_num.go(
  r: Result<&2, &2, Posix.Error, Posix.NumP>
) -> Result<&2, &2, Posix.Error, Posix.NumP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{NumP{_, rest, offn}}:
      Posix.parse.num(rest, offn)

def Posix.parse.dot_then_num(
  s: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.NumP>:
  Posix.parse.dot_then_num.go(Posix.parse.dot(Done{NumP{0, s, offn}}))

def Posix.parse.week.go(
  r: Result<&2, &2, Posix.Error, U32>, rest: String, offn: Nat, +month: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{week}:
      Posix.parse.wday(Posix.parse.dot_then_num(rest, offn), month, week)

def Posix.parse.week(
  r: Result<&2, &2, Posix.Error, Posix.NumP>, +month: U32
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{NumP{n, rest, offn}}:
      Posix.parse.week.go(Posix.parse.bound(n, 1, 5), rest, offn, month)

def Posix.parse.month.go(
  r: Result<&2, &2, Posix.Error, U32>, rest: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{month}:
      Posix.parse.week(Posix.parse.num(rest, offn), month)

def Posix.parse.month(
  r: Result<&2, &2, Posix.Error, Posix.NumP>
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{NumP{m, rest, offn}}:
      Posix.parse.month.go(Posix.parse.bound(m, 1, 12), rest, offn)

def Posix.parse.rule.m(
  s: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  Posix.parse.month(Posix.parse.dot(Posix.parse.num(s, offn)))

def Posix.parse.rule.j(
  is_j: Bool, dig: Bool
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match is_j:
    case True{}:
      Fail{Unsupported{}}
    case False{}:
      match dig:
        case True{}:
          Fail{Unsupported{}}
        case False{}:
          Fail{Invalid{}}

def Posix.parse.rule.kind(
  is_m: Bool, t: String, offn: Nat, +c: Char
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match is_m:
    case True{}:
      Posix.parse.rule.m(t, 1n+offn)
    case False{}:
      Posix.parse.rule.j(Posix.eqc(c, 'J'), Posix.digit(c))

def Posix.parse.rule(
  +s: String, offn: Nat
) -> Result<&2, &2, Posix.Error, Posix.RuleP>:
  match s:
    case SNil{}:
      Fail{Invalid{}}
    case SCon{+c, t}:
      Posix.parse.rule.kind(Posix.eqc(c, 'M'), t, offn, c)

def Posix.parse.end2(
  r: Result<&2, &2, Posix.Error, Posix.RuleP>, std: DT.UtcOffset,
  dst: DT.UtcOffset, start: Posix.Rule
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{RuleP{end, rest, _}}:
      match rest:
        case SNil{}:
          Done{TzDst{std, dst, start, end}}
        case SCon{_, _}:
          Fail{Invalid{}}

def Posix.parse.end(
  comma: Bool, +s: String, offn: Nat, std: DT.UtcOffset, dst: DT.UtcOffset,
  start: Posix.Rule
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match comma:
    case False{}:
      Fail{Invalid{}}
    case True{}:
      match s:
        case SNil{}:
          Fail{Invalid{}}
        case SCon{_, t}:
          Posix.parse.end2(Posix.parse.rule(t, 1n+offn), std, dst, start)

def Posix.parse.start3(
  +rest: String, start: Posix.Rule, offn: Nat, std: DT.UtcOffset,
  dst: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match rest:
    case SNil{}:
      Fail{Invalid{}}
    case SCon{+c, _}:
      Posix.parse.end(Posix.eqc(c, ','), rest, offn, std, dst, start)

def Posix.parse.start2(
  r: Result<&2, &2, Posix.Error, Posix.RuleP>, std: DT.UtcOffset,
  dst: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{RuleP{start, rest, offn}}:
      Posix.parse.start3(rest, start, offn, std, dst)

def Posix.parse.rules(
  s: String, offn: Nat, std: DT.UtcOffset, dst: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  Posix.parse.start2(Posix.parse.rule(s, offn), std, dst)

def Posix.parse.dst.comma(
  comma: Bool, t: String, offn: Nat, std: DT.UtcOffset, dst: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match comma:
    case True{}:
      Posix.parse.rules(t, 1n+offn, std, dst)
    case False{}:
      Fail{Invalid{}}

def Posix.parse.dst.off(
  r: Result<&2, &2, Posix.Error, Posix.OffP>, std: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{OffP{dst, rest, offn}}:
      match rest:
        case SNil{}:
          Fail{Invalid{}}
        case SCon{+c, t}:
          Posix.parse.dst.comma(Posix.eqc(c, ','), t, offn, std, dst)

def Posix.parse.dst.def(
  r: Result<&2, &2, Posix.Error, DT.UtcOffset>, s: String, offn: Nat,
  std: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{dst}:
      Posix.parse.rules(s, offn, std, dst)

def Posix.parse.dst.body.c(
  comma: Bool, +s: String, t: String, offn: Nat, +std: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match comma:
    case True{}:
      Posix.parse.dst.def(Posix.dst_default(std), t, 1n+offn, std)
    case False{}:
      Posix.parse.dst.off(Posix.parse.offset(s, offn), std)

def Posix.parse.dst.body(
  +s: String, offn: Nat, std: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match s:
    case SNil{}:
      Fail{Invalid{}}
    case SCon{+c, t}:
      Posix.parse.dst.body.c(Posix.eqc(c, ','), s, t, offn, std)

def Posix.parse.dst(
  r: Result<&2, &2, Posix.Error, Posix.NameP>, std: DT.UtcOffset
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{NameP{rest, off}}:
      Posix.parse.dst.body(rest, off, std)

def Posix.parse.tail(
  r: Result<&2, &2, Posix.Error, Posix.OffP>
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{OffP{std, rest, offn}}:
      match rest:
        case SNil{}:
          Done{TzStd{std}}
        case SCon{_, _}:
          Posix.parse.dst(Posix.parse.name(rest, offn), std)

def Posix.parse.after_name(
  r: Result<&2, &2, Posix.Error, Posix.NameP>
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{NameP{rest, off}}:
      Posix.parse.tail(Posix.parse.offset(rest, off))

def Posix.parse(
  s: String
) -> Result<&2, &2, Posix.Error, Posix.Tz>:
  Posix.parse.after_name(Posix.parse.name(s, 0n))
