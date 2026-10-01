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

Run `BEND_HOME=/path/to/bend-checkout ./tools/check-compatibility`.
The checkout must contain `bend2/main.ts`; this script invokes bun directly.
For local verification with an already verified Bend binary, use
`BEND_COMPAT=/absolute/path/to/bend ./tools/check-compatibility` instead.
Neither mode downloads a compiler or selects the legacy wrapper automatically.
It checks `date`, `datetime`, `duration`, `format`, `instant`, `iso8601`,
`package`, `period`, and `week` with `--check-only`, requiring the
`ALL PROOFS CHECK` success marker as well as a zero exit status.
It also runs the existing `tests/date_test.bend` and requires an exact `ok` line,
covering leap-year behavior including 1900 and 2000.

Compatibility here applies to the core sources in this checkout. The separate
zone sources import the older core hash and are outside this matrix; it does not
establish zone compatibility with these Bend versions.

## Hub publication

The published `bend-datetime@0.4.0.0` and `bend-time-lib@0.4.0.0` core tree is
immutable. Its `Date.leap.100` and `Date.leap.4` names remain invalid on Bend
2.0.28 and newer. This source fix does not repair those Hub imports; users need
a new publication containing the renamed helpers, or this fixed checkout.
