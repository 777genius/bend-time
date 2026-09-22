import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ./zone.bend as Z

law zone_fixed_epoch:
  {
    Z.Zone.at(Z.Zone.fixed(DT.OffsetZero{}), I.Instant.from_unix(0))
    == Done{DT.OffsetZero{}}
    : Result<&2, &2, Z.Zone.Error, DT.UtcOffset>
  }
