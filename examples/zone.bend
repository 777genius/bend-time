import Base
import 0x888714bde93f46c139372bb9fdc57a19/bytes.bend as B
import 0x888714bde93f46c139372bb9fdc57a19/hex.bend as Hx
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import ../tzif.bend as Tf
import ../zone.bend as Z
import ../zoned.bend as Zd
import ../zone_format.bend as Zf
import ../tests/tzif/moscow.bend as Mc

def ZoneEx.cat(
  xs: List<&2, U32>, ys: List<&2, U32>
) -> List<&2, U32>:
  match xs:
    case Nil{}:
      ys
    case Con{h, t}:
      Con{h, ZoneEx.cat(t, ys)}

def ZoneEx.hexes.cat(
  xs: List<&2, U32>, r: Result<&2, &2, Hx.Hex.Error, B.Bytes>
) -> Result<&2, &2, Z.Zone.Error, List<&2, U32>>:
  match r:
    case Fail{_}:
      Fail{Z.Invalid{}}
    case Done{B.Bytes{data}}:
      Done{ZoneEx.cat(xs, data)}

def ZoneEx.hexes.go(
  chunks: List<&2, String>,
  acc: Result<&2, &2, Z.Zone.Error, List<&2, U32>>,
  +id: String
) -> Result<&2, &2, Z.Zone.Error, Z.Zone>:
  match chunks:
    case Nil{}:
      match acc:
        case Fail{e}:
          Fail{e}
        case Done{xs}:
          Tf.Zone.from_tzif(id, B.Bytes{xs})
    case Con{h, t}:
      match acc:
        case Fail{e}:
          Fail{e}
        case Done{xs}:
          ZoneEx.hexes.go(t, ZoneEx.hexes.cat(xs, Hx.Hex.decode(h)), id)

def ZoneEx.txt(
  r: Result<&2, &2, Zf.ZoneFormat.Error, String>
) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{s}:
      s

def ZoneEx.zdt(
  r: Result<&2, &2, Z.Zone.Error, Zd.ZonedDateTime>
) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{zdt}:
      ZoneEx.txt(Zf.ZoneFormat.show(zdt))

def ZoneEx.show(
  r: Result<&2, &2, Z.Zone.Error, Z.Zone>
) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{z}:
      ZoneEx.zdt(
        Zd.ZonedDateTime.from_local(
          DT.LocalDateTime.from(
            D.Date{2026, 9, 18}, DT.TimeOfDay{15, 30, 0, DT.FracNone{}}
          ),
          z
        )
      )

def main() -> IO(Unit):
  IO.print(
    ZoneEx.show(
      ZoneEx.hexes.go(Mc.Moscow.chunks(), Done{Nil{}}, "Europe/Moscow")
    )
  )
