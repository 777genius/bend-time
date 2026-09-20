import Base
import ../date.bend as D

def Readme.from_unix(
  r: Result<&2, &2, D.Date.Error, U32>
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
      Readme.from_unix(D.Date.to_unix(d))

def main() -> IO(Unit):
  IO.print(Readme.of_date(D.Date.from(2026, 9, 18)))
