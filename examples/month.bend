import Base
import ../date.bend as D

def Readme.day(r: Result<&2, &2, D.Date.Error, D.Date>) -> String:
  match r:
    case Fail{_}:
      "fail"
    case Done{D.Date{_, _, d}}:
      U32.show(d)

def main() -> IO(Unit):
  IO.print(Readme.day(D.Date.end_of_month(D.Date{2026, 2, 1})))
