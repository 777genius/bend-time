# Time proof status

Domain: proleptic Gregorian dates years `1..9999`, RFC 3339 subset with a
required offset. No clock. Day counts use Hinnant civil days (not
`U32 * 86400`).

| Claim | Status | Domain |
|---|---|---|
| `Date.from(2026, 9, 18)` | proved | closed |
| `Date.from(2026, 2, 30)` fails | proved | closed |
| `Date.leap(2000)` | proved | leap |
| `Date.leap(1900)` | proved | common |
| `show` of offset 0 is `Z` | proved | closed |
| `to_unix(1970-01-01) = 0` | proved | epoch |
| `weekday(1970-01-01) = Thu` | proved | closed |
| `from_days(to_days(2026-09-18))` | proved | closed |
| `to_unix(2026-09-18) = 1789689600` | tested | |
| add/sub days, 1-01-01 / 9999-12-31 roundtrip | tested | |
| `1900-01-01` unix | tested | `OutOfRange` |
| `read("…T15:30:00+03:00")` same unix as `…T12:30:00Z` | tested | |
| `1900-02-29` / `2000-02-29` | tested | |
| `read("…T15:30:00+03:00")` same instant as `…T12:30:00Z` | tested | |
| `-00:00`, space vs `T`, missing offset, `:60`, 10th frac digit | tested | |
| `read(show(x))` keeps the instant | tested | Z / +03:00 / +00:00 |

No `@unsafe`. No `F32`. No `IO.now`. Payload walks do not call Base
`String.length` / `String.split` / `List.length`.
