# Time proof status

Domain: proleptic Gregorian dates years `1..9999`, RFC 3339 subset with a
required offset. No clock. Day counts use Hinnant civil days (not
`U32 * 86400`). Unix is an Instant view, not a Date method.

| Claim | Status | Domain |
|---|---|---|
| `Date.from(2026, 9, 18)` | proved | closed |
| `Date.from(2026, 2, 30)` fails | proved | closed |
| `Date.leap(2000)` | proved | leap |
| `Date.leap(1900)` | proved | common |
| `show` of offset 0 is `Z` | proved | closed |
| `Instant.to_unix(from_utc_date(1970-01-01)) = 0` | proved | epoch |
| `weekday(1970-01-01) = Thu` | proved | closed |
| `from_days(to_days(2026-09-18))` | proved | closed |
| `to_unix(from_utc_date(2026-09-18)) = 1789689600` | tested | Instant |
| add/sub days, 1-01-01 / 9999-12-31 roundtrip | tested | |
| `1900-01-01` unix | tested | `Instant.Error` |
| year 1 `to_unix` fails; `from_instant_utc` succeeds | tested | Instant ≠ unix |
| `Duration.add(zero, zero)` | proved | |
| `Duration.to_secs(from_secs(0)) = 0` | proved | |
| Instant add/until/is_lt; Date.is_lt | tested | |
| `from_instant` +03:00 / −01:00; LocalDateTime.at_offset | tested | |
| `read_instant` Z = +03:00; `show_instant` is Z | tested | Instant text |
| `Period.from(0,13,0) = from(1,1,0)` | proved | |
| Jan 31 + 1 month clamps to Feb 28 | tested | Period |
| `read("…T15:30:00+03:00")` same unix as `…T12:30:00Z` | tested | |
| `1900-02-29` / `2000-02-29` | tested | |
| `read("…T15:30:00+03:00")` same instant as `…T12:30:00Z` | tested | |
| `-00:00`, space vs `T`, missing offset, `:60`, 10th frac digit | tested | |
| `read(show(x))` keeps the instant | tested | Z / +03:00 / +00:00 |

No `@unsafe`. No `F32`. No `IO.now`. Payload walks do not call Base
`String.length` / `String.split` / `List.length`.
