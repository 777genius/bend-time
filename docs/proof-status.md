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
| `1900-02-29` / `2000-02-29` | tested | |
| `read("…T15:30:00+03:00")` same instant as `…T12:30:00Z` | tested | |
| `-00:00`, space vs `T`, missing offset, `:60`, 10th frac digit | tested | |
| `read(show(x))` keeps the instant | tested | Z / +03:00 / +00:00 |

No `@unsafe`. No `F32`. No `IO.now`. Payload walks do not call Base
`String.length` / `String.split` / `List.length`.
