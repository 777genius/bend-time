# bend-time

Proleptic Gregorian dates, UTC instants, elapsed `Duration`, calendar `Period`, ISO week, `P`/`PT`, an RFC 3339 **subset**, IANA zones from TZif, and RFC 9557 text for [Bend 2](https://github.com/bendlang/bend). No clock. Zone is a second package root (`zone_package.bend`); it is not on the core hub hash.

## Install

```python
import 0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend as D
import 0x9b6a4fc7ceea91864a75396e1b8365e5/week.bend as W
import 0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend as I
import 0x9b6a4fc7ceea91864a75396e1b8365e5/duration.bend as Dur
import 0x9b6a4fc7ceea91864a75396e1b8365e5/period.bend as Per
import 0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend as DT
import 0x9b6a4fc7ceea91864a75396e1b8365e5/format.bend as F
import 0x9b6a4fc7ceea91864a75396e1b8365e5/iso8601.bend as Iso
```

[date](https://hub.bend-lang.com/0x9b6a4fc7ceea91864a75396e1b8365e5/date.bend) · [week](https://hub.bend-lang.com/0x9b6a4fc7ceea91864a75396e1b8365e5/week.bend) · [instant](https://hub.bend-lang.com/0x9b6a4fc7ceea91864a75396e1b8365e5/instant.bend) · [duration](https://hub.bend-lang.com/0x9b6a4fc7ceea91864a75396e1b8365e5/duration.bend) · [period](https://hub.bend-lang.com/0x9b6a4fc7ceea91864a75396e1b8365e5/period.bend) · [datetime](https://hub.bend-lang.com/0x9b6a4fc7ceea91864a75396e1b8365e5/datetime.bend) · [format](https://hub.bend-lang.com/0x9b6a4fc7ceea91864a75396e1b8365e5/format.bend) · [iso8601](https://hub.bend-lang.com/0x9b6a4fc7ceea91864a75396e1b8365e5/iso8601.bend) · [manifest](https://hub.bend-lang.com/0x9b6a4fc7ceea91864a75396e1b8365e5/manifest)

This hash is v0.4.0. v0.3.0 was `0x6ce79f1afc193de100ced4c79d7e2350`. `format.bend` and `iso8601.bend` pull [bend-parse](https://github.com/777genius/bend-parse) as `0xe49a3e6521e1b71e55654a885f27bcc1`. From this repo: `import ./date.bend as D`, `import ./week.bend as W`, `import ./iso8601.bend as Iso`.

Zone is a second hash (v0.5.0). Core stays `0x9b6a4fc7ceea91864a75396e1b8365e5`.

```python
import 0x5118d7c8d8a6cbdfca48647d1a5a6fde/zone.bend as Z
import 0x5118d7c8d8a6cbdfca48647d1a5a6fde/zoned.bend as Zd
import 0x5118d7c8d8a6cbdfca48647d1a5a6fde/tzif.bend as Tf
import 0x5118d7c8d8a6cbdfca48647d1a5a6fde/zone_format.bend as Zf
```

[zone](https://hub.bend-lang.com/0x5118d7c8d8a6cbdfca48647d1a5a6fde/zone.bend) · [zoned](https://hub.bend-lang.com/0x5118d7c8d8a6cbdfca48647d1a5a6fde/zoned.bend) · [tzif](https://hub.bend-lang.com/0x5118d7c8d8a6cbdfca48647d1a5a6fde/tzif.bend) · [zone_format](https://hub.bend-lang.com/0x5118d7c8d8a6cbdfca48647d1a5a6fde/zone_format.bend) · [manifest](https://hub.bend-lang.com/0x5118d7c8d8a6cbdfca48647d1a5a6fde/manifest)

`from_tzif` is on `tzif.bend`. Copy: [`examples/zoned.bend`](examples/zoned.bend) prints `1789734600`. [`examples/zone.bend`](examples/zone.bend) prints `2026-09-18T15:30:00+03:00[Europe/Moscow]`.

## v0.5

IANA zones from TZif, POSIX TZ `M`-rules, `ZonedDateTime`, RFC 9557 `[id]`. Gap and fold Fail on `resolve`. `add(Duration)` re-resolves; `add_period` is civil then `from_local`. No registry. No Clock. Core hub hash unchanged.

## v0.4

Month bounds, `with_*`, weekday movers, `until_days`. `IsoWeek`. `Period.between`. Local/Offset `add_period` (offset kept). `Duration.from_mins` / `to_hms`. Instant trunc. `Iso8601` `P`/`PT` (`PT1H30M`, `P1Y2M`). Not a Span. Not Clock.

Unix still lives on `Instant`, not `Date`. `from_utc_date` is midnight UTC. Seconds, not millis.

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

Prints `2026-09-18T12:30:00Z`. Copy: [`examples/readme.bend`](examples/readme.bend). Last day of February: [`examples/month.bend`](examples/month.bend) prints `28`. `PT1H30M`: [`examples/iso8601.bend`](examples/iso8601.bend). Unix midnight UTC: [`examples/unix.bend`](examples/unix.bend) prints `1789689600`.

## API

```text
Date.from(year, month, day) -> Result<Date, Date.Error>
Date.from_days / add_days / sub_days
Date.start_of_month / end_of_month / start_of_year / end_of_year
Date.with_day / with_month / with_year
Date.days_in_month(date) -> Result<U32, Date.Error>
Date.next_weekday / previous_weekday
Date.next_or_same_weekday / previous_or_same_weekday
Date.until_days(start, end) -> Result<U32, Date.Error>
Date.weekday(date) -> Weekday
Weekday.to_u32(w) -> U32
Date.is_lt / is_le / is_gt / is_ge

IsoWeek.start(d) -> Result<Date, Date.Error>
IsoWeek.from_date(d) -> Result<IsoWeek, Date.Error>
IsoWeek.from(year, week, weekday) -> Result<Date, Date.Error>

Instant.from_unix(secs) -> Instant
Instant.to_unix(i) -> Result<U32, Instant.Error>
Instant.from_utc_date(date) -> Instant
Instant.to_utc_date(i) -> Result<Date, Date.Error>
Instant.from(days, sod, nanos) -> Result<Instant, Instant.Error>
Instant.add / sub
Instant.until(start, end) -> Result<Duration, Instant.Error>
Instant.is_eq / is_lt / is_le / is_gt / is_ge
Instant.trunc_sec / trunc_min / trunc_hour / trunc_day

Duration.zero() -> Duration
Duration.from_secs(secs) -> Duration
Duration.from_days(days) -> Duration
Duration.from_hours(h) -> Result<Duration, Duration.Error>
Duration.from_mins(mi) -> Result<Duration, Duration.Error>
Duration.from_hms(h, mi, s) -> Result<Duration, Duration.Error>
Duration.to_hms(d) -> Result<Hms, Duration.Error>
Duration.to_secs(d) -> Result<U32, Duration.Error>
Duration.add / sub

Period.from(years, months, days) -> Result<Period, Period.Error>
Period.add_to(p, date) -> Result<Date, Date.Error>
Period.between(start, end) -> Result<Period, Period.Error>

LocalDateTime.from(date, time) -> LocalDateTime
LocalDateTime.add / sub            Duration
LocalDateTime.until(start, end) -> Result<Duration, Instant.Error>
LocalDateTime.add_period(ldt, p) -> Result<LocalDateTime, Date.Error>
LocalDateTime.at_offset(local, offset) -> OffsetDateTime

OffsetDateTime.to_instant(odt) -> Instant
OffsetDateTime.from_instant(i, offset) -> Result<OffsetDateTime, Date.Error>
OffsetDateTime.from_instant_utc(i) -> Result<OffsetDateTime, Date.Error>
OffsetDateTime.add / sub           Duration
OffsetDateTime.add_period(odt, p) -> Result<OffsetDateTime, Date.Error>
OffsetDateTime.to_local(odt) -> LocalDateTime
OffsetDateTime.same_instant(a, b) -> Bool
OffsetDateTime.to_unix / from_unix

Format.read_date / show_date
Format.read / show
Format.read_instant / show_instant

Iso8601.show_duration / read_duration
Iso8601.show_period / read_period

Zone.fixed(offset) -> Zone
Zone.id(z) -> String
Zone.at(z, instant) -> Result<UtcOffset, Zone.Error>
Zone.resolve / resolve_earlier / resolve_later
Zone.from_tzif(id, bytes) -> Result<Zone, Zone.Error>   # tzif.bend

ZonedDateTime.from_instant(i, z) -> Result<ZonedDateTime, Zone.Error>
ZonedDateTime.from_local(ldt, z) -> Result<ZonedDateTime, Zone.Error>
ZonedDateTime.to_instant(zdt) -> Instant
ZonedDateTime.to_local / to_offset / to_odt
ZonedDateTime.zone(zdt) -> Zone
ZonedDateTime.same_instant(a, b) -> Bool
ZonedDateTime.add / sub            Duration
ZonedDateTime.add_period(zdt, p) -> Result<ZonedDateTime, Zone.Error>

ZoneFormat.show(zdt) -> Result<String, ZoneFormat.Error>
ZoneFormat.read(text, zone) -> Result<ZonedDateTime, ZoneFormat.Error>
```

- Years `1..9999`. Invalid civil dates fail. `with_*` is strict (`Date.from`); month clamp is `Period.add_to` only (`2026-01-31` + 1 month → `2026-02-28`).
- Unix is Instant, UTC, `U32`, 1970-01-01 through 2106-02-07. Year 1 is a valid Instant, not a valid unix second. `to_unix` drops nanos.
- `Duration` is non-negative elapsed time. `from_secs` is total. `to_hms` can Fail (hours overflow). ISO show uses stored days (`P1D`, not `PT24H`). `PT90M` is `from_mins(90)`, not `from_hms`.
- `Instant.until` / `Date.until_days` / `Period.between` fail if the end is before the start.
- `OffsetDateTime.add(Duration)` moves the timeline. `add_period` keeps the wall and the offset. They do not share a path.
- `Weekday` is Mon..Sun. `1970-01-01` is Thursday. `0001-01-01` is Monday.
- RFC 3339: offset required. `Z` and `+00:00` are 0; `show` emits `Z`; `-00:00` fails. No `:60`, no `24:00:00`, no space instead of `T`, at most 9 fraction digits.
- `Iso8601` duration is `P[nD]T[nH][nM][nS]`. Period is `P[nY][nM][nW][nD]` (`W` = 7 days). `P1Y` as Duration fails. Mixed `P1YT1H` fails both. Trailing space is `Extra`. `read(show(x))` keeps the value, not the spelling.
- `Zone` is Fixed or IANA rules. `from_local` is strict `resolve` (gap and fold Fail). `add(Duration)` re-resolves the Instant; `add_period` moves civil time then `from_local`. They do not share a path and do not call `OffsetDateTime.add`.
- RFC 9557 `show`/`read` split on `[` first. `read` takes a caller-supplied `Zone`; there is no registry. Offset in the text must match `Zone.at`. Fold is the offset, not `resolve`.

`Format.Error` wraps parse failures. A format consumer does not import parse.

## Proofs

Closed date/leap/`Z`/epoch laws are **proved**. `Zone.at(fixed(Z), unix 0)` is **proved** in `ZONE_PROOF.bend` (`./tools/gate-zone`). Calendar movers, DST gap/fold, Moscow 15:30, and RFC 9557 are **tested**. Table: [docs/proof-status.md](docs/proof-status.md).

## Check

Bend **2.0.5** (`0b7e2b11`), bun 1.3.11, clang 14+. Pin: [docs/compatibility.md](docs/compatibility.md).

```sh
./tools/e2e
./tools/e2e-zone
```

## License

Apache-2.0. Copyright 2026 Илия.
