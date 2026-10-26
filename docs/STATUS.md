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

## S7

Slice S7 s1 (the guest side of `Enc`, `decrypt`, `open`, `observe` and
the Schnorr attestation verify, Q-S7-1 (a)) is complete. The change is
not committed; its base is the USER commit 8077f7a (O32). The gate `make
clean` then `make check` is GREEN, exit 0. The host and precompile rows
wait for the intent-lang S5 and S6 commits (O33).

Changes:

- `examples/enc.lang` (new, guest): `Enc A := Prod Unit A`, `encEta`,
  `decrypt`, `encBind`, `Quorum`, `open`, `observe` and the laws
  `etaLaw`, `bindLaw`, `openLaw`, `privacy` and `fheHom` (O36). `Enc` is
  not sealed (Q-S7-2 (a), O34).
- `examples/elgamal.lang` (new, kit; a line in `examples/kit.txt`):
  exponential ElGamal on G1, the sum of two ciphers, a threshold open of
  two shares with the Lagrange weights in the exponent, a DLEQ proof of
  a share, and one Schnorr signature as the attest (O35).
- `test/check`: `enc-guest-family.lang` (`REFUSE_DATA`) and
  `attest-wrong.lang` (`PATH_END`, kit).
- `test/eval/expect.txt`: 18 rows (15 elgamal, 3 enc).
- No src change and no domain change.

Traps found in S7:

- A program cannot declare a family (`REFUSE_DATA`), so a guest `Enc`
  is an alias, not a cell family, and a `REFUSE_CELL` case on a program
  `Enc` cannot occur (O34).
- The kit has no `u256Mul`: each scalar that a prover computes (the
  Schnorr s, the DLEQ z) is a literal from an off-chain computation
  (O35).
- The review found that `u256Sub r x` saturates at zero for x above r,
  breaking decryption, and that omitting C1 from the DLEQ challenge
  admits a false share. Decryption now negates x C1 as a point, the
  challenge includes C1, and six regression rows cover both fixes
  (O37). The valid DLEQ response was regenerated.

| Count | S3 | S7 | Reason |
|---|---|---|---|
| examples | 44 | 46 | `enc.lang`, `elgamal.lang` |
| check refusals | 172 | 174 | `enc-guest-family.lang`, `attest-wrong.lang` |
| evals | 199 | 217 | 15 elgamal rows, 3 enc rows |

The other counts do not change: parse refusals 19, pool refusals 4,
bridge refusals 3, kit-only refusals 22, proves 2, contracts 2 written 5
refused, rings 6 built 2 refused, differential 28 guest evals, runs 5.

## S8

Slice S8 (`ZKBridge` as the mapping cylinder and the bLSAG claim rings,
the guest side, Q-S8-1 (a) to Q-S8-4 (a)) is complete. The change is not
committed; its base is the USER commit 8e859a9 on 8077f7a (the S7 tree
with the USER review fixes, O37). The gate `make clean` then `make
check` is GREEN, exit 0.

Changes:

- `examples/cylinder.lang` (new, guest): `Cyl A B f := (b : B) * Trunc1
  (Option A)`, `cylPub`, `cylPriv`, `cylPush` (`squash1`), `cylDown`,
  `cylSec`, `cylRet`, `cylEquiv` (`isoToEquiv`) and `cylPath` (`ua`),
  with a `Size` instance at f = succ (O38).
- `examples/bridge.lang`: an S8 section with a copy of `Cyl` (Q-S6-1
  (a)), `PrivateInputs`, `result`, `ZKBridge`, `public`,
  `privateComp`, `zkProof`, `zkDownOf`, `zkEquiv` and `lawPublic`
  (O38); the claim poll word, `ringAt`, `sigImage`, `fresh`,
  `RingClaim`, `RingState` and `claimRing` beside `claim` (O39, O41,
  O43); the laws
  `lawRing`, `lawCross`, `lawImage`, `lawSecond` and `lawClaimRing`; 11
  eval entries, plus 6 review regression entries for the claim state.
- `test/check/zk-cyl-refl.lang` (`PATH_END`, guest).
- `test/bridge`: `bridge-ring-cross.lang`, `bridge-claim-twice.lang`
  and `bridge-claim-earlier.lang`
  (`PATH_END`, all three in `test/bridge/kit.txt`).
- `test/eval/expect.txt`: 20 rows (3 cylinder, 17 bridge).
- No src change and no domain change.

Traps found in S8:

- The original `claimRing` checked a caller-supplied spent list but
  returned only the pool. Reusing its signature with an empty list
  paid twice. The transition now takes and returns the pool and spent
  images together as `RingState`, adding its image and preserving the
  prior images. Callers thread that state. Replay refusals exercise
  the returned state immediately and after another depositor claims
  (O43).
- A top-level `Equiv` value is refused (`examples/equiv.lang`), so
  `zkEquiv` is a function of `Unit` (O38).
- `BLSAG_TAG` is a global constant and H_p hashes only the key, so one
  key gives one key image at each tag and each poll. The poll word
  separates claim signatures from ballot signatures, but no tag can
  separate key images. The eval row `imgBallot` is 1. Key-image
  unlinkability rests on one-time deposit keys, a VALIDATION assumption
  (O39).
- The wf-builder and its opus fallback both stopped on the
  `reasoning_extraction` classifier; the main loop built S8 by hand
  (O42).

| Count | S7 | S8 | Reason |
|---|---|---|---|
| examples | 46 | 47 | `cylinder.lang` |
| check refusals | 174 | 175 | `zk-cyl-refl.lang` |
| bridge refusals | 3 | 6 | `bridge-ring-cross.lang`, `bridge-claim-twice.lang`, `bridge-claim-earlier.lang` |
| evals | 217 | 237 | 3 cylinder rows, 17 bridge rows |

The other counts do not change: parse refusals 19, pool refusals 4,
kit-only refusals 22, proves 2, contracts 2 written 5 refused, rings 6
built 2 refused, differential 28 guest evals, runs 5.

## S4

Slice S4 s1 (Part 1: the port of the intent-lang S4 cocell comonads,
intent-lang 4b36026) is complete. Part 2 (`Trace`, its category laws,
the meaning functor and `Stream` of batches) is S4 s2 (Q-S4-1 (a),
O47). The change is not committed; its base is the USER commit 617d39b
on 8e859a9 (the S8 tree with the USER review fix, O43). The gate `make
clean` then `make check` is GREEN, exit 0.

Changes (the port, O44):

- `domain/domain.lang`: `cofamily Stream (A : Type 0) := sCorec (sHead
  : A) (sTail : Stream A)`, with `sExtend` and `sDuplicate`.
- `src/front/lexer.c`, `src/front/lexer.h`, `src/front/parser.c` and
  `src/front/ast.h`: the keyword `cofamily`, `DECL_COFAMILY`, and
  `lex_internal` (`.` is a name character in the text that the checker
  makes).
- `src/front/check.c`: `check_cofamily` elaborates a cofamily to the
  positions `Stream.pos`, `Stream A := Stream.pos -> A`, the
  destructors `sHead` and `sTail`, the walk `Stream.walk`, the
  corecursor `sCorec` and the bisimulation principle `StreamBisim`. A
  cofamily outside the domain file is `REFUSE_DATA`. A state field of a
  stream type is `REFUSE_STATE`.
- `examples/cocell.lang` (new, guest): the counit, extend and duplicate
  laws (`lawCounit`, `lawExtendEps`, `lawAssoc` and the duplicate laws)
  and 5 eval entries.
- `test/check`: `cofamily-guest.lang` (`REFUSE_DATA`) and
  `cofamily-state.lang` (`REFUSE_STATE`, also in `test/check/kit.txt`).
- `test/eval/expect.txt`: 5 `cocell` rows, after the bridge-lang rows.
- `test/fronttool.c`: the intent-lang S4 C regression cases (label
  scope, universe levels, the dependent-label refusal).
- `SPEC.md`, `docs/VALIDATION.md` and `formers/FORMERS.md`: the CC text;
  the CC row is DONE.
- No bridge-lang-only file changes (O45).

Traps found in S4 s1:

- The wf-builder and its opus fallback stopped on the API classifier
  before they wrote a file. Part 1 is a build by hand (O47).
- The ported texts cite the intent-lang O28 and "choice (ii)" (O46).

| Count | S8 | S4 | Reason |
|---|---|---|---|
| examples | 47 | 48 | `cocell.lang` |
| check refusals | 175 | 177 | `cofamily-guest.lang`, `cofamily-state.lang` |
| evals | 237 | 242 | 5 `cocell` rows |

The other counts do not change: parse refusals 19, pool refusals 4,
bridge refusals 6, kit-only refusals 22, proves 2, contracts 2 written
5 refused, rings 6 built 2 refused, differential 28 guest evals, runs 5.

## S4 s2

Slice S4 s2 (Part 2: `Trace`, its category laws, the meaning functor
and `Stream` of batches, Q-S4-1 (a), Q-S4-3 (a) and Q-S4-4 (a)) is
complete, so S4 is complete. The change is not committed; its base is
the USER commit 2f78a8e on 617d39b (the S4 s1 tree). The gate `make
clean` then `make check` is GREEN, exit 0.

Changes (O48):

- `examples/trace.lang` (new, kit): the reserve words `W`, the steps
  `Step` (swapIn, swapOut, addLiq and claim) and `stepW` over the
  copied word functions of `examples/pool.lang` and
  `examples/bridge.lang` (Q-S6-1 (a)); `Trace := FreeMon Step` with
  `tIdl`, `tIdr` and `tAssoc` at open traces and `tIsSet`; the target
  `Run := Trunc0 W -> Trunc0 W` with `runIsSet` and refl monoid laws;
  the meaning functor `mu` (`fmFold`) with `muId`, `muSeq` and `muStep`
  by refl; the slice `TraceAt` with `idAt`, `seqAt` and `inOutAt`; the
  batch stream `batches`, `settle2`, `settled` (`sExtend`), `dupNext`
  (`sDuplicate`), `states` and `lawSettle`; the original 9 eval entries.
  The review adds positive-input and rounded-price guards to the trace
  steps, plus 9 regression evals (O52).
- `examples/kit.txt`: `trace.lang`.
- `test/eval/expect.txt`: 18 `trace` rows, after the `cocell` rows.
- No src change and no domain change.

Traps found in S4 s2:

- Calling the raw reserve functions bypassed `Positive` and `PriceEq`:
  a zero input swap and a price-changing liquidity addition were
  accepted. `swapInStepW` and `addLiqStepW` now check those conditions
  before either reserve can be projected (O52).
- A target of `W -> W` needs `isSet U256`, which has no guest proof
  (O29). The target `Trunc0 W -> Trunc0 W` is a set by `squash0` at
  each point, so `fmFold` needs no `U256` rule (O48, Q-S4-4 (a)).
- A path in `TraceAt p q` needs a PathP of the endpoint paths. The laws
  are on the trace component only (Q-S4-3 (a)).
- The wf-builder and its opus fallback stopped on the
  `reasoning_extraction` classifier before they made an edit. S4 s2 is
  a build by hand (O50).

| Count | S4 s1 | S4 s2 | Reason |
|---|---|---|---|
| examples | 48 | 49 | `trace.lang` |
| evals | 242 | 260 | 9 original `trace` rows and 9 review regressions |

The other counts do not change: parse refusals 19, check refusals 177,
pool refusals 4, bridge refusals 6, kit-only refusals 22, proves 2,
contracts 2 written 5 refused, rings 6 built 2 refused, differential 28
guest evals, runs 5.

## S7 s2

Slice S7 s2 (the port of intent-lang 1b65dec: the sealed `Enc` monad,
the law-only `decrypt` and the host ElGamal, Q-S4-2 (a)) is complete,
with the Q-S3-2 (a) item. The change is not committed; its base is the
USER commit e77666f on 2f78a8e (the S4 s2 tree). The gate `make clean`
then `make check` is GREEN, exit 0.

Changes (O53 to O57):

- The port of intent-lang 1b65dec (O53): `sealed family Enc` with
  `encBind`, `encMap`, `encOp2` and the law defs `decrypt` and
  `observe` in `domain/domain.lang`; the keywords `sealed` and `law`
  (`src/front/lexer.c`, `src/front/lexer.h`, `src/front/parser.c` and
  `src/front/ast.h`); the law-only rule O7 and the sealed check
  (`src/front/check.c` and `src/front/core.h`); the host ElGamal
  (`src/front/elgamal.c` and `src/front/elgamal.h`) and its tool
  `test/elgamaltool.c` (8 rows); `Makefile`, `SPEC.md`,
  `docs/VALIDATION.md` and `formers/FORMERS.md`; 11 fronttool rows.
- `examples/enc.lang`: the intent-lang laws and values, then the
  bridge-lang `etaLaw`, `bindLaw` (an `elim` proof), `privacyA`,
  `fheHom`, `two` and `bindAt` (O55).
- `examples/enc-ideal.lang` (new, kit): the intent-lang ideal model,
  then the S7 s1 `Quorum`, `open`, `openLaw`, `two`, `decEta` and
  `openAt` (Q-S7-3 (a), O56).
- `test/check`: 8 new rows (`enc-fold`, `enc-decrypt`, `enc-leak`,
  `enc-annot`, `enc-proj` and `enc-relay` with `REFUSE_LAW`,
  `enc-state` with `REFUSE_STATE` under `--kit`, `law-guest` with
  `REFUSE_DATA`); the comment of `enc-guest-family.lang`.
- `test/eval/expect.txt`: 7 new rows after the `trace` rows; `decEta`
  and `openAt` are `enc-ideal` rows; the `bindAt` value is an `encEta`
  term.
- Q-S3-2 (a) (O57): the 7 aacc8ad cases in `test/fronttool.c` and the
  constant-line `transp` rule at `ZkBallot` in `src/front/eval.c`.

Traps found in S7 s2:

- The sealed `Enc` makes each guest def that opens a ciphertext
  law-only. A def with a `Size` or A codomain is then `REFUSE_LAW`. The
  guest `open`, `decEta` and `openAt` moved to the kit (O56).
- On the sealed `Enc`, refl fails for `bindLaw` at a neutral `c`. The
  proof is an `elim` on `c`, as the intent-lang `lawBind` (O55).
- "rule O7" in the ported text is the intent-lang seal rule, not the
  bridge-lang O7 (O54).
- `enc-state.lang` is a `--kit` row with `REFUSE_STATE`, so the
  kit-only refusals stay 22 (O58).

| Count | S4 s2 | S7 s2 | Reason |
|---|---|---|---|
| examples | 49 | 50 | `enc-ideal.lang` |
| check refusals | 177 | 185 | 8 intent-lang rows (O53) |
| evals | 260 | 267 | 7 intent-lang rows; `decEta` and `openAt` move to `enc-ideal` and the `bindAt` value changes, with no count change (O56) |

The other counts do not change: parse refusals 19, pool refusals 4,
bridge refusals 6, kit-only refusals 22, proves 2, contracts 2 written 5
refused, rings 6 built 2 refused, differential 28 guest evals, runs 5.

## S9 s1

Slice S9 s1 (the tally, the tally law and the liquidity Decisions, PLAN
3.1 and 4.3, Q-S9-1 (a) and Q-S9-2 (a)) is complete. The change is not
committed; its base is the USER commit b71c078 on e77666f (the S7 s2
tree with the USER edit O59). The gate `make clean` then `make check` is
GREEN, exit 0.

Changes (O59 to O63):

- O59 records the USER edit of b71c078: the `rule_path` carrier fix in
  `src/front/check.c` and 5 `law_guest` rows in `test/fronttool.c`.
- `examples/tally.lang` (new, guest): `Votes`, a `Ballot` carrying an
  encrypted vector and a truncated proof that it is one-hot (O63),
  `castEnc`, `tallyEnc` (by `encOp2`, with no opening), `count`, the
  tally law `tallyLaw` (its proof `tally3` is a triple `elim`), the
  liquidity `Decision`, `decide` (2 of 3) and `closeLaw` (O60, O61).
- `examples/tally-ideal.lang` (new, kit, a row of `examples/kit.txt`):
  the trusted scope opens the tally: `opened`, `counted`, `close` and
  `closed` (O61).
- `test/check/tally-open.lang` (new): a guest def that opens the tally,
  `REFUSE_LAW`. `tally-ballot.lang` and `tally-proof.lang` reject an
  uncertified ballot and a proof for a different ciphertext (O63).
- `test/eval/expect.txt`: 10 new rows after the `enc-ideal` rows: 4
  `tally` rows and 6 `tally-ideal` rows.

Traps found in S9 s1:

- A Path carrier cannot hide `decrypt` (O59). The S9 laws use `decrypt`
  only in the ends of a Path.
- refl fails for the tally law at neutral ciphertexts. The proof is a
  triple `elim`, as `lawOp2` (O55, O60).
- `vadd` is not commutative by conversion, so the ballot order of
  `tallyLaw` must be the order of `tallyEnc` (O61).
- A bare `Enc Votes` permits one member to submit multiple votes.
  The ballot now carries a proof of one-hot validity tied to its
  ciphertext. The aggregate remains `Enc Votes` (O63).

| Count | S7 s2 | S9 s1 | Reason |
|---|---|---|---|
| examples | 50 | 52 | `tally.lang`, `tally-ideal.lang` |
| check refusals | 185 | 188 | `tally-open.lang`, `tally-ballot.lang`, `tally-proof.lang` |
| evals | 267 | 277 | 4 `tally` rows, 6 `tally-ideal` rows |

The other counts do not change: parse refusals 19, pool refusals 4,
bridge refusals 6, kit-only refusals 22, proves 2, contracts 2 written 5
refused, rings 6 built 2 refused, differential 28 guest evals, runs 5.

## S9 s2

Slice S9 s2 (the remote enactment and the signed ballot, PLAN 3.1, 4.3,
4.6 and 7, Q-S9-3 (a) and Q-S9-4 (b)) is complete. Thus S9 is complete,
and Part D is closed. The change is not committed; its base is the USER
commit 174f975 on b71c078 (the S9 s1 tree). The gate `make clean` then
`make check` is GREEN, exit 0. There is no src change and no domain
change.

Changes (O64 to O68):

- `examples/enact.lang` (new, kit, a row of `examples/kit.txt`): the
  Decision word `decisionWord`, the home enactment `enactW`, the remote
  enactment `enactRemote` with a Schnorr attest, the typed `Attested`
  and `addLiqRemote`, and the laws `lawAttest` and `lawRemoteAdd` (O64).
- `examples/ballot.lang` (new, kit, a row of `examples/kit.txt`): the
  ring-signed ballot `VoteSig`, the one-poll `Box`, `castSigned`, the
  poll word "ballot", and the laws `lawVote` and `lawDup` (O65, O66).
- `test/check/ballot-twice.lang`, `ballot-poll.lang` and
  `enact-twice.lang` (new, rows of `test/check/kit.txt`): duplicate
  ballots, cross-poll signatures and duplicate typed enactments refuse
  with `PATH_END` (O67, O69).
- `test/eval/expect.txt`: 37 new rows after `tally-ideal closedAll`: 25
  `enact` rows and 12 `ballot` rows.

Traps found in S9 s2:

- The M5 mutant (a `VoteSig` with no `fresh` check) does not show in the
  eval rows, because the rows check `fresh`, not `castSigned`. Only the
  check row `ballot-twice.lang` kills it (O67).
- The key image does not change with the poll, because H_p has no tag.
  A `Box` holds one poll, and S10 keys the spent set by the poll (O66).
- The poll word must not be the claim word. With the claim tag in
  `ballotPollOf` (M4), a ballot signature is also correct at the claim
  poll (O65, O67).
- Review found same-proposal replay: the original removal could run
  twice, producing reserves `(800, 800)` rather than `(900, 900)`.
  `EnactState` and `RemotePool k` now retain enacted proposal numbers;
  callers thread the returned state (O69).
- Review found that a poll-2 signature could enter a poll-1 Box. A Box
  now stores its poll number, and `castSigned` checks that poll (O69).
- Review found that `enactW` bypassed the price and share predicates.
  `decisionOk` now checks them before changing reserves. A stale,
  correctly signed Decision is refused without consuming its proposal.
  Rounding toward the pool remains accepted (O69).

| Count | S9 s1 | S9 s2 | Reason |
|---|---|---|---|
| examples | 52 | 54 | `enact.lang`, `ballot.lang` |
| parse refusals | 19 | 19 | no new parse row |
| check refusals | 188 | 191 | `ballot-twice.lang`, `ballot-poll.lang`, `enact-twice.lang` (`PATH_END`) |
| pool refusals | 4 | 4 | no new pool row |
| bridge refusals | 6 | 6 | no new bridge row |
| kit-only refusals | 22 | 22 | This count is the `REFUSE_KIT` rows of `test/check/expect.txt` (`test/gate.sh`). `ballot-twice.lang` is a `PATH_END` row (it is refused also under `--kit`), thus it is a check refusal, not a kit-only refusal |
| evals | 277 | 314 | 25 `enact` rows, 12 `ballot` rows |
| proves | 2 | 2 | no new prove row |
| contracts | 2 written, 5 refused | 2 written, 5 refused | no contract change |
| rings | 6 built, 2 refused | 6 built, 2 refused | no ring change |
| differential | 28 guest evals | 28 guest evals | no new differential row |

The host counts do not change: runs 5, differential 14 host runs, run
refusals 10, asmtool 8 checks, builds 3, lower refusals 16, build checks
33, dispatch 20 checks, evm steps 43, differential 14 EVM rows,
precompile 128 steps, mock 13 rows, diff 15 rows.

## S10 s1

Slice S10 s1 (the port of the intent-lang S7 one-hot proof and the
signed encrypted cast, PLAN 4.6, Q-S10-1 (a), Q-S10-4 (a) and Q-S10-7
(a)) is complete. The change is not committed; its base is the USER
commit 76af1b9 on 174f975 (tree b9f6b6b3, the S9 s2 tree with the O69
review fixes). The gate `make check` is GREEN, exit 0. There is a src
change (`src/front/sigma.c`, `src/front/sigma.h`, `src/front/check.c`)
and a domain change (`ZKProof`, `Transcript`, `verified`).

Changes (O70 to O74):

- `src/front/sigma.c` and `src/front/sigma.h` (new): the one-hot Sigma
  proofs of intent-lang ef5abe8 on bn254, with `hash2` in place of the
  intent-lang `thr_hash` (O71).
- `src/front/check.c`: the walk of `law_uses` does not go into the
  argument of `ZKProof` (O71).
- `domain/domain.lang`: `ZKProof W := Trunc1 W`, the sealed family
  `Transcript` and `law def verified` (O71).
- `examples/zkproof.lang` (new) and `examples/onehot.lang` (new, kit, a
  row of `examples/kit.txt`): the ported ZK examples (O71).
- `examples/cast.lang` (new, kit, a row of `examples/kit.txt`): the
  signed encrypted cast `castW`, the typed `castTyped`, the law
  `lawCast`, the bound ctx `ctxOf` and the poll word `pollWord` (O72).
- `test/sigmatool.c` (new, `build/sigmatool`, a `Makefile` target and a
  `make check` step): the ported sigma rows and the `cast` mode that
  prints the S10 ballot words (O71, O72).
- `test/elgamaltool.c`: the two tally rows (Q-S9-4 (b), O72).
- `test/check/zk-leak.lang` (REFUSE_LAW) and
  `test/check/transcript-state.lang` (REFUSE_STATE, also a row of
  `test/check/kit.txt`): new check rows (O71).
- `test/fronttool.c`: 3 rows for `ZKProof`, `Transcript` and `verified`
  (O71).
- `test/precompile.sh`: the onehot block, 7 steps (O71).
- `test/eval/expect.txt`: 21 new rows: 9 port rows and 12 `cast` rows
  (O71, O72).

Traps found in S10 s1:

- `langc --kit eval` prints U256 words in decimal, thus a search for
  `0x` words in its output finds none. The key image check compares
  the decimal words (O72).
- The port script applied the precompile hunk with `-C1` before the
  zkcast block. The onehot block was moved by hand to after the zkcast
  block (O71).
- `langc --kit check examples/cast.lang` takes about 14 s, because
  `lawCast` and `typed1` evaluate `castOk` at check time. Each `cast`
  eval row takes about the same time.
- The M5 mutant must remove both slot 1 C2 words from `ctWord`. When
  only the last hash is removed, C2 x stays in the chain. `wSlot1C2`
  changes x and y, thus the row stays 0 and does not test the mutant
  (O73).
- M4 (`ctxOf` with no key image) stops at check time: `lawCast` gives
  PATH_END. Thus `lawCast` is the check row of M4, and no eval row is
  necessary (O73).
- The bound ctx cite is intent-lang O34. PLAN O34 is Q-S7-2 (a). The
  record fixed the cite in `cast.lang` and `test/sigmatool.c` (O74).
- The review of the staged slice fixed the `law_uses` comment of
  `check.c` (def name `ZKProof`, cite S10 s1 and O71, not the
  intent-lang "S7, Q-S7-1 (a)") and the `hash2` count of O71 (12 calls
  and 3 comment lines of sigma.c, not 15 calls and 1 comment) (O74).

| Count | S9 s2 | S10 s1 | Reason |
|---|---|---|---|
| examples | 54 | 57 | `zkproof.lang`, `onehot.lang`, `cast.lang` |
| parse refusals | 19 | 19 | no new parse row |
| check refusals | 191 | 193 | `zk-leak.lang` (REFUSE_LAW), `transcript-state.lang` (REFUSE_STATE) |
| pool refusals | 4 | 4 | no new pool row |
| bridge refusals | 6 | 6 | no new bridge row |
| kit-only refusals | 22 | 22 | no new `REFUSE_KIT` row |
| evals | 314 | 335 | 9 port rows, 12 `cast` rows |
| proves | 2 | 2 | no new prove row |
| contracts | 2 written, 5 refused | 2 written, 5 refused | no contract change |
| rings | 6 built, 2 refused | 6 built, 2 refused | no ring change |
| differential | 28 guest evals | 28 guest evals | no new differential row |

The host counts change in one place: precompile 128 to 135 steps (the
onehot block). The new host rows are `build/sigmatool` ("sigma
regressions: passed") and the two elgamaltool tally rows. The other
host counts do not change: runs 5, differential 14 host runs, run
refusals 10, asmtool 8 checks, builds 3, lower refusals 16, build
checks 33, dispatch 20 checks, evm steps 43, differential 14 EVM rows,
mock 13 rows, diff 15 rows.

## S10 s2

Slice S10 s2 (the twin contract, PLAN 7, Q-S10-2 (a), Q-S10-3 (a),
Q-S10-5 (a), Q-S10-6 (a), Q-S10-7 (a), Q-S10-9 (a), Q-S10-11 (c),
Q-S10-12 (a) and Q-S10-14 (a)) is complete. The change is not committed; its base is
the USER commit 460fda6 on 76af1b9 (tree ec8644a, the staged S10 s1
tree). The gate `make check` is GREEN, exit 0. There is a src change:
the side value and the kit primitives `u256Mul` and `u256Div`.

DEVIATIONS for the USER:

- The claim has no ring signature on the EVM (Q-S10-11 (c),
  temporary). The key image comes from the claim arguments, and `claim`
  marks each key image once. Thus a second key image is a second claim:
  `test/run/twin-remote.script` shows it. The claim ring signature
  stays in the kit eval (`examples/bridge.lang`). A later slice gives
  one shared bLSAG routine for `cast` and `claim`.
- The open ring fix of Q-S10-10 (a) moves to that slice (Q-S10-12 (a)).
  That slice rules the source of H_i: a closed key table or a zkHp
  lowering (O75).

Changes (O75):

- `src/asm.h`: EVM_OP_CODESIZE (0x38).
- `src/evm.c` and `src/evm.h`: when `init` has an argument, the
  creation code copies the 32-byte word after the code (offset CODESIZE
  minus 32) and stores it in field 0 (the side value, Q-S10-5 (a)).
- `src/lower.c`: an `init` with one U256 argument lowers; the
  BINARY_OPS rows of `u256Mul` (IR_OP_MUL_TRAP) and `u256Div`
  (IR_OP_DIV).
- `src/front/check.c`: `langc --kit run` takes `init WORD` as the first
  script line; the kit rows `u256Mul` and `u256Div`.
- `src/front/core.h` and `src/front/eval.c`: OP_U256_MUL and
  OP_U256_DIV (at the end of the Op enum) and their eval arms (each
  trap gives EVAL_OVERFLOW).
- `test/buildtool.c`: the 5 `evm_build` calls give NULL (the same
  bytes).
- `test/evmchain.sh`: `deploy PROG [WORD]` appends the side word.
- `examples/side.lang` (new, kit, a row of `examples/kit.txt`),
  `test/run/side.script` and `test/run/side.out` (new), and the EVM side
  rows of `test/precompile.sh`.
- `test/lower/init-two-args.lang` (new, REFUSE_LOWER, a row of
  `test/lower/expect.txt`) and the comment of
  `test/lower/init-args.lang`.
- `examples/precompile.lang` and `examples/enact.lang`: the `u256Mul`
  and `u256Div` rows. `test/eval/expect.txt`: 18 rows.
  `test/precompile.sh`: 6 `mulv` and `divv` steps.
  `docs/host/README.md`: 2 rows.
- `examples/twin.lang` (new, kit, a row of `examples/kit.txt`): the
  twin contract. One bytecode, two deployments (side 0 home, side 1
  remote).
- `test/run/twin-home.script`, `test/run/twin-home.out`,
  `test/run/twin-remote.script` and `test/run/twin-remote.out` (new).
  `test/run.sh` runs `examples/NAME.lang` for a script
  `NAME-TAG.script`.
- `test/gate.sh`: the twin size row (`sized`, the shared tail of
  `ring_built`).
- `test/check/pruned-op.lang`: the R19 row names `natMul`, not
  `u256Mul` (a kit primitive since Q-S10-9 (a); Q-S10-14 (a)).

Traps found in S10 s2:

- P1: a deploy of a program with an `init` argument but without the
  appended word originally stored the last 32 bytes of the runtime in
  slot 0. The review fix requires exactly 32 appended bytes and reverts
  for missing, partial or extra constructor data.
- P2: the build drops an entry with more than 32 words
  (ENTRY_PARAMS_MAX) with no diagnostic, and exits 0 (Q-S10-8). An
  entry takes at most 30 words (the 255-byte ABI string,
  EVM_SIGNATURE).
- The guest run does not see the appended word: the run script gives
  it on the `init` line. Thus only the EVM rows test the side word of
  the build (M-s1, M-s2, O75).
- `langc eval` takes arguments only for an entry. A closed def that
  traps prints `trap` with exit 0 and an empty stderr. Thus the eval
  rows `=> trap` are entries (O75).
- The eval rows and the EVM rows of `u256Mul` and `u256Div` each kill
  only the mutants of their side (M-s3 to M-s6, O75).
- A gate of one part after a src change does not see the check rows:
  run the full gate. Resumes 7 to 10 ran only the precompile, eval and
  run gates after the `u256Mul` change, thus only the final gate found
  the R19 row `pruned-op.lang` (Q-S10-14).

The attest words of the runs (key 7, Q-S10-4 (a); the words print in
decimal):

- `wordA = hash (hash 1u 100u) 100u` (the Decision word of `addLiq 100
  100`) is
  69914689039486352338164481898370239755594127164942748291139874641240398830175u.
- `batchB` (the hash chain starting at `batchSeed 0u`, of the 3 deposits
  (5, 6, 10), (7, 8, 10) and (9, 10, 10)) is
  65464856881474182367233619130168970009212943138116352224957205723450756253912u.
- Attest A signs `attestMsg 0u 1u wordA` (the remote `enact` of n = 1)
  with the nonce k = 23. Attest B signs `attestMsg 0u 0u batchB` (the
  `accept` of batch 0) with k = 29. For each, s = (k + 7 e) mod r.
  `attestMsg 1u 0u batchB` does not verify.

| Count | S10 s1 | S10 s2 | Reason |
|---|---|---|---|
| examples | 57 | 59 | `side.lang`, `twin.lang` |
| parse refusals | 19 | 19 | no new parse row |
| check refusals | 193 | 193 | no new check row |
| pool refusals | 4 | 4 | no new pool row |
| bridge refusals | 6 | 6 | no new bridge row |
| kit-only refusals | 22 | 22 | no new `REFUSE_KIT` row |
| evals | 335 | 353 | 9 `precompile` rows, 9 `enact` rows (Q-S10-9 (a)) |
| proves | 2 | 2 | no new prove row |
| contracts | 2 written, 5 refused | 2 written, 5 refused | no contract change |
| rings | 6 built, 2 refused | 7 built, 2 refused | the `twin.lang` size row |
| differential | 28 guest evals | 28 guest evals | no new differential row |

The host counts change in 4 places: runs 5 to 8 (`side.script`,
`twin-home.script`, `twin-remote.script`), lower refusals 16 to 17
(`init-two-args.lang`), build checks 33 to 34 (the same row), and
precompile 135 to 146 steps (the side slot 0 and `sideOf` steps, 6
`mulv` and `divv` steps, 3 malformed constructor refusals). The review
adds 13 twin DSL regression rows. The other host counts do not change:
differential 14 host runs, run refusals 10, asmtool 8 checks, builds 3,
dispatch 20 checks, evm steps 43, differential 14 EVM rows, mock 13
rows, diff 15 rows.

## S10 s3

Slice S10 s3 (the two-deployment differential, the gas rows and the
contract mutants, PLAN 7, Q-S10-8 (a), Q-S10-13 (a), Q-S10-15 (a) and
Q-S10-16 (a)) is complete. The change is not committed; its base is
the USER commit 5e4b34b (tree f9e91e4, the staged S10 s2 tree). The
gate `make check` is GREEN, exit 0. There is a src change: the entry
arity check of `src/lower.c`.

DEVIATIONS for the USER:

- The claim has no ring signature on the EVM (Q-S10-11 (c), temporary,
  as in S10 s2). Under Q-S10-15 (a) the DEVIATION stays open into S10
  s4: s4 gives one shared unrolled bLSAG routine for `cast` and
  `claim`, then the claim ring signature on the EVM. s4 stops and asks
  if the routine does not fit under EIP-170 (644 free bytes).
- The open ring fix of Q-S10-10 (a) stays open into s4 (Q-S10-12 (a)).
  s4 starts with a ruling on the source of H_i: (b) the closed key
  table or (c) a zkHp lowering.

Changes (O77):

- `src/lower.c`: `residualize` refuses an entry with more than
  ENTRY_PARAMS_MAX (32) word arguments with EVM_ARITY (Q-S10-8 (a)).
  Before s3 the build dropped the entry with no diagnostic and exited
  0.
- `test/lower/arity33.lang` (new, EVM_ARITY, a row of
  `test/lower/expect.txt`): an entry with 33 word arguments.
- `examples/twin.lang`, `examples/enact.lang`, `examples/elgamal.lang`
  and `test/check/enact-twice.lang`: `attestMsg` takes a tag as its
  first word (Q-S10-13 (a)), `hash (hash (hash dom side) n) d`, with
  `enactTag` (ASCII enact) for `enact` and `acceptTag` (ASCII accept)
  for `accept`. The Schnorr words change (below).
- `test/eval/expect.txt`: 2 cross rows, `elgamal attestCrossTag => 0`
  and `enact attestCross => 0`.
- `test/run/twin-home.script`, `test/run/twin-remote.script` and
  `test/run/twin-remote.out`: the new attest words, and the cross row
  of the remote script (step 12, attest A on `accept`, revert).
- `test/run/twin-d4-home.script` (25 steps), `test/run/twin-d4-home.out`,
  `test/run/twin-d4-remote.script` (9 steps) and
  `test/run/twin-d4-remote.out` (new): the D4 runs. `test/run.sh` runs
  `examples/twin.lang` for them. Step 6 of the remote script is the
  row of Q-S10-16 (a): a `castSlot` on side 1 with the slot 0 words of
  voter 0 of the home script, revert.
- `test/evmchain.sh`: a set variable `to` is the address of the call in
  place of the receiver (`step`, `logs`), and the new function `gas`.
  Each old caller gives the same result.
- `test/diff.sh`: part 3, the D4 differential (2 script rows, the mock
  row, 2 guest rows) and the gas rows (one for each of the 13 entries
  of `test/run/twin-d4.gas`).
- `test/run/twin-d4.gas` (new): the gas bound of each entry.
- `docs/VALIDATION.md`: the S10 s3 size table and the gas section.

Traps found in S10 s3:

- A U256 entry takes at most 31 words. At 32 words the build gives
  EVM_SIGNATURE: the ABI text is 258 bytes, more than the limit of 255.
  The P2 text of S10 s2 says 30 (history; this is the s3 measure).
- The examples of `examples/kit.txt` need `langc --kit eval`.
- The twin scripts start with an `init` line. The EVM step loop skips
  that line: the deploy gives the side word.
- An awk bound file read with `FNR == NR` passes an empty bound file
  (the test is then true for each line of the next file). Use
  `FILENAME == ARGV[1]`.
- `evm run` adds no intrinsic gas. The gas rows give the gas of the
  execution only.
- A mutant of `examples/twin.lang` changes `langc run` and the EVM code
  the same way. Thus the diff rows of the steps, the side storage and
  the mock do not see it; only the run rows of `test/run.sh` and the
  gas rows see it.
- No row called `castSlot` on side 1 until Q-S10-16 (a), thus M-d3b was
  LIVE in resume 8.

The mutants (scratch copies, `cp` + `cmp` restore, `make -B` for src):

- M-a1 (`src/lower.c`, the refusal only when the extra count is more
  than ENTRY_PARAMS_MAX): KILLED, `test/lower/arity33.lang`.
- M-x1 (`examples/twin.lang`, the `accept` tag): KILLED, `test/run.sh`
  (step 12 of `twin-remote.script` gives `accept ok`).
- M-x2 (`examples/enact.lang`, the tag): KILLED, the eval row
  `enact attestCross`.
- M-d1 (`examples/twin.lang`, `enact` with no once check): KILLED,
  `test/run.sh` (`twin-d4-home.script`, `twin-remote.script`).
- M-d2 (`castSlot` with no open check): KILLED, `test/run.sh`
  (`twin-d4-home.script`) and `test/twin.sh` (`slotAfterOpen`).
- M-d3 (`cast` with no side check): EQUIVALENT. `slots` has one writer,
  `castSlot`, and `castSlot` has its own side check. On side 1 `slots`
  stays empty, thus a `cast` on side 1 does not find its slot word and
  reverts. No row can kill M-d3 while the side check of `castSlot`
  holds.
- M-d3b (`castSlot` with no side check): LIVE in resume 8, KILLED after
  Q-S10-16 (a) by `test/run.sh` (step 6 of `twin-d4-remote.script`
  gives `castSlot ok`). `test/diff.sh` does not see it (the trap
  above).
- M-g1 (`claim` with one more hash test): KILLED, `test/diff.sh`, the
  gas row of `claim` (76733, more than the bound 76543).
- M-d4 (`examples/enact.lang`, `homeAdd` with `addW 101u 100u`):
  KILLED, `test/diff.sh`, the 2 guest rows.
- M-d5 (`src/evm.c`, the side word read at CODESIZE minus 31): KILLED,
  `test/diff.sh`, the remote `sideOf` step and the remote side storage.
- M-d6 (`src/evm.c`, the `pay` amount plus 1): KILLED, `test/diff.sh`,
  7 FAIL rows (the D4 mock row is one of them).
- M-g2 (`src/evm.c`, one more JUMPDEST at the start of the dispatcher):
  KILLED, `test/diff.sh`, the 13 gas rows.

The attest words of S10 s3 (key 7, s = (k + 7 e) mod r; `wordA` and
`batchB` do not change; the S10 s2 words above are history):

- sA, attest A (k = 23, `attestMsg enactTag 0u 1u wordA`, the remote
  `enact` of n = 1):
  0x16c7db2f9518158af598a29100524e94c3f6f0040de3e355d901cfa8d41af243u.
- sB, attest B (k = 29, `attestMsg acceptTag 0u 0u batchB`, the
  `accept` of batch 0):
  0x268feef28dee689791678ad63da3acf52842a5a5af98decc4cd795d22db5112cu.
- sR, `sRemove` of `examples/enact.lang` (k = 29,
  `attestMsg enactTag 0u 2u` of the removeLiq word):
  0x19216fc3a115aa4ef29669ad890882cab0deb9c59c99f95eb00bd7fbc23ea121u.
- sE, `sSig` of `examples/elgamal.lang` (k = 23,
  `attestMsg acceptTag 0u 1u 42u`):
  0x2c254087c58dacac565702fa12e3acecadff90b43dbe5b5f7d9a6c67b9f07e7eu.

| Count | S10 s2 | S10 s3 | Reason |
|---|---|---|---|
| evals | 353 | 355 | `elgamal attestCrossTag`, `enact attestCross` (Q-S10-13 (a)) |
| lower refusals | 17 | 18 | `arity33.lang` (Q-S10-8 (a)) |
| build checks | 34 | 35 | the same row |
| runs | 8 | 10 | `twin-d4-home.script`, `twin-d4-remote.script` |
| diff gate rows | 15 | 33 | 5 D4 rows (2 script rows, the mock row, 2 guest rows) and 13 gas rows |

The other count lines of the gate log do not change.

## S10 s4

Slice S10 s4 (the bLSAG slice, PLAN 7, Q-S10-10 (a), Q-S10-12 (a),
Q-S10-17 (b) and Q-S10-18 (a)) is complete. The change is not
committed; its base is the USER commit 29cd010 (the S10 s3 commit). The
gate `make check` is GREEN, exit 0. There is a src change: the routine
path of `src/ir.h`, `src/lower.c` and `src/evm.c`.

DEVIATIONS for the USER:

- The DEVIATION of S10 s2 (the claim has no ring signature on the EVM,
  Q-S10-11 (c)) is CLOSED. `claim` checks a bLSAG ring signature
  through the shared routine `sharedRing`.
- The open ring fix of Q-S10-10 (a) is CLOSED: H_i comes from the
  closed key table (Q-S10-17 (b)).
- The claim form deviates from DESIGN.md section 6 (Q-S10-18 (a)): 4
  ring map fields keyed by i, not one map keyed by `hash i j`, and the
  claimed key is (I, n), not (I, batch hash). The DESIGN form is 25649
  bytes, over EIP-170 (VALIDATION).

Changes (O78):

- `src/ir.h`, `src/lower.c`, `src/evm.c`: the shared routine path
  (IR_STMT_ROUTINE, `lower_routine_call`, `evm_routine`). A def named
  `shared` plus an uppercase letter lowers once; each entry calls it.
- `test/build.sh`, `test/lower/expect.txt`: the rows
  `test/lower/shared-shape.lang`, `shared-arg.lang` (REFUSE_LOWER) and
  `shared-call.lang` (new).
- `test/buildtool.c`, `test/emittool.c`, `test/evmtool.c`,
  `test/lowertool.c`: the new IR fields in the positional initializers
  (the check-clang trap).
- `examples/twin.lang`: `sharedRing` for `cast` and `claim`, the ring
  map fields, `claimTag`, the claimed key (I, n), the claim selector
  0xaf3c21e4 (11 args).
- `test/twin.lang`, `test/twin.txt`: `claimSig`, `claimSigWord`,
  `claimWith`, `claimKeyOne`, and the rows `claimBatchZero` 1,
  `claimBatchOne` 0, `claimBadSig` 0 (13 to 14 rows).
- `test/run/twin-*.script` and the 4 `.out` files: the deposits use the
  table keys; the new attest B words; the claim rows; `twin-d4.gas`
  `cast 403491`, `claim 189658`.

The attest B words (k = 29, key 7, s = (29 + 7 e) mod r): the batch
hash 572081921815354849002554863167009082274090072192049687847530274301525086388u
and sB 0x27c9abd2761fb046918a43f12368d786597badd7a2aad894b90b0ab96a0ab3e9u.

The claim rows of `test/run/twin-remote.script`: 8 ok (pay 9u, event
Claimed); 9 revert (the claimed key (I, 0)); 10 revert (the accept
check: no batch hash with d 20u); 11 revert: the key image of key 1 (a
point on BN254) with the words of the key 0 signature is fresh in
`claimed`, but the ring check refuses it. The key image depends on the
key only, not on the poll or on d.

Traps:

- clang `-Wextra -Werror` refuses a positional initializer that leaves
  out a new field (-Wmissing-field-initializers); tcc accepts it. Run
  `make check-clang` after each IR struct change.
- langc gives no size past EIP-170 (EVM_SIZE). Measure a form over the
  limit by a differential build.
- fold is a right fold: `claimSigWord l k` is the word k from the END
  of l.
- `wordAt` is a domain field: the name gave REFUSE_NAME R4.
- A key image that is not on BN254 (the first row 11 used (5u, 6u))
  traps in `ecMul`; the row now uses the real image of key 1.
- The attest s words are hex (`0x...u`), the h words decimal.

Mutants: M1 (the claim ring check to `u256Le d d`) KILLED by
`test/run.sh` (row 11) and `test/twin.sh` (`claimBadSig`); the gas row
cannot kill it. M2 (the routine arg slots 0 and 1 swapped in
`src/evm.c`) KILLED for `cast` and `claim` by `test/diff.sh` (16
failures of 33 rows).

| Count | S10 s3 | S10 s4 | Reason |
|---|---|---|---|
| lower refusals | 18 | 20 | `shared-shape.lang`, `shared-arg.lang` |
| build checks | 35 | 40 | 2 rows and 3 expect checks |
| twin rows | 13 | 14 | `claimBadSig` |

The other count lines of the gate log do not change.

Review (2026-10-25): the key image sentence here and in O78 (the image
depends on the key only), one comment in `test/run/twin-remote.script`,
one `frame_end` call for each function in `src/evm.c`, and the `shared
calls` count in `test/build.sh` at byte boundaries only. The counts do
not change.

## S10 close

The S10 close is OPEN at amendment (Q-S10-19). This s5 audit is based
on the USER commit fe1e366 (S10 s4).
The change is not committed. The serial baseline
(`bridge-lang-work/S10-s5-baseline.log`) and the serial final gate
(`bridge-lang-work/S10-s5-final-gate.log`) exit 0. After the review
fixes, the serial review gate writes
`bridge-lang-work/S10-s5-review-gate.log`; the commit needs its EXIT 0.

| Slice | Work | Evidence |
|---|---|---|
| s1 | One-hot proof and signed encrypted cast | `examples/cast.lang`, O70 to O74 |
| s2 | One bytecode, side constructor, twin bridge and DAO | `examples/twin.lang`, O75 |
| s3 | Two deployments, gas rows and contract mutants | `test/diff.sh`, O77 |
| s4 | Shared bLSAG, open ring fix, signed claim on the EVM | `sharedRing`, claim rows 8 to 11, O78 |
| s5 | Routine call refusal text and exit audit | `test/build.sh` exact message rows, O79 |

The exit audit of PLAN 7 is below. Amendment stays OPEN:

| Exit | State | Slice | Evidence |
|---|---|---|---|
| Same bytecode, side in storage | DONE | s2, s3 | The two deployments in `test/diff.sh`, `sideOf` rows |
| `cast`: bLSAG and one-hot proof, encrypted tally | DONE | s1, s4 | `sharedRing`, signed cast and tally rows in the twin scripts |
| `close`: MPC opening, constitution, stored decision | DONE | s2, s3 | Two close steps, opened and decided rows in the twin scripts |
| `enact`: home decision and remote attestation | DONE | s2, s3 | Home and remote enact steps and the attest A rows |
| `enact`: amendment as orbit-lang | OPEN | Q-S10-19 | No constitution installation or poll reset in the twin bytecode |
| `deposit`: swap, pull, batch and event | DONE | s2, s3 | Three deposit steps and their storage and event rows |
| `seal`: block bound and batch hash event | DONE | s2, s3 | Seal step, guard at `sealAt`, and Sealed event rows |
| `accept`: remote attestation and stored hash | DONE | s2, s3 | Remote accept and accepted batch state |
| `claim`: ring, signature, replay check, swap, pay, event | DONE | s2, s4 | `twin-remote.script` rows 8 to 11; `claimBadSig`; s4 mutants M1 and M2 |
| Size and gas rows | DONE | s3 to s5 | VALIDATION, `test/run/twin-d4.gas`; runtime 24166, init plus argument 25094 bytes |

The only supported ring size is 3. `claim` has three member indices
and three signature responses; `sharedRing` is unrolled for them.
The measured claim bound is 189658 execution gas for the recorded
steps. Other ring sizes and other prestates have no measured bound.
No transaction intrinsic gas is included. See VALIDATION and O17.

| Count | S10 s4 | S10 s5 |
|---|---|---|
| examples | 59 | 59 |
| parse refusals | 19 | 19 |
| check refusals | 193 | 193 |
| pool, bridge, kit refusals | 4, 6, 22 | 4, 6, 22 |
| evals, proves | 355, 2 | 355, 2 |
| contracts written, refused | 2, 5 | 2, 5 |
| rings built, refused | 7, 2 | 7, 2 |
| guest differential evals | 28 | 28 |
| runs, host differential runs, run refusals | 10, 14, 10 | 10, 14, 10 |
| twin rows | 14 | 14 |
| asm checks | 8 | 8 |
| builds, lower refusals | 3, 20 | 3, 21 |
| build checks | 40 | 45 |
| dispatch checks | 20 | 20 |
| EVM steps, differential rows | 43, 14 | 43, 14 |
| precompile steps | 146 | 146 |
| mock rows, diff rows | 13, 33 | 13, 33 |
| emit execution regressions | 24 | 24 |
| gate failures | 0 | 0 |

`src/lower.c` now names a shared routine call in both call refusals.
The exact message rows for `shared-arg.lang` and `shared-state.lang`
check more than the code REFUSE_LOWER: each call refusal has a row.
The entry word refusals keep their existing text.

Open at this audit: Q-S10-19, then the remaining mutant work and
the project close (PLAN S11). The s4 mutants M1 and M2 are already
KILLED. The runtime has
410 free bytes. The closed key table, four ring map fields and claimed
key (I, n) are the ruled form. Larger rings or a variable ring ABI
need a USER scope decision, a size check and new gas rows.

The guest prelude still has `amend` (`SPEC.md:119`), with its laws
in `examples/dao.lang`. Q-S10-2 (a) keeps the separate table writer.
These do not install a constitution or reset a poll in the twin
contract. Its `enact` guard accepts only tags 0 to 2. No scope ruling
that removes amendment from PLAN 7 was found. The USER must rule
Q-S10-19, or the requirement must be met, before S10 can close.

Review of the s5 stage (2026-10-25), five findings, all fixed: the
first routine call refusal had no exact message row (now
`test/lower/shared-state.lang`, lower refusals 21, build checks 45);
the S10 row of PLAN kept `s5 is PLANNED`; VALIDATION named fe1e366
and the s4 runtime as the size source (the s5 tree gives the same
25062 and 24166 bytes); this section gave the gate rule, not the
results; one line break in the paragraph above.
