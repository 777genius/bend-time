import Base
import 0xe49a3e6521e1b71e55654a885f27bcc1/parse.bend as P
import ./duration.bend as Dur
import ./period.bend as Per
type Iso8601.Error is Data:
  Unexpected{offset: Nat, char: Char}
  Eof{offset: Nat}
  Overflow{offset: Nat}
  Extra{offset: Nat, char: Char}
  Invalid{}
type Iso8601.DurS is Data:
  DurS{
    days: U32, h: U32, mi: U32, s: U32, nanos: U32,
    saw_d: Bool, saw_t: Bool, saw_h: Bool, saw_m: Bool, saw_s: Bool
  }
type Iso8601.DurM is Data:
  DSeek{}
  DNum{acc: U32}
  DFrac{sec: U32, acc: U32, left: Nat}
type Iso8601.DurC is Data:
  DurFail{e: Iso8601.Error}
  DurCont{st: Iso8601.DurS, mode: Iso8601.DurM}
type Iso8601.PerS is Data:
  PerS{
    years: U32, months: U32, days: U32,
    saw_y: Bool, saw_m: Bool, saw_w: Bool, saw_d: Bool
  }
type Iso8601.PerM is Data:
  PSeek{}
  PNum{acc: U32}
type Iso8601.PerC is Data:
  PerFail{e: Iso8601.Error}
  PerCont{st: Iso8601.PerS, mode: Iso8601.PerM}
def Iso8601.from_parse(e: P.Parse.Error) -> Iso8601.Error:
  match e:
    case P.Unexpected{offset, char}:
      Unexpected{offset, char}
    case P.Eof{offset}:
      Eof{offset}
    case P.Overflow{offset}:
      Overflow{offset}
    case P.Extra{offset, char}:
      Extra{offset, char}
def Iso8601.digit(n: U32) -> Char:
  Char.from_u32((Char.to_u32('0') + n : U32))
def Iso8601.pad_n.go(k: Nat, +n: U32, acc: String) -> String:
  match k:
    case 0n:
      acc
    case 1n++p:
      Iso8601.pad_n.go(
        p, U32.div(n, 10), SCon{Iso8601.digit(U32.mod(n, 10)), acc}
      )
def Iso8601.pad_n(n: U32, k: Nat) -> String:
  Iso8601.pad_n.go(k, n, SNil{})
def Iso8601.lead0(s: String) -> Bool:
  match s:
    case SNil{}:
      False{}
    case SCon{h, _}:
      Char.is_eq(h, '0')
def Iso8601.strip0(k: Nat, s: String, z: Bool) -> String:
  match k:
    case 0n:
      SCon{'0', SNil{}}
    case 1n++p:
      match s:
        case SNil{}:
          SCon{'0', SNil{}}
        case SCon{+h, +t}:
          match z:
            case False{}:
              SCon{h, t}
            case True{}:
              Iso8601.strip0(p, t, Iso8601.lead0(t))
def Iso8601.show_u32(+n: U32) -> String:
  +s = Iso8601.pad_n(n, 10n)
  Iso8601.strip0(10n, s, Iso8601.lead0(s))
def Iso8601.show.unit.go(+n: U32, c: Char, z: Bool) -> String:
  match z:
    case True{}:
      SNil{}
    case False{}:
      String.append(Iso8601.show_u32(n), SCon{c, SNil{}})
def Iso8601.show.unit(+n: U32, c: Char) -> String:
  Iso8601.show.unit.go(n, c, U32.is_eq(n, 0))
def Iso8601.frac.strip.go(+k: Nat, +n: U32, z: Bool) -> U32 & Nat:
  match k:
    case 0n:
      (n, 1n)
    case 1n:
      (n, 1n)
    case 1n++p:
      match z:
        case True{}:
          Iso8601.frac.strip.go(
            p, U32.div(n, 10), U32.is_eq(U32.mod(U32.div(n, 10), 10), 0)
          )
        case False{}:
          (n, k)
def Iso8601.frac.strip(+n: U32, k: Nat) -> U32 & Nat:
  Iso8601.frac.strip.go(k, n, U32.is_eq(U32.mod(n, 10), 0))
def Iso8601.show.frac2(nk: U32 & Nat) -> String:
  (n, k) = nk
  Iso8601.pad_n(n, k)
def Iso8601.show.frac(+nanos: U32) -> String:
  Iso8601.show.frac2(Iso8601.frac.strip(nanos, 9n))
def Iso8601.show.s2(+s: U32, +nanos: U32, z: Bool) -> String:
  match z:
    case True{}:
      String.append(Iso8601.show_u32(s), "S")
    case False{}:
      String.append(
        Iso8601.show_u32(s),
        String.append(".", String.append(Iso8601.show.frac(nanos), "S"))
      )
def Iso8601.show.s(+s: U32, +nanos: U32, need: Bool) -> String:
  match need:
    case False{}:
      SNil{}
    case True{}:
      Iso8601.show.s2(s, nanos, U32.is_eq(nanos, 0))
def Iso8601.show.t(
  +h: U32, +mi: U32, +s: U32, +nanos: U32
) -> String:
  String.append(
    Iso8601.show.unit(h, 'H'),
    String.append(
      Iso8601.show.unit(mi, 'M'),
      Iso8601.show.s(s, nanos, Bool.or(U32.is_gt(s, 0), U32.is_gt(nanos, 0)))
    )
  )
def Iso8601.show_duration.go(
  +days: U32, +h: U32, +mi: U32, +s: U32, +nanos: U32, has_d: Bool, has_t: Bool
) -> String:
  match has_d has_t:
    case False{} False{}:
      "PT0S"
    case True{} False{}:
      String.append("P", String.append(Iso8601.show_u32(days), "D"))
    case False{} True{}:
      String.append("PT", Iso8601.show.t(h, mi, s, nanos))
    case True{} True{}:
      String.append(
        "P",
        String.append(
          Iso8601.show_u32(days),
          String.append("DT", Iso8601.show.t(h, mi, s, nanos))
        )
      )
def Iso8601.show_duration.has(
  +days: U32, +h: U32, +mi: U32, +s: U32, +nanos: U32
) -> String:
  Iso8601.show_duration.go(
    days, h, mi, s, nanos,
    U32.is_gt(days, 0),
    Bool.or(
      U32.is_gt(h, 0),
      Bool.or(
        U32.is_gt(mi, 0),
        Bool.or(U32.is_gt(s, 0), U32.is_gt(nanos, 0))
      )
    )
  )
def Iso8601.show_duration(d: Dur.Duration) -> String:
  match d:
    case Dur.Duration{+days, +sod, +nanos}:
      Iso8601.show_duration.has(
        days,
        U32.div(sod, 3600),
        U32.div(U32.mod(sod, 3600), 60),
        U32.mod(sod, 60),
        nanos
      )
def Iso8601.show_period.body(+y: U32, +m: U32, +d: U32) -> String:
  String.append(
    Iso8601.show.unit(y, 'Y'),
    String.append(Iso8601.show.unit(m, 'M'), Iso8601.show.unit(d, 'D'))
  )
def Iso8601.show_period.p(body: String) -> String:
  match body:
    case SNil{}:
      "P0D"
    case SCon{_, _}:
      String.append("P", body)
def Iso8601.show_period(p: Per.Period) -> String:
  match p:
    case Per.Period{+y, +m, +d}:
      Iso8601.show_period.p(Iso8601.show_period.body(y, m, d))
def Iso8601.dur0() -> Iso8601.DurS:
  DurS{0, 0, 0, 0, 0, False{}, False{}, False{}, False{}, False{}}
def Iso8601.per0() -> Iso8601.PerS:
  PerS{0, 0, 0, False{}, False{}, False{}, False{}}
def Iso8601.or3(+a: Bool, +b: Bool, +c: Bool) -> Bool:
  Bool.or(a, Bool.or(b, c))
def Iso8601.or4(+a: Bool, +b: Bool, +c: Bool, +d: Bool) -> Bool:
  Bool.or(a, Iso8601.or3(b, c, d))
def Iso8601.expect.map(
  r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Iso8601.Error, P.Parse.Cur>:
  match r:
    case Fail{e}:
      Fail{Iso8601.from_parse(e)}
    case Done{cur}:
      Done{cur}
def Iso8601.expect(
  cur: P.Parse.Cur, +c: Char
) -> Result<&2, &2, Iso8601.Error, P.Parse.Cur>:
  Iso8601.expect.map(P.Parse.expect_char(cur, c))
def Iso8601.dur.mk.ns2(
  r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match r:
    case Fail{_}:
      Fail{Invalid{}}
    case Done{d}:
      Done{d}
def Iso8601.dur.mk.ns(
  r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>, nanos: U32
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match r:
    case Fail{_}:
      Fail{Invalid{}}
    case Done{d}:
      Iso8601.dur.mk.ns2(Dur.Duration.add(d, Dur.Duration{0, 0, nanos}))
def Iso8601.dur.mk.s(
  r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>, +s: U32, nanos: U32
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match r:
    case Fail{_}:
      Fail{Invalid{}}
    case Done{d}:
      Iso8601.dur.mk.ns(Dur.Duration.add(d, Dur.Duration.from_secs(s)), nanos)
def Iso8601.dur.mk.mi2(
  d: Dur.Duration, rm: Result<&2, &2, Dur.Duration.Error, Dur.Duration>,
  s: U32, nanos: U32
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match rm:
    case Fail{_}:
      Fail{Invalid{}}
    case Done{dm}:
      Iso8601.dur.mk.s(Dur.Duration.add(d, dm), s, nanos)
def Iso8601.dur.mk.mi(
  r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>, +mi: U32, s: U32, nanos: U32
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match r:
    case Fail{_}:
      Fail{Invalid{}}
    case Done{d}:
      Iso8601.dur.mk.mi2(d, Dur.Duration.from_mins(mi), s, nanos)
def Iso8601.dur.mk.h2(
  d: Dur.Duration, rh: Result<&2, &2, Dur.Duration.Error, Dur.Duration>,
  mi: U32, s: U32, nanos: U32
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match rh:
    case Fail{_}:
      Fail{Invalid{}}
    case Done{dh}:
      Iso8601.dur.mk.mi(Dur.Duration.add(d, dh), mi, s, nanos)
def Iso8601.dur.mk.h(
  r: Result<&2, &2, Dur.Duration.Error, Dur.Duration>, +h: U32, mi: U32, s: U32, nanos: U32
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match r:
    case Fail{_}:
      Fail{Invalid{}}
    case Done{d}:
      Iso8601.dur.mk.h2(d, Dur.Duration.from_hours(h), mi, s, nanos)
def Iso8601.dur.mk(st: Iso8601.DurS) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match st:
    case DurS{+days, +h, +mi, +s, +nanos, _, _, _, _, _}:
      Iso8601.dur.mk.h(
        Done{Dur.Duration.from_days(days)}, h, mi, s, nanos
      )
def Iso8601.dur.valid3(
  st: Iso8601.DurS, has: Bool, tok: Bool
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match has:
    case False{}:
      Fail{Invalid{}}
    case True{}:
      match tok:
        case False{}:
          Fail{Invalid{}}
        case True{}:
          Iso8601.dur.mk(st)
def Iso8601.dur.valid(+st: Iso8601.DurS) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match st:
    case DurS{_, _, _, _, _, +saw_d, +saw_t, +saw_h, +saw_m, +saw_s}:
      Iso8601.dur.valid3(
        st,
        Iso8601.or4(saw_d, saw_h, saw_m, saw_s),
        Bool.or(Bool.not(saw_t), Iso8601.or3(saw_h, saw_m, saw_s))
      )
def Iso8601.dur.eof(
  st: Iso8601.DurS, mode: Iso8601.DurM
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match mode:
    case DSeek{}:
      Iso8601.dur.valid(st)
    case DNum{_}:
      Fail{Invalid{}}
    case DFrac{_, _, _}:
      Fail{Invalid{}}
def Iso8601.dur.put_t2(
  days: U32, h: U32, mi: U32, s: U32, nanos: U32,
  saw_d: Bool, saw_h: Bool, saw_m: Bool, saw_s: Bool, dup: Bool
) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match dup:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{DurS{days, h, mi, s, nanos, saw_d, True{}, saw_h, saw_m, saw_s}}
def Iso8601.dur.put_t(st: Iso8601.DurS) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match st:
    case DurS{days, h, mi, s, nanos, saw_d, +saw_t, saw_h, saw_m, saw_s}:
      Iso8601.dur.put_t2(
        days, h, mi, s, nanos, saw_d, saw_h, saw_m, saw_s, saw_t
      )
def Iso8601.dur.put_d2(
  n: U32, h: U32, mi: U32, s: U32, nanos: U32,
  saw_h: Bool, saw_m: Bool, saw_s: Bool, bad: Bool
) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match bad:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{DurS{n, h, mi, s, nanos, True{}, False{}, saw_h, saw_m, saw_s}}
def Iso8601.dur.put_d(
  st: Iso8601.DurS, n: U32
) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match st:
    case DurS{_, h, mi, s, nanos, +saw_d, +saw_t, saw_h, saw_m, saw_s}:
      Iso8601.dur.put_d2(
        n, h, mi, s, nanos, saw_h, saw_m, saw_s, Bool.or(saw_d, saw_t)
      )
def Iso8601.dur.put_h2(
  days: U32, n: U32, mi: U32, s: U32, nanos: U32,
  saw_d: Bool, saw_m: Bool, saw_s: Bool, bad: Bool
) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match bad:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{DurS{days, n, mi, s, nanos, saw_d, True{}, True{}, saw_m, saw_s}}
def Iso8601.dur.put_h(
  st: Iso8601.DurS, n: U32
) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match st:
    case DurS{days, _, mi, s, nanos, saw_d, +saw_t, +saw_h, +saw_m, +saw_s}:
      Iso8601.dur.put_h2(
        days, n, mi, s, nanos, saw_d, saw_m, saw_s,
        Bool.or(Bool.not(saw_t), Iso8601.or3(saw_h, saw_m, saw_s))
      )
def Iso8601.dur.put_m2(
  days: U32, h: U32, n: U32, s: U32, nanos: U32,
  saw_d: Bool, saw_h: Bool, saw_s: Bool, bad: Bool
) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match bad:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{DurS{days, h, n, s, nanos, saw_d, True{}, saw_h, True{}, saw_s}}
def Iso8601.dur.put_m(
  st: Iso8601.DurS, n: U32
) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match st:
    case DurS{days, h, _, s, nanos, saw_d, +saw_t, saw_h, +saw_m, +saw_s}:
      Iso8601.dur.put_m2(
        days, h, n, s, nanos, saw_d, saw_h, saw_s,
        Bool.or(Bool.not(saw_t), Bool.or(saw_m, saw_s))
      )
def Iso8601.dur.put_s2(
  days: U32, h: U32, mi: U32, n: U32, nanos: U32,
  saw_d: Bool, saw_h: Bool, saw_m: Bool, bad: Bool
) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match bad:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{DurS{days, h, mi, n, nanos, saw_d, True{}, saw_h, saw_m, True{}}}
def Iso8601.dur.put_s(
  st: Iso8601.DurS, n: U32, nanos: U32
) -> Result<&2, &2, Iso8601.Error, Iso8601.DurS>:
  match st:
    case DurS{days, h, mi, _, _, saw_d, +saw_t, saw_h, saw_m, +saw_s}:
      Iso8601.dur.put_s2(
        days, h, mi, n, nanos, saw_d, saw_h, saw_m,
        Bool.or(Bool.not(saw_t), saw_s)
      )
def Iso8601.dur.frac.scale(+acc: U32, got: Nat) -> U32:
  U32.mul(acc, U32.pow(10, Nat.sub(9n, got)))
def Iso8601.dur.cont_r(
  r: Result<&2, &2, Iso8601.Error, Iso8601.DurS>, mode: Iso8601.DurM
) -> Iso8601.DurC:
  match r:
    case Fail{e}:
      DurFail{e}
    case Done{st}:
      DurCont{st, mode}
def Iso8601.dur.ndig2(
  off: Nat, st: Iso8601.DurS, +acc: U32, +h: Char, s: P.Parse.St
) -> Iso8601.DurC:
  match s:
    case P.StOv{}:
      DurFail{Overflow{off}}
    case P.StBad{_}:
      DurFail{Invalid{}}
    case P.StOk{}:
      DurCont{st, DNum{P.Parse.nacc(acc, h)}}
def Iso8601.dur.ndig(
  off: Nat, st: Iso8601.DurS, +acc: U32, +h: Char
) -> Iso8601.DurC:
  Iso8601.dur.ndig2(off, st, acc, h, P.Parse.st.of(acc, h, U32.not(0)))
def Iso8601.dur.unit_dot(
  st: Iso8601.DurS, n: U32, is_dot: Bool
) -> Iso8601.DurC:
  match is_dot:
    case True{}:
      DurCont{st, DFrac{n, 0, 9n}}
    case False{}:
      DurFail{Invalid{}}
def Iso8601.dur.unit_s(
  st: Iso8601.DurS, n: U32, +c: Char, is_s: Bool
) -> Iso8601.DurC:
  match is_s:
    case True{}:
      Iso8601.dur.cont_r(Iso8601.dur.put_s(st, n, 0), DSeek{})
    case False{}:
      Iso8601.dur.unit_dot(st, n, Char.is_eq(c, '.'))
def Iso8601.dur.unit_m(
  st: Iso8601.DurS, n: U32, +c: Char, is_m: Bool
) -> Iso8601.DurC:
  match is_m:
    case True{}:
      Iso8601.dur.cont_r(Iso8601.dur.put_m(st, n), DSeek{})
    case False{}:
      Iso8601.dur.unit_s(st, n, c, Char.is_eq(c, 'S'))
def Iso8601.dur.unit_h(
  st: Iso8601.DurS, n: U32, +c: Char, is_h: Bool
) -> Iso8601.DurC:
  match is_h:
    case True{}:
      Iso8601.dur.cont_r(Iso8601.dur.put_h(st, n), DSeek{})
    case False{}:
      Iso8601.dur.unit_m(st, n, c, Char.is_eq(c, 'M'))
def Iso8601.dur.unit(
  st: Iso8601.DurS, n: U32, +c: Char
) -> Iso8601.DurC:
  Iso8601.dur.unit_h(st, n, c, Char.is_eq(c, 'H'))
def Iso8601.dur.unit_d(
  st: Iso8601.DurS, n: U32, +c: Char, is_d: Bool
) -> Iso8601.DurC:
  match is_d:
    case True{}:
      Iso8601.dur.cont_r(Iso8601.dur.put_d(st, n), DSeek{})
    case False{}:
      Iso8601.dur.unit(st, n, c)
def Iso8601.dur.num(
  off: Nat, st: Iso8601.DurS, acc: U32, +h: Char, is_dig: Bool
) -> Iso8601.DurC:
  match is_dig:
    case True{}:
      Iso8601.dur.ndig(off, st, acc, h)
    case False{}:
      Iso8601.dur.unit_d(st, acc, h, Char.is_eq(h, 'D'))
def Iso8601.dur.frac.s2(
  st: Iso8601.DurS, sec: U32, acc: U32, left: Nat, empty: Bool
) -> Iso8601.DurC:
  match empty:
    case True{}:
      DurFail{Invalid{}}
    case False{}:
      Iso8601.dur.cont_r(
        Iso8601.dur.put_s(st, sec, Iso8601.dur.frac.scale(acc, Nat.sub(9n, left))),
        DSeek{}
      )
def Iso8601.dur.frac.s(
  st: Iso8601.DurS, sec: U32, acc: U32, +left: Nat, is_s: Bool
) -> Iso8601.DurC:
  match is_s:
    case True{}:
      Iso8601.dur.frac.s2(st, sec, acc, left, Nat.is_eq(left, 9n))
    case False{}:
      DurFail{Invalid{}}
def Iso8601.dur.frac.dig(
  st: Iso8601.DurS, sec: U32, +acc: U32, left: Nat, +h: Char
) -> Iso8601.DurC:
  match left:
    case 0n:
      DurFail{Invalid{}}
    case 1n++p:
      DurCont{st, DFrac{sec, P.Parse.nacc(acc, h), p}}
def Iso8601.dur.frac(
  st: Iso8601.DurS, sec: U32, acc: U32, left: Nat, +h: Char, is_dig: Bool
) -> Iso8601.DurC:
  match is_dig:
    case True{}:
      Iso8601.dur.frac.dig(st, sec, acc, left, h)
    case False{}:
      Iso8601.dur.frac.s(st, sec, acc, left, Char.is_eq(h, 'S'))
def Iso8601.dur.seek2(
  off: Nat, st: Iso8601.DurS, +h: Char, is_dig: Bool
) -> Iso8601.DurC:
  match is_dig:
    case True{}:
      DurCont{st, DNum{P.Parse.nacc(0, h)}}
    case False{}:
      DurFail{Extra{off, h}}
def Iso8601.dur.seek(
  off: Nat, st: Iso8601.DurS, h: Char, is_t: Bool, is_dig: Bool
) -> Iso8601.DurC:
  match is_t:
    case True{}:
      Iso8601.dur.cont_r(Iso8601.dur.put_t(st), DSeek{})
    case False{}:
      Iso8601.dur.seek2(off, st, h, is_dig)
def Iso8601.dur.act(
  off: Nat, st: Iso8601.DurS, mode: Iso8601.DurM, +h: Char, is_t: Bool, is_dig: Bool
) -> Iso8601.DurC:
  match mode:
    case DSeek{}:
      Iso8601.dur.seek(off, st, h, is_t, is_dig)
    case DNum{acc}:
      Iso8601.dur.num(off, st, acc, h, is_dig)
    case DFrac{sec, acc, left}:
      Iso8601.dur.frac(st, sec, acc, left, h, is_dig)
def Iso8601.dur.go(
  s: String, +off: Nat, c: Iso8601.DurC
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match s c:
    case _ DurFail{e}:
      Fail{e}
    case SNil{} DurCont{st, mode}:
      Iso8601.dur.eof(st, mode)
    case SCon{+h, t} DurCont{st, mode}:
      Iso8601.dur.go(
        t, 1n+off,
        Iso8601.dur.act(
          off, st, mode, h, Char.is_eq(h, 'T'), Char.is_digit(h)
        )
      )
def Iso8601.read_duration.p(
  r: Result<&2, &2, Iso8601.Error, P.Parse.Cur>
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{P.Cur{s, off}}:
      Iso8601.dur.go(s, off, DurCont{Iso8601.dur0(), DSeek{}})
def Iso8601.read_duration(
  text: String
) -> Result<&2, &2, Iso8601.Error, Dur.Duration>:
  Iso8601.read_duration.p(Iso8601.expect(P.Parse.start(text), 'P'))
def Iso8601.per.mk2(
  r: Result<&2, &2, Per.Period.Error, Per.Period>
) -> Result<&2, &2, Iso8601.Error, Per.Period>:
  match r:
    case Fail{_}:
      Fail{Invalid{}}
    case Done{p}:
      Done{p}
def Iso8601.per.valid2(
  y: U32, m: U32, d: U32, ok: Bool
) -> Result<&2, &2, Iso8601.Error, Per.Period>:
  match ok:
    case False{}:
      Fail{Invalid{}}
    case True{}:
      Iso8601.per.mk2(Per.Period.from(y, m, d))
def Iso8601.per.valid(st: Iso8601.PerS) -> Result<&2, &2, Iso8601.Error, Per.Period>:
  match st:
    case PerS{+y, +m, +d, +saw_y, +saw_m, +saw_w, +saw_d}:
      Iso8601.per.valid2(y, m, d, Iso8601.or4(saw_y, saw_m, saw_w, saw_d))
def Iso8601.per.eof(
  st: Iso8601.PerS, mode: Iso8601.PerM
) -> Result<&2, &2, Iso8601.Error, Per.Period>:
  match mode:
    case PSeek{}:
      Iso8601.per.valid(st)
    case PNum{_}:
      Fail{Invalid{}}
def Iso8601.add_u32.go(+a: U32, +b: U32, ov: Bool) -> Result<&2, &2, Iso8601.Error, U32>:
  match ov:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{U32.add(a, b)}
def Iso8601.add_u32(+a: U32, +b: U32) -> Result<&2, &2, Iso8601.Error, U32>:
  Iso8601.add_u32.go(a, b, U32.is_gt(b, U32.sub(U32.not(0), a)))
def Iso8601.per.weeks2(+n: U32, ov: Bool) -> Result<&2, &2, Iso8601.Error, U32>:
  match ov:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{U32.mul(n, 7)}
def Iso8601.per.weeks(+n: U32) -> Result<&2, &2, Iso8601.Error, U32>:
  Iso8601.per.weeks2(n, U32.is_gt(n, U32.div(U32.not(0), 7)))
def Iso8601.per.put_y2(
  n: U32, m: U32, d: U32, saw_m: Bool, saw_w: Bool, saw_d: Bool, bad: Bool
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match bad:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{PerS{n, m, d, True{}, saw_m, saw_w, saw_d}}
def Iso8601.per.put_y(
  st: Iso8601.PerS, n: U32
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match st:
    case PerS{_, m, d, +saw_y, +saw_m, +saw_w, +saw_d}:
      Iso8601.per.put_y2(
        n, m, d, saw_m, saw_w, saw_d, Iso8601.or4(saw_y, saw_m, saw_w, saw_d)
      )
def Iso8601.per.put_m2(
  y: U32, n: U32, d: U32, saw_y: Bool, saw_w: Bool, saw_d: Bool, bad: Bool
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match bad:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{PerS{y, n, d, saw_y, True{}, saw_w, saw_d}}
def Iso8601.per.put_m(
  st: Iso8601.PerS, n: U32
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match st:
    case PerS{y, _, d, saw_y, +saw_m, +saw_w, +saw_d}:
      Iso8601.per.put_m2(
        y, n, d, saw_y, saw_w, saw_d, Iso8601.or3(saw_m, saw_w, saw_d)
      )
def Iso8601.per.put_w.go(
  y: U32, m: U32, saw_y: Bool, saw_m: Bool,
  rw: Result<&2, &2, Iso8601.Error, U32>
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match rw:
    case Fail{e}:
      Fail{e}
    case Done{w}:
      Done{PerS{y, m, w, saw_y, saw_m, True{}, False{}}}
def Iso8601.per.put_w2(
  y: U32, m: U32, saw_y: Bool, saw_m: Bool, n: U32, bad: Bool
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match bad:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Iso8601.per.put_w.go(y, m, saw_y, saw_m, Iso8601.per.weeks(n))
def Iso8601.per.put_w(
  st: Iso8601.PerS, n: U32
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match st:
    case PerS{y, m, _, saw_y, saw_m, +saw_w, +saw_d}:
      Iso8601.per.put_w2(y, m, saw_y, saw_m, n, Bool.or(saw_w, saw_d))
def Iso8601.per.put_d.go(
  y: U32, m: U32, saw_y: Bool, saw_m: Bool, saw_w: Bool,
  rd: Result<&2, &2, Iso8601.Error, U32>
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match rd:
    case Fail{e}:
      Fail{e}
    case Done{days}:
      Done{PerS{y, m, days, saw_y, saw_m, saw_w, True{}}}
def Iso8601.per.put_d2(
  y: U32, m: U32, d: U32, saw_y: Bool, saw_m: Bool, saw_w: Bool, n: U32, bad: Bool
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match bad:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Iso8601.per.put_d.go(y, m, saw_y, saw_m, saw_w, Iso8601.add_u32(d, n))
def Iso8601.per.put_d(
  st: Iso8601.PerS, n: U32
) -> Result<&2, &2, Iso8601.Error, Iso8601.PerS>:
  match st:
    case PerS{y, m, d, saw_y, saw_m, saw_w, +saw_d}:
      Iso8601.per.put_d2(y, m, d, saw_y, saw_m, saw_w, n, saw_d)
def Iso8601.per.cont_r(
  r: Result<&2, &2, Iso8601.Error, Iso8601.PerS>, mode: Iso8601.PerM
) -> Iso8601.PerC:
  match r:
    case Fail{e}:
      PerFail{e}
    case Done{st}:
      PerCont{st, mode}
def Iso8601.per.ndig2(
  off: Nat, st: Iso8601.PerS, +acc: U32, +h: Char, s: P.Parse.St
) -> Iso8601.PerC:
  match s:
    case P.StOv{}:
      PerFail{Overflow{off}}
    case P.StBad{_}:
      PerFail{Invalid{}}
    case P.StOk{}:
      PerCont{st, PNum{P.Parse.nacc(acc, h)}}
def Iso8601.per.ndig(
  off: Nat, st: Iso8601.PerS, +acc: U32, +h: Char
) -> Iso8601.PerC:
  Iso8601.per.ndig2(off, st, acc, h, P.Parse.st.of(acc, h, U32.not(0)))
def Iso8601.per.unit_d(
  st: Iso8601.PerS, n: U32, is_d: Bool
) -> Iso8601.PerC:
  match is_d:
    case True{}:
      Iso8601.per.cont_r(Iso8601.per.put_d(st, n), PSeek{})
    case False{}:
      PerFail{Invalid{}}
def Iso8601.per.unit_w(
  st: Iso8601.PerS, n: U32, +c: Char, is_w: Bool
) -> Iso8601.PerC:
  match is_w:
    case True{}:
      Iso8601.per.cont_r(Iso8601.per.put_w(st, n), PSeek{})
    case False{}:
      Iso8601.per.unit_d(st, n, Char.is_eq(c, 'D'))
def Iso8601.per.unit_m(
  st: Iso8601.PerS, n: U32, +c: Char, is_m: Bool
) -> Iso8601.PerC:
  match is_m:
    case True{}:
      Iso8601.per.cont_r(Iso8601.per.put_m(st, n), PSeek{})
    case False{}:
      Iso8601.per.unit_w(st, n, c, Char.is_eq(c, 'W'))
def Iso8601.per.unit(
  st: Iso8601.PerS, n: U32, +c: Char
) -> Iso8601.PerC:
  Iso8601.per.unit_m(st, n, c, Char.is_eq(c, 'M'))
def Iso8601.per.unit_y(
  st: Iso8601.PerS, n: U32, +c: Char, is_y: Bool
) -> Iso8601.PerC:
  match is_y:
    case True{}:
      Iso8601.per.cont_r(Iso8601.per.put_y(st, n), PSeek{})
    case False{}:
      Iso8601.per.unit(st, n, c)
def Iso8601.per.num(
  off: Nat, st: Iso8601.PerS, acc: U32, +h: Char, is_dig: Bool
) -> Iso8601.PerC:
  match is_dig:
    case True{}:
      Iso8601.per.ndig(off, st, acc, h)
    case False{}:
      Iso8601.per.unit_y(st, acc, h, Char.is_eq(h, 'Y'))
def Iso8601.per.seek2(
  off: Nat, st: Iso8601.PerS, +h: Char, is_dig: Bool
) -> Iso8601.PerC:
  match is_dig:
    case True{}:
      PerCont{st, PNum{P.Parse.nacc(0, h)}}
    case False{}:
      PerFail{Extra{off, h}}
def Iso8601.per.seek(
  off: Nat, st: Iso8601.PerS, h: Char, is_t: Bool, is_dig: Bool
) -> Iso8601.PerC:
  match is_t:
    case True{}:
      PerFail{Invalid{}}
    case False{}:
      Iso8601.per.seek2(off, st, h, is_dig)
def Iso8601.per.act(
  off: Nat, st: Iso8601.PerS, mode: Iso8601.PerM, +h: Char, is_t: Bool, is_dig: Bool
) -> Iso8601.PerC:
  match mode:
    case PSeek{}:
      Iso8601.per.seek(off, st, h, is_t, is_dig)
    case PNum{acc}:
      Iso8601.per.num(off, st, acc, h, is_dig)
def Iso8601.per.go(
  s: String, +off: Nat, c: Iso8601.PerC
) -> Result<&2, &2, Iso8601.Error, Per.Period>:
  match s c:
    case _ PerFail{e}:
      Fail{e}
    case SNil{} PerCont{st, mode}:
      Iso8601.per.eof(st, mode)
    case SCon{+h, t} PerCont{st, mode}:
      Iso8601.per.go(
        t, 1n+off,
        Iso8601.per.act(
          off, st, mode, h, Char.is_eq(h, 'T'), Char.is_digit(h)
        )
      )
def Iso8601.read_period.p(
  r: Result<&2, &2, Iso8601.Error, P.Parse.Cur>
) -> Result<&2, &2, Iso8601.Error, Per.Period>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{P.Cur{s, off}}:
      Iso8601.per.go(s, off, PerCont{Iso8601.per0(), PSeek{}})
def Iso8601.read_period(
  text: String
) -> Result<&2, &2, Iso8601.Error, Per.Period>:
  Iso8601.read_period.p(Iso8601.expect(P.Parse.start(text), 'P'))
