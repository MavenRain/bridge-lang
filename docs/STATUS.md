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

## S6

Slice S6 (Part B, the bridge steps on the guest side, docs/PLAN.md
sections 3.3, 4.4, 5 and 9) is complete. The change is not committed; its
base is cf2a1a2. The gate `make clean` then `make check` is GREEN, exit 0.
Part B is guest code only: no src file changes. The code was written by
hand, because the builder agent stopped two times on an API classifier
error.

Changes:

- `examples/bridge.lang` (new): a copy of the pool defs of
  `examples/pool.lang` up to `swapOut` (`capped` is not in the copy;
  Q-S6-1, O21), then Part B: `Side` (`Fin 2`; `sideA`, `sideB`),
  `Credit` (`U256`), `Key` (the two affine words of a BN254 G1 point),
  `isDenom` and `Denom` (the words 10 and 100, O22), `Msg`, `mkMsg`,
  `credit`, `InFlight` (`List Msg`, Q-S6-2), `sumCredit`, `BridgeState kA
  kB`, `total` (yA + yB + the credit in flight), `deposit`, `Sealed`,
  `seal` (the side and the batch number, O14), `sealedMsgs`, `Sig`,
  `Accepted`, `accept`, `sameMsg`, `inBatch`, `Mem`, `removeMsg`, `claimW`
  (the exchanged swap, O23) and `claim`.
- `deposit` takes `Lt (credit m) (resY k p)` and a `PoolLaw` proof, as the
  S5 operations do (Q-S5-2). `accept` takes the attestation as an
  argument; S7 checks it. `claim` takes a `Mem m a` proof; S8 replaces it
  with a bLSAG ring claim.
- Fixed values: both pools start at (1000, 1000) with k0 = 1000000. A
  deposit of 100 takes 112 in and gives (1112, 900). A claim of 100 pays
  90 out and gives (910, 1100). Laws by refl: `lawTotal` (2000),
  `lawDeposit` (the total after the deposit is the total before),
  `lawClaim` (the same for the claim), `lawClaimPays` (90 out),
  `lawClaimBelow` (909 * 1100 is less than k0), `lawUaReserve` (the
  transport of the reserve 1112 along `ua U256 U256 (idEquiv U256)` is
  1112).
- `examples/kit.txt`: `bridge.lang`.
- `test/bridge/` (new): 3 refusals, all `PATH_END`, with
  `examples/bridge.lang` as the prelude: a claim of a message that is not
  in the batch, a claim that pays 91 out for 100 in (999900 is less than
  k0), and a deposit that drops its message (1900, not 2000).
- `test/gate.sh` line 52: `refusals test/bridge bridge
  examples/bridge.lang` (O24).
- `test/eval/expect.txt`: 19 `bridge` rows: the pool words after the
  deposit and after the claim, the batch membership (1 for the message
  in the batch, 0 for a message that is not), the credit in flight (100,
  then 0), the total in each of the three states (2000), the transported
  reserve (1112), the least solutions (`depKeeps` 10 and 100, `claimKeeps`
  100), and 2 traps: a deposit of the whole credit reserve, and a claim
  that takes y past `2^128 - 1` (read through the x projection).
  Review regressions cover removing one of several equal messages,
  removing an absent message, removing from an empty batch, and
  conserving the total when a second equal deposit remains in flight.
  `removeMsg` consumes one occurrence, preserving the other deposits.

Traps found in S6:

- A transport along `ua` at `Pool k0` (a Sigma with `mul` in its type)
  stops with `OOM: lawUaPool: the arena limit is reached` after 1.38 s. At
  a `U256` word it reduces by refl. So the `ua` law is on the reserve word
  (Q-S6-3).
- A sum over the kernel `Bag` needs, in the swap case, a path from
  `u256Add a (u256Add b r)` to `u256Add b (u256Add a r)` at an open r. No
  rule gives it, so `InFlight` is a list in S6 (Q-S6-2).
- An eval of a Flag prints 1 or 0, not `flagYes` or `flagNo`.
- The gate puts the prelude and the refusal file into one file. So a
  refusal file must not use a name that the prelude defines. The refusal
  files use `bad`, which no prelude defines.

| Count | S5 | S6 | Reason |
|---|---|---|---|
| examples | 42 | 43 | `bridge.lang` |
| bridge refusals | none | 3 | `test/bridge`, with `examples/bridge.lang` as the prelude |
| evals | 180 | 199 | 19 `bridge` rows |

The other counts do not change: parse refusals 19, check refusals 171,
pool refusals 4, kit-only refusals 22, proves 2, contracts 2 written 5
refused, rings 6 built 2 refused, differential 28 guest evals, 14 host
runs and 14 EVM rows, runs 5, run refusals 10, lower refusals 16, build
checks 33, precompile steps 128, evm steps 43, mock 13 rows, diff 15
rows, emit 24 executions, and the regressions.

## S3

Slice S3 (R1 narrowing: `REFUSE_CELL`, the free monoid, the former
matrix as CM and CC rows) is complete as a port of intent-lang 32c1d13
(its parent aacc8ad). The change is not committed; its base is ce6f9d3.
The patch is `git diff aacc8ad 32c1d13` of intent-lang without
docs/PLAN.md and docs/STATUS.md, with `intent-lang` renamed
`bridge-lang`. It applied clean: 34 paths, no reject. The gate `make
clean` then `make check` is GREEN, exit 0.

Changes:

- `src/front/check.c`: a declared type constructor must have the
  cell-signature shape (`REFUSE_CELL`); universe aliases are normalized;
  higher-kinded parameters and type indices are refused; closed operation
  labels are kept; a guest use of the kit cons list `List` is refused
  (`test/check/guest-list.lang`). `src/front/front.c`: one hunk.
- `domain/domain.lang`: `FreeMon` with `fmFold`, bind and map; `Quot` and
  the indexed cons `Bag` are replaced by `Orbit`, `Parity`, `ChoiceBag`,
  `OrbitN` and the free commutative monoid `Bag` (`bagOf`, `bagUnit`,
  `bagOp`, `bagAssoc`, `bagComm`, `bagUnitL`, `bagSquash`; no `Size`
  index); the Charter rule type is `Size`.
- `examples/freemon.lang` (new). 12 examples, SPEC.md,
  formers/FORMERS.md, formers/tcc-evm-contract.md, docs/host/README.md,
  9 test/check files, `test/check/guest-list.lang` (new),
  `test/check/expect.txt` and `test/lower/orbit-word.lang` follow the new
  families.
- `test/fronttool.c`: 10 C regression cases (5 `REFUSE_CELL` and the
  review cases).
- `test/eval/expect.txt`: 9 rows rewritten in place (formers `xs`, quot
  `toTrunc3`, 7 elim rows). The 21 pool and 19 bridge rows stay.
- No change in the bridge-lang-only files (`examples/pool.lang`,
  `examples/bridge.lang`, `test/pool/*`, `test/bridge/*`): they use
  `List`, `nil`, `cons`, `unfold` and `fold` under `--kit`, and the
  `List` refusal is guest mode only (O28).
- Local lines kept against the patch: O26 and O27.

Traps found in S3:

- A fold out of the free commutative monoid `Bag Msg` into `U256` needs
  four paths at open words: `u256Add` assoc, comm and left unit (each
  `PATH_END`) and `isSet U256` (`PATH_UIP`). The S6 trap named only the
  comm path. So `InFlight` stays `List Msg` (Q-S3-1, O29).
- The intent-lang aacc8ad fronttool case `constant` (`transp` along a
  constant `ZkBallot C` line is the identity by refl) is `PATH_END` on
  the bridge-lang checker: `src/front/eval.c` line 2525 has no
  constant-line rule at `ZkBallot` (Q-S3-2, O31).
- The `Q-S3-n` citations in the ported files name intent-lang rulings
  (O30).

| Count | S6 | S3 | Reason |
|---|---|---|---|
| examples | 43 | 44 | `freemon.lang` |
| check refusals | 171 | 172 | `test/check/guest-list.lang` (`REFUSE_CELL`) |

The other counts do not change: parse refusals 19, pool refusals 4,
bridge refusals 3, kit-only refusals 22, evals 199, proves 2, contracts 2
written 5 refused, rings 6 built 2 refused, differential 28 guest evals,
14 host runs and 14 EVM rows, runs 5, run refusals 10, lower refusals 16,
build checks 33, precompile steps 128, evm steps 43, mock 13 rows, diff
15 rows, emit 24 executions, and the regressions (fronttool has 10 more
cases).
