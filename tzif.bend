import Base
import 0x888714bde93f46c139372bb9fdc57a19/bytes.bend as B
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ./zone.bend as Z
import ./tzif_hdr.bend as H
import ./posix_tz.bend as Px

type Tzif.Tm is Data:
  TmDrop{}
  TmAt{at: I.Instant}
type Tzif.TmP is Data:
  TmP{tms: List<&2, Tzif.Tm>, cur: H.Tzif.Cur}
type Tzif.TX is Data:
  TX{
    n: U32,
    acc: List<&2, Tzif.Tm>,
    hi: U32,
    lo: U32,
    phase: U32,
    z: Bool
  }
type Tzif.IdxP is Data:
  IdxP{idx: List<&2, U32>, cur: H.Tzif.Cur}
type Tzif.IS is Data:
  IS{n: U32, acc: List<&2, U32>, z: Bool}
type Tzif.LtP is Data:
  LtP{types: List<&2, Z.Zone.LocalType>, cur: H.Tzif.Cur}
type Tzif.LS is Data:
  LXOk{
    n: U32,
    acc: List<&2, Z.Zone.LocalType>,
    raw: U32,
    phase: U32,
    z: Bool,
    seen: Bool
  }
  LXFail{e: Z.Zone.Error}
type Tzif.Prev is Data:
  PrevNone{}
  PrevAt{at: I.Instant}
type Tzif.KR is Data:
  KR{prev: Tzif.Prev, acc: List<&2, Z.Zone.Trans>}

def Tzif.times.emit2(
  keep: Bool, +n: U32, acc: List<&2, Tzif.Tm>, +lo: U32
) -> Tzif.TX:
  match keep:
    case True{}:
      +n2 = U32.sub(n, 1)
      TX{n2, Con{TmAt{I.Instant.from_unix(lo)}, acc}, 0, 0, 0, U32.is_eq(n2, 0)}
    case False{}:
      +n2 = U32.sub(n, 1)
      TX{n2, Con{TmDrop{}, acc}, 0, 0, 0, U32.is_eq(n2, 0)}

def Tzif.times.emit(
  +n: U32, acc: List<&2, Tzif.Tm>, +hi: U32, lo: U32
) -> Tzif.TX:
  Tzif.times.emit2(U32.is_eq(hi, 0), n, acc, lo)

def Tzif.times.col(
  n: U32, acc: List<&2, Tzif.Tm>, +hi: U32, +lo: U32, +phase: U32, +b: U32,
  in_hi: Bool
) -> Tzif.TX:
  match in_hi:
    case True{}:
      TX{n, acc, U32.add(U32.mul(hi, 256), b), lo, U32.add(phase, 1), False{}}
    case False{}:
      TX{n, acc, hi, U32.add(U32.mul(lo, 256), b), U32.add(phase, 1), False{}}

def Tzif.times.ph(
  n: U32, acc: List<&2, Tzif.Tm>, hi: U32, lo: U32, +phase: U32, +b: U32,
  last: Bool
) -> Tzif.TX:
  match last:
    case True{}:
      Tzif.times.emit(n, acc, hi, U32.add(U32.mul(lo, 256), b))
    case False{}:
      Tzif.times.col(n, acc, hi, lo, phase, b, U32.is_lt(phase, 4))

def Tzif.times.next(
  tx: Tzif.TX, b: U32
) -> Tzif.TX:
  match tx:
    case TX{+n, acc, +hi, +lo, +phase, _}:
      Tzif.times.ph(n, acc, hi, lo, phase, b, U32.is_eq(phase, 7))

def Tzif.times.done(
  rest: List<&2, U32>, off: Nat, acc: List<&2, Tzif.Tm>
) -> Result<&2, &2, Z.Zone.Error, Tzif.TmP>:
  Done{TmP{List.reverse(&2, Tzif.Tm, acc), H.Cur{rest, off}}}

def Tzif.times.go(
  +rest: List<&2, U32>, tx: Tzif.TX, off: Nat
) -> Result<&2, &2, Z.Zone.Error, Tzif.TmP>:
  match rest:
    case Nil{}:
      match tx:
        case TX{_, acc, _, _, _, True{}}:
          Tzif.times.done(Nil{}, off, acc)
        case TX{_, _, _, _, _, False{}}:
          Fail{Z.Invalid{}}
    case Con{b, t}:
      match tx:
        case TX{_, acc, _, _, _, True{}}:
          Tzif.times.done(rest, off, acc)
        case TX{_, _, _, _, _, False{}}:
          Tzif.times.go(t, Tzif.times.next(tx, b), 1n+off)

def Tzif.times(
  +n: U32, cur: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.TmP>:
  match cur:
    case H.Cur{rest, off}:
      Tzif.times.go(rest, TX{n, Nil{}, 0, 0, 0, U32.is_eq(n, 0)}, off)

def Tzif.idx.next(
  ix: Tzif.IS, b: U32
) -> Tzif.IS:
  match ix:
    case IS{+n, acc, _}:
      +n2 = U32.sub(n, 1)
      IS{n2, Con{b, acc}, U32.is_eq(n2, 0)}

def Tzif.idx.done(
  rest: List<&2, U32>, off: Nat, acc: List<&2, U32>
) -> Result<&2, &2, Z.Zone.Error, Tzif.IdxP>:
  Done{IdxP{List.reverse(&2, U32, acc), H.Cur{rest, off}}}

def Tzif.idx.go(
  +rest: List<&2, U32>, ix: Tzif.IS, off: Nat
) -> Result<&2, &2, Z.Zone.Error, Tzif.IdxP>:
  match rest:
    case Nil{}:
      match ix:
        case IS{_, acc, True{}}:
          Tzif.idx.done(Nil{}, off, acc)
        case IS{_, _, False{}}:
          Fail{Z.Invalid{}}
    case Con{b, t}:
      match ix:
        case IS{_, acc, True{}}:
          Tzif.idx.done(rest, off, acc)
        case IS{_, _, False{}}:
          Tzif.idx.go(t, Tzif.idx.next(ix, b), 1n+off)

def Tzif.idx(
  +n: U32, cur: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.IdxP>:
  match cur:
    case H.Cur{rest, off}:
      Tzif.idx.go(rest, IS{n, Nil{}, U32.is_eq(n, 0)}, off)

def Tzif.keep.ord(
  +at: I.Instant, ty: U32, acc: List<&2, Z.Zone.Trans>, bad: Bool
) -> Result<&2, &2, Z.Zone.Error, Tzif.KR>:
  match bad:
    case True{}:
      Fail{Z.Invalid{}}
    case False{}:
      Done{KR{PrevAt{at}, Con{Z.Trans{at, ty}, acc}}}

def Tzif.keep.prev(
  prev: Tzif.Prev, +at: I.Instant, ty: U32, acc: List<&2, Z.Zone.Trans>
) -> Result<&2, &2, Z.Zone.Error, Tzif.KR>:
  match prev:
    case PrevNone{}:
      Done{KR{PrevAt{at}, Con{Z.Trans{at, ty}, acc}}}
    case PrevAt{+p}:
      Tzif.keep.ord(at, ty, acc, I.Instant.is_le(at, p))

def Tzif.keep.step(
  tm: Tzif.Tm, ty: U32, prev: Tzif.Prev, acc: List<&2, Z.Zone.Trans>, ge: Bool
) -> Result<&2, &2, Z.Zone.Error, Tzif.KR>:
  match tm:
    case TmDrop{}:
      match ge:
        case True{}:
          Fail{Z.Invalid{}}
        case False{}:
          Done{KR{prev, acc}}
    case TmAt{at}:
      match ge:
        case True{}:
          Fail{Z.Invalid{}}
        case False{}:
          Tzif.keep.prev(prev, at, ty, acc)

def Tzif.keep.go(
  tms: List<&2, Tzif.Tm>, idx: List<&2, U32>, +typecnt: U32,
  st: Result<&2, &2, Z.Zone.Error, Tzif.KR>
) -> Result<&2, &2, Z.Zone.Error, List<&2, Z.Zone.Trans>>:
  match tms:
    case Nil{}:
      match idx:
        case Nil{}:
          match st:
            case Fail{e}:
              Fail{e}
            case Done{KR{_, acc}}:
              Done{List.reverse(&2, Z.Zone.Trans, acc)}
        case Con{_, _}:
          Fail{Z.Invalid{}}
    case Con{tm, rest_t}:
      match idx:
        case Nil{}:
          Fail{Z.Invalid{}}
        case Con{+ty, rest_i}:
          match st:
            case Fail{e}:
              Fail{e}
            case Done{KR{prev, acc}}:
              Tzif.keep.go(
                rest_t, rest_i, typecnt,
                Tzif.keep.step(tm, ty, prev, acc, U32.is_ge(ty, typecnt))
              )

def Tzif.keep(
  tms: List<&2, Tzif.Tm>, idx: List<&2, U32>, typecnt: U32
) -> Result<&2, &2, Z.Zone.Error, List<&2, Z.Zone.Trans>>:
  Tzif.keep.go(tms, idx, typecnt, Done{KR{PrevNone{}, Nil{}}})

def Tzif.ltype.emit.r(
  r: Result<&2, &2, Z.Zone.Error, DT.UtcOffset>,
  +n: U32, acc: List<&2, Z.Zone.LocalType>, seen: Bool
) -> Tzif.LS:
  match r:
    case Fail{_}:
      +n2 = U32.sub(n, 1)
      LXOk{
        n2, Con{Z.LocalType{DT.OffsetZero{}}, acc}, 0, 0, U32.is_eq(n2, 0), seen
      }
    case Done{o}:
      +n2 = U32.sub(n, 1)
      LXOk{n2, Con{Z.LocalType{o}, acc}, 0, 0, U32.is_eq(n2, 0), True{}}

def Tzif.ltype.emit(
  n: U32, acc: List<&2, Z.Zone.LocalType>, raw: U32, seen: Bool
) -> Tzif.LS:
  Tzif.ltype.emit.r(H.Tzif.i32_off(raw), n, acc, seen)

def Tzif.ltype.col(
  n: U32, acc: List<&2, Z.Zone.LocalType>, +raw: U32, +phase: U32, +b: U32,
  seen: Bool, in_raw: Bool
) -> Tzif.LS:
  match in_raw:
    case True{}:
      LXOk{
        n, acc, U32.add(U32.mul(raw, 256), b), U32.add(phase, 1), False{}, seen
      }
    case False{}:
      LXOk{n, acc, raw, U32.add(phase, 1), False{}, seen}

def Tzif.ltype.ph(
  n: U32, acc: List<&2, Z.Zone.LocalType>, raw: U32, +phase: U32, +b: U32,
  seen: Bool, last: Bool
) -> Tzif.LS:
  match last:
    case True{}:
      Tzif.ltype.emit(n, acc, raw, seen)
    case False{}:
      Tzif.ltype.col(n, acc, raw, phase, b, seen, U32.is_lt(phase, 4))

def Tzif.ltype.next(
  lx: Tzif.LS, b: U32
) -> Tzif.LS:
  match lx:
    case LXFail{e}:
      LXFail{e}
    case LXOk{+n, acc, +raw, +phase, _, seen}:
      Tzif.ltype.ph(n, acc, raw, phase, b, seen, U32.is_eq(phase, 5))

def Tzif.ltype.done(
  rest: List<&2, U32>, off: Nat, acc: List<&2, Z.Zone.LocalType>
) -> Result<&2, &2, Z.Zone.Error, Tzif.LtP>:
  Done{LtP{List.reverse(&2, Z.Zone.LocalType, acc), H.Cur{rest, off}}}

def Tzif.ltype.fin(
  seen: Bool, rest: List<&2, U32>, off: Nat, acc: List<&2, Z.Zone.LocalType>
) -> Result<&2, &2, Z.Zone.Error, Tzif.LtP>:
  match seen:
    case True{}:
      Tzif.ltype.done(rest, off, acc)
    case False{}:
      Fail{Z.Unsupported{}}

def Tzif.ltype.go(
  +rest: List<&2, U32>, lx: Tzif.LS, off: Nat
) -> Result<&2, &2, Z.Zone.Error, Tzif.LtP>:
  match rest:
    case Nil{}:
      match lx:
        case LXFail{e}:
          Fail{e}
        case LXOk{_, acc, _, _, True{}, seen}:
          Tzif.ltype.fin(seen, Nil{}, off, acc)
        case LXOk{_, _, _, _, False{}, _}:
          Fail{Z.Invalid{}}
    case Con{b, t}:
      match lx:
        case LXFail{e}:
          Fail{e}
        case LXOk{_, acc, _, _, True{}, seen}:
          Tzif.ltype.fin(seen, rest, off, acc)
        case LXOk{_, _, _, _, False{}, _}:
          Tzif.ltype.go(t, Tzif.ltype.next(lx, b), 1n+off)

def Tzif.ltype(
  +n: U32, cur: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.LtP>:
  match cur:
    case H.Cur{rest, off}:
      Tzif.ltype.go(
        rest, LXOk{n, Nil{}, 0, 0, U32.is_eq(n, 0), False{}}, off
      )

def Tzif.str.go(
  xs: List<&2, U32>
) -> String:
  match xs:
    case Nil{}:
      SNil{}
    case Con{b, t}:
      SCon{Char.from_u32(b), Tzif.str.go(t)}

def Tzif.px.map(
  r: Result<&2, &2, Px.Posix.Error, Px.Posix.Tz>
) -> Result<&2, &2, Z.Zone.Error, Maybe<&2, Px.Posix.Tz>>:
  match r:
    case Fail{Px.Invalid{}}:
      Fail{Z.Invalid{}}
    case Fail{Px.Unsupported{}}:
      Fail{Z.Unsupported{}}
    case Fail{Px.OutOfRange{}}:
      Fail{Z.OutOfRange{}}
    case Done{tz}:
      Done{Some{tz}}

def Tzif.footer.nl(
  ok: Bool, inner_rev: List<&2, U32>
) -> Result<&2, &2, Z.Zone.Error, Maybe<&2, Px.Posix.Tz>>:
  match ok:
    case False{}:
      Fail{Z.Invalid{}}
    case True{}:
      Tzif.px.map(
        Px.Posix.parse(Tzif.str.go(List.reverse(&2, U32, inner_rev)))
      )

def Tzif.footer.inner(
  last_nl: Bool, acc: List<&2, U32>
) -> Result<&2, &2, Z.Zone.Error, Maybe<&2, Px.Posix.Tz>>:
  match last_nl:
    case False{}:
      Fail{Z.Invalid{}}
    case True{}:
      match acc:
        case Nil{}:
          Fail{Z.Invalid{}}
        case Con{b, inner_rev}:
          Tzif.footer.nl(U32.is_eq(b, 10), inner_rev)

def Tzif.footer.last(
  rest: List<&2, U32>, acc: List<&2, U32>, last_nl: Bool
) -> Result<&2, &2, Z.Zone.Error, Maybe<&2, Px.Posix.Tz>>:
  match rest:
    case Nil{}:
      Tzif.footer.inner(last_nl, acc)
    case Con{+b, t}:
      Tzif.footer.last(t, Con{b, acc}, U32.is_eq(b, 10))

def Tzif.footer.first(
  t: List<&2, U32>, ok: Bool
) -> Result<&2, &2, Z.Zone.Error, Maybe<&2, Px.Posix.Tz>>:
  match ok:
    case True{}:
      Tzif.footer.last(t, Nil{}, False{})
    case False{}:
      Fail{Z.Invalid{}}

def Tzif.footer.go(
  rest: List<&2, U32>
) -> Result<&2, &2, Z.Zone.Error, Maybe<&2, Px.Posix.Tz>>:
  match rest:
    case Nil{}:
      Done{None{}}
    case Con{b, t}:
      Tzif.footer.first(t, U32.is_eq(b, 10))

def Tzif.footer(
  cur: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Maybe<&2, Px.Posix.Tz>>:
  match cur:
    case H.Cur{rest, _}:
      Tzif.footer.go(rest)

def Tzif.pack(
  +id: String, types: List<&2, Z.Zone.LocalType>,
  trans: List<&2, Z.Zone.Trans>,
  r: Result<&2, &2, Z.Zone.Error, Maybe<&2, Px.Posix.Tz>>
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{px}:
      Z.Zone.from_rules(id, types, trans, px)

def Tzif.skipr_tail.n(
  c: H.Tzif.Cur, r: Result<&2, &2, Z.Zone.Error, U32>
) -> Result<&2, &2, Z.Zone.Error, H.Tzif.Cur>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{n}:
      H.Tzif.skip(n, c)

def Tzif.skipr_tail(
  cnt: H.Tzif.Cnt, c: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, H.Tzif.Cur>:
  Tzif.skipr_tail.n(c, H.Tzif.v2tail(cnt))

def Tzif.after.skip(
  r: Result<&2, &2, Z.Zone.Error, H.Tzif.Cur>,
  +id: String, types: List<&2, Z.Zone.LocalType>,
  trans: List<&2, Z.Zone.Trans>
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{c}:
      Tzif.pack(id, types, trans, Tzif.footer(c))

def Tzif.after.keep(
  r: Result<&2, &2, Z.Zone.Error, List<&2, Z.Zone.Trans>>,
  +id: String, cnt: H.Tzif.Cnt, types: List<&2, Z.Zone.LocalType>, c: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{trans}:
      Tzif.after.skip(Tzif.skipr_tail(cnt, c), id, types, trans)

def Tzif.after.lt(
  r: Result<&2, &2, Z.Zone.Error, Tzif.LtP>,
  +id: String, cnt: H.Tzif.Cnt, tms: List<&2, Tzif.Tm>, idx: List<&2, U32>,
  ty: U32
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{LtP{types, c}}:
      Tzif.after.keep(Tzif.keep(tms, idx, ty), id, cnt, types, c)

def Tzif.after.ty(
  +id: String, +cnt: H.Tzif.Cnt, tms: List<&2, Tzif.Tm>,
  idx: List<&2, U32>, c: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match cnt:
    case H.Cnt{_, _, _, _, +ty, _}:
      Tzif.after.lt(Tzif.ltype(ty, c), id, cnt, tms, idx, ty)

def Tzif.after.idx(
  r: Result<&2, &2, Z.Zone.Error, Tzif.IdxP>,
  +id: String, +cnt: H.Tzif.Cnt, tms: List<&2, Tzif.Tm>
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{IdxP{idx, c}}:
      Tzif.after.ty(id, cnt, tms, idx, c)

def Tzif.after.tm.go(
  +id: String, +cnt: H.Tzif.Cnt, tms: List<&2, Tzif.Tm>, c: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match cnt:
    case H.Cnt{_, _, _, +time, _, _}:
      Tzif.after.idx(Tzif.idx(time, c), id, cnt, tms)

def Tzif.after.tm(
  r: Result<&2, &2, Z.Zone.Error, Tzif.TmP>,
  +id: String, cnt: H.Tzif.Cnt
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{TmP{tms, c}}:
      Tzif.after.tm.go(id, cnt, tms, c)

def Tzif.after(
  +id: String, +cnt: H.Tzif.Cnt, cur: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match cnt:
    case H.Cnt{_, _, _, +time, _, _}:
      Tzif.after.tm(Tzif.times(time, cur), id, cnt)

def Tzif.v2.cap(
  r: Result<&2, &2, Z.Zone.Error, H.Tzif.Cnt>, +id: String, c: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{cnt}:
      Tzif.after(id, cnt, c)

def Tzif.v2.go(
  r: Result<&2, &2, Z.Zone.Error, H.Tzif.CntP>, +id: String
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{H.CntP{cnt, c}}:
      Tzif.v2.cap(H.Tzif.cap(H.Tzif.cap.lim(cnt)), id, c)

def Tzif.hdr.cnt_of(
  r: Result<&2, &2, Z.Zone.Error, H.Tzif.Cur>
) -> Result<&2, &2, Z.Zone.Error, H.Tzif.CntP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{c}:
      H.Tzif.hdr(c)

def Tzif.v1.skip(
  r: Result<&2, &2, Z.Zone.Error, U32>, +id: String, c: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{n}:
      Tzif.v2.go(Tzif.hdr.cnt_of(H.Tzif.skip(n, c)), id)

def Tzif.v1.cap(
  r: Result<&2, &2, Z.Zone.Error, H.Tzif.Cnt>, +id: String, c: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{cnt}:
      Tzif.v1.skip(H.Tzif.v1body(cnt), id, c)

def Tzif.v1.go(
  r: Result<&2, &2, Z.Zone.Error, H.Tzif.CntP>, +id: String
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{H.CntP{cnt, c}}:
      Tzif.v1.cap(H.Tzif.cap.lim(cnt), id, c)

def Tzif.parse(
  +id: String, cur: H.Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  Tzif.v1.go(H.Tzif.hdr(cur), id)

def Zone.from_tzif.empty(
  +id: String, data: List<&2, U32>, empty: Bool
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match empty:
    case True{}:
      Fail{Z.Invalid{}}
    case False{}:
      Tzif.parse(id, H.Cur{data, 0n})

def Zone.from_tzif(
  +id: String, bytes: B.Bytes
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  Zone.from_tzif.empty(id, B.Bytes.to_u32_list(bytes), String.eq(id, ""))
