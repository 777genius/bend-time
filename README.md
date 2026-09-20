# bend-time

Proleptic Gregorian dates and an RFC 3339 **subset** for [Bend 2](https://github.com/bendlang/bend). Unix seconds, weekday, day shift. No clock, no IANA, no month arithmetic. Import `date.bend` for numbers; `format.bend` for text.

## Install

```python
import 0xa2203fa800985a49e0255336bb562c81/format.bend as F
import 0xa2203fa800985a49e0255336bb562c81/date.bend as D
```

[format](https://hub.bend-lang.com/0xa2203fa800985a49e0255336bb562c81/format.bend) · [date](https://hub.bend-lang.com/0xa2203fa800985a49e0255336bb562c81/date.bend) · [manifest](https://hub.bend-lang.com/0xa2203fa800985a49e0255336bb562c81/manifest)

This hash is v0.2.0. `format.bend` pulls [bend-parse](https://github.com/777genius/bend-parse) as `0xe49a3e6521e1b71e55654a885f27bcc1`. From this repo: `import ./format.bend as F`.

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

Prints `2026-09-18T12:30:00Z`. Copy: [`examples/readme.bend`](examples/readme.bend). Numbers only: [`examples/date.bend`](examples/date.bend) prints `ok`. Unix midnight UTC: [`examples/unix.bend`](examples/unix.bend) prints `1789689600`.

## API

```text
Date.from(year, month, day) -> Result<Date, Date.Error>
Date.from_days(z) -> Result<Date, Date.Error>
Date.add_days(date, n) -> Result<Date, Date.Error>
Date.sub_days(date, n) -> Result<Date, Date.Error>
Date.weekday(date) -> Weekday
Date.to_unix(date) -> Result<U32, Date.Error>
Date.from_unix(secs) -> Result<Date, Date.Error>
Format.read_date(text) -> Result<Date, Format.Error>
Format.show_date(date) -> String
Format.read(text) -> Result<OffsetDateTime, Format.Error>
Format.show(odt) -> String
OffsetDateTime.same_instant(a, b) -> Bool
OffsetDateTime.to_unix(odt) -> Result<U32, Date.Error>
OffsetDateTime.from_unix(secs) -> Result<OffsetDateTime, Date.Error>
```

- Years `1..9999`. Invalid civil dates fail (no rollover). `1900-02-29` fails; `2000-02-29` succeeds.
- Unix seconds are UTC, unsigned, 1970-01-01 through 2106-02-07. Before 1970 is `OutOfRange`. `Date.to_unix` is midnight UTC. Fractions are truncated.
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
