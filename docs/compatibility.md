# Toolchain compatibility

## Legacy E2E

| Tool | Version |
|---|---|
| Bend | 2.0.5 at `0b7e2b11c1054f5d0f4eb955cadb47997ef1115d` |
| bun | 1.3.11 |
| node | 24 (compiled JS once) |
| clang | 14+ |

`./tools/bend` and the existing `./tools/e2e` remain pinned to Bend 2.0.5.
Set `BEND_HOME` to a checkout of that commit to skip the wrapper's clone.
This E2E gate covers interpreted JS, native compilation, and compiled Node execution.

## Core compatibility

The independent CI compatibility matrix checks these Bend source versions with bun 1.3.11:

| Bend | Pinned source commit |
|---|---|
| 2.0.28 | `bc178404f4778704fa5584a73fcdf72bcdf9f32c` |
| 2.0.34 | `7d8a3eb036042c6549461054d25a10f26d361c5c` |
| 2.0.36 | `ae1101ca7d15364f9274fa6b1367d175884a7da7` |

Run `BEND_HOME=/path/to/bend-checkout ./tools/check-compatibility`.
The checkout must contain `bend2/main.ts`; this script invokes bun directly.
For local verification with an already verified Bend binary, use
`BEND_COMPAT=/absolute/path/to/bend ./tools/check-compatibility` instead.
Neither mode downloads a compiler or selects the legacy wrapper automatically.
It checks `date`, `datetime`, `duration`, `format`, `instant`, `iso8601`,
`package`, `period`, and `week` with `--check-only`, requiring an exact
`All terms check.` or `ALL PROOFS CHECK` success line as well as a zero exit status.
It also runs all eight existing core regression suites and requires an exact
`ok` line from each: date, duration, period, instant, local datetime, format,
ISO week, and ISO-8601. These cover leap-year behavior including 1900 and 2000,
calendar arithmetic, elapsed time, offsets, and text parsing/formatting.

Compatibility here applies to the core sources in this checkout. The separate
zone sources import the older core hash and are outside this matrix; it does not
establish zone compatibility with these Bend versions.

## Hub publication

The fixed core is published as `bend-datetime@0.4.0.1` and
`bend-time-lib@0.4.0.1`, both pointing to
`0x5d092e40b48ee431bc4b160e8797f9d5`. The ten-file Hub manifest, including
`LICENSE`, matches the `0.4.0.1` release sources byte for byte. The repository
checkout now also adds `Date.quarter`, `Date.start_of_quarter`,
`Date.end_of_quarter`, and `Date.day_of_year`; these helpers are not published
in that immutable Hub tree. Named package imports and the existing date regression tests were also
checked from Hub on Bend 2.0.34.

The older `0.4.0.0` core tree at `0x9b6a4fc7ceea91864a75396e1b8365e5` is
immutable. Its `Date.leap.100` and `Date.leap.4` names remain invalid on Bend
2.0.28 and newer; upgrade to `0.4.0.1` or use this fixed checkout. The zone
package still imports that old core hash and is not repaired by this release.
