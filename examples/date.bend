import Base
import ../date.bend as D

def Readme.from_result(
  r: Result<&2, &2, D.Date.Error, D.Date>
) -> String:
  match r:
    case Done{_}:
      "ok"
    case Fail{_}:
      "fail"

def main() -> IO(Unit):
  IO.print(Readme.from_result(D.Date.from(2026, 9, 18)))
