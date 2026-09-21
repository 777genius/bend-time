import Base
import ../date.bend as D
import ../instant.bend as I

def Readme.from_unix(
  r: Result<&2, &2, I.Instant.Error, U32>
) -> String:
  match r:
    case Done{n}:
      U32.show(n)
    case Fail{_}:
      "fail"

def Readme.of_date(
  r: Result<&2, &2, D.Date.Error, D.Date>
) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{d}:
      Readme.from_unix(I.Instant.to_unix(I.Instant.from_utc_date(d)))

def main() -> IO(Unit):
  IO.print(Readme.of_date(D.Date.from(2026, 9, 18)))
