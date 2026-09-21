import Base
import ../duration.bend as Dur

def Readme.sod(d: Dur.Duration) -> String:
  match d:
    case Dur.Duration{_, sod, _}:
      U32.show(sod)

def main() -> IO(Unit):
  IO.print(Readme.sod(Dur.Duration.from_secs(5400)))
