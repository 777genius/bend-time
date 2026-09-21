# bend-time

Proleptic Gregorian dates, UTC instants, elapsed `Duration`, calendar `Period`, and an RFC 3339 **subset** for [Bend 2](https://github.com/bendlang/bend). Unix seconds, weekday, day shift, Instant arithmetic. No clock, no IANA. Import `date.bend` for the calendar; `instant.bend` for the timeline; `format.bend` for text.

## Install

```python
import 0x6ce79f1afc193de100ced4c79d7e2350/format.bend as F
import 0x6ce79f1afc193de100ced4c79d7e2350/date.bend as D
import 0x6ce79f1afc193de100ced4c79d7e2350/instant.bend as I
import 0x6ce79f1afc193de100ced4c79d7e2350/duration.bend as Dur
import 0x6ce79f1afc193de100ced4c79d7e2350/period.bend as Per
import 0x6ce79f1afc193de100ced4c79d7e2350/datetime.bend as DT
```

[format](https://hub.bend-lang.com/0x6ce79f1afc193de100ced4c79d7e2350/format.bend) · [date](https://hub.bend-lang.com/0x6ce79f1afc193de100ced4c79d7e2350/date.bend) · [instant](https://hub.bend-lang.com/0x6ce79f1afc193de100ced4c79d7e2350/instant.bend) · [duration](https://hub.bend-lang.com/0x6ce79f1afc193de100ced4c79d7e2350/duration.bend) · [period](https://hub.bend-lang.com/0x6ce79f1afc193de100ced4c79d7e2350/period.bend) · [datetime](https://hub.bend-lang.com/0x6ce79f1afc193de100ced4c79d7e2350/datetime.bend) · [manifest](https://hub.bend-lang.com/0x6ce79f1afc193de100ced4c79d7e2350/manifest)

This hash is v0.3.0. v0.2.0 was `0xa2203fa800985a49e0255336bb562c81`. `format.bend` pulls [bend-parse](https://github.com/777genius/bend-parse) as `0xe49a3e6521e1b71e55654a885f27bcc1`. From this repo: `import ./format.bend as F`, `import ./instant.bend as I`.

## Upgrade from v0.2

Unix moved off `Date`:

| v0.2 | v0.3 |
|---|---|
| `Date.to_unix(d)` | `Instant.to_unix(Instant.from_utc_date(d))` |
| `Date.from_unix(s)` | `Instant.to_utc_date(Instant.from_unix(s))` |

`from_utc_date` is **midnight UTC**, not local and not “the unix of a birthday”. `Instant.from_unix` is total (no `Result`). Seconds, not millis.

## Example

```python
import Base
import ./format.bend as F

def Readme.from_result(
  r: Result<&2, &2, F.Format.Error, String>
) -> String:
  match r:
    case Done{s}:
      s
    case Fail{_}:
      "fail"

def main() -> IO(Unit):
  IO.print(
    Readme.from_result(
      F.Format.show_read(F.Format.read("2026-09-18T12:30:00Z"))
    )
  )
```

Prints `2026-09-18T12:30:00Z`. Copy: [`examples/readme.bend`](examples/readme.bend). Numbers only: [`examples/date.bend`](examples/date.bend) prints `ok`. Unix midnight UTC: [`examples/unix.bend`](examples/unix.bend) prints `1789689600`. Ninety minutes as sod: [`examples/duration.bend`](examples/duration.bend) prints `5400`.

## API

```text
Date.from(year, month, day) -> Result<Date, Date.Error>
Date.from_days(z) -> Result<Date, Date.Error>
Date.add_days(date, n) -> Result<Date, Date.Error>
Date.sub_days(date, n) -> Result<Date, Date.Error>
Date.weekday(date) -> Weekday
Instant.from_unix(secs) -> Instant
Instant.to_unix(i) -> Result<U32, Instant.Error>
Instant.from_utc_date(date) -> Instant
Instant.to_utc_date(i) -> Result<Date, Date.Error>
Instant.is_eq(a, b) -> Bool
Instant.is_lt / is_le / is_gt / is_ge
Instant.from(days, sod, nanos) -> Result<Instant, Instant.Error>
Instant.add(i, d) -> Result<Instant, Instant.Error>
Instant.sub(i, d) -> Result<Instant, Instant.Error>
Instant.until(start, end) -> Result<Duration, Instant.Error>
Date.is_lt / is_le / is_gt / is_ge
Duration.zero() -> Duration
Duration.from_secs(secs) -> Duration
Duration.to_secs(d) -> Result<U32, Duration.Error>
Duration.from_hms(h, mi, s) -> Result<Duration, Duration.Error>
Duration.add / sub
Period.from(years, months, days) -> Result<Period, Period.Error>
Period.add_to(p, date) -> Result<Date, Date.Error>
Format.read_date(text) -> Result<Date, Format.Error>
Format.show_date(date) -> String
Format.read(text) -> Result<OffsetDateTime, Format.Error>
Format.show(odt) -> String
Format.read_instant(text) -> Result<Instant, Format.Error>
Format.show_instant(i) -> Result<String, Date.Error>
OffsetDateTime.to_instant(odt) -> Instant
OffsetDateTime.from_instant(i, offset) -> Result<OffsetDateTime, Date.Error>
OffsetDateTime.from_instant_utc(i) -> Result<OffsetDateTime, Date.Error>
OffsetDateTime.add(odt, d) -> Result<OffsetDateTime, Instant.Error>
OffsetDateTime.sub(odt, d) -> Result<OffsetDateTime, Instant.Error>
LocalDateTime.from(date, time) -> LocalDateTime
LocalDateTime.at_offset(local, offset) -> OffsetDateTime
OffsetDateTime.to_local(odt) -> LocalDateTime
OffsetDateTime.same_instant(a, b) -> Bool
OffsetDateTime.to_unix(odt) -> Result<U32, Date.Error>
OffsetDateTime.from_unix(secs) -> Result<OffsetDateTime, Date.Error>
```

- Years `1..9999`. Invalid civil dates fail (no rollover). `1900-02-29` fails; `2000-02-29` succeeds.
- Unix seconds live on `Instant`, UTC, unsigned, 1970-01-01 through 2106-02-07. Before 1970 is `Instant.Error`. `from_utc_date` is midnight UTC. `to_unix` drops nanos. `Date` has no unix.
- Year 1 is a valid Instant; it is not a valid unix second. Reverse Instant through `from_instant_utc`, not through unix.
- `Duration` is non-negative elapsed time (not months). `from_secs` is total. `to_secs` drops nanos. `Instant.until` fails if the end is before the start.
- `Period.add_to` clamps to the last valid day of the month (`2026-01-31` + 1 month → `2026-02-28`). `Date.from` stays strict.
- `from_instant` keeps the Instant and moves the clock. `LocalDateTime.at_offset` keeps the wall fields and changes the Instant.
- `Weekday` is Mon..Sun. `1970-01-01` is Thursday.
- Offset is required on `Format.read`. `Z` and `+00:00` are offset 0; `show` emits `Z`. `-00:00` is rejected.
- No `:60`, no `24:00:00`, no space instead of `T`, at most 9 fraction digits.
- `2026-09-18T15:30:00+03:00` and `2026-09-18T12:30:00Z` are the same instant.
- Text roundtrip of spelling is not promised; `read(show(x))` keeps the instant.

`Format.Error` wraps parse failures. A format consumer does not import parse.

## Proofs

Closed date/leap/`Z` show are **proved**. Same-instant and the RFC 3339 fail set are **tested**. Table: [docs/proof-status.md](docs/proof-status.md).

## Check

Bend **2.0.5** (`0b7e2b11`), bun 1.3.11, clang 14+. Pin: [docs/compatibility.md](docs/compatibility.md).

```sh
./tools/e2e
```

## License

Apache-2.0. Copyright 2026 Илия.
