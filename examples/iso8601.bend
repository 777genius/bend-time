import Base
import ../duration.bend as Dur
import ../iso8601.bend as Iso

def main() -> IO(Unit):
  IO.print(Iso.Iso8601.show_duration(Dur.Duration.from_secs(5400)))
