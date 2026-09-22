import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/format.bend as F
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ./zone.bend as Z
import ./zoned.bend as Zd

type ZoneFormat.Error is Data:
  Unexpected{offset: Nat, char: Char}
  Eof{offset: Nat}
  Overflow{offset: Nat}
  Extra{offset: Nat, char: Char}
  InvalidDate{year: U32, month: U32, day: U32}
  InvalidTime{hour: U32, minute: U32, second: U32}
  InvalidOffset{hour: U32, minute: U32}
  NegativeZeroOffset{}
  BadFraction{offset: Nat}
  Invalid{}
  Mismatch{}

type ZoneFormat.Split is Data:
  Split{prefix: String, idrest: String}

def ZoneFormat.eqc(+a: Char, +b: Char) -> Bool:
  U32.is_eq(Char.to_u32(a), Char.to_u32(b))

def ZoneFormat.rev.go(s: String, acc: String) -> String:
  match s:
    case SNil{}:
      acc
    case SCon{c, t}:
      ZoneFormat.rev.go(t, SCon{c, acc})

def ZoneFormat.rev(s: String) -> String:
  ZoneFormat.rev.go(s, SNil{})

def ZoneFormat.split.go(
  +s: String, acc: String, br: Bool, +c: Char
) -> Result<&2, &2, ZoneFormat.Error, ZoneFormat.Split>:
  match s:
    case SNil{}:
      match br:
        case True{}:
          Done{Split{ZoneFormat.rev(acc), s}}
        case False{}:
          Fail{Invalid{}}
    case SCon{+c2, t}:
      match br:
        case True{}:
          Done{Split{ZoneFormat.rev(acc), s}}
        case False{}:
          ZoneFormat.split.go(t, SCon{c, acc}, ZoneFormat.eqc(c2, '['), c2)

def ZoneFormat.split(
  +s: String
) -> Result<&2, &2, ZoneFormat.Error, ZoneFormat.Split>:
  match s:
    case SNil{}:
      Fail{Invalid{}}
    case SCon{+c, t}:
      ZoneFormat.split.go(t, SNil{}, ZoneFormat.eqc(c, '['), c)

def ZoneFormat.from_fmt(
  e: F.Format.Error
) -> ZoneFormat.Error:
  match e:
    case F.Unexpected{offset, char}:
      Unexpected{offset, char}
    case F.Eof{offset}:
      Eof{offset}
    case F.Overflow{offset}:
      Overflow{offset}
    case F.Extra{offset, char}:
      Extra{offset, char}
    case F.InvalidDate{year, month, day}:
      InvalidDate{year, month, day}
    case F.InvalidTime{hour, minute, second}:
      InvalidTime{hour, minute, second}
    case F.InvalidOffset{hour, minute}:
      InvalidOffset{hour, minute}
    case F.NegativeZeroOffset{}:
      NegativeZeroOffset{}
    case F.BadFraction{offset}:
      BadFraction{offset}

def ZoneFormat.from_zone(
  e: Z.Zone.Error
) -> ZoneFormat.Error:
  match e:
    case Z.Invalid{}:
      Invalid{}
    case Z.Unsupported{}:
      Invalid{}
    case Z.OutOfRange{}:
      Invalid{}
    case Z.Gap{_}:
      Invalid{}
    case Z.Fold{_}:
      Invalid{}

def ZoneFormat.show.s(
  odt: DT.OffsetDateTime, id: String
) -> String:
  String.append(
    F.Format.show(odt),
    String.append("[", String.append(id, "]"))
  )

def ZoneFormat.show.go(
  r: Result<&2, &2, Z.Zone.Error, DT.OffsetDateTime>, id: String
) -> Result<&2, &2, ZoneFormat.Error, String>:
  match r:
    case Fail{e}:
      Fail{ZoneFormat.from_zone(e)}
    case Done{odt}:
      Done{ZoneFormat.show.s(odt, id)}

def ZoneFormat.show(
  +zdt: Zd.ZonedDateTime
) -> Result<&2, &2, ZoneFormat.Error, String>:
  match zdt:
    case Zd.ZonedDateTime{_, +zone}:
      ZoneFormat.show.go(Zd.ZonedDateTime.to_odt(zdt), Z.Zone.id(zone))

def ZoneFormat.read.zdt(
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  match r:
    case Fail{e}:
      Fail{ZoneFormat.from_zone(e)}
    case Done{zdt}:
      Done{zdt}

def ZoneFormat.read.off.ok(
  eq: Bool, +i: I.Instant, +z: Z.Zone
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  match eq:
    case False{}:
      Fail{Invalid{}}
    case True{}:
      ZoneFormat.read.zdt(Zd.ZonedDateTime.from_instant(i, z))

def ZoneFormat.read.off(
  +i: I.Instant, +z: Z.Zone, want: DT.UtcOffset,
  r: Result<&2, &2, Z.Zone.Error, DT.UtcOffset>
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  match r:
    case Fail{e}:
      Fail{ZoneFormat.from_zone(e)}
    case Done{got}:
      ZoneFormat.read.off.ok(Z.Zone.off_eq(got, want), i, z)

def ZoneFormat.read.eq(
  empty: Bool, mis: Bool, +i: I.Instant, +z: Z.Zone, +odt: DT.OffsetDateTime
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  match empty:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      match mis:
        case True{}:
          Fail{Mismatch{}}
        case False{}:
          match odt:
            case DT.OffsetDateTime{_, _, off}:
              ZoneFormat.read.off(i, z, off, Z.Zone.at(z, i))

def ZoneFormat.read.trail(
  rest: String, +id: String, +odt: DT.OffsetDateTime, +z: Z.Zone
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  match rest:
    case SNil{}:
      ZoneFormat.read.eq(
        String.eq(id, ""),
        Bool.not(String.eq(id, Z.Zone.id(z))),
        DT.OffsetDateTime.to_instant(odt),
        z,
        odt
      )
    case SCon{c, _}:
      Fail{Extra{0n, c}}

def ZoneFormat.read.id.go(
  +s: String, acc: String, +odt: DT.OffsetDateTime, +z: Z.Zone, br: Bool,
  +c: Char
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  match s:
    case SNil{}:
      match br:
        case True{}:
          ZoneFormat.read.trail(s, ZoneFormat.rev(acc), odt, z)
        case False{}:
          Fail{Eof{0n}}
    case SCon{+c2, t}:
      match br:
        case True{}:
          ZoneFormat.read.trail(s, ZoneFormat.rev(acc), odt, z)
        case False{}:
          ZoneFormat.read.id.go(
            t, SCon{c, acc}, odt, z, ZoneFormat.eqc(c2, ']'), c2
          )

def ZoneFormat.read.id(
  odt: DT.OffsetDateTime, +z: Z.Zone, +rest: String
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  match rest:
    case SNil{}:
      Fail{Eof{0n}}
    case SCon{+c, t}:
      ZoneFormat.read.id.go(t, SNil{}, odt, z, ZoneFormat.eqc(c, ']'), c)

def ZoneFormat.read.odt(
  r: Result<&2, &2, F.Format.Error, DT.OffsetDateTime>,
  +z: Z.Zone, rest: String
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  match r:
    case Fail{e}:
      Fail{ZoneFormat.from_fmt(e)}
    case Done{odt}:
      ZoneFormat.read.id(odt, z, rest)

def ZoneFormat.read.split(
  r: Result<&2, &2, ZoneFormat.Error, ZoneFormat.Split>, +z: Z.Zone
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{Split{prefix, rest}}:
      ZoneFormat.read.odt(F.Format.read(prefix), z, rest)

def ZoneFormat.read(
  text: String, +z: Z.Zone
) -> Result<&2, &2, ZoneFormat.Error, Zd.ZonedDateTime>:
  ZoneFormat.read.split(ZoneFormat.split(text), z)
