# Time proof status

Domain: proleptic Gregorian dates years `1..9999`, RFC 3339 subset with a
required offset, ISO `P`/`PT`. No clock. Day counts use Hinnant civil days.
Unix is an Instant view, not a Date method.

| Claim | Status | Domain |
|---|---|---|
| `Date.from(2026, 9, 18)` | proved | closed |
| `Date.from(2026, 2, 30)` fails | proved | closed |
| `Date.leap(2000)` / `leap(1900)` | proved | leap / common |
| `show` of offset 0 is `Z` | proved | closed |
| `to_unix(from_utc_date(1970-01-01)) = 0` | proved | epoch |
| `weekday(1970-01-01) = Thu` | proved | closed |
| `from_days(to_days(2026-09-18))` | proved | closed |
| `Duration.add(zero, zero)` | proved | |
| `to_secs(from_secs(0)) = 0` | proved | |
| `Period.from(0,13,0) = from(1,1,0)` | proved | |
| `start_of_month(2026-09-18) = 2026-09-01` | proved | |
| `between(2026-01-01, 2026-01-01) = from(0,0,0)` | proved | |
| `to_hms(zero) = Hms{0,0,0}` | proved | |
| `to_unix(from_utc_date(2026-09-18)) = 1789689600` | tested | Instant |
| add/sub days, 1-01-01 / 9999-12-31 roundtrip | tested | |
| `1900-01-01` unix / year 1 Instant ≠ unix | tested | |
| Instant add/until/is_lt; Date.is_lt | tested | |
| `from_instant` +03:00 / −01:00; `at_offset` | tested | |
| `read_instant` Z = +03:00; `show_instant` is Z | tested | Instant text |
| Jan 31 + 1 month clamps to Feb 28 | tested | Period |
| LDT + Duration; LDT/ODT `add_period` keeps wall | tested | |
| `1900-02-29` / `2000-02-29` | tested | |
| `+03:00` same instant and unix as `Z` | tested | |
| `-00:00`, space vs `T`, missing offset, `:60`, 10th frac digit | tested | |
| `read(show(x))` keeps the instant | tested | Z / +03:00 / +00:00 |
| `PT1H30M` / `P1Y2M` show and read | tested | Iso8601 |
| `Zone.at(fixed(Z), from_unix(0)) = OffsetZero` | proved | ZONE_PROOF |
| NY 2026-03-08 02:30 gap / 01:30 fold earlier+later | tested | Zone |
| Moscow 2026-09-18 15:30 → East 3, unix 1789734600 | tested | TZif |

No `@unsafe`. No `F32`. No `IO.now`. Payload walks do not call Base
`String.length` / `String.split` / `List.length`. Core `PROOF.bend` does
not import zone.
