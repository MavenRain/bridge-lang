# bridge-lang plan

bridge-lang is a Cubical TT language for two parts of one system: a
zero-knowledge, homomorphically encrypted, multi-party DAO (the DAO of
MavenRain/orbit-lang), and the liquidity bridge with AMM pools that the DAO
governs. A program declares the DAO, the pools and the bridge. The compiler
checks the laws and writes the EVM bytecode of the contract. The same
contract deploys on each side of the bridge. `design/DESIGN.md` holds the
request and the design verbatim.

## 1. Rulings

USER rulings (the request, 2026-10-22):

- R1 type formers: for type constructors (higher kinds), only cell monads
  and their duals, in a locally presentable, locally cartesian closed
  (infinity,1)-category, as Cubical TT realizes it.
- R2 base types and operations: the minimum that a smart contract needs for
  a ZK FHE MPC DAO (MavenRain/orbit-lang) that governs a liquidity bridge
  with AMM pools, with the pasted denotational design.
- R3 host: TinyCC.
- R4 target: EVM bytecode for any EVM chain.

USER rulings (S1, 2026-10-22), verbatim:

> Take all recommendations for Q1-Q10 and give next session prompt

Thus each question of section 11 takes its RECOMMENDED option:

- Q1 (a) (O3): R1 as intent-lang ruled it. Ambient Pi, Sigma, Path and U
  with Glue are not limited. Declared type constructors are only CM and CC.
  The cell criterion is syntactic; cons lists are refused, the free monoid
  is used.
- Q2 (a) (O5): swap, liquidity and bridge paths are morphisms of `Trace`,
  the free category on a graph of steps (a CM in the slice over `X * X`).
- Q3 (a) (O6): `Pool k` holds `k ≤ x * y` over `U256`; swap outputs are the
  least solutions.
- Q4 (a) (O8): liquidity keeps the price, not the product. The DAO is the
  only liquidity provider. `removeLiq` reindexes `k`.
- Q5 (a) (O9): virtual credit reserves, batches of deposits, an attestation
  of each batch, claims on the other side; credit conservation.
- Q6 (a) (O13): one Schnorr signature on BN254 under the DAO threshold key
  (FROST off the chain). One key for ElGamal and Schnorr is a VALIDATION
  assumption.
- Q7 (a) (O10, O11): privacy is unlinkability (denominations, one-time
  keys, bLSAG ring claims, key images). Amounts and pool arithmetic are
  public. FHE is only in the DAO tally.
- Q8 (a): the DAO runs on side A. Side B enacts an attested Decision.
- Q9 (a) (O15): port the intent-lang slices when they exist.
- Q10 (a): no fee and no minimum output.

Builder calls (NOT ruled; section 10 gives each one, section 11 gives the
questions that the USER ruled in S1):

- O1: the name bridge-lang.
- O2: the kit is hosts/tcc-evm-contract (U256, Addr, Env, `pay`, `pull`,
  events). The cubical kernel, the BN254 host and the bLSAG ring signatures
  come from orbit-lang at 2162fb2 (section 6).
- Tests are guest-language files plus `langc run` scripts. The kit gate
  scripts stay. We add no new harness.

## 2. The reading of R1

R1 has the same text as in intent-lang. This plan proposes the reading that
intent-lang ruled on 2026-10-22 (intent-lang Q1 (a), Q2 (a)). RULED: Q1
(a).

### 2.1 The ambient structure

A locally presentable, locally cartesian closed (infinity,1)-category has
dependent sums and products along each map (base change
`Sigma_f -| f* -| Pi_f`), identity types and, with univalence, a universe.
Cubical TT (CCHM) realizes this structure with computation:

| Ambient part | Cubical TT term | Note |
|---|---|---|
| Pi, Sigma | `(x : A) -> B x`, `(x : A) * B x` | the LCC structure |
| identity | `Path A a b`, `PathP`, the interval `I`, `transp`, `hcomp` | Kan operations |
| universe | `U`, `Glue`, `ua` | univalence by Glue |

These are the internal language of the category. A program does not
declare them, and R1 does not limit them.

### 2.2 The admitted type constructors

A type constructor is a declaration with a type parameter, or any map
`U -> U`. R1 admits two classes and no others (O3):

| Class | Definition | Structure from the kernel | Examples in bridge-lang |
|---|---|---|---|
| CM, cell monad | The free algebra monad of a cell signature. The type parameter occurs in one constructor only, the generator `eta`. Each other constructor (a point, path or higher cell) takes closed base data and arguments of the defined type only. | unit = `eta`; bind = the recursor; the three laws are paths by the induction principle | `Option`, the free monoid, `Bag` (free commutative monoid, a QIT), `‖-‖`, `Orbit` of the DAO, `Enc` (identity monad, sealed), `Trace` (the free category on a graph, section 4.1) |
| CC, cocell comonad | The cofree coalgebra comonad of a cocell signature: a coinductive record with one observation `eps : D A -> A`. | counit = `eps`; extend = the corecursor | `Stream` (the sequence of batches, O16) |

A declaration with no type parameter is not a type constructor. So the HIT
`ZKBridge` of the design (index values `kA kB`, no type parameter) is
admitted as a higher inductive type, as `Orbit` is in orbit-lang.

New refusal code: `REFUSE_CELL` refuses a parameterized declaration that is
not a cell signature or a cocell signature (as intent-lang S3).

## 3. The minimal base signature (R2)

Each name has one of three kinds, as in orbit-lang:

| Kind | Meaning |
|---|---|
| slot | The program gives the type from formers and kit base data. |
| defined | The prelude defines it from slots, formers and kit base data. |
| primitive | Opaque. The kit implements it. Only the listed operations use it. |

Kit base data (tcc-evm-contract): `U256`, `Addr`, `Env` (`now`, `caller`),
`Out` (`pay`, `pull`, `emit`), the contract `State`. No other base data.
`Nat` stays internal to the kernel, as in orbit-lang.

### 3.1 Part D: the DAO

As intent-lang section 3.1 (orbit-lang slots and operations, encrypted
one-hot ballots, `tallyEnc`, the MPC `open`, the tally law
`open q (tallyEnc bs) ≡ count (map decrypt bs)`). The difference is the
decided value: `Decision` holds a liquidity action (section 4.3, Q4), not a
swap parameter.

### 3.2 Part P: the pools

| Name | Kind | Reading |
|---|---|---|
| Pos | defined | `(n : U256) * Le 1 n`, the surrogate of `R+` (section 4.2); the name in the code is `Positive` (O20) |
| Pool k | defined | `(x : Positive) * (y : Positive) * Le k (x * y)` (section 4.2) |
| Step | defined | the graph of pool steps: `swapIn`, `swapOut`, `addLiq` (section 4.1) |
| Trace | CM | the free category on `Step` (section 4.1) |
| swapIn, swapOut | defined | exact-input and exact-output swaps (section 4.2) |
| addLiq, removeLiq | defined | liquidity steps, only by a DAO decision (section 4.3) |

### 3.3 Part B: the bridge

| Name | Kind | Reading |
|---|---|---|
| Side | slot | two points `A`, `B`; a storage value of each deployment |
| Asset | slot | the token unit of a side; `e : Asset_A ≃ Asset_B` (section 4.4) |
| Credit | defined | `U256`, the virtual reserve of each pool (section 4.4) |
| BridgeState | defined | `Pool kA * Pool kB * InFlight` |
| InFlight | defined | `Bag Msg`: credit that left one pool and is not yet in the other |
| Msg | defined | `(key : Point) * (c : Denom)`: a one-time BN254 key and a credit denomination |
| Denom | slot | the finite set of credit denominations (Q7) |
| deposit, attest, claim | defined | section 4.4 and 4.5 |
| ZKBridge | defined (HIT) | the mapping cylinder of `result` (section 4.5) |

### 3.4 Enc, the MPC opening and their laws

As intent-lang section 3.4: `Enc` is the identity cell monad behind a
sealed eliminator, `decrypt` is a law-only monad morphism `Enc -> Id`,
`open : Quorum -> Enc A -> A` with `open q c ≡ decrypt c`, and the observer
view `observe : Enc A -> ‖ A ‖`. The design's `fheHom` is the monad
morphism law of `decrypt`. It is not a constructor of `ZKBridge` (its type
is a `PathP` in `Cipher`, not in `ZKBridge`), so it is a law (O12).

## 4. Readings of the design on Cubical TT

### 4.1 A swap is not a path in Pool k

`Pool k` is a subtype of `U256 * U256`, a set with decidable equality
(Hedberg). So `Path (Pool k) p p'` is empty when `p` and `p'` differ. The
same holds for the reals and the rationals of the design: in Cubical TT and
HoTT they are sets, so a "continuous trajectory" is not a path in the
identity-type sense. The design's swap path, liquidity path and bridge path
cannot exist as written (O5).

Reading (O5): each of these is a morphism of the free category on a graph
of steps. `Step : Pool k -> Pool k -> U` has one constructor per kind of
step. `Trace` is the free category on `Step`:

```text
data Trace (S : X -> X -> U) : X -> X -> U
  eta  : S p q -> Trace S p q
  id   : Trace S p p
  seq  : Trace S p q -> Trace S q r -> Trace S p r
  idl, idr, assoc : paths
  trunc : set truncation
```

The parameter `S` occurs only in the generator `eta`, so `Trace` is a cell
monad in the slice over `X * X` (CM, R1). The design's path composition is
`seq`. Its unit and associativity are paths of the HIT, so the TCM laws
`μ(id) = id` and `μ(g ∘ f) = μ(g) ∘ μ(f)` hold for each meaning functor `μ`
out of `Trace` (the recursor). The interval `I` stays for the laws (paths
between equal values, homotopies between proofs).

### 4.2 The invariant over integers

The design asks for `x * y ≡ k` with `R+` or a surrogate. The token
reserves of a contract are integers. An exact product is not kept by an
integer swap. Reading (O6, Q3): `Pool k` holds `k ≤ x * y`. A swap returns
the output that keeps the product at or above its old value:

```text
swapIn  dx : y' = least n with (x + dx) * n >= x * y,  dy = y - y' = floor (y * dx / (x + dx))
swapOut c  : dx = least m with floor (y * m / (x + m)) >= c = ceil (x * c / (y - c)),  c < y
```

The design's "unique positive solution" is read as this least solution. It
is unique. Each swap maps `Pool k` into `Pool k`, and the product does not
decrease. Reserves stay below `2^128`, so `x * y` fits in `U256`; a larger
value reverts (O7).

### 4.3 Liquidity

The design says that scaling both reserves by one factor keeps the product.
This is not true: a factor `λ` multiplies the product by `λ^2`. Scaling
keeps the price `x : y`. Reading (O8, Q4): `addLiq (dx, dy)` with
`dx * y = dy * x` up to rounding toward the pool keeps the price and maps
`Pool k` into `Pool k` (the product goes up). `removeLiq` lowers the
product, so it maps `Pool k` to `Pool k'` with a smaller `k'`: a step in the
total space `(k : U256) * Pool k`, not in one fiber.

Minimal reading of the owner of the liquidity: the DAO is the only
liquidity provider. A liquidity step is a DAO `Decision`, and its tokens
come from or go to the DAO treasury address. So no liquidity-share token
exists.

### 4.4 The bridge

Each contract runs on one chain and sees only its own state. So the joint
state `Pool kA * Pool kB` has no single atomic transition, and the design's
"single path" needs a message between the chains. Reading (O9, Q5):

- Each pool pairs the local asset (reserve `x`) with a virtual credit
  reserve (`y`). The credit is a number in the pool. No token is minted or
  locked, as the design requires.
- `deposit` on the source side: the user picks a denomination `c` and a
  one-time key `P`. The contract pulls `dx = swapOut c` of the asset,
  removes `c` from the credit reserve and adds `(P, c)` to the open batch.
- The DAO committee attests each closed batch (section 4.6).
- `claim` on the destination side: the claimant proves that its key is in
  an attested batch (section 4.5). The contract adds `c` to the credit
  reserve, pays `swapIn c` of the asset to the address in the claim (4.2
  with the roles of `x` and `y` exchanged: credit in, asset out), and marks
  the key image used.

Law (conservation): `yA + yB + sum (InFlight)` does not change in a bridge
step. A liquidity step changes it by the credit of its decision.

Univalence: `e : Asset_A ≃ Asset_B` is the unit equivalence of the two
token representations (the identity when the decimals agree). The pool and
bridge code is written once, over a variable `Asset`. The side B instance is
the transport of the side A instance along `ua e`. By the computation rule
of Glue, this transport is `e`. So "the same bytecode on both chains" is
the transport, and no relayer is in the denotation. The relayer exists only
in the chain fragment, as the attestation.

`Stream` (CC) gives the sequence of batches of a side (O16).

No fee and no minimum output exist, because the design gives none (Q10).
A claim always succeeds when its proof is valid, because a constant-product
pool never pays its whole reserve. So no refund path is needed.

### 4.5 ZKBridge is a mapping cylinder

The constructors `public`, `privateComp` and `zkProof` of `ZKBridge` make
the mapping cylinder of `result : PrivateInputs -> BridgeState`. A mapping
cylinder is equivalent to its codomain. So `ZKBridge ≃ BridgeState`. This
equivalence is the design's "the public denotation is independent of
private data up to equivalence". `BridgeState` is a set, so `ZKBridge` is a
set. Then the higher constructor `mpcCube` adds no new paths: each square in
a set has a filler. Its content is the chain check of section 4.6.

What is private on a transparent EVM chain (O10, Q7): the ERC-20 transfers
make each deposit amount and each payout public. The private input is the
link between a deposit and a claim. `PrivateInputs` = the one-time secret
key of a deposit. `result` = the claim of its batch. The ZK proof is a bLSAG
ring signature over the keys of one batch with one denomination (the ring
of orbit-lang ballots), with a key image against a second claim. So the
claim shows "some deposit in this ring", and the truncation `‖-‖` is the
hiding.

The design says "All pool arithmetic is performed under this homotopy".
This is not possible on the chain: a swap needs multiplication and division
of two unknowns, and exponential ElGamal is only additive. The EVM and
Telcoin Network have no FHE operations. Reading (O11): pool arithmetic is
public. FHE is used where it is additive: the encrypted DAO ballots and the
tally (Part D).

### 4.6 The chain fragment

| Part | On the chain | Off the chain |
|---|---|---|
| `Enc` | exponential ElGamal on BN254 G1, affine `bind` by `ecAdd` (0x06) and `ecMul` (0x07) | encryption by the voter |
| `open` | DLEQ check of each share, Lagrange combination in the exponent, `m G` check | the MPC committee (the DAO members) |
| `attest` | one Schnorr signature on BN254 under the DAO threshold key over `keccak (side, batch number, batch)`: 2 `ecMul`, 1 `ecAdd`, keccak | FROST threshold signing by the DAO members: the `mpcCube`; the chain sees only the combined signature |
| claim proof | bLSAG verify (orbit-lang), key image check | the claimant |
| ballots | bLSAG plus one-hot disjunctive Chaum-Pedersen (as intent-lang) | the voter |

One BN254 key serves ElGamal decryption and Schnorr attestation. Key reuse
across two schemes is a VALIDATION assumption (O13). The attested message
holds the side and the batch number. The domain separation for two bridges
with one committee is O14.

## 5. Laws

| Law (design) | Form in bridge-lang |
|---|---|
| `μ(id) = id`, `μ(g ∘ f) = μ(g) ∘ μ(f)` | the free category laws of `Trace` (4.1), for each meaning functor |
| invariant preserved | `swapIn`, `swapOut`, `addLiq : Pool k -> Pool k` (4.2, 4.3); the least-solution law of 4.2 |
| total value | credit conservation (4.4) |
| cross-chain correspondence | `transport (ua e) ≡ e` on the pool code (4.4) |
| public denotation independent of private data | `ZKBridge ≃ BridgeState` (4.5); `observe` paths by `squash` |
| `fheHom` | the monad morphism law of `decrypt` (3.4) |
| MPC | `open q c ≡ decrypt c`; the attestation verifies iff the combined signature is valid |
| DAO laws | the orbit-lang laws 1 to 6, and the tally law of intent-lang 3.1 |

## 6. Kernel route

orbit-lang at 2162fb2 has the CCHM kernel (Path, `transp`, `hcomp`, Glue,
`ua`), HITs, QITs, HIITs and QIITs (`Orbit`, `Bag n`), fold and unfold, the
BN254 host (field, curve, `ecAdd`, `ecMul`, hash to point), the bLSAG
primitives, the contract writer, the guest/host/EVM differential and the
precompile rows. orbit-lang was made from the same kit, so its file layout
matches this repo.

intent-lang (S0 at 56821a7) plans the same R1 narrowing (its S3), `Enc`
(its S5) and `open` (its S6). Reading (O15, Q9): S2 ports orbit-lang
2162fb2. The slices that intent-lang also needs port the intent-lang
commits when they exist, so the work is done once.

S2 (2026-10-22) made the port by `git archive` of orbit-lang 2162fb2
(`src`, `domain`, `examples`, `test`, `gen`, `Makefile`), plus the doc
edits that docs/STATUS.md lists (section S2) and the O18 restore of
`test/gate.sh`. kitshift was not used: it keeps each shared file at the
seed text, and it drops `*.out` files (intent-lang S2 survey, section 5).
intent-lang had no S2 commit at S1 (its HEAD 599f84d is its S1), so the
port did not come from intent-lang.

## 7. The contract

One contract, the same bytecode on each side. The side is a constructor
value in storage.

| Entry | Side | Effect |
|---|---|---|
| `cast` | home | verifies the bLSAG signature and the one-hot proof, adds the encrypted ballot to the encrypted tally |
| `close` | home | verifies the MPC opening of the tally, computes the Decision by the constitution, stores it |
| `enact` | each | runs a liquidity Decision (home: directly; other side: with its attestation, Q8); `amend` as orbit-lang |
| `deposit` | each | `swapOut c`, `pull dx` from the caller, adds `(P, c)` to the open batch, emits `Deposited` |
| `seal` | each | closes the open batch at a block bound, emits `Sealed` with the batch hash |
| `accept` | each | verifies the attestation of a remote batch, stores its hash |
| `claim` | each | verifies the ring against an accepted batch and the bLSAG signature, checks the key image, `swapIn c`, `pay` to the named address, emits `Claimed` |

Size and gas rows per entry (EIP-170, EIP-3860) come in the contract slice.
The ring size bounds the gas of `claim` (O17).

## 8. Tests

- Guest files: the DAO, pool and bridge examples, one refusal row for each
  new refusal code, evals for each law of section 5.
- `langc run` scripts: entry runs on the guest evaluator, two deployments
  (side A and side B) with the attestation passed by the script.
- The differential: the same scripts on the guest evaluator and on geth
  `evm`, as in orbit-lang.
- The precompile rows: BN254 vectors for ElGamal, DLEQ, Schnorr and bLSAG,
  host against `evm`.

## 9. Slices

| Slice | Content | Status |
|---|---|---|
| S0 | Seed: the template with the tcc-evm-contract host, the design verbatim, this plan, the kit gate GREEN, the private remote | DONE |
| S1 | USER rulings on the questions of section 11; record them in this plan | DONE |
| S2 | Kernel port from orbit-lang 2162fb2 (section 6); the gate counts of orbit-lang | DONE (2026-10-22): examples 41, parse refusals 19, check refusals 171, kit-only refusals 22, evals 159, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures |
| S3 | R1 narrowing: `REFUSE_CELL`, the free monoid, the former matrix as CM and CC rows (port of intent-lang 32c1d13) | DONE (2026-10-23): examples 44, parse refusals 19, check refusals 172, pool refusals 4, bridge refusals 3, kit-only refusals 22, evals 199, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures |
| S4 | `Trace` as the free category CM in a slice; the category laws; the meaning functor; `Stream` of batches (CC) | DONE (2026-10-23), s1 the port of intent-lang 4b36026 (O44 to O47), s2 Part 2 in the kit example `examples/trace.lang` (Q-S4-1 (a), Q-S4-3 (a), Q-S4-4 (a)): examples 49, parse refusals 19, check refusals 177, pool refusals 4, bridge refusals 6, kit-only refusals 22, evals 260, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures; s2 has no src change and no domain change (O48 to O52) |
| S5 | Part P: `Pos`, `Pool k`, `swapIn`, `swapOut`, the least-solution law, `addLiq`, `removeLiq`, the overflow bound | DONE (2026-10-22): examples 42, parse refusals 19, check refusals 171, pool refusals 4, kit-only refusals 22, evals 180, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures |
| S6 | Part B: credit, `InFlight`, `deposit`, `seal`, `accept`, `claim` on the guest side; conservation; `ua e` transport | DONE (2026-10-22): examples 43, parse refusals 19, check refusals 171, pool refusals 4, bridge refusals 3, kit-only refusals 22, evals 199, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures |
| S7 | `Enc`, `decrypt`, `open`, Schnorr attestation verify; host and precompile rows (port from intent-lang S5 and S6 when they exist) | s1 DONE (2026-10-23), the guest side (Q-S7-1 (a)): examples 46, parse refusals 19, check refusals 174, pool refusals 4, bridge refusals 3, kit-only refusals 22, evals 217, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures; the host and precompile rows wait for intent-lang S5 and S6 (O33) |
| S8 | `ZKBridge` as the mapping cylinder; `ZKBridge ≃ BridgeState`; bLSAG claim rings and key images | DONE (2026-10-23), the guest side (Q-S8-1 (a) to Q-S8-4 (a)): examples 47, parse refusals 19, check refusals 175, pool refusals 4, bridge refusals 6, kit-only refusals 22, evals 237, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures; no src change and no domain change (O38 to O43) |
| S9 | Part D: encrypted ballots, `tallyEnc`, the tally law, liquidity Decisions, the remote enactment | PLANNED |
| S10 | The contract of section 7: writer, two-deployment differential, gas and size rows | PLANNED |
| S11 | Mutants and close | PLANNED |

## 10. Open items

- O1: the name bridge-lang. Builder call.
- O2: the kit and the kernel route (section 6). Builder call.
- O3: the reading of R1 (section 2), as intent-lang ruled it. RULED: Q1
  (a).
- O4: `ZKBridge` has no type parameter, so R1 does not limit it (2.2).
  Builder call.
- O5: a swap, a liquidity change and a bridge transfer are morphisms of the
  free category `Trace`, not paths, because `Pool k` is a set (4.1).
  RULED: Q2 (a).
- O6: `Pool k` holds `k ≤ x * y` over `U256`; swap outputs are the least
  solutions (4.2). RULED: Q3 (a).
- O7: reserves stay below `2^128`; a larger value reverts. The S5 slice
  checks the kit `U256` overflow behavior. Builder call. S5 result: the
  kit `u256Add` traps on an overflow and `u256Sub` stops at 0
  (`src/front/u256.h` lines 20 and 21). The kit has no `u256Mul` and no
  `u256Div` (sealed-lang R19, `docs/host/README.md` line 316), so
  `examples/pool.lang` gives `mul`, `divFloor` and `divCeil` as folds over
  the 256 powers of two (Q-S5-1). `mul` traps on a product of `2^256` or
  more. `divFloor` traps on a divisor of 0 and needs a divisor below
  `2^255`. `capped r` is the bound on one word: `r` when `r` is below
  `2^128`, else a trap. The operations use `checkedReserves x y`: it
  checks that each new reserve is from 1 to `2^128 - 1` before it gives
  either. A failure traps through each projection, because the evaluator
  is lazy and a check in one field does not run when a caller reads only
  the other field.
- O8: liquidity keeps the price, not the product; the DAO is the only
  liquidity provider (4.3). RULED: Q4 (a).
- O9: the bridge model: virtual credit reserves, batches, attestation,
  claims (4.4). RULED: Q5 (a).
- O10: privacy is the unlinkability of a deposit and its claim; amounts are
  public (4.5). RULED: Q7 (a).
- O11: pool arithmetic is public; FHE is only in the DAO tally (4.5).
  RULED: Q7 (a).
- O12: `fheHom` is a law of `decrypt`, not a constructor (3.4). Builder
  call.
- O13: one BN254 key for ElGamal and Schnorr (4.6). RULED: Q6 (a).
- O14: the attested message names the side and the batch number. A second
  bridge with the same committee needs the chain id or the contract address
  in the message; the kit `Env` has neither. Builder call; S10 decides.
- O15: reuse of the intent-lang slices (section 6). RULED: Q9 (a).
- O16: `Stream` of batches is the one CC instance of the plan. Builder
  call.
- O17: the ring size of a claim bounds its gas. S10 measures it. Builder
  call.
- O18: the dash check of `test/gate.sh` skips `design/DESIGN.md`, because
  the design is verbatim and holds two em-dashes (tile-lang ruling
  2026-10-09). Builder call. S2 kept the exemption after the port (the
  orbit test/gate.sh has none).
- O19: the kanon run dirs .kanon-exec/ and .kanon-wait/ are ignored, so
  `git add -A` cannot stage them. Builder call.
- O20: the name `Pos` (3.2) is a domain family of the DAO, the positions
  of a bag (`domain/domain.lang` line 71, orbit-lang S7 B3). A guest
  `def Pos` gives `REFUSE_NAME` (rule R4). So the name in the code is
  `Positive`. Builder call.
- O21: Q-S6-1 (a) is taken: `examples/bridge.lang` holds a copy of the
  pool defs of `examples/pool.lang` up to `swapOut`. Builder call.
- O22: `Denom` is the words 10 and 100 as a refinement of `U256` (the
  `Positive` form). `Side` is `Fin 2`. `Key` is the two affine words of a
  BN254 G1 point. The names Side, Asset, Credit, Msg, Denom, InFlight,
  BridgeState, deposit, seal, accept, claim, Key, Sealed, Accepted, Mem
  and Sig have no clash in `domain/domain.lang` or as a name in
  `src/front/check.c`. Builder call.
- O23: the exchanged swap `claimW` is in `examples/bridge.lang`, so
  `examples/pool.lang` and its rows stay as committed. Builder call.
- O24: `test/gate.sh` line 52, `refusals test/bridge bridge
  examples/bridge.lang` (the S5 form; no new harness). Builder call.
- O25: the S3 port base is intent-lang 32c1d13 on aacc8ad: `git diff
  aacc8ad 32c1d13` without docs/PLAN.md and docs/STATUS.md, with
  `intent-lang` renamed `bridge-lang`. The patch applied clean: 34 paths,
  no reject, offsets only in `src/front/check.c` and `test/fronttool.c`.
  Builder call.
- O26: local lines kept against the patch (S2-port drift; bridge-lang S2
  took orbit-lang 2162fb2, intent-lang aacc8ad has a later text):
  `docs/host/README.md` lines 3 and 310 (the orbit text);
  `src/front/check.c` the zkProve local name `ballot_type` and its
  message, the zkProject argument check form and one DOMAIN_FAMILY
  message (line 3403); `src/front/eval.c` line 2525 has no constant-line
  `transp` rule at `ZkBallot` (intent-lang 32c1d13 has one, O31).
  `src/front/front.c` differs only by the `bridge-lang` rename. Same
  behavior class on the gate.
  Builder call.
- O27: bridge-lang-only rows kept: `test/eval/expect.txt` 21 pool rows
  and 19 bridge rows after line 159 (the patch rewrote 9 rows in place:
  formers `xs`, quot `toTrunc3`, 7 elim rows); `test/fronttool.c` keeps
  the orbit `Evil` DOMAIN_FAMILY case and the `impossible : Fin 0` case.
  The 7 intent-lang aacc8ad cases that bridge-lang lacks are Q-S3-2.
  Builder call.
- O28: the bridge-lang-only files (`examples/pool.lang`,
  `examples/bridge.lang`, `test/pool/*`, `test/bridge/*`) check unchanged
  after the port: they use the kit `List`, `nil`, `cons`, `unfold` and
  `fold` under `--kit`, and `REFUSE_CELL` on `List` is guest mode only.
  Pool refusals 4, bridge refusals 3, the 21 pool and 19 bridge eval rows
  at their values. Verified by the gate.
- O29: the Q-S6-2 (a) probe, a scratch copy of `examples/bridge.lang`
  with `InFlight := Bag Msg` and `sumCredit` as the elim of `Bag` into
  `U256`: the first diagnostic is `PATH_END: addAssoc: the path at i1 is
  u256Add (u256Add a b) c, but the type needs u256Add a (u256Add b c)`.
  Each lemma alone: `u256Add` assoc, comm, left unit and right unit at
  open words PATH_END; `isSet U256` PATH_UIP; `flagOr` assoc and comm
  PATH_END; `flagOr flagNo a = a` ok; `isSet Flag` PATH_UIP. So
  `InFlight` stays `List Msg` (Q-S3-1). Builder call.
- O30: a "USER ruling Q-S3-n" citation in a ported file names the
  intent-lang PLAN ruling, not a bridge-lang one, as the S2-port texts
  cite orbit-lang rulings: `domain/domain.lang` cites Q-S3-5, Q-S3-6,
  Q-S3-7 and Q-S3-8; `examples/freemon.lang` and `src/front/check.c`
  cite Q-S3-5. The bridge-lang S3 questions are in section 11.
- O31: the fronttool drift probe (scratch copy of the tree with the 7
  intent-lang aacc8ad cases): 6 pass on the bridge-lang checker; the
  `constant` case (`transp (fun (_ : I) => ZkBallot C) i0 b` is `b` by
  refl) fails with PATH_END. The gap is `src/front/eval.c` line 2525
  (`case OP_ZK_BALLOT: break;` in the transp reduction); intent-lang
  32c1d13 returns the base there when the two ends of the line convert.
  No repo change (Q-S3-2). Builder call.
- O32: the S3 commit is the USER commit 8077f7a on ce6f9d3. Its tree
  (290291f3) is not the staged S3 tree (ee302089). The USER edits:
  `src/front/check.c` normalizes aliases in the field types of a cell
  signature, refuses a type argument in data (a Sigma or a closed
  family) and checks the header again after the constructors;
  `SPEC.md` says so; `test/fronttool.c` has 13 more cases. The gate
  counts do not change. Recorded in S7.
- O33: Q-S7-1 (a) is taken: the guest side first. intent-lang has no S5
  and no S6 commit (its top is 32c1d13), so the host ElGamal, the DLEQ
  and Lagrange host rows and the precompile rows come with the port of
  those commits (Q9 (a)). Builder call.
- O34: Q-S7-2 (a) is taken: `Enc` is not sealed. A program cannot
  declare a family (`REFUSE_DATA`, `src/front/check.c` line 4096;
  `test/check/enc-guest-family.lang`), so `examples/enc.lang` has the
  alias `Enc A := Prod Unit A`, and `decrypt` is the projection
  `second`. A program can use `decrypt` out of a law, and a
  redefinition is not `REFUSE_SIG` (the SIGNATURE rows at
  `src/front/check.c` line 3854 have the DAO names only). The ZK splice
  is the C string `zk_source` in `src/front/front.c` (line 53), not a
  `kernel/` file. Builder call.
- O35: `examples/elgamal.lang` (kit) is exponential ElGamal on G1 with
  the generator (1, 2). The kit has no `u256Mul` (Q-S5-1), so the
  scalars of the proofs and the Lagrange weights 2 and r - 1 (the shares
  at 1 and 2) are literals, computed off the chain: the Schnorr s is
  (23 + 7 e) mod r and the DLEQ z is (19 + 12 c) mod r, with e and c
  from a frontend eval of the challenge hash. The attest message is
  `hash (hash side n) d`; S10 gives the byte form of the contract.
  The DLEQ challenge commits to A, B, X, C1 and d, including the
  ciphertext base; the z literal uses that transcript.
  Builder call.
- O36: the laws of S7. In `examples/enc.lang` the monad laws of 3.4
  (`etaLaw`, `bindLaw`, `openLaw`) are refl at open values (the
  projection of a pair), `privacy` is `squash1` at open values, and
  `fheHom` is refl at a closed value. In `examples/elgamal.lang` the
  open law (a `Point` path) and the attest law (a `Flag` path) are refl
  at closed values only (Q-S5-2: no rule makes a path from a Flag test).
  A false attest law is `PATH_END` (`test/check/attest-wrong.lang`).
  Builder call.
- O37: the S7 review fixes two issues in `examples/elgamal.lang`.
  `elgPoint` negates x C1 as a point instead of using the saturating
  subtraction `u256Sub r x`, so keys above r decrypt correctly, with
  rows for 0, r, r + 1 and the maximum U256. The DLEQ challenge now
  includes C1: otherwise a prover can choose C1 after the challenge
  and pass a false share. Two rows reject a concrete forgery and
  confirm that its claimed relation is false. The valid DLEQ z was
  recomputed for the corrected transcript.
- O38: Q-S8-1 (a) is taken: `ZKBridge` is a guest mapping cylinder. A
  program cannot declare a family (`REFUSE_DATA`, O34), so
  `examples/cylinder.lang` has the alias `Cyl A B f := (b : B) * Trunc1
  (Option A)`, and `examples/bridge.lang` has a copy (Q-S6-1 (a)). A
  point is its public state and a truncated optional private input.
  `zkProof` is `cylPush`: the path from `privateComp x` to `public
  (result x)`, by `squash1`. `cylSec` is refl, `cylRet` is `squash1`,
  and `isoToEquiv` gives the equivalence of `ZKBridge` and
  `BridgeState` at open values; `ua` gives the path of types
  (`cylPath`). A top-level `Equiv` value is refused
  (`examples/equiv.lang`), so `zkEquiv` is a function of `Unit`.
  `lawPublic` is refl at closed values (PLAN 5). A refl in the place of
  `cylPush` is `PATH_END` (`test/check/zk-cyl-refl.lang`). No src
  change and no domain change. Builder call.
- O39: Q-S8-2 (a) is taken: the tag stays "orbit" (Q-S2-1 stayed OPEN until O51).
  The poll word of a claim is the hash of the domain word "claim"
  (0x636c61696d) and the batch number, so a claim signature is not a
  ballot signature. The tag is the global constant `BLSAG_TAG`
  (`src/front/blsag.c` line 12), and H_p hashes only (P.x, P.y)
  (`src/front/blsag.c` line 87). So one key gives one key image at each
  tag and each poll (`test/precompile.sh` lines 118 and 119 at poll 7
  are equal to lines 105 and 106 at poll 0), and a tag cannot separate
  key images. The eval row `imgBallot` (1) shows this link. VALIDATION
  assumption: key-image unlinkability between the claim rings and the
  ballot rings (S9) rests on one-time deposit keys (PLAN 4.5, O13).
  Builder call.
- O40: Q-S8-3 (a) is taken: `mpcCube` has no guest constructor.
  `ZKBridge` is a set, and the content of the square is the S7 attest
  law (O36). Builder call.
- O41: Q-S8-4 (a) is taken: `claimRing` is beside `claim` in
  `examples/bridge.lang`; `Mem` and `claim` do not change. `RingClaim a
  d s spent` has two paths: `zkVerify` of s over the keys of the batch
  of a with denomination d (`ringAt`) at the claim poll, and `fresh` of
  the key image of s (`sigImage`, the last two words) in spent. A
  claim transition takes and returns `RingState k`, pairing its pool
  with the spent-image list, and prepends the newly spent image while
  preserving the existing list. Callers thread the returned state. A
  second claim with the same key gives the same key image, so it is not
  fresh against that state (`test/bridge/bridge-claim-twice.lang`,
  `PATH_END`), including after another depositor claims
  (`test/bridge/bridge-claim-earlier.lang`). A
  `flagYes` law at poll 0 is `PATH_END`
  (`test/bridge/bridge-ring-cross.lang`). The pool words of `pRing` are
  those of `pClaim`, (910, 1100) (`lawClaimRing`). Builder call.
- O42: the builder calls of S8. The wf-builder (fable xhigh) and the
  opus xhigh fallback both stopped on the `reasoning_extraction`
  classifier, so the main loop built S8 by hand (USER ruling 10-05).
  The comment at `examples/bridge.lang` lines 95 to 97 ("the kernel Bag
  has a Size index") is stale (`domain/domain.lang` lines 64 to 70);
  S8 did not change it. The optional `test/check/zk-guest-ring.lang`
  (`REFUSE_KIT`) is not in S8: its first refusal is the U256 type, as
  `kit-type-u256.lang` shows.
- O43: staged review found that the original `claimRing` returned only
  the pool and never recorded its key image. Reusing `sig0` with the
  original empty spent list checked successfully and paid again,
  changing (910, 1100) to (835, 1200). `RingState` now carries both
  fields through the transition (O41). Six added eval rows check both
  payouts, retention of the first image, and the two-image list after
  a different depositor claims. The replay refusals use the actual
  returned state rather than a manually assembled spent list.
- O44: the S4 port base is intent-lang 4b36026 on 32c1d13: `git diff
  32c1d13 4b36026` without `docs/PLAN.md` and `docs/STATUS.md`, then
  `sd intent-lang bridge-lang`. The bridge-lang base is the USER commit
  617d39b on 8e859a9 (the S8 tree with the USER review fix, O43). 13
  paths apply with line offsets only. The local differences of
  `SPEC.md`, `docs/VALIDATION.md`, `src/front/check.c` and
  `test/fronttool.c` are not in the hunks. The 3 lists
  `test/check/expect.txt`, `test/check/kit.txt` and
  `test/eval/expect.txt` do not apply, because S5 to S8 added rows at
  their ends. Their new rows (2, 1 and 5) are after the bridge-lang
  rows. intent-lang has a newer USER commit, 1b65dec (its S5: the
  sealed `Enc` monad, a law-only `decrypt`, host ElGamal). S4 does not
  port it (Q-S4-2).
- O45: the keyword check. The lexer hunk adds one keyword, `cofamily`.
  The domain hunk adds `Stream`, `sCorec`, `sHead`, `sTail`, `sExtend`
  and `sDuplicate`, and the checker makes `Stream.pos`, `Stream.walk`
  and `StreamBisim`. No bridge-lang-only file in `examples`, `test`,
  `domain` or `kernel` uses one of these names (`rg -nw`). So no file
  is migrated.
- O46: an "O28" or a "choice (ii)" citation in a ported file
  (`SPEC.md`, `docs/VALIDATION.md`, `domain/domain.lang`,
  `examples/cocell.lang`, `formers/FORMERS.md`) names the intent-lang
  O28 and its elaboration choice, as in O30. The bridge-lang O28 is a
  different item.
- O47: builder calls. The wf-builder (fable xhigh) stopped on the API
  classifier (`reasoning_extraction`, request
  req_011CgKe94yKUvGDYAgRVQSyh) before it wrote a file. The opus xhigh
  fallback stopped on the same classifier (request
  req_011CgKeADaGfqrXNeZLD3grW). Part 1 is a build by hand (USER
  ruling 10-05, as in O42). The session context limit came before Part
  2, so Part 2 is S4 s2 (Q-S4-1 (a)).
- O48: the S4 s2 design (Part 2; PLAN 4.1, 4.4 and section 5). It is
  the kit example `examples/trace.lang`, with no src change and no
  domain change. `W := Prod U256 U256` is the reserve words. `Step :=
  Sum U256 (Sum U256 (Sum W U256))` has four kinds of step: `swapIn dx`,
  `swapOut c`, `addLiq (dx, dy)` and `claim c`. `stepW` uses `elim` on
  `Sum` to select the copied word functions `swapInW`, `swapOutW` and
  `addLiqW` (from `examples/pool.lang`) and `claimW` (from
  `examples/bridge.lang`), in the Q-S6-1 (a) pattern. `Trace := FreeMon
  Step` is the free category on the graph with one object and one edge
  for each step. The laws `tIdl`, `tIdr` and `tAssoc` are the path
  constructors `fmUnitL`, `fmUnitR` and `fmAssoc`, so they hold at open
  traces. `tIsSet := fmIsSet Step` is the trunc. The target is `Run :=
  Trunc0 W -> Trunc0 W`. `runIsSet` is `squash0` at each point, and the
  monoid laws of `Run` are refl. Thus `fmFold` does not need `isSet
  U256` (the O29 gap). `stepRun s` is the `fold` of `Trunc0`: `trunc0 W
  (stepW s r)` at a point and `squash0` at the squash case. The meaning
  functor is `mu := fmFold Step Run runIsSet runId runSeq runAssoc
  runUnitL runUnitR stepRun`. `muId`, `muSeq` (at open f and g) and
  `muStep` (at an open s) are refl by computation. The slice is
  `TraceAt p q := (t : Trace) * Path (Trunc0 W) (mu t (trunc0 W p))
  (trunc0 W q)`, on `FreeMon`, not on `List`. `idAt` and `seqAt` are
  open (`seqAt` uses `trans` and `ap` of `mu`), and `inOutAt` is
  closed. The batch stream is `batches := sCorec Batch U256 batchAt (n +
  1) 1u`, where batch n is `addLiq (n, n)`. `settle2` is the run from
  `w0` of the first two batches. `settled := sExtend Batch (Trunc0 W)
  settle2 batches`, and `dupNext` uses `sDuplicate`. The seed of
  `states` is the index and the state. `lawSettle : Path (Trunc0 W)
  stateTwo settledHead` is refl (closed). 9 eval rows (Q-S4-3 (a),
  Q-S4-4 (a)).
- O49: the S4 s2 probes. The first check of the full candidate stopped
  with `PARSE_EXPECT` at `examples/trace.lang:56:3` ("expected 'def',
  'axiom', 'family', 'cofamily', 'state' or 'event', found 'fun'"). It
  was a copy error (a body line of `swapOut` without its head), not a
  checker limit. The second check was `ok`. Candidate (i) as written
  (the target is the endomaps `W -> W` of the words) was not probed:
  `isSet (W -> W)` needs `isSet U256`, which has no guest proof (O29,
  the PATH_UIP gap, Q-S3-1). Candidate (ii) with `List Step` was not
  probed: its unit and assoc laws hold only at closed values, and
  `FreeMon` gives them at open values. The 9 eval values were
  calculated by hand before the run, and all 9 are equal to the eval
  output. An example: `runInOut` is (1221, 820), because 100 goes in
  and floor (1000 * 100 / 1100) = 90 goes out, then 90 goes out and
  ceil (1100 * 90 / 820) = 121 goes in.
- O50: the builder calls of S4 s2. The wf-builder (fable xhigh) stopped
  on the `reasoning_extraction` classifier (request
  req_011CgKoi6L8icQ15kfWgRji3) before it made an edit. The opus xhigh
  fallback stopped on the same classifier (request
  req_011CgKojhynFu57zzzyMSy8f). The main loop built S4 s2 by hand
  (USER ruling 10-05, as in O42 and O47). The session context limit
  came before the record, so a second session did the record.
- O51: the USER blanket ruling (2026-10-23, verbatim): "Rule all
  defaults for Q-S*-*". Each question with no ruling takes (a): Q-S2-1,
  Q-S3-1, Q-S3-2, Q-S4-1, Q-S4-2, Q-S5-1, Q-S5-2, Q-S6-1, Q-S6-2,
  Q-S6-3, Q-S7-1, Q-S7-2 and the new Q-S4-3 and Q-S4-4. The effects:
  Q-S2-1 (a) keeps the tag "orbit". Its second half (a tag for each
  use) is overtaken by Q-S8-2 (a) (O39), because no tag can separate
  key images. Q-S3-2 (a): the 7 intent-lang aacc8ad fronttool cases
  and the constant-line `transp` rule at `ZkBallot` (intent-lang
  32c1d13) go with the S7 port. Q-S4-2 (a): S7 s2, the port of
  intent-lang 1b65dec, is the next slice, before S9. The other (a)
  options are the forms that are already in the tree.

- O52: staged S4 s2 review: `stepW` called the raw reserve functions
  without the preconditions carried by the public pool operations.
  From (1000, 1000), adding (100, 1) produced (1100, 1001), and
  `TraceAt` accepted that endpoint with `refl`, although `PriceEq`
  fails. A zero input swap was also accepted despite `Positive`.
  `swapInStepW` now checks a positive input. `addLiqStepW` checks
  positive amounts and the same rounded price condition as `PriceEq`:
  `dx * y <= dy * x < dx * y + x`. The guards wrap the whole result,
  so either reserve projection rejects an invalid step. The invalid
  endpoint proof is refused after the fix. Nine regression evals cover
  zero inputs, both price inequalities and a valid rounded addition
  (100, 83) at (1100, 910), producing (1200, 993). There are now 18
  trace evals and 260 evals overall.

## 11. Questions for the USER (S1)

All ten are RULED (S1, 2026-10-22; the quote is in section 1).

- Q1 (O3): reading of R1. (a) as intent-lang ruled: ambient Pi, Sigma,
  Path, U unlimited; declared constructors only CM and CC; the syntactic
  cell criterion. RECOMMENDED. (b) another reading. RULED: (a).
- Q2 (O5): the design's paths in `Pool k`. (a) morphisms of the free
  category `Trace` (a CM). RECOMMENDED. (b) a non-discrete carrier (real
  numbers as a HIT); it is still a set, so this does not help. (c) maps out
  of the interval into a topological carrier; not computable on the EVM.
  RULED: (a).
- Q3 (O6): the invariant. (a) `k ≤ x * y` with least-solution outputs.
  RECOMMENDED. (b) exact rationals off the chain, integer settlement on the
  chain. RULED: (a).
- Q4 (O8): liquidity. (a) keeps the price; the DAO is the only liquidity
  provider. RECOMMENDED. (b) liquidity shares for any user (one more token
  type). RULED: (a).
- Q5 (O9): the bridge model. (a) virtual credit reserves, batches,
  attestation and claims (4.4). RECOMMENDED. (b) a two-asset pool on each
  side and a price oracle. RULED: (a).
- Q6 (O13): the attestation. (a) one Schnorr signature on BN254 under the
  DAO threshold key (FROST off the chain). RECOMMENDED. (b) `t` of `n`
  `ecrecover` signatures of the members. RULED: (a).
- Q7 (O10, O11): privacy. (a) unlinkability by denominations, one-time
  keys and bLSAG ring claims; amounts public; FHE in the DAO tally.
  RECOMMENDED. (b) no bridge privacy; ZK, FHE and MPC only in the DAO.
  (c) shielded notes with a SNARK verifier (`ecPairing`, 0x08); not minimal.
  RULED: (a).
- Q8: the DAO home. (a) the DAO runs on side A; side B enacts an attested
  Decision. RECOMMENDED. (b) one DAO on each side. RULED: (a).
- Q9 (O15): (a) port the intent-lang slices when they exist. RECOMMENDED.
  (b) build them again here. RULED: (a).
- Q10: fee and minimum output. (a) none, because the design gives none.
  RECOMMENDED. (b) a minimum output on `claim`; it needs a refund path.
  RULED: (a).

### S2 questions (RULED)

- Q-S2-1. The bLSAG domain tag of the ported code is the ASCII word
  "orbit" (`src/front/blsag.c` line 12). (a) keep it until S8, where the
  claim rings make new ring vectors; S8 then gives the claim rings and the
  ballot rings (S9) each its own tag, so that a key image of one use cannot
  link to the other. Choose the words in the tag format of
  `src/front/blsag.c` line 12. RECOMMENDED. (b) change it to "bridge" in
  S3 and make the 14 precompile rows again. (c) keep "orbit" for good.
  RULED: (a) (USER, 2026-10-23). Q-S8-2 (a) overtakes its second half
  (a tag for each use), because no tag can separate key images (O39,
  O51).
- Q-S2-2. The order after S2, if intent-lang S3 (REFUSE_CELL) has no USER
  commit yet. bridge-lang S3 ports it (Q9 (a)). (a) do S5 (Part P) next:
  `Pool k` is indexed by a `U256` value, not by a type, so R1 does not
  touch it; S3 and S4 come after the intent-lang S3 commit. RECOMMENDED.
  (b) wait for intent-lang S3. (c) build S3 here (this goes against Q9
  (a)). RULED: (a) (the USER ran the S5 prompt, 2026-10-22).

### S5 questions (RULED)

- Q-S5-1 (kit multiply and divide). (a) keep the guest folds of
  `examples/pool.lang`; S10 measures their gas, then decides. RECOMMENDED.
  (b) add `u256Mul`, `u256Div` (and a ceil form) as kit operations now:
  `src/front/check.c` BUILTINS (line 184 area), `src/front/eval.c`
  `u256_arith` (line 1333), `src/front/u256.c` (`u256_mul` is still in
  `src/front/u256.h` line 22), the EVM lowering in `src/lower.c`. This
  undoes sealed-lang R19 here. (c) (b) only for the EVM form, guest folds
  for the laws. RULED: (a) (USER, 2026-10-23).
- Q-S5-2 (the laws). The checker has no rule that makes a `Path Flag _
  flagYes` proof from a Flag test (`rule_flag_if`, `src/front/check.c`
  line 2286), so `swapIn : Pool k -> Pos -> Pool k` (4.2) cannot check
  its law. (a) laws at fixed values: each operation takes its
  precondition (`Lt c y`, `PriceEq`, `Share`) and a `PoolLaw` proof of
  the new reserves as arguments and gives a `Pool k` (`removeLiq` gives
  `(k' : U256) * Pool k'`); closed values with refl fields are the laws
  at fixed points; evals check the boundary. Commit 44ee99d has this
  form. RECOMMENDED. (b) a dependent Flag eliminator (a `decide` rule at
  `rule_flag_if`), so that `swapIn : Pool k -> Positive -> Option (Pool
  k)` checks the invariant at run time. This is a src change (the Q-S5-1
  rulings apply). RULED: (a) (USER, 2026-10-23).

### S6 questions (RULED)

- Q-S6-1 (the pool defs in a second example). (a) copy them in
  `examples/bridge.lang`; the gate checks each guest file alone.
  RECOMMENDED, taken (O21). (b) a prelude form for examples and evals in
  `test/gate.sh`, so that `examples/bridge.lang` reads
  `examples/pool.lang` and holds no copy. RULED: (a) (USER, 2026-10-23).
- Q-S6-2 (the `InFlight` carrier). (a) `List Msg` in batch order until
  bridge-lang S3 ports the intent-lang free commutative monoid; then
  `InFlight` becomes that bag. RECOMMENDED. (b) a kit path rule for the
  commutativity of `u256Add` (a src change: the BUILTINS table,
  `src/front/check.c` line 129; `u256Add` is at line 184), so that a sum
  over the current `Bag` checks now. (c) a count for each denomination in
  a pair of Nat; it needs a dependent eliminator on `Fin 2` (there is
  none; the Q-S5-2 site, `src/front/check.c` line 2286). RULED: (a)
  (USER, 2026-10-23).
- Q-S6-3 (`ua e` on a whole pool value). (a) the law on the reserve word;
  the S10 two-deployment differential checks the same bytecode on the
  two sides. RECOMMENDED. (b) a larger arena, or a lazy Glue transport at
  a Sigma (a src change; the limit is at `src/front/eval.c` line 90).
  RULED: (a) (USER, 2026-10-23).

### S3 questions (RULED)

- Q-S3-1 (the `InFlight` carrier after the S3 port; from Q-S6-2 (a)).
  The probe (O29) shows that a fold out of `Bag Msg` into `U256` needs
  four rules at open words: `u256Add` assoc, comm and left unit
  (PATH_END) and `isSet U256` (PATH_UIP). (a) keep `InFlight := List Msg`
  (a kit file; `examples/bridge.lang` is in `examples/kit.txt`) until a
  later slice. RECOMMENDED. (b) kit path rules for `u256Add` (assoc, comm
  and unit) and a set rule for `U256` (a src change: the BUILTINS table of
  `src/front/check.c`, `u256Add` at line 187, and the PATH_UIP site), so
  that `sumCredit` checks; `inBatch` also needs `flagOr` assoc and comm
  and `isSet Flag`, and `removeMsg` the same at `Prod Flag (Prod InFlight
  InFlight)`. (c) `InFlight := FreeMon Msg` with `fmFold`: it takes
  `isSet U256` and the `u256Add` laws as arguments, so it needs the (b)
  rules too. RULED: (a) (USER, 2026-10-23).
- Q-S3-2 (the 7 intent-lang aacc8ad fronttool cases, O27 and O31). (a)
  add the 6 cases that pass as regression cases in a later slice (no src
  change), and port the constant-line `transp` rule at `ZkBallot` from
  intent-lang 32c1d13 `src/front/eval.c` (the gap is bridge-lang
  `src/front/eval.c` line 2525) with the seventh case in the S7 port.
  RECOMMENDED. (b) add the 6 cases now and leave the seventh out. (c)
  leave all 7 out; the intent-lang review cases are not bridge-lang work.
  RULED: (a) (USER, 2026-10-23). The 7 cases and the `transp` rule go
  with the S7 port (S7 s2, O51).

The USER RULED Q-S2-1, Q-S3-1, Q-S3-2, Q-S5-1, Q-S5-2, Q-S6-1, Q-S6-2
and Q-S6-3 (a) (2026-10-23, O51). Q-S6-2 (a) is the S6 form; the S3
probe (O29) did not make the change, so Q-S3-1 carries the carrier
question.

### S7 questions (RULED)

- Q-S7-1 (the order of the host and precompile rows). intent-lang has no
  S5 and no S6 commit. (a) the guest side first: `Enc`, `decrypt`,
  `open`, `observe` and the Schnorr attestation verify as guest code and
  laws over the kit BN254 operations, with eval rows; the host and
  precompile rows after the intent-lang S5 and S6 commits (a port, Q9
  (a)). RECOMMENDED, taken (O33). (b) wait for them. RULED: (a) (USER,
  2026-10-23).
- Q-S7-2 (the seal of `Enc`). A program cannot declare a family
  (`REFUSE_DATA`), and the checker has no seal rule and no law-only
  rule: `fold`, `elim` and the projections are guest operations, and
  `REFUSE_SIG` comes only from the SIGNATURE rows. (a) no src change and
  no domain change now: `examples/enc.lang` has the alias `Enc A :=
  Prod Unit A`, `decrypt` is the projection, the laws are refl; the seal
  is a recorded gap (O34) until the intent-lang S5 port. RECOMMENDED,
  taken. (b) `family Enc (A : Type 0) := encEta (encOf : A)` in
  `domain/domain.lang` (the CM row of 2.2), not sealed; a program def
  with one of its names is then `REFUSE_NAME`. (c) (b) and a seal rule
  in `src/front/check.c`: a guest program cannot fold, elim or project
  an `Enc`, and uses `decrypt` only in a law; SIGNATURE rows, so that a
  redefinition is `REFUSE_SIG`. (d) new internal operations in the form
  of `ZkBallot` (`src/front/core.h` line 94, the BUILTINS table, a rule
  in the form of the `zkProject` rule, a reduction in the form of
  `src/front/eval.c` line 1871, a `transp` case at `src/front/eval.c`
  line 2525) and an `Enc` splice in `src/front/front.c` (the `zk_source`
  form). A reuse of `ZkBallot` is not an option: `Enc Choice` would be
  the private ballot type of the ZK splice. RULED: (a) (USER,
  2026-10-23). The port of intent-lang 1b65dec (S7 s2, Q-S4-2 (a))
  replaces the alias with the sealed `Enc`.

Q-S7-1 (a) and Q-S7-2 (a) are taken. The USER RULED both (a)
(2026-10-23, O51).

### S8 questions (RULED)

- Q-S8-1 (the form of `ZKBridge`). (a) a guest `Cyl` in `examples`, no
  src change and no domain change. RECOMMENDED, taken (O38). (b)
  `family Cyl` in `domain/domain.lang`. (c) a kernel splice
  `kernel/zkbridge.lang`. RULED: (a) (USER, 2026-10-23).
- Q-S8-2 (the claim domain; Q-S2-1 was OPEN then). (a) keep the tag
  "orbit", put the word "claim" in the poll slot, and record key-image
  unlinkability as a VALIDATION assumption (one-time keys, O13), with
  the fact that a tag cannot separate key images. RECOMMENDED, taken
  (O39). (b) src: the tag as a parameter and H_p(tag, P); all the zk,
  precompile, prove and contract vectors again. (c) Q-S2-1 (b) as
  written: the global tag "bridge"; src, the vectors again, and no
  key-image separation. RULED: (a) (USER, 2026-10-23).
- Q-S8-3 (`mpcCube`). (a) no guest constructor; `ZKBridge` is a set;
  the content is the S7 attest law. RECOMMENDED, taken (O40). (b) a
  refl square on `zkProof` at closed values. (c) defer to S10. RULED:
  (a) (USER, 2026-10-23).
- Q-S8-4 (the place of the ring claim). (a) extend
  `examples/bridge.lang` beside `claim` and keep `Mem`. RECOMMENDED,
  taken (O41). (b) replace `Mem` in `claim` (this changes
  `examples/bridge.lang` line 141, `pClaim` and
  `test/bridge/bridge-claim-absent.lang`). (c) a new kit example with a
  copy of `examples/bridge.lang` (the Q-S6-1 pattern). RULED: (a)
  (USER, 2026-10-23).

The USER RULED Q-S8-1 (a), Q-S8-2 (a), Q-S8-3 (a) and Q-S8-4 (a)
(2026-10-23). The blanket ruling of O51 then RULED Q-S2-1, Q-S3-1,
Q-S3-2, Q-S5-1, Q-S5-2, Q-S6-1, Q-S6-2, Q-S6-3 and Q-S7-2 (a).

### S4 questions (RULED)

- Q-S4-1 (the order of Part 2). (a) S4 s2 next: `Trace`, its category
  laws, the meaning functor and `Stream` of batches on the ported
  `cofamily Stream`, before S9. RECOMMENDED, taken (O47). (b) S9 first,
  then S4 s2. RULED: (a) (USER, 2026-10-23).
- Q-S4-2 (the port of intent-lang 1b65dec, its S5, O44). S9 uses `Enc`
  for the encrypted ballots. (a) port 1b65dec after S4 s2 and before
  S9, so that S9 uses the sealed `Enc` and does not migrate later; the
  port is a src change and answers Q-S7-2 in the intent-lang form.
  RECOMMENDED. (b) S9 first on the S7 alias `Enc A := Prod Unit A`
  (Q-S7-2 (a)), then the port and a migration of S9. No step of S4 s1
  takes an option. RULED: (a) (USER, 2026-10-23).
- Q-S4-3 (the slice laws). A path in `TraceAt p q` needs a PathP of the
  endpoint paths over `tIdl` (and the other laws). (a) the laws on the
  trace component (open, the `FreeMon` constructors); the endpoint
  component is a proposition because `Trunc0 W` is a set; the Sigma
  form of the laws is a recorded gap. RECOMMENDED, taken (O48). (b) a
  guest `isProp` lemma for a PathP into a set (a toPathP form) in a
  later slice, then the full Sigma laws. (c) the lemma in
  `domain/domain.lang`. RULED: (a) (USER, 2026-10-23).
- Q-S4-4 (the target of `mu`). The run is in `Trunc0 W`, so a guest map
  can read the words back only into a set. (a) keep `Trunc0 W`; the S10
  contract uses the word functions, not `mu`. RECOMMENDED, taken (O48).
  (b) a set rule for `U256` (src, the Q-S3-1 (b) rule), then `Run := W
  -> W`. RULED: (a) (USER, 2026-10-23).

Q-S4-1 (a), Q-S4-3 (a) and Q-S4-4 (a) are taken. The USER RULED all
four S4 questions (a) (2026-10-23, O51). Q-S4-2 (a) makes S7 s2 (the
port of intent-lang 1b65dec) the next slice. No question is OPEN.
