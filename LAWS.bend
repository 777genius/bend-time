import Base
import ./date.bend as D
import ./datetime.bend as DT
import ./duration.bend as Dur
import ./format.bend as F
import ./instant.bend as I
import ./period.bend as Per

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

law unix_epoch:
  {
    I.Instant.to_unix(I.Instant.from_utc_date(D.Date{1970, 1, 1})) == Done{0}
    : Result<&2, &2, I.Instant.Error, U32>
  }

law weekday_thu:
  {D.Date.weekday(D.Date{1970, 1, 1}) == D.Thu{} : D.Weekday}

law from_days_2026:
  {
    D.Date.from_days(D.Date.to_days(D.Date{2026, 9, 18}))
    == Done{D.Date{2026, 9, 18}}
    : Result<&2, &2, D.Date.Error, D.Date>
  }

law dur_zero:
  {
    Dur.Duration.add(Dur.Duration.zero(), Dur.Duration.zero())
    == Done{Dur.Duration.zero()}
    : Result<&2, &2, Dur.Duration.Error, Dur.Duration>
  }

law dur_secs0:
  {
    Dur.Duration.to_secs(Dur.Duration.from_secs(0)) == Done{0}
    : Result<&2, &2, Dur.Duration.Error, U32>
  }

law period_norm:
  {
    Per.Period.from(0, 13, 0) == Per.Period.from(1, 1, 0)
    : Result<&2, &2, Per.Period.Error, Per.Period>
  }

law som_2026:
  {
    D.Date.start_of_month(D.Date{2026, 9, 18}) == D.Date{2026, 9, 1}
    : D.Date
  }

law between_id:
  {
    Per.Period.between(D.Date{2026, 1, 1}, D.Date{2026, 1, 1})
    == Per.Period.from(0, 0, 0)
    : Result<&2, &2, Per.Period.Error, Per.Period>
  }

law hms_zero:
  {
    Dur.Duration.to_hms(Dur.Duration.zero()) == Done{Dur.Hms{0, 0, 0}}
    : Result<&2, &2, Dur.Duration.Error, Dur.Duration.Hms>
  }
