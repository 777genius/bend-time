# bend-time

Proleptic Gregorian dates and an RFC 3339 **subset** for [Bend 2](https://github.com/bendlang/bend). No clock, no IANA, no month arithmetic. Import `date.bend` for numbers; `format.bend` for text.

## Install

```python
import 0x6648eb78d8a978a0e437eabbfbc841cd/format.bend as F
import 0x6648eb78d8a978a0e437eabbfbc841cd/date.bend as D
```

[format](https://hub.bend-lang.com/0x6648eb78d8a978a0e437eabbfbc841cd/format.bend) · [date](https://hub.bend-lang.com/0x6648eb78d8a978a0e437eabbfbc841cd/date.bend) · [manifest](https://hub.bend-lang.com/0x6648eb78d8a978a0e437eabbfbc841cd/manifest)

This hash is v0.1.0. `format.bend` pulls [bend-parse](https://github.com/777genius/bend-parse) as `0xe49a3e6521e1b71e55654a885f27bcc1`. From this repo: `import ./format.bend as F`.

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

Prints `2026-09-18T12:30:00Z`. Copy: [`examples/readme.bend`](examples/readme.bend). Numbers only: [`examples/date.bend`](examples/date.bend) prints `ok`.

## API

```text
Date.from(year, month, day) -> Result<Date, Date.Error>
Format.read_date(text) -> Result<Date, Format.Error>
Format.show_date(date) -> String
Format.read(text) -> Result<OffsetDateTime, Format.Error>
Format.show(odt) -> String
OffsetDateTime.same_instant(a, b) -> Bool
```

- Years `1..9999`. Invalid civil dates fail (no rollover). `1900-02-29` fails; `2000-02-29` succeeds.
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
