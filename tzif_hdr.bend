import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import ./zone.bend as Z

type Tzif.Cur is Data:
  Cur{rest: List<&2, U32>, off: Nat}

type Tzif.U32P is Data:
  U32P{n: U32, cur: Tzif.Cur}

type Tzif.Cnt is Data:
  Cnt{isut: U32, isstd: U32, leap: U32, time: U32, ty: U32, ch: U32}

type Tzif.CntP is Data:
  CntP{cnt: Tzif.Cnt, cur: Tzif.Cur}

def Tzif.byte(
  cur: Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.U32P>:
  match cur:
    case Cur{Nil{}, _}:
      Fail{Z.Invalid{}}
    case Cur{Con{b, rest}, off}:
      Done{U32P{b, Cur{rest, 1n+off}}}

def Tzif.skip.go(
  +rest: List<&2, U32>, n: U32, off: Nat, z: Bool
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match rest:
    case Nil{}:
      match z:
        case True{}:
          Done{Cur{Nil{}, off}}
        case False{}:
          Fail{Z.Invalid{}}
    case Con{_, t}:
      match z:
        case True{}:
          Done{Cur{rest, off}}
        case False{}:
          +n2 = U32.sub(n, 1)
          Tzif.skip.go(t, n2, 1n+off, U32.is_eq(n2, 0))

def Tzif.skip(
  +n: U32, cur: Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match cur:
    case Cur{rest, off}:
      Tzif.skip.go(rest, n, off, U32.is_eq(n, 0))

def Tzif.be32.step(
  a: U32, r: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.U32P>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{U32P{b, cur}}:
      Done{U32P{U32.add(U32.mul(a, 256), b), cur}}

def Tzif.be32.go(
  n: Nat, acc: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.U32P>:
  match n:
    case 0n:
      acc
    case 1n+p:
      match acc:
        case Fail{e}:
          Fail{e}
        case Done{U32P{a, cur}}:
          Tzif.be32.go(p, Tzif.be32.step(a, Tzif.byte(cur)))

def Tzif.be32(
  cur: Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.U32P>:
  Tzif.be32.go(4n, Done{U32P{0, cur}})

def Tzif.i32_off.out(
  r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>
) -> Result<&2, &2, Z.Zone.Error, DT.UtcOffset>:
  match r:
    case Fail{_}:
      Fail{Z.Unsupported{}}
    case Done{o}:
      Done{o}

def Tzif.i32_off.hm(
  west: Bool, +h: U32, +mi: U32
) -> Result<&2, &2, Z.Zone.Error, DT.UtcOffset>:
  Tzif.i32_off.out(DT.UtcOffset.from(west, h, mi))

def Tzif.i32_off.mod(
  west: Bool, +raw: U32, z: Bool
) -> Result<&2, &2, Z.Zone.Error, DT.UtcOffset>:
  match z:
    case False{}:
      Fail{Z.Unsupported{}}
    case True{}:
      Tzif.i32_off.hm(
        west, U32.div(raw, 3600), U32.div(U32.mod(raw, 3600), 60)
      )

def Tzif.i32_off.sec(
  west: Bool, +raw: U32
) -> Result<&2, &2, Z.Zone.Error, DT.UtcOffset>:
  Tzif.i32_off.mod(west, raw, U32.is_eq(U32.mod(raw, 60), 0))

def Tzif.i32_off.sign(
  +raw: U32, west: Bool
) -> Result<&2, &2, Z.Zone.Error, DT.UtcOffset>:
  match west:
    case True{}:
      Tzif.i32_off.sec(True{}, U32.add(U32.not(raw), 1))
    case False{}:
      Tzif.i32_off.sec(False{}, raw)

def Tzif.i32_off.z(
  +raw: U32, z: Bool
) -> Result<&2, &2, Z.Zone.Error, DT.UtcOffset>:
  match z:
    case True{}:
      Done{DT.OffsetZero{}}
    case False{}:
      Tzif.i32_off.sign(raw, U32.is_ge(raw, U32.shln(1, 31n)))

def Tzif.i32_off(
  +raw: U32
) -> Result<&2, &2, Z.Zone.Error, DT.UtcOffset>:
  Tzif.i32_off.z(raw, U32.is_eq(raw, 0))

def Tzif.uadd.wrap(
  s: U32, wrap: Bool
) -> Result<&2, &2, Z.Zone.Error, U32>:
  match wrap:
    case True{}:
      Fail{Z.Invalid{}}
    case False{}:
      Done{s}

def Tzif.uadd(
  +a: U32, +b: U32
) -> Result<&2, &2, Z.Zone.Error, U32>:
  +s = U32.add(a, b)
  Tzif.uadd.wrap(s, U32.is_lt(s, a))

def Tzif.umul.ov(
  +a: U32, +b: U32, ov: Bool
) -> Result<&2, &2, Z.Zone.Error, U32>:
  match ov:
    case True{}:
      Fail{Z.Invalid{}}
    case False{}:
      Done{U32.mul(a, b)}

def Tzif.umul.z(
  +a: U32, +b: U32, z: Bool
) -> Result<&2, &2, Z.Zone.Error, U32>:
  match z:
    case True{}:
      Done{0}
    case False{}:
      Tzif.umul.ov(a, b, U32.is_gt(a, U32.div(U32.not(0), b)))

def Tzif.umul(
  +a: U32, +b: U32
) -> Result<&2, &2, Z.Zone.Error, U32>:
  Tzif.umul.z(a, b, U32.is_eq(b, 0))

def Tzif.add2(
  r: Result<&2, &2, Z.Zone.Error, U32>, b: U32
) -> Result<&2, &2, Z.Zone.Error, U32>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{a}:
      Tzif.uadd(a, b)

def Tzif.mulr(
  r: Result<&2, &2, Z.Zone.Error, U32>, b: U32
) -> Result<&2, &2, Z.Zone.Error, U32>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{a}:
      Tzif.umul(a, b)

def Tzif.addr(
  r: Result<&2, &2, Z.Zone.Error, U32>,
  s: Result<&2, &2, Z.Zone.Error, U32>
) -> Result<&2, &2, Z.Zone.Error, U32>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{a}:
      match s:
        case Fail{e}:
          Fail{e}
        case Done{b}:
          Tzif.uadd(a, b)

def Tzif.v1size(
  cnt: Tzif.Cnt
) -> Result<&2, &2, Z.Zone.Error, U32>:
  match cnt:
    case Cnt{+isut, +isstd, +leap, +time, +ty, +ch}:
      Tzif.add2(
        Tzif.add2(
          Tzif.add2(
            Tzif.addr(
              Tzif.addr(Tzif.umul(time, 4), Tzif.umul(ty, 6)),
              Tzif.umul(leap, 8)
            ),
            time
          ),
          ch
        ),
        isstd
      )

def Tzif.v1size2(
  cnt: Tzif.Cnt, r: Result<&2, &2, Z.Zone.Error, U32>
) -> Result<&2, &2, Z.Zone.Error, U32>:
  match cnt:
    case Cnt{+isut, _, _, _, _, _}:
      Tzif.add2(r, isut)

def Tzif.v1body(
  +cnt: Tzif.Cnt
) -> Result<&2, &2, Z.Zone.Error, U32>:
  Tzif.v1size2(cnt, Tzif.v1size(cnt))

def Tzif.v2tail(
  cnt: Tzif.Cnt
) -> Result<&2, &2, Z.Zone.Error, U32>:
  match cnt:
    case Cnt{+isut, +isstd, +leap, _, _, +ch}:
      Tzif.add2(
        Tzif.add2(
          Tzif.add2(Tzif.umul(leap, 12), ch),
          isstd
        ),
        isut
      )

def Tzif.cap.gt(
  bad: Bool
) -> Result<&2, &2, Z.Zone.Error, Unit>:
  match bad:
    case True{}:
      Fail{Z.Invalid{}}
    case False{}:
      Done{Unit{}}

def Tzif.cap.one(
  +n: U32, +lim: U32
) -> Result<&2, &2, Z.Zone.Error, Unit>:
  Tzif.cap.gt(U32.is_gt(n, lim))

def Tzif.cap.next(
  r: Result<&2, &2, Z.Zone.Error, Unit>, +n: U32, +lim: U32
) -> Result<&2, &2, Z.Zone.Error, Unit>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{_}:
      Tzif.cap.one(n, lim)

def Tzif.cap.gtz(
  cnt: Tzif.Cnt, z: Bool
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cnt>:
  match z:
    case True{}:
      Fail{Z.Invalid{}}
    case False{}:
      Done{cnt}

def Tzif.cap.lim.end(
  r: Result<&2, &2, Z.Zone.Error, Unit>, cnt: Tzif.Cnt
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cnt>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{_}:
      Done{cnt}

def Tzif.cap.lim(
  +cnt: Tzif.Cnt
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cnt>:
  match cnt:
    case Cnt{_, _, +leap, +time, +ty, +ch}:
      Tzif.cap.lim.end(
        Tzif.cap.next(
          Tzif.cap.next(
            Tzif.cap.next(Tzif.cap.one(leap, 256), time, 4000),
            ty, 256
          ),
          ch, 1024
        ),
        cnt
      )

def Tzif.cap.end(
  r: Result<&2, &2, Z.Zone.Error, Unit>, +cnt: Tzif.Cnt, +ty: U32
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cnt>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{_}:
      Tzif.cap.gtz(cnt, U32.is_eq(ty, 0))

def Tzif.cap.ty0(
  +cnt: Tzif.Cnt
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cnt>:
  match cnt:
    case Cnt{_, _, _, _, +ty, _}:
      Tzif.cap.gtz(cnt, U32.is_eq(ty, 0))

def Tzif.cap(
  r: Result<&2, &2, Z.Zone.Error, Tzif.Cnt>
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cnt>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{cnt}:
      Tzif.cap.ty0(cnt)

def Tzif.expect.eq(
  c: Tzif.Cur, ok: Bool
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match ok:
    case True{}:
      Done{c}
    case False{}:
      Fail{Z.Invalid{}}

def Tzif.expect.go(
  want: U32, r: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{U32P{b, c}}:
      Tzif.expect.eq(c, U32.is_eq(b, want))

def Tzif.expect(
  cur: Tzif.Cur, want: U32
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  Tzif.expect.go(want, Tzif.byte(cur))

def Tzif.ver.three(
  c: Tzif.Cur, is3: Bool
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match is3:
    case True{}:
      Done{c}
    case False{}:
      Fail{Z.Unsupported{}}

def Tzif.ver.two(
  c: Tzif.Cur, +b: U32, is2: Bool
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match is2:
    case True{}:
      Done{c}
    case False{}:
      Tzif.ver.three(c, U32.is_eq(b, 51))

def Tzif.ver.z(
  c: Tzif.Cur, +b: U32, is0: Bool
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match is0:
    case True{}:
      Fail{Z.Unsupported{}}
    case False{}:
      Tzif.ver.two(c, b, U32.is_eq(b, 50))

def Tzif.ver.go(
  r: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{U32P{+b, c}}:
      Tzif.ver.z(c, b, U32.is_eq(b, 0))

def Tzif.ver(
  cur: Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  Tzif.ver.go(Tzif.byte(cur))

def Tzif.magic.i(
  r: Result<&2, &2, Z.Zone.Error, Tzif.Cur>
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{c}:
      Tzif.expect(c, 105)

def Tzif.magic.z(
  r: Result<&2, &2, Z.Zone.Error, Tzif.Cur>
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{c}:
      Tzif.magic.i(Tzif.expect(c, 90))

def Tzif.magic.f(
  r: Result<&2, &2, Z.Zone.Error, Tzif.Cur>
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{c}:
      Tzif.expect(c, 102)

def Tzif.magic(
  cur: Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  Tzif.magic.f(Tzif.magic.z(Tzif.expect(cur, 84)))

def Tzif.skipr(
  n: U32, r: Result<&2, &2, Z.Zone.Error, Tzif.Cur>
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{c}:
      Tzif.skip(n, c)

def Tzif.verr(
  r: Result<&2, &2, Z.Zone.Error, Tzif.Cur>
) -> Result<&2, &2, Z.Zone.Error, Tzif.Cur>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{c}:
      Tzif.ver(c)

def Tzif.cnt.pack(
  +isut: U32, +isstd: U32, +leap: U32, +time: U32, +ty: U32,
  r: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.CntP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{U32P{ch, c}}:
      Done{CntP{Cnt{isut, isstd, leap, time, ty, ch}, c}}

def Tzif.cnt.ch(
  +isut: U32, +isstd: U32, +leap: U32, +time: U32,
  r: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.CntP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{U32P{ty, c}}:
      Tzif.cnt.pack(isut, isstd, leap, time, ty, Tzif.be32(c))

def Tzif.cnt.ty(
  +isut: U32, +isstd: U32, +leap: U32,
  r: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.CntP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{U32P{time, c}}:
      Tzif.cnt.ch(isut, isstd, leap, time, Tzif.be32(c))

def Tzif.cnt.time(
  +isut: U32, +isstd: U32,
  r: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.CntP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{U32P{leap, c}}:
      Tzif.cnt.ty(isut, isstd, leap, Tzif.be32(c))

def Tzif.cnt.leap(
  +isut: U32, r: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.CntP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{U32P{isstd, c}}:
      Tzif.cnt.time(isut, isstd, Tzif.be32(c))

def Tzif.cnt.isut(
  r: Result<&2, &2, Z.Zone.Error, Tzif.U32P>
) -> Result<&2, &2, Z.Zone.Error, Tzif.CntP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{U32P{isut, c}}:
      Tzif.cnt.leap(isut, Tzif.be32(c))

def Tzif.cnt(
  cur: Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.CntP>:
  Tzif.cnt.isut(Tzif.be32(cur))

def Tzif.hdr.cnt(
  r: Result<&2, &2, Z.Zone.Error, Tzif.Cur>
) -> Result<&2, &2, Z.Zone.Error, Tzif.CntP>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{c}:
      Tzif.cnt(c)

def Tzif.hdr(
  cur: Tzif.Cur
) -> Result<&2, &2, Z.Zone.Error, Tzif.CntP>:
  Tzif.hdr.cnt(
    Tzif.skipr(15, Tzif.verr(Tzif.magic(cur)))
  )

