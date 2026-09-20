import Base
import ./date.bend as D
import ./datetime.bend as DT
import ./format.bend as F

law date_2026:
  {
    D.Date.from(2026, 9, 18) == Done{D.Date{2026, 9, 18}}
    : Result<&2, &2, D.Date.Error, D.Date>
  }

law date_feb30:
  {
    D.Date.from(2026, 2, 30) == Fail{D.InvalidDate{2026, 2, 30}}
    : Result<&2, &2, D.Date.Error, D.Date>
  }

law leap_2000:
  {D.Date.leap(2000) == True{} : Bool}

law leap_1900:
  {D.Date.leap(1900) == False{} : Bool}

law show_z:
  {
    F.Format.show_off(DT.OffsetZero{}) == "Z" : String
  }
