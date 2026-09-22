import Base
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import ../zone.bend as Z
import ../zoned.bend as Zd

def Readme.unix(r: Result<&2, &2, I.Instant.Error, U32>) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{n}:
      U32.show(n)

def Readme.zdt(
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{zdt}:
      Readme.unix(I.Instant.to_unix(Zd.ZonedDateTime.to_instant(zdt)))

def Readme.off(
  r: Result<&2, &2, DT.UtcOffset.Error, DT.UtcOffset>
) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{off}:
      Readme.zdt(
        Zd.ZonedDateTime.from_local(
          DT.LocalDateTime.from(
            D.Date{2026, 9, 18}, DT.TimeOfDay{15, 30, 0, DT.FracNone{}}
          ),
          Z.Zone.fixed(off)
        )
      )

def main() -> IO(Unit):
  IO.print(Readme.off(DT.UtcOffset.from(False{}, 3, 0)))
