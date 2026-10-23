# bridge-lang status

> Write here: one paragraph. Say which milestone the build implements, and
> which milestone it does not complete yet.

## Implemented

> Write here: one item for each feature that works. Name the former (F1 to
> F15), the core type or the core operation.

- <feature>.

## Remaining M0 work

> Write here: one numbered item for each missing feature. Say what each item
> needs first.

1. <work item>.

## Known limits

> Write here: one item for each limit of the current build, with its cause
> (a fuel budget, a host limit, a stack size).

- <limit>.

## Internal boundaries

> Write here: one paragraph for each module group. Say which module holds
> which job, which tests check which tables, and which types a program
> cannot use.

## S2

Slice S2 (the kernel port, docs/PLAN.md sections 6 and 9) is complete on
commit df5f4ed plus the S2 changes. The port is `git archive` of
orbit-lang 2162fb2 (`src`, `domain`, `examples`, `test`, `gen`,
`Makefile`). It changes 55 files, adds 178 files and keeps 109 files.
kitshift was not used. The gate `make clean` then `make check` is GREEN,
exit 0. Run `make clean` first: the archive gives each file the commit
time, which is older than an earlier build/langc, so make does not
rebuild it.

Changes after the archive step:

- `test/gate.sh`: the dash check skips `design/DESIGN.md` again (O18). The
  orbit file has no exemption. The file differs from the orbit text only
  at this check (+2 -1).
- `examples/inventory.lang` and `test/check/domain-name.lang` are
  removed. orbit-lang removed them in its own kernel port (7734007).
- SPEC.md, docs/host/README.md, docs/VALIDATION.md, formers/FORMERS.md,
  formers/tcc-evm-contract.md and probe/CAPABILITY.md take the orbit
  text. docs/host/CAPABILITY.md and probe/guard.py were already the same.
  .gitignore keeps the bridge text (O19).
- SPEC.md lines 1, 3 and 14: the self name `orbit-lang` becomes
  `bridge-lang`.
- docs/host/README.md line 3: "and orbit-lang uses it" becomes "and
  bridge-lang uses it". Builder call: the line names the user of the kit.
- The other `orbit` words in the taken files stay: the provenance notes
  `(orbit-lang Sn ...)`, the orbit gate record of docs/VALIDATION.md line
  16, and the DAO words `Orbit`, `OrbitN`, `orbitProj`, `orbitExt`,
  `bagOrbit` and `bagorbit`.
- The code has no rename site. The 23 provenance comments stay. The bLSAG
  domain tag "orbit" (`src/front/blsag.c` line 12) stays (Q-S2-1).

| Count | S1 | S2 | Reason |
|---|---|---|---|
| examples | 19 | 41 | port: the orbit examples come in; `inventory` goes |
| parse refusals | 13 | 19 | port: the orbit parse rows |
| check refusals | 57 | 171 | port: the orbit check rows; `domain-name` goes |
| kit-only refusals | none | 22 | port: the orbit S3 guest mode |
| evals | 55 | 159 | port: the orbit eval rows |
| proves | none | 2 | port |
| contracts | none | 2 written, 5 refused | port: the orbit contract writer |
| rings | none | 6 built, 2 refused | port: the orbit bLSAG rings |
| differential guest evals | none | 28 | port |
| differential host runs | none | 14 | port |
| differential EVM rows | none | 14 | port |
| lower refusals | 11 | 16 | port |
| build checks | 28 | 33 | port |
| precompile steps | none | 128 | port: 14 rows |
| bLSAG, path, writer regressions | none | passed | port |

The other counts do not change: runs 5, run refusals 10, asmtool 8 of 8,
builds 3, dispatch 20, evm steps 43, mock 13 rows, diff 15 rows, emit 24
executions, and the review, domain, run fuel, build output, lower and evm
hashing regressions.

## S5

Slice S5 (Part P, the pools, docs/PLAN.md sections 3.2, 4.2, 4.3 and 9)
is complete. The code is commit 44ee99d on d8175d5. The gate `make clean`
then `make check` is GREEN, exit 0. Part P is guest code only: no src
file changes.

Changes:

- `examples/pool.lang` (new): `mul`, `divFloor` and `divCeil` as folds
  over `pows`, the 256 powers of two, smallest first. A fold runs from
  the last element, so `mul` and `divFloor` read the bits from the top.
  The kit has no `u256Mul` and no `u256Div` (sealed-lang R19), and Nat
  has no `natMul` (Q-S5-1). `mul` traps on a product of `2^256` or more.
  `divFloor` traps on a divisor of 0 (`zeroTrap`).
- `examples/pool.lang`: `Le`, `Lt`, `Positive` (the `Pos` of PLAN 3.2,
  O20), `Pool k`, `mkPool`, `resX`, `resY`, `PoolLaw`, `poolFromWords`,
  `swapIn`, `swapOut`, `PriceEq`, `addLiq`, `Share` and `removeLiq`. Each
  operation takes its precondition and a `PoolLaw` proof of the new
  reserves and gives a `Pool k`. `removeLiq` gives `(k' : U256) * Pool
  k'` (PLAN 4.3). Closed values with refl in each field are the laws at
  fixed values (Q-S5-2).
- `checkedReserves` checks that each new reserve is from 1 to `2^128 - 1`
  before it gives either (O7). `capped` is the bound on one word; no
  operation uses it.
- `examples/kit.txt`: `pool.lang`.
- `test/pool/` (new): 4 refusals, all `PATH_END`: a swap that gives out
  too much, an `addLiq` with a bad price, a swap of the whole y reserve,
  a `removeLiq` with a bad share. Each file holds only the bad
  definition.
- `test/gate.sh`: `refusals DIR LABEL [PRELUDE]`. With a prelude, the
  gate puts the prelude file before each refusal file. The test/pool
  rows use `examples/pool.lang`.
- `test/eval/expect.txt`: 21 `pool` rows: the 4 operations at fixed
  values and a rounded `removeLiq`, `outY`, the least solutions at their
  boundary (`inKeeps` 910 and 909, `outGives` 99 and 98), the bound
  (`inX` 0 and 1), and 9 further reserve-bound rows (6 traps and 3
  successful boundary cases), covering both projections of results.

Traps found in S5:

- An open product in a type (`Le k (mul x y)`) unrolls the 256-step fold
  with a stuck `flagIf` in each step. The normal form has an exponential
  size, and `langc check` stops with `EVAL_FUEL: mkPool: the evaluation
  takes more than 20000000 steps`. The fix is `powsAt a b`: it is `pows`
  only when `u256Eq a a` and `u256Eq b b` reduce, so for an open word the
  fold stops at once. The check time is then 0.09 s.
- The evaluator is lazy. A check in one field of a pair does not run
  when a caller reads only the other field. So `checkedReserves` checks
  both reserves before it gives the pair.
- An eval entry takes Nat or Flag arguments and gives a Nat or Flag
  (`src/front/check.c`, `entry_of`). Applying a `Nat -> U256` helper to
  command-line arguments gives `EVAL_ARGS: ... not an entry`.
- A guest `def Pos` gives `REFUSE_NAME` (rule R4): `Pos` is a domain
  family (`domain/domain.lang` line 71).

| Count | S2 | S5 | Reason |
|---|---|---|---|
| examples | 41 | 42 | `pool.lang` |
| check refusals | 171 | 171 | the pool rows are in test/pool |
| pool refusals | none | 4 | `test/pool`, with `examples/pool.lang` as the prelude |
| evals | 159 | 180 | 21 `pool` rows |

The other counts do not change: parse refusals 19, kit-only refusals 22,
proves 2, contracts 2 written 5 refused, rings 6 built 2 refused,
differential 28 guest evals, 14 host runs and 14 EVM rows, runs 5, run
refusals 10, lower refusals 16, build checks 33, precompile steps 128,
evm steps 43, mock 13 rows, diff 15 rows, emit 24 executions, and the
regressions.
