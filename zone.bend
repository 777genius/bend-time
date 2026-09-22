import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ./posix_tz.bend as Px
import ./posix_at.bend as Pa

type Zone.Error is Data:
  Invalid{}
  Unsupported{}
  OutOfRange{}
  Gap{ldt: DT.LocalDateTime}
  Fold{ldt: DT.LocalDateTime}

type Zone.LocalType is Data:
  LocalType{offset: DT.UtcOffset}

type Zone.Trans is Data:
  Trans{at: I.Instant, ty: U32}

type Zone.Rules is Data:
  Rules{
    types: List<&2, Zone.LocalType>,
    trans: List<&2, Zone.Trans>,
    posix: Maybe<&2, Px.Posix.Tz>
  }

type Zone is Data:
  ZoneFixed{id: String, offset: DT.UtcOffset}
  ZoneId{id: String, rules: Zone.Rules}

type Zone.Hit is Data:
  Hit0{}
  Hit1{i: I.Instant}
  Hit2{earlier: I.Instant, later: I.Instant}

def Zone.digit(n: U32) -> Char:
  Char.from_u32((Char.to_u32('0') + n : U32))

def Zone.pad2(+n: U32) -> String:
  SCon{
    Zone.digit(U32.div(n, 10)),
    SCon{Zone.digit(U32.mod(n, 10)), SNil{}}
  }

def Zone.off_eq(a: DT.UtcOffset, b: DT.UtcOffset) -> Bool:
  match a:
    case DT.OffsetZero{}:
      match b:
        case DT.OffsetZero{}:
          True{}
        case _:
          False{}
    case DT.OffsetEast{+h1, +m1}:
      match b:
        case DT.OffsetEast{+h2, +m2}:
          Bool.and(U32.is_eq(h1, h2), U32.is_eq(m1, m2))
        case _:
          False{}
    case DT.OffsetWest{+h1, +m1}:
      match b:
        case DT.OffsetWest{+h2, +m2}:
          Bool.and(U32.is_eq(h1, h2), U32.is_eq(m1, m2))
        case _:
          False{}

def Zone.fixed_id(offset: DT.UtcOffset) -> String:
  match offset:
    case DT.OffsetZero{}:
      "Z"
    case DT.OffsetEast{h, mi}:
      String.append(
        "Fixed/+",
        String.append(Zone.pad2(h), String.append(":", Zone.pad2(mi)))
      )
    case DT.OffsetWest{h, mi}:
      String.append(
        "Fixed/-",
        String.append(Zone.pad2(h), String.append(":", Zone.pad2(mi)))
      )

def Zone.fixed(+offset: DT.UtcOffset) -> Zone:
  ZoneFixed{Zone.fixed_id(offset), offset}

def Zone.type_at.go(
  types: List<&2, Zone.LocalType>, +ty: U32, z: Bool
) -> Result<&2, &2, Zone.Error, Zone.LocalType>:
  match types:
    case Nil{}:
      Fail{Invalid{}}
    case Con{h, t}:
      match z:
        case True{}:
          Done{h}
        case False{}:
          +ty2 = U32.sub(ty, 1)
          Zone.type_at.go(t, ty2, U32.is_eq(ty2, 0))

def Zone.type_at(
  types: List<&2, Zone.LocalType>, +ty: U32
) -> Result<&2, &2, Zone.Error, Zone.LocalType>:
  Zone.type_at.go(types, ty, U32.is_eq(ty, 0))

def Zone.trans_ok.ord(
  at: I.Instant, bad: Bool
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match bad:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Done{at}

def Zone.trans_ok.step(
  +prev: I.Instant, +at: I.Instant
) -> Result<&2, &2, Zone.Error, I.Instant>:
  Zone.trans_ok.ord(at, I.Instant.is_le(at, prev))

def Zone.trans_ok.go(
  trans: List<&2, Zone.Trans>, prev: Result<&2, &2, Zone.Error, I.Instant>
) -> Result<&2, &2, Zone.Error, Unit>:
  match trans:
    case Nil{}:
      match prev:
        case Fail{e}:
          Fail{e}
        case Done{_}:
          Done{Unit{}}
    case Con{Trans{+at, _}, rest}:
      match prev:
        case Fail{e}:
          Fail{e}
        case Done{+p}:
          Zone.trans_ok.go(rest, Zone.trans_ok.step(p, at))

def Zone.trans_ok(
  trans: List<&2, Zone.Trans>
) -> Result<&2, &2, Zone.Error, Unit>:
  match trans:
    case Nil{}:
      Done{Unit{}}
    case Con{Trans{+at, _}, rest}:
      Zone.trans_ok.go(rest, Done{at})

def Zone.from_rules.pack(
  +id: String, types: List<&2, Zone.LocalType>, trans: List<&2, Zone.Trans>,
  posix: Maybe<&2, Px.Posix.Tz>, r: Result<&2, &2, Zone.Error, Unit>
) -> Result<&2, &2, Zone.Error, Zone>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{_}:
      Done{ZoneId{id, Rules{types, trans, posix}}}

def Zone.from_rules.types(
  +id: String, +types: List<&2, Zone.LocalType>, +trans: List<&2, Zone.Trans>,
  posix: Maybe<&2, Px.Posix.Tz>
) -> Result<&2, &2, Zone.Error, Zone>:
  match types:
    case Nil{}:
      Fail{Invalid{}}
    case Con{_, _}:
      Zone.from_rules.pack(id, types, trans, posix, Zone.trans_ok(trans))

def Zone.from_rules.empty(
  +id: String, types: List<&2, Zone.LocalType>, trans: List<&2, Zone.Trans>,
  posix: Maybe<&2, Px.Posix.Tz>, empty: Bool
) -> Result<&2, &2, Zone.Error, Zone>:
  match empty:
    case True{}:
      Fail{Invalid{}}
    case False{}:
      Zone.from_rules.types(id, types, trans, posix)

def Zone.from_rules(
  +id: String, types: List<&2, Zone.LocalType>, trans: List<&2, Zone.Trans>,
  posix: Maybe<&2, Px.Posix.Tz>
) -> Result<&2, &2, Zone.Error, Zone>:
  Zone.from_rules.empty(id, types, trans, posix, String.eq(id, ""))

def Zone.id(z: Zone) -> String:
  match z:
    case ZoneFixed{id, _}:
      id
    case ZoneId{id, _}:
      id

def Zone.px.off(
  r: Result<&2, &2, Px.Posix.Error, DT.UtcOffset>
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  match r:
    case Fail{Px.Invalid{}}:
      Fail{Invalid{}}
    case Fail{Px.Unsupported{}}:
      Fail{Unsupported{}}
    case Fail{Px.OutOfRange{}}:
      Fail{OutOfRange{}}
    case Done{o}:
      Done{o}

def Zone.at.off(
  r: Result<&2, &2, Zone.Error, Zone.LocalType>
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{LocalType{off}}:
      Done{off}

def Zone.at.pick2(
  prev: DT.UtcOffset, +types: List<&2, Zone.LocalType>, ty: U32, lt: Bool
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  match lt:
    case True{}:
      Done{prev}
    case False{}:
      Zone.at.off(Zone.type_at(types, ty))

def Zone.at.pick(
  +instant: I.Instant, at: I.Instant, prev: DT.UtcOffset,
  +types: List<&2, Zone.LocalType>, ty: U32
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  Zone.at.pick2(prev, types, ty, I.Instant.is_lt(instant, at))

def Zone.at.tail(
  posix: Maybe<&2, Px.Posix.Tz>, +instant: I.Instant, prev: DT.UtcOffset
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  match posix:
    case None{}:
      Done{prev}
    case Some{tz}:
      Zone.px.off(Pa.Posix.at(tz, instant))

def Zone.at.done(
  seen: Bool, posix: Maybe<&2, Px.Posix.Tz>, +instant: I.Instant,
  p: DT.UtcOffset
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  match seen:
    case True{}:
      Done{p}
    case False{}:
      Zone.at.tail(posix, instant, p)

def Zone.at.go(
  trans: List<&2, Zone.Trans>, +types: List<&2, Zone.LocalType>,
  +instant: I.Instant, prev: Result<&2, &2, Zone.Error, DT.UtcOffset>,
  posix: Maybe<&2, Px.Posix.Tz>, seen: Bool
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  match trans:
    case Nil{}:
      match prev:
        case Fail{e}:
          Fail{e}
        case Done{p}:
          Zone.at.done(seen, posix, instant, p)
    case Con{Trans{+at, ty}, rest}:
      match prev:
        case Fail{e}:
          Fail{e}
        case Done{p}:
          Zone.at.go(
            rest, types, instant, Zone.at.pick(instant, at, p, types, ty),
            posix, Bool.or(seen, I.Instant.is_lt(instant, at))
          )

def Zone.at.head(
  +instant: I.Instant, +types: List<&2, Zone.LocalType>,
  trans: List<&2, Zone.Trans>, posix: Maybe<&2, Px.Posix.Tz>
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  match types:
    case Nil{}:
      Fail{Invalid{}}
    case Con{LocalType{off0}, _}:
      Zone.at.go(trans, types, instant, Done{off0}, posix, False{})

def Zone.at.rules(
  +instant: I.Instant, rules: Zone.Rules
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  match rules:
    case Rules{types, trans, posix}:
      Zone.at.head(instant, types, trans, posix)

def Zone.at(
  z: Zone, +i: I.Instant
) -> Result<&2, &2, Zone.Error, DT.UtcOffset>:
  match z:
    case ZoneFixed{_, offset}:
      Done{offset}
    case ZoneId{_, rules}:
      Zone.at.rules(i, rules)

def Zone.hit.lt(+i: I.Instant, +j: I.Instant, lt: Bool) -> Zone.Hit:
  match lt:
    case True{}:
      Hit2{i, j}
    case False{}:
      Hit2{j, i}

def Zone.hit.ord(+i: I.Instant, +j: I.Instant, eq: Bool) -> Zone.Hit:
  match eq:
    case True{}:
      Hit1{j}
    case False{}:
      Zone.hit.lt(i, j, I.Instant.is_lt(i, j))

def Zone.hit.add(acc: Zone.Hit, +i: I.Instant) -> Zone.Hit:
  match acc:
    case Hit0{}:
      Hit1{i}
    case Hit1{+j}:
      Zone.hit.ord(i, j, I.Instant.is_eq(i, j))
    case Hit2{e, l}:
      Hit2{e, l}

def Zone.resolve.ok(
  +acc: Zone.Hit, +i: I.Instant, eq: Bool
) -> Result<&2, &2, Zone.Error, Zone.Hit>:
  match eq:
    case False{}:
      Done{acc}
    case True{}:
      Done{Zone.hit.add(acc, i)}

def Zone.resolve.at(
  +acc: Zone.Hit, +i: I.Instant, +o: DT.UtcOffset,
  r: Result<&2, &2, Zone.Error, DT.UtcOffset>
) -> Result<&2, &2, Zone.Error, Zone.Hit>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{got}:
      Zone.resolve.ok(acc, i, Zone.off_eq(got, o))

def Zone.resolve.try(
  +ldt: DT.LocalDateTime, +z: Zone, +o: DT.UtcOffset, acc: Zone.Hit
) -> Result<&2, &2, Zone.Error, Zone.Hit>:
  +i = DT.OffsetDateTime.to_instant(DT.LocalDateTime.at_offset(ldt, o))
  Zone.resolve.at(acc, i, o, Zone.at(z, i))

def Zone.resolve.px.dst(
  +ldt: DT.LocalDateTime, +z: Zone, dst: DT.UtcOffset,
  r: Result<&2, &2, Zone.Error, Zone.Hit>
) -> Result<&2, &2, Zone.Error, Zone.Hit>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{a}:
      Zone.resolve.try(ldt, z, dst, a)

def Zone.resolve.px.tz(
  +ldt: DT.LocalDateTime, +z: Zone, tz: Px.Posix.Tz, acc: Zone.Hit
) -> Result<&2, &2, Zone.Error, Zone.Hit>:
  match tz:
    case Px.TzStd{off}:
      Zone.resolve.try(ldt, z, off, acc)
    case Px.TzDst{+std, +dst, _, _}:
      Zone.resolve.px.dst(ldt, z, dst, Zone.resolve.try(ldt, z, std, acc))

def Zone.resolve.px(
  +ldt: DT.LocalDateTime, +z: Zone, posix: Maybe<&2, Px.Posix.Tz>,
  acc: Zone.Hit
) -> Result<&2, &2, Zone.Error, Zone.Hit>:
  match posix:
    case None{}:
      Done{acc}
    case Some{tz}:
      Zone.resolve.px.tz(ldt, z, tz, acc)

def Zone.resolve.hits(
  types: List<&2, Zone.LocalType>, +ldt: DT.LocalDateTime, +z: Zone,
  posix: Maybe<&2, Px.Posix.Tz>, acc: Result<&2, &2, Zone.Error, Zone.Hit>
) -> Result<&2, &2, Zone.Error, Zone.Hit>:
  match types:
    case Nil{}:
      match acc:
        case Fail{e}:
          Fail{e}
        case Done{a}:
          Zone.resolve.px(ldt, z, posix, a)
    case Con{LocalType{o}, rest}:
      match acc:
        case Fail{e}:
          Fail{e}
        case Done{a}:
          Zone.resolve.hits(rest, ldt, z, posix, Zone.resolve.try(ldt, z, o, a))

def Zone.resolve.end(
  +ldt: DT.LocalDateTime, acc: Zone.Hit
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match acc:
    case Hit0{}:
      Fail{Gap{ldt}}
    case Hit1{i}:
      Done{i}
    case Hit2{_, _}:
      Fail{Fold{ldt}}

def Zone.resolve.pick_earlier(
  +ldt: DT.LocalDateTime, acc: Zone.Hit
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match acc:
    case Hit0{}:
      Fail{Gap{ldt}}
    case Hit1{i}:
      Done{i}
    case Hit2{earlier, _}:
      Done{earlier}

def Zone.resolve.pick_later(
  +ldt: DT.LocalDateTime, acc: Zone.Hit
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match acc:
    case Hit0{}:
      Fail{Gap{ldt}}
    case Hit1{i}:
      Done{i}
    case Hit2{_, later}:
      Done{later}

def Zone.resolve.fin(
  +ldt: DT.LocalDateTime, r: Result<&2, &2, Zone.Error, Zone.Hit>
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{acc}:
      Zone.resolve.end(ldt, acc)

def Zone.resolve.earlier.fin(
  +ldt: DT.LocalDateTime, r: Result<&2, &2, Zone.Error, Zone.Hit>
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{acc}:
      Zone.resolve.pick_earlier(ldt, acc)

def Zone.resolve.later.fin(
  +ldt: DT.LocalDateTime, r: Result<&2, &2, Zone.Error, Zone.Hit>
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{acc}:
      Zone.resolve.pick_later(ldt, acc)

def Zone.resolve.id(
  +z: Zone, +ldt: DT.LocalDateTime, rules: Zone.Rules
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match rules:
    case Rules{types, _, posix}:
      Zone.resolve.fin(
        ldt, Zone.resolve.hits(types, ldt, z, posix, Done{Hit0{}})
      )

def Zone.resolve.earlier.id(
  +z: Zone, +ldt: DT.LocalDateTime, rules: Zone.Rules
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match rules:
    case Rules{types, _, posix}:
      Zone.resolve.earlier.fin(
        ldt, Zone.resolve.hits(types, ldt, z, posix, Done{Hit0{}})
      )

def Zone.resolve.later.id(
  +z: Zone, +ldt: DT.LocalDateTime, rules: Zone.Rules
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match rules:
    case Rules{types, _, posix}:
      Zone.resolve.later.fin(
        ldt, Zone.resolve.hits(types, ldt, z, posix, Done{Hit0{}})
      )

def Zone.resolve.fixed(
  +ldt: DT.LocalDateTime, o: DT.UtcOffset
) -> Result<&2, &2, Zone.Error, I.Instant>:
  Done{DT.OffsetDateTime.to_instant(DT.LocalDateTime.at_offset(ldt, o))}

def Zone.resolve(
  +z: Zone, +ldt: DT.LocalDateTime
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match z:
    case ZoneFixed{_, o}:
      Zone.resolve.fixed(ldt, o)
    case ZoneId{_, rules}:
      Zone.resolve.id(z, ldt, rules)

def Zone.resolve_earlier(
  +z: Zone, +ldt: DT.LocalDateTime
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match z:
    case ZoneFixed{_, o}:
      Zone.resolve.fixed(ldt, o)
    case ZoneId{_, rules}:
      Zone.resolve.earlier.id(z, ldt, rules)

def Zone.resolve_later(
  +z: Zone, +ldt: DT.LocalDateTime
) -> Result<&2, &2, Zone.Error, I.Instant>:
  match z:
    case ZoneFixed{_, o}:
      Zone.resolve.fixed(ldt, o)
    case ZoneId{_, rules}:
      Zone.resolve.later.id(z, ldt, rules)
