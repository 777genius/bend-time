import Base
import 0xe49a3e6521e1b71e55654a885f27bcc1/parse.bend as P
import ./date.bend as D
import ./datetime.bend as DT
import ./instant.bend as I

type Format.Error is Data:
  Unexpected{offset: Nat, char: Char}
  Eof{offset: Nat}
  Overflow{offset: Nat}
  Extra{offset: Nat, char: Char}
  InvalidDate{year: U32, month: U32, day: U32}
  InvalidTime{hour: U32, minute: U32, second: U32}
  InvalidOffset{hour: U32, minute: U32}
  NegativeZeroOffset{}
  BadFraction{offset: Nat}

type Format.FracP is Data:
  FracP{frac: DT.TimeFrac, cur: P.Parse.Cur}

type Format.OffP is Data:
  OffP{offset: DT.UtcOffset, cur: P.Parse.Cur}

type Format.DateP is Data:
  DateP{date: D.Date, cur: P.Parse.Cur}

def Format.from_parse(e: P.Parse.Error) -> Format.Error:
  match e:
    case P.Unexpected{offset, char}:
      Unexpected{offset, char}
    case P.Eof{offset}:
      Eof{offset}
    case P.Overflow{offset}:
      Overflow{offset}
    case P.Extra{offset, char}:
      Extra{offset, char}

def Format.digit(n: U32) -> Char:
  Char.from_u32((Char.to_u32('0') + n : U32))

def Format.pad2(+n: U32) -> String:
  SCon{
    Format.digit(U32.div(n, 10)),
    SCon{Format.digit(U32.mod(n, 10)), SNil{}}
  }

def Format.pad4(+n: U32) -> String:
  SCon{
    Format.digit(U32.div(n, 1000)),
    SCon{
      Format.digit(U32.mod(U32.div(n, 100), 10)),
      SCon{
        Format.digit(U32.mod(U32.div(n, 10), 10)),
        SCon{Format.digit(U32.mod(n, 10)), SNil{}}
      }
    }
  }

def Format.pad_n.go(k: Nat, +n: U32, acc: String) -> String:
  match k:
    case 0n:
      acc
    case 1n++p:
      Format.pad_n.go(
        p, U32.div(n, 10), SCon{Format.digit(U32.mod(n, 10)), acc}
      )

def Format.pad_n(n: U32, k: Nat) -> String:
  Format.pad_n.go(k, n, SNil{})

def Format.show_date(date: D.Date) -> String:
  match date:
    case D.Date{y, m, d}:
      String.append(
        Format.pad4(y),
        String.append(
          "-", String.append(Format.pad2(m), String.append("-", Format.pad2(d)))
        )
      )

def Format.show_frac(frac: DT.TimeFrac) -> String:
  match frac:
    case DT.FracNone{}:
      SNil{}
    case DT.Frac{digits, value}:
      SCon{'.', Format.pad_n(value, digits)}

def Format.show_off(offset: DT.UtcOffset) -> String:
  match offset:
    case DT.OffsetZero{}:
      "Z"
    case DT.OffsetEast{h, mi}:
      String.append(
        "+", String.append(Format.pad2(h), String.append(":", Format.pad2(mi)))
      )
    case DT.OffsetWest{h, mi}:
      String.append(
        "-", String.append(Format.pad2(h), String.append(":", Format.pad2(mi)))
      )

def Format.show_time(time: DT.TimeOfDay) -> String:
  match time:
    case DT.TimeOfDay{h, mi, s, frac}:
      String.append(
        Format.pad2(h),
        String.append(
          ":",
          String.append(
            Format.pad2(mi),
            String.append(
              ":", String.append(Format.pad2(s), Format.show_frac(frac))
            )
          )
        )
      )

def Format.show.join(ds: String, ts: String, os: String) -> String:
  String.append(ds, String.append("T", String.append(ts, os)))

def Format.show(odt: DT.OffsetDateTime) -> String:
  match odt:
    case DT.OffsetDateTime{date, time, offset}:
      Format.show.join(
        Format.show_date(date), Format.show_time(time), Format.show_off(offset)
      )

def Format.cur_off(cur: P.Parse.Cur) -> Nat:
  match cur:
    case P.Cur{_, off}:
      off

def Format.nacc(+acc: U32, +h: Char) -> U32:
  U32.add(U32.mul(acc, 10), (Char.to_u32(h) - Char.to_u32('0') : U32))

def Format.frac.end_ok2(
  s: String, acc: U32, off: Nat, got: Nat, z: Bool
) -> Result<&2, &2, Format.Error, Format.FracP>:
  match z:
    case True{}:
      Fail{BadFraction{off}}
    case False{}:
      Done{FracP{DT.Frac{got, acc}, P.Cur{s, off}}}

def Format.frac.end_ok(
  s: String, acc: U32, off: Nat, +got: Nat
) -> Result<&2, &2, Format.Error, Format.FracP>:
  Format.frac.end_ok2(s, acc, off, got, Nat.is_eq(got, 0n))

def Format.frac.go(
  s: String, n: Nat, dig: Bool, +h: Char, +acc: U32, off: Nat, got: Nat
) -> Result<&2, &2, Format.Error, Format.FracP>:
  match s n dig:
    case _ 0n True{}:
      Fail{BadFraction{off}}
    case _ 0n False{}:
      Format.frac.end_ok(SCon{h, s}, acc, off, got)
    case _ 1n++p False{}:
      Format.frac.end_ok(SCon{h, s}, acc, off, got)
    case SNil{} 1n++p True{}:
      Format.frac.end_ok(SNil{}, Format.nacc(acc, h), 1n+off, 1n+got)
    case SCon{+h2, t} 1n++p True{}:
      Format.frac.go(
        t, p, Char.is_digit(h2), h2, Format.nacc(acc, h), 1n+off, 1n+got
      )

def Format.frac.start(
  s: String, off: Nat
) -> Result<&2, &2, Format.Error, Format.FracP>:
  match s:
    case SNil{}:
      Fail{BadFraction{off}}
    case SCon{+h, t}:
      Format.frac.go(t, 9n, Char.is_digit(h), h, 0, off, 0n)

def Format.frac.digits2(
  r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Format.Error, Format.FracP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{P.Cur{rest, off}}:
      Format.frac.start(rest, off)

def Format.frac.dot(
  cur: P.Parse.Cur, is_dot: Bool
) -> Result<&2, &2, Format.Error, Format.FracP>:
  match is_dot:
    case False{}:
      Done{FracP{DT.FracNone{}, cur}}
    case True{}:
      Format.frac.digits2(P.Parse.expect_char(cur, '.'))

def Format.frac.after2(
  cur: P.Parse.Cur, m: Maybe<&2, Char>
) -> Result<&2, &2, Format.Error, Format.FracP>:
  match m:
    case None{}:
      Done{FracP{DT.FracNone{}, cur}}
    case Some{c}:
      Format.frac.dot(cur, Char.is_eq(c, '.'))

def Format.frac.after(
  +cur: P.Parse.Cur
) -> Result<&2, &2, Format.Error, Format.FracP>:
  Format.frac.after2(cur, P.Parse.peek(cur))

def Format.off.mk(
  west: Bool, h: U32, mi: U32, cur: P.Parse.Cur,
  r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match r:
    case Fail{DT.NegativeZero{}}:
      Fail{NegativeZeroOffset{}}
    case Fail{DT.InvalidOffset{hh, mm}}:
      Fail{InvalidOffset{hh, mm}}
    case Done{off}:
      Done{OffP{off, cur}}

def Format.off.min2(
  +west: Bool, +h: U32, r: Result<&2, &2, P.Parse.Error, P.Parse.Dec>
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{P.Dec{+mi, cur}}:
      Format.off.mk(west, h, mi, cur, DT.UtcOffset.from(west, h, mi))

def Format.off.colon(
  west: Bool, h: U32, r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{cur}:
      Format.off.min2(west, h, P.Parse.read_fixed_decimal(cur, 2n, 99))

def Format.off.hour2(
  west: Bool, r: Result<&2, &2, P.Parse.Error, P.Parse.Dec>
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{P.Dec{h, cur}}:
      Format.off.colon(west, h, P.Parse.expect_char(cur, ':'))

def Format.off.sign2(
  west: Bool, r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{cur}:
      Format.off.hour2(west, P.Parse.read_fixed_decimal(cur, 2n, 99))

def Format.off.z2(
  r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{cur}:
      Done{OffP{DT.OffsetZero{}, cur}}

def Format.off.minus(
  minus: Bool, cur: P.Parse.Cur, +c: Char
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match minus:
    case True{}:
      Format.off.sign2(True{}, P.Parse.expect_char(cur, '-'))
    case False{}:
      Fail{Unexpected{Format.cur_off(cur), c}}

def Format.off.pm(
  plus: Bool, minus: Bool, cur: P.Parse.Cur, +c: Char
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match plus:
    case True{}:
      Format.off.sign2(False{}, P.Parse.expect_char(cur, '+'))
    case False{}:
      Format.off.minus(minus, cur, c)

def Format.off.ch2(
  z: Bool, plus: Bool, minus: Bool, cur: P.Parse.Cur, +c: Char
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match z:
    case True{}:
      Format.off.z2(P.Parse.expect_char(cur, 'Z'))
    case False{}:
      Format.off.pm(plus, minus, cur, c)

def Format.off.ch(
  cur: P.Parse.Cur, +c: Char
) -> Result<&2, &2, Format.Error, Format.OffP>:
  Format.off.ch2(
    Char.is_eq(c, 'Z'), Char.is_eq(c, '+'), Char.is_eq(c, '-'), cur, c
  )

def Format.off.after2(
  cur: P.Parse.Cur, m: Maybe<&2, Char>
) -> Result<&2, &2, Format.Error, Format.OffP>:
  match m:
    case None{}:
      Fail{Eof{Format.cur_off(cur)}}
    case Some{c}:
      Format.off.ch(cur, c)

def Format.off.after(
  +cur: P.Parse.Cur
) -> Result<&2, &2, Format.Error, Format.OffP>:
  Format.off.after2(cur, P.Parse.peek(cur))

def Format.civil.mk(
  +y: U32, +m: U32, +d: U32, cur: P.Parse.Cur,
  r: Result<&2, &2, D.Date.Error, D.Date>
) -> Result<&2, &2, Format.Error, Format.DateP>:
  match r:
    case Fail{D.InvalidDate{yy, mm, dd}}:
      Fail{InvalidDate{yy, mm, dd}}
    case Fail{D.OutOfRange{}}:
      Fail{InvalidDate{y, m, d}}
    case Done{date}:
      Done{DateP{date, cur}}

def Format.civil.d2(
  +y: U32, +m: U32, r: Result<&2, &2, P.Parse.Error, P.Parse.Dec>
) -> Result<&2, &2, Format.Error, Format.DateP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{P.Dec{+d, cur}}:
      Format.civil.mk(y, m, d, cur, D.Date.from(y, m, d))

def Format.civil.dash2(
  y: U32, m: U32, r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Format.Error, Format.DateP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{cur}:
      Format.civil.d2(y, m, P.Parse.read_fixed_decimal(cur, 2n, 99))

def Format.civil.m2(
  y: U32, r: Result<&2, &2, P.Parse.Error, P.Parse.Dec>
) -> Result<&2, &2, Format.Error, Format.DateP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{P.Dec{m, cur}}:
      Format.civil.dash2(y, m, P.Parse.expect_char(cur, '-'))

def Format.civil.dash1(
  y: U32, r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Format.Error, Format.DateP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{cur}:
      Format.civil.m2(y, P.Parse.read_fixed_decimal(cur, 2n, 99))

def Format.civil.y(
  r: Result<&2, &2, P.Parse.Error, P.Parse.Dec>
) -> Result<&2, &2, Format.Error, Format.DateP>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{P.Dec{y, cur}}:
      Format.civil.dash1(y, P.Parse.expect_char(cur, '-'))

def Format.civil(text: String) -> Result<&2, &2, Format.Error, Format.DateP>:
  Format.civil.y(P.Parse.read_fixed_decimal(P.Parse.start(text), 4n, 9999))

def Format.read_date.fin2(
  date: D.Date, r: Result<&2, &2, P.Parse.Error, Unit>
) -> Result<&2, &2, Format.Error, D.Date>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{_}:
      Done{date}

def Format.read_date.fin(
  r: Result<&2, &2, Format.Error, Format.DateP>
) -> Result<&2, &2, Format.Error, D.Date>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{DateP{date, cur}}:
      Format.read_date.fin2(date, P.Parse.finish(cur))

def Format.read_date(text: String) -> Result<&2, &2, Format.Error, D.Date>:
  Format.read_date.fin(Format.civil(text))

def Format.read.fin2(
  odt: DT.OffsetDateTime, r: Result<&2, &2, P.Parse.Error, Unit>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{_}:
      Done{odt}

def Format.read.off2(
  date: D.Date, time: DT.TimeOfDay,
  r: Result<&2, &2, Format.Error, Format.OffP>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{OffP{offset, cur}}:
      Format.read.fin2(DT.OffsetDateTime.from(date, time, offset), P.Parse.finish(cur))

def Format.read.time2(
  date: D.Date, +h: U32, +mi: U32, +s: U32, frac: DT.TimeFrac, cur: P.Parse.Cur,
  r: Result<&2, &2, DT.TimeOfDay.Error, DT.TimeOfDay>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{DT.InvalidTime{hh, mm, ss}}:
      Fail{InvalidTime{hh, mm, ss}}
    case Done{time}:
      Format.read.off2(date, time, Format.off.after(cur))

def Format.read.frac2(
  date: D.Date, +h: U32, +mi: U32, +s: U32,
  r: Result<&2, &2, Format.Error, Format.FracP>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{FracP{+frac, cur}}:
      Format.read.time2(
        date, h, mi, s, frac, cur, DT.TimeOfDay.from(h, mi, s, frac)
      )

def Format.read.sec2(
  date: D.Date, h: U32, mi: U32,
  r: Result<&2, &2, P.Parse.Error, P.Parse.Dec>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{P.Dec{s, cur}}:
      Format.read.frac2(date, h, mi, s, Format.frac.after(cur))

def Format.read.colon2(
  date: D.Date, h: U32, mi: U32,
  r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{cur}:
      Format.read.sec2(date, h, mi, P.Parse.read_fixed_decimal(cur, 2n, 99))

def Format.read.min2(
  date: D.Date, h: U32, r: Result<&2, &2, P.Parse.Error, P.Parse.Dec>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{P.Dec{mi, cur}}:
      Format.read.colon2(date, h, mi, P.Parse.expect_char(cur, ':'))

def Format.read.colon1(
  date: D.Date, h: U32, r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{cur}:
      Format.read.min2(date, h, P.Parse.read_fixed_decimal(cur, 2n, 99))

def Format.read.hour2(
  date: D.Date, r: Result<&2, &2, P.Parse.Error, P.Parse.Dec>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{P.Dec{h, cur}}:
      Format.read.colon1(date, h, P.Parse.expect_char(cur, ':'))

def Format.read.t2(
  date: D.Date, r: Result<&2, &2, P.Parse.Error, P.Parse.Cur>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{Format.from_parse(e)}
    case Done{cur}:
      Format.read.hour2(date, P.Parse.read_fixed_decimal(cur, 2n, 99))

def Format.read.after_date(
  r: Result<&2, &2, Format.Error, Format.DateP>
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{DateP{date, cur}}:
      Format.read.t2(date, P.Parse.expect_char(cur, 'T'))

def Format.read(
  text: String
) -> Result<&2, &2, Format.Error, DT.OffsetDateTime>:
  Format.read.after_date(Format.civil(text))

def Format.show_read(
  r: Result<&2, &2, Format.Error, DT.OffsetDateTime>
) -> Result<&2, &2, Format.Error, String>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{odt}:
      Done{Format.show(odt)}

def Format.show_instant.map(
  r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>
) -> Result<&2, &2, D.Date.Error, String>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{odt}:
      Done{Format.show(odt)}

def Format.show_instant(
  i: I.Instant
) -> Result<&2, &2, D.Date.Error, String>:
  Format.show_instant.map(DT.OffsetDateTime.from_instant_utc(i))

def Format.read_instant.map(
  r: Result<&2, &2, Format.Error, DT.OffsetDateTime>
) -> Result<&2, &2, Format.Error, I.Instant>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{odt}:
      Done{DT.OffsetDateTime.to_instant(odt)}

def Format.read_instant(
  text: String
) -> Result<&2, &2, Format.Error, I.Instant>:
  Format.read_instant.map(Format.read(text))
