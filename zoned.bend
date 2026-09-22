import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/duration.bend as Dur
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import 0x9b6a4fc7ceea91864a75396e1b8365e5/period.bend as Per
import ./zone.bend as Z

type ZonedDateTime is Data:
  ZonedDateTime{instant: I.Instant, zone: Z.Zone}

def ZonedDateTime.from_instant.odt(
  +i: I.Instant, +z: Z.Zone,
  r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>
) -> Result<&2, &2, Z.Zone.Error, ZonedDateTime>:
  match r:
    case Fail{_}:
      Fail{Z.OutOfRange{}}
    case Done{_}:
      Done{ZonedDateTime{i, z}}

def ZonedDateTime.from_instant.at(
  +i: I.Instant, +z: Z.Zone,
  r: Result<&2, &2, Z.Zone.Error, DT.UtcOffset>
) -> Result<&2, &2, Z.Zone.Error, ZonedDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{off}:
      ZonedDateTime.from_instant.odt(
        i, z, DT.OffsetDateTime.from_instant(i, off)
      )

def ZonedDateTime.from_instant(
  +i: I.Instant, +z: Z.Zone
) -> Result<&2, &2, Z.Zone.Error, ZonedDateTime>:
  ZonedDateTime.from_instant.at(i, z, Z.Zone.at(z, i))

def ZonedDateTime.from_local.go(
  +z: Z.Zone, r: Result<&2, &2, Z.Zone.Error, I.Instant>
) -> Result<&2, &2, Z.Zone.Error, ZonedDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{i}:
      ZonedDateTime.from_instant(i, z)

def ZonedDateTime.from_local(
  +ldt: DT.LocalDateTime, +z: Z.Zone
) -> Result<&2, &2, Z.Zone.Error, ZonedDateTime>:
  ZonedDateTime.from_local.go(z, Z.Zone.resolve(z, ldt))

def ZonedDateTime.to_instant(zdt: ZonedDateTime) -> I.Instant:
  match zdt:
    case ZonedDateTime{instant, _}:
      instant

def ZonedDateTime.zone(zdt: ZonedDateTime) -> Z.Zone:
  match zdt:
    case ZonedDateTime{_, zone}:
      zone

def ZonedDateTime.to_offset(
  zdt: ZonedDateTime
) -> Result<&2, &2, Z.Zone.Error, DT.UtcOffset>:
  match zdt:
    case ZonedDateTime{instant, zone}:
      Z.Zone.at(zone, instant)

def ZonedDateTime.odt_of.date(
  r: Result<&2, &2, D.Date.Error, DT.OffsetDateTime>
) -> Result<&2, &2, Z.Zone.Error, DT.OffsetDateTime>:
  match r:
    case Fail{_}:
      Fail{Z.OutOfRange{}}
    case Done{odt}:
      Done{odt}

def ZonedDateTime.odt_of(
  i: I.Instant, r: Result<&2, &2, Z.Zone.Error, DT.UtcOffset>
) -> Result<&2, &2, Z.Zone.Error, DT.OffsetDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{off}:
      ZonedDateTime.odt_of.date(DT.OffsetDateTime.from_instant(i, off))

def ZonedDateTime.to_odt(
  +zdt: ZonedDateTime
) -> Result<&2, &2, Z.Zone.Error, DT.OffsetDateTime>:
  match zdt:
    case ZonedDateTime{+instant, zone}:
      ZonedDateTime.odt_of(instant, Z.Zone.at(zone, instant))

def ZonedDateTime.to_local.map(
  r: Result<&2, &2, Z.Zone.Error, DT.OffsetDateTime>
) -> Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{odt}:
      Done{DT.OffsetDateTime.to_local(odt)}

def ZonedDateTime.to_local(
  zdt: ZonedDateTime
) -> Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>:
  ZonedDateTime.to_local.map(ZonedDateTime.to_odt(zdt))

def ZonedDateTime.same_instant(+a: ZonedDateTime, +b: ZonedDateTime) -> Bool:
  I.Instant.is_eq(ZonedDateTime.to_instant(a), ZonedDateTime.to_instant(b))

def ZonedDateTime.add.zdt(
  r: Result<&2, &2, Z.Zone.Error, ZonedDateTime>
) -> Result<&2, &2, I.Instant.Error, ZonedDateTime>:
  match r:
    case Fail{_}:
      Fail{I.OutOfRange{}}
    case Done{zdt}:
      Done{zdt}

def ZonedDateTime.add.map(
  zone: Z.Zone, r: Result<&2, &2, I.Instant.Error, I.Instant>
) -> Result<&2, &2, I.Instant.Error, ZonedDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{i}:
      ZonedDateTime.add.zdt(ZonedDateTime.from_instant(i, zone))

def ZonedDateTime.add(
  +zdt: ZonedDateTime, d: Dur.Duration
) -> Result<&2, &2, I.Instant.Error, ZonedDateTime>:
  match zdt:
    case ZonedDateTime{+instant, +zone}:
      ZonedDateTime.add.map(zone, I.Instant.add(instant, d))

def ZonedDateTime.sub(
  +zdt: ZonedDateTime, d: Dur.Duration
) -> Result<&2, &2, I.Instant.Error, ZonedDateTime>:
  match zdt:
    case ZonedDateTime{+instant, +zone}:
      ZonedDateTime.add.map(zone, I.Instant.sub(instant, d))

def ZonedDateTime.add_period.loc(
  zone: Z.Zone, r: Result<&2, &2, D.Date.Error, DT.LocalDateTime>
) -> Result<&2, &2, Z.Zone.Error, ZonedDateTime>:
  match r:
    case Fail{_}:
      Fail{Z.OutOfRange{}}
    case Done{ldt2}:
      ZonedDateTime.from_local(ldt2, zone)

def ZonedDateTime.add_period.go(
  zone: Z.Zone, p: Per.Period,
  r: Result<&2, &2, Z.Zone.Error, DT.LocalDateTime>
) -> Result<&2, &2, Z.Zone.Error, ZonedDateTime>:
  match r:
    case Fail{e}:
      Fail{e}
    case Done{ldt}:
      ZonedDateTime.add_period.loc(zone, DT.LocalDateTime.add_period(ldt, p))

def ZonedDateTime.add_period(
  +zdt: ZonedDateTime, p: Per.Period
) -> Result<&2, &2, Z.Zone.Error, ZonedDateTime>:
  match zdt:
    case ZonedDateTime{_, +zone}:
      ZonedDateTime.add_period.go(zone, p, ZonedDateTime.to_local(zdt))
