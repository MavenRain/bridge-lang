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
| S7 | `Enc`, `decrypt`, `open`, Schnorr attestation verify; host and precompile rows (port from intent-lang S5 and S6 when they exist) | s1 DONE (2026-10-23), the guest side (Q-S7-1 (a)): examples 46, parse refusals 19, check refusals 174, pool refusals 4, bridge refusals 3, kit-only refusals 22, evals 217, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures; the host and precompile rows wait for intent-lang S5 and S6 (O33); s2 DONE (2026-10-23), the port of intent-lang 1b65dec (the sealed `Enc`, the law-only `decrypt` and the host ElGamal) and the Q-S3-2 (a) item (O53 to O58, Q-S7-3 (a)): examples 50, parse refusals 19, check refusals 185, pool refusals 4, bridge refusals 6, kit-only refusals 22, evals 267, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures; the precompile rows wait for the port of intent-lang S6 9b99528 (O33) |
| S8 | `ZKBridge` as the mapping cylinder; `ZKBridge ≃ BridgeState`; bLSAG claim rings and key images | DONE (2026-10-23), the guest side (Q-S8-1 (a) to Q-S8-4 (a)): examples 47, parse refusals 19, check refusals 175, pool refusals 4, bridge refusals 6, kit-only refusals 22, evals 237, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures; no src change and no domain change (O38 to O43) |
| S9 | Part D: encrypted ballots, `tallyEnc`, the tally law, liquidity Decisions, the remote enactment | DONE (2026-10-24), Part D is closed. s1 DONE (2026-10-23), the tally, the tally law and the liquidity Decisions (Q-S9-1 (a), Q-S9-2 (a)): examples 52, parse refusals 19, check refusals 188, pool refusals 4, bridge refusals 6, kit-only refusals 22, evals 277, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures; s1 has no src change and no domain change (O59 to O63). s2 DONE (2026-10-24), the remote enactment and the signed ballot in the kit examples `examples/enact.lang` and `examples/ballot.lang` (Q-S9-3 (a), Q-S9-4 (b)): examples 54, parse refusals 19, check refusals 191, pool refusals 4, bridge refusals 6, kit-only refusals 22, evals 314, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures; s2 has no src change and no domain change (O64 to O68) |
| S10 | The contract of section 7: writer, two-deployment differential, gas and size rows | DONE (2026-10-26), the contract of section 7 is closed. s1 DONE (2026-10-24), the port of the intent-lang S7 one-hot proof (ef5abe8, Q-S10-1 (a)) and the signed encrypted cast in the kit example `examples/cast.lang` (Q-S10-4 (a), Q-S10-7 (a)): examples 57, parse refusals 19, check refusals 193, pool refusals 4, bridge refusals 6, kit-only refusals 22, evals 335, proves 2, contracts 2 written 5 refused, rings 6 built 2 refused, gate 0 failures, precompile 135 steps; s1 has a src change (`src/front/sigma.c`, `src/front/sigma.h`, the ZK walk skip of `src/front/check.c`) and a domain change (`ZKProof`, `Transcript`, `verified`) (O70 to O74); s2 DONE (2026-10-25), the twin contract `examples/twin.lang` (one bytecode, two deployments, the side value as the `init` argument, Q-S10-2 (a), Q-S10-3 (a), Q-S10-5 (a)) and the kit primitives `u256Mul` and `u256Div` (Q-S10-9 (a)): examples 59, evals 353, rings 7 built 2 refused, runs 8, lower refusals 17, build checks 34, precompile 143 steps, gate 0 failures; s2 has a src change (the `init` argument in `src/lower.c`, `src/evm.c`, `src/evm.h`, `src/asm.h` and `src/front/check.c`; `u256Mul` and `u256Div` in `src/front/core.h`, `src/front/check.c`, `src/front/eval.c` and `src/lower.c`) and a temporary DEVIATION from PLAN 7 (the claim has no ring signature on the EVM, Q-S10-11 (c)) (O75); s3 DONE (2026-10-25), the geth two-deployment differential of `examples/twin.lang` (D4), the gas rows and the contract mutants (Q-S10-8 (a), Q-S10-13 (a), Q-S10-15 (a), Q-S10-16 (a)): evals 355, lower refusals 18, build checks 35, runs 10, diff gate 33 rows, gate 0 failures; s3 has a src change (the entry arity check in `residualize`, `src/lower.c`) (O77); s4 DONE (2026-10-25), the bLSAG slice: one shared unrolled routine `sharedRing` for `cast` and `claim` (the routine path of `src/ir.h`, `src/lower.c` and `src/evm.c`), the open ring fix of Q-S10-10 (a) with the closed key table of Q-S10-17 (b), the claim ring signature on the EVM in the 4 ring map fields of Q-S10-18 (a) (runtime 24166 bytes, 410 free under EIP-170): lower refusals 20, build checks 40, twin rows 14, diff gate 33 rows, gate 0 failures; s4 has a src change (the routine path) and CLOSES the DEVIATION of s2 (O78); s5 DONE (2026-10-25), routine call refusal text fixed and close audit recorded (O79): lower refusals 21, build checks 45, twin rows 14, diff gate 33 rows, gate 0 failures; s6 DONE (2026-10-26), amendment in the twin bytecode (Q-S10-19 (a) to Q-S10-26 (a)): the State fields `poll` and `charter`, the amend `enact` tag 3 with the quota menu of `close`, one live poll and the views `pollOf` and `charterOf` (runtime 24472 bytes, 104 free under EIP-170): lower refusals 21, build checks 45, twin rows 22, diff gate 35 rows, gate 0 failures; s6 has no src change (O80); each exit of PLAN 7 is DONE |
| S11 | Mutants and close | DONE (2026-10-26), the plan is CLOSED. The mutants DONE (2026-10-26), the contract mutant matrix: 29 mutants, 28 KILLED, 1 EQUIVALENT (M-d3); S11 adds 10 guest mutants of `examples/twin.lang`, all KILLED, and 8 twin rows: twin rows 30, lower refusals 21, build checks 45, diff gate 35 rows, gate 0 failures; S11 has no src change and no domain change (O81); the close DONE (2026-10-26): the USER RULED Q-S7-3 (a), Q-S9-1 (a), Q-S9-2 (a), Q-S9-3 (a) and Q-S9-4 (b) (section 11), no question is OPEN, the plan is CLOSED (O82) |

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
- O17: S10 measures the claim at ring size 3: 189661 execution gas
  on the recorded steps of `test/diff.sh` (O78 to O80). The twin contract
  has three member indices and three signature responses. Other ring
  sizes have no entry in this ABI and have no measured bound. A bound
  for another size needs a new contract and new size and gas rows.
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

- O53: S7 s2 is the port of intent-lang 1b65dec (the USER commit on
  4b36026, "Add the sealed Enc monad, law-only decrypt and host ElGamal
  (S5)", Q-S4-2 (a)). The patch is `git diff 4b36026 1b65dec` of
  intent-lang without `docs/PLAN.md` and `docs/STATUS.md`, with each
  `intent-lang` changed to `bridge-lang`. `git apply --reject` applies
  each hunk except the 4 lists (`examples/kit.txt`,
  `test/check/expect.txt`, `test/check/kit.txt` and
  `test/eval/expect.txt`: the rows are at the end, O44) and the
  `check_family` hunk of `src/front/check.c`. The local merge:
  bridge-lang calls `cell_header` a second time after the universe
  loop, and `has_type_param` takes the machine, so the sealed check
  comes after the `cell_generators` line with
  `has_type_param(m, &m->families[first])`. The new list rows come
  after the local rows. The lexer adds the keywords `sealed` and `law`.
  No guest identifier has these names (only comments and the file name
  `u256-law.lang`). The host names `g1_neg` and `g1_eq` of
  `src/front/elgamal.c` do not clash with `src/front/bn254.h` or
  `src/front/blsag.h`. intent-lang S6 is 9b99528 (on 1b65dec, "Add
  threshold opening with private dealer entropy (S6)"). S7 s2 ports
  nothing from it.
- O54: "rule O7" in `SPEC.md`, `domain/domain.lang`,
  `src/front/check.c` and the ported examples is the intent-lang seal
  rule (intent-lang SPEC rule O7), not the bridge-lang O7 (the reserves
  bound). The text stays as in intent-lang, as `domain/domain.lang`
  keeps the foreign "(O23)".
- O55: the merge of `examples/enc.lang`. The intent-lang content comes
  first with no change, then the bridge-lang guest defs `etaLaw`,
  `bindLaw`, `privacyA`, `fheHom`, `two` and `bindAt`. The local defs
  of `Enc`, `encEta`, `decrypt`, `encBind` and `observe` are removed:
  the domain has them. This closes the gap of O34: `Enc` is sealed and
  `decrypt` is law-only. In S7 s1, `bindLaw` was refl on the alias. On
  the sealed `Enc`, refl fails at a neutral `c`, so `bindLaw` is now
  the `elim` proof of the intent-lang `lawBind` at each A. The law is
  not weaker. The intent-lang `privacy` (at `Size`) keeps its name, and
  the local generic `privacy` is now `privacyA`. The `bindAt` value is
  `encEta Size (szS (szS (szS sz0)))` (it was `pair unit ...`).
  `test/check/enc-guest-family.lang` stays `REFUSE_DATA`, because
  `check_decl` refuses a program family before the name check. Only its
  comment changes.
- O56: Q-S7-3 (a) is taken (the law-only migration). With the port, the
  guest `open` of S7 s1 is refused: `langc: REFUSE_LAW: open: open uses
  a law-only name (decrypt, observe, an elim, fold or projection of a
  sealed family) but its type is not a law (a Path or Trunc1 codomain);
  rule O7`. `open`, `decEta` and `openAt` open a ciphertext and return
  A or `Size`. `Quorum` and `openLaw` need `open`. These five defs move
  to the kit example `examples/enc-ideal.lang` (the trusted scope, as
  the intent-lang `openSum`). `two` is in the two files, because
  `bindAt` stays in the guest. The eval rows are now `enc-ideal decEta`
  and `enc-ideal openAt`, with the same values. No law is weaker. The
  port of intent-lang S6 replaces the kit `Quorum` and `open` with the
  domain `family Quorum` and `law def open` (a name clash to resolve in
  that port).
- O57: Q-S3-2 (a). The 7 intent-lang aacc8ad fronttool cases are in
  `test/fronttool.c` after the `prove_output` rows. The constant-line
  `transp` rule at `ZkBallot` (intent-lang 32c1d13, `transp_data` in
  `src/front/eval.c`) replaces the `break` of `case OP_ZK_BALLOT`:
  when the two ends of the line convert, `transp` returns the base. It
  is the only src change outside the port. The fifth case (`constant`,
  by refl) passes with it. The S7 s2 survey found `PATH_END` for that
  case without the rule. The build did not run it again without the
  rule. The 18 new fronttool rows (11 of 1b65dec and the 7 cases) pass
  ("domain regressions: passed"). The 8 rows of the new
  `test/elgamaltool.c` pass ("elgamal regressions: passed").
- O58: the builder calls of S7 s2. There is no builder call: the main
  loop built S7 s2 by hand (USER ruling 10-05, as in O42, O47 and O50).
  The first session made the map and stopped at the context limit with
  a clean tree. A second session did the build and the record. The map
  expected 23 kit-only refusals. The real count is 22: `enc-state.lang`
  is a `REFUSE_STATE` row checked with `--kit` (`test/check/kit.txt`),
  not a `REFUSE_KIT` row.
- O59: the USER edit of b71c078 (the S7 s2 commit). The commit tree
  7f204eec is not the staged tree 1c5dd4c0. In `src/front/check.c`
  `rule_path`, `core_ends(..., CORE_PATHP, "_", t, ...)` replaces NULL:
  the checked carrier stays in `CORE_PATHP.a`, so the law-use check sees
  the carrier before it is quoted under the interval binder (+1 comment
  line). A law-only name in a Path carrier (for example `Path ((fun _ =>
  Size) (decrypt Size c)) sz0 sz0`) is now refused. `test/fronttool.c`
  has 5 new `law_guest` rows after `shadowed`: `erasedCarrier`,
  `carrierAnn`, `checkedCarrier` and `carrierRelay` (`REFUSE_LAW`), and
  `truncatedCarrier` (accepted, because the carrier is under `Trunc1`).
  For S9: a guest def cannot hide `decrypt` in a Path carrier through a
  beta redex. The S9 laws use `decrypt` only in the ends of a Path.
- O60: S9 s1, the tally (PLAN 3.1, Q-S9-1 (a), Q-S9-2 (a)). The guest
  example `examples/tally.lang` has `Votes := Prod Size Size` (counts
  for 2 choices). `Ballot` pairs an `Enc Votes` with a
  truncated proof that it encrypts `oneHot v` for some `Choice` v (O63).
  `castEnc` packages the ciphertext and this proof. `tallyEnc` uses two
  `encOp2` of `vadd` over the ciphertexts of the 3 members without
  opening them. `count` is the plain sum. The tally law
  `tallyLaw : Path Votes (decrypt Votes (tallyEnc bs)) (count (fun m =>
  decrypt Votes (witness (bs m))))` is the intent-lang 3.1 law, with `open q` as
  `decrypt` (`open q c` is `decrypt c`, the kit `openLaw`). Its proof
  `tally3` is a triple `elim` on the 3 ciphertexts, in the form of
  `lawOp2` in `examples/enc.lang`: refl fails at neutral ciphertexts
  (O55). `tally3` and `tallyLaw` use `decrypt` only in the ends of a
  Path, so they are law-only defs with a law type (rule O7, O59). There
  is no intent-lang source: intent-lang 9b99528 has only the plan rows.
- O61: the liquidity Decisions (PLAN 4.3, Q4). `Liq := Sum Votes Votes`
  is the addLiq or removeLiq amount pair (the guest `Size` surrogate of
  the kit `U256` pair of `examples/pool.lang`). `Decision := Sum Unit
  Liq`, and `inl unit` keeps the pool. `decide p v` is `inr p` when the
  first count is 2 or more (2 of 3 members), else `inl unit`. `level`
  folds `up` from the def `lzero` (the map form; the fold base has a
  known type). `closeLaw` is the cong of `decide p` on `tallyLaw`. The
  kit example `examples/tally-ideal.lang` copies the defs from `sizeAdd`
  to `decide` (each example is standalone) and the kit `Quorum` and
  `open` of `examples/enc-ideal.lang` (Q-S7-3 (a)). Then it opens the
  tally: `opened`, `counted`, `close` and `closed`. A guest def that
  opens the tally is `REFUSE_LAW` (`test/check/tally-open.lang`). The 7
  hand-written eval values agree with the run. The `tallied` row prints
  `encEta (Prod Size Size) ...`: the alias `Votes` prints as its body.
  3 hand mutants are killed: the right end of `tally3` (`PATH_END`), the
  ballot order in `tallyLaw` (`TYPE_MISMATCH`, because `vadd` is not
  commutative by conversion), and a guest `countAt` that opens the tally
  (`REFUSE_LAW`). No src change and no domain change.
- O62: the builder calls of S9 s1. There is no builder call: the main
  loop built S9 s1 by hand (USER ruling 10-05, as in O42, O47, O50 and
  O58). The first session made the map (Step 0 and Step 1) and stopped
  at the step budget with a clean tree. A second session did the build
  and the record.
- O63: the S9 s1 review found that `Ballot := Enc Votes` admitted an
  encrypted vector with several yes votes from one member. With m0
  encrypting (2, 0) and m1 and m2 each encrypting (0, 1), `close` passed
  the proposal despite two members voting no. `Ballot` now pairs its
  ciphertext with `OneHot c := Trunc1 ((v : Choice) * Path Votes
  (decrypt Votes c) (oneHot v))`. The proof is bound to the ciphertext
  and its witness stays under `Trunc1`. `castEnc` supplies the proof;
  `tallyEnc` sums only certified ballots and returns `Enc Votes`, since
  an aggregate is not a single ballot. The tally laws use `witness` to
  select each ciphertext. `tally-ballot.lang` refuses a bare encrypted
  (2, 0), and `tally-proof.lang` refuses a certificate copied from a
  different ciphertext (both `TYPE_MISMATCH`). `tally-open.lang` still
  refuses guest opening with `REFUSE_LAW`. Three new kit evals cover
  zero, one and three yes votes; the existing row covers two.
- O64: S9 s2, the remote enactment (PLAN 4.3, 7, Q8). The kit example
  `examples/enact.lang` copies the pool defs of `examples/pool.lang` and
  the Schnorr defs of `examples/elgamal.lang` (each example is
  standalone). `DecisionW := Sum Unit LiqW` is the `U256` form of the s1
  `Decision`: keep, addLiq (dx, dy) or removeLiq (dx, dy). The Decision
  word is `decisionWord d := hash (hash tag dx) dy` (keccak). The tag is
  0 for keep (dx = dy = 0), 1 for addLiq and 2 for removeLiq. The home
  side runs `enactW d r` directly. The other side runs `enactRemote n d
  sig st`, and it changes the pool only with an attest: a Schnorr
  signature of `attestMsg 0u n (decisionWord d)`, as `attestOk` of
  `examples/elgamal.lang`. Side 0 is the home side, and n is the
  proposal number. A wrong signature, a wrong word or a replay at a
  different proposal number keeps the pool. `EnactState` holds reserves
  and enacted proposal numbers, so the same proposal also cannot enact
  twice. `decisionOk` checks the positive add amounts and the `PriceEq`
  or `Share` predicates before `enactW` changes reserves. The typed form
  `Attested n d sig` is a Path to `flagYes`. `addLiqRemote` takes it with
  a freshness proof and the `PriceEq` and `PoolLaw` proofs of `addLiq`,
  and returns the updated `RemotePool k` with its enacted list. Callers
  thread the returned state. The laws `lawAttest` and
  `lawRemoteAdd` are refl. `sigAdd` and `sigRemove` are fixed test
  signatures of the key 7: s = k + 7 e mod r, with literals that are
  calculated off the chain. The 12 hand-written `enact` eval rows agree
  with the first run.
- O65: S9 s2, the signed ballot (PLAN 3.1, 4.6, Q-S9-1 (a)). The kit
  example `examples/ballot.lang` copies the ballot defs of
  `examples/tally.lang` (`sizeAdd` to `castEnc`, with no `Member`) and
  the ring defs of `examples/bridge.lang` (`Key` to `fresh`). `voters`
  is the ring of the keys `zkKey 0`, `zkKey 1` and `zkKey 2`. The ring
  signature signs the ciphertext word w at the poll word `ballotPollOf
  n := hash 0x62616c6c6f74u n` ("ballot"). This word is not the claim
  word 0x636c61696du of O39, thus a ballot signature is not a claim
  signature. `VoteSig n w s spent` is a pair of two Paths to `flagYes`:
  `zkVerify` of the signature and `fresh (sigImage s) spent`. `Box :=
  Prod U256 (Prod (List Ballot) (List Key))` holds the poll number,
  ballots and key images. `castSigned` verifies at `boxPoll box`, adds
  the ballot and key image, and preserves that poll number. Q-S9-3 (a)
  is taken: w is an input in s2, and the S10
  `cast` hashes the stored ElGamal ciphertext into w. The 10
  hand-written `ballot` eval rows agree with the first run.
- O66: the key image does not change with the poll. H_p has no tag (the
  S8 `imgBallot` row), thus the key image of a voter is the same at each
  poll (the `imgPollFree` row). Thus the spent list of a `Box` is the
  spent list of one poll. S10 keys the spent set by the poll.
- O67: the hand mutants of S9 s2, on scratch copies (`langc --kit check`
  and `eval` of one file; the repo files did not change). M1 (`sAdd` + 1
  in `sigAdd`) is KILLED: check refuses `pRemoteAdd` with `PATH_END`,
  thus all 12 `enact` rows stop. M2 (the `flagIf` arms of `enactRemote`
  in the opposite order) is KILLED: 5 rows differ. M3 (tag 1u for
  removeLiq in `decisionWord`) is KILLED: 4 rows differ. M4 (the claim
  tag in `ballotPollOf`) is KILLED: the `voteAtClaim` row differs. M5
  (the `fresh` half of `VoteSig` changed to `Path Flag flagYes flagYes`)
  keeps the shape, thus `ballot.lang` checks and no eval row differs:
  the rows check `fresh`, not `castSigned`. The new check row
  `test/check/ballot-twice.lang` (a row of `test/check/kit.txt`) kills
  M5. Its `boxTwice` adds a second ballot of key 0 (`svDup`) to `box1`,
  and langc refuses it with `PATH_END`.
- O68: the builder calls of S9 s2. There is no builder call: the main
  loop built S9 s2 by hand (USER ruling 10-05, as in O62). The first
  session made the s2 map, the second session did the build, and the
  third session did the record. The optional host tally row
  (`test/elgamaltool.c`) is not built, thus Q-S9-4 (b) is taken: the row
  moves to S10 with the one-hot proof.
- O69: review fixes (2026-10-24). The original `enactRemote` accepted
  `sigRemove` twice at proposal 2, taking `(1000, 1000)` to `(800, 800)`
  instead of stopping at `(900, 900)`. The enacted list now prevents
  this for both the word and typed APIs. The original `castSigned`
  accepted a fresh voter's poll-2 signature into `box1` of poll 1;
  the poll now comes from the Box. The original `enactW` accepted
  add `(100, 1)` or remove `(100, 1)` at `(1000, 1000)`, although these
  violate `PriceEq` and `Share`; the word predicates now keep the pool.
  A changed pool price also refuses a stale, correctly attested add
  without consuming its proposal. `ballot-poll.lang` and
  `enact-twice.lang` are `PATH_END` refusals, and `ballot-twice.lang`
  follows the updated Box API. Fifteen new eval rows cover replay,
  invalid and rounded liquidity, independent poll state, and reserve
  guards on both state projections. The s2 totals after review are
  191 check refusals and 314 evals.
- O70: S10 Step 0 (2026-10-24). The base is the USER commit 76af1b9
  on 174f975 ("Add remote enactment and ring-signed ballots"). Its
  tree b9f6b6b3 is not the staged S9 s2 tree 4b7bd053: the USER edit
  of O69 changes 10 files (+444/-56). The S9 s2 totals after O69 are
  191 check refusals and 314 evals. intent-lang HEAD is ef5abe8. The
  baseline (`make clean`, then `make check`) is GREEN, exit 0:
  examples 54, parse refusals 19, check refusals 191, pool refusals
  4, bridge refusals 6, kit-only refusals 22, evals 314, proves 2,
  precompile 128 steps. Q-S7-3 (a), Q-S9-1 (a), Q-S9-2 (a), Q-S9-3
  (a) and Q-S9-4 (b) are taken and wait for the USER ruling. Q-S9-4
  (b) moves the host tally row to S10 s1 (O72).
- O71: S10 s1, the port of the intent-lang S7 one-hot proof
  (intent-lang ef5abe8, Q-S10-1 (a), O15: the work is done once). The
  port takes the parts that are not secp256k1. The src change:
  `src/front/sigma.c` and `src/front/sigma.h` (the OR proof of each
  slot and the sum proof on bn254), and the ZK walk skip of
  `law_uses` in `src/front/check.c` (5 hunks): the walk does not go
  into the argument of `ZKProof`, thus a program def can state a ZK
  proof about `decrypt` (rule O7). The 12 `thr_hash` calls and the 3
  comment lines of sigma.c (16 names on 15 lines) and the 5 comment
  lines of sigma.h use `hash2`, and no `thr_` name stays. The domain
  change (11 lines, as intent-lang Q-S7-1 and Q-S7-2 (a)): `ZKProof W
  := Trunc1 W`, the sealed family `Transcript` and `law def verified`.
  The examples: `examples/zkproof.lang` and `examples/onehot.lang`
  (kit, a row of `examples/kit.txt`). The rows: `test/sigmatool.c`
  ("sigma regressions: passed"), `test/check/zk-leak.lang`
  (REFUSE_LAW), `test/check/transcript-state.lang` (REFUSE_STATE, also
  a row of `test/check/kit.txt`), 3 fronttool rows, 9 eval rows and
  the precompile onehot block (7 steps, 128 to 135). The 63 proof
  words of sigmatool are the literals of `onehot.lang`: there is no
  difference. The port script applied the precompile hunk with `-C1`
  before the zkcast block; it was moved by hand to after that block.
- O72: S10 s1, the host rows and the signed encrypted cast (PLAN 4.6,
  Q-S9-3 (a), Q-S9-4 (b), Q-S10-4 (a), Q-S10-7 (a)). The elgamaltool
  tally rows: slot 0 encrypts 1, 0 and 1, slot 1 encrypts 0, 1 and 0,
  and `elg_add` of each slot gives "tally slot 0" 2 and "tally slot 1"
  1. `build/sigmatool cast` prints the S10 ballot words for the key 7
  (Q-S10-4 (a)): 3 voters, the ring `blsag_key(v) G`, the key image
  of each voter (the last two words of `blsag_sign`), ctx =
  hash2(hash2(ix, iy), 1), the choices 0, 1 and 0, and a forged slot
  0 (an encryption of 2) that gives SIG_BAD_SLOT. The ported default
  vectors (blsag_key 5) stay for the 9 port rows. The guest key image
  agrees with the host: `langc --kit eval examples/ballot.lang sv0`
  prints the words in decimal, and its last two words are ix and iy
  of the host. The kit example `examples/cast.lang` (a row of
  `examples/kit.txt`) joins three parts in one Flag: the ring
  signature of `ballot.lang` over `ctWord` (the hash chain of the 8
  ciphertext coordinates, Q-S9-3 (a)), a fresh key image, and the
  one-hot proofs at `ctxOf img n := hash (hash ix iy) n` (intent-lang
  O34). The ring signs `pollWord n p := hash (ballotPollOf n) p`,
  which binds the proposal word (Q-S10-7 (a)). `castW` adds each slot
  to the tally with `elgAdd` and adds the key image to the spent list
  of the poll. `lawCast` is refl. The 12 hand-written `cast` eval rows
  agree with the first run: the three casts give 1; the duplicate key
  image, another poll, another proposal, the forged slot, a copied
  proof, other ciphertexts and `wSlot1C2` give 0; the two tally rows
  give 1 (slot 0 opens to 2 and slot 1 opens to 1).
- O73: the hand mutants of S10 s1, on scratch copies. The runner
  copies each file first, rebuilds with `make -B`, and restores each
  file with `cp` and `cmp`. All 6 are KILLED. M1 (`sig_or_verify`
  with no e0 + e1 check): the sigmatool rows "sigma OR forged split"
  and "sigma OR swapped slot index j" FAIL. M2 (no ZK walk skip in
  `law_uses`): the check of `zkproof.lang` refuses with REFUSE_LAW
  (rule O7), and the fronttool row `openedZK` FAILS; with no mutant,
  the check gives ok. M3 (`castNext` with no `cons` of the key image):
  `castDup` changes from 0 to 1. M4 (`ctxOf` with no key image): check
  refuses `lawCast` with PATH_END, thus each `cast` eval row stops;
  `lawCast` is the check row of M4. M5 (`ctWord` with 5 hashes, with
  no slot 1 C2 x and y): `wSlot1C2` changes from 0 to 1, and
  `castFirst` stays 1, because `zkSign` and `zkVerify` both move. M6
  (the second elgamaltool ballot is (1, 0)): the rows "tally slot 0"
  and "tally slot 1" FAIL. No mutant lived, thus there is no new check
  or eval row.
- O74: the builder calls of S10 s1. There is no builder call: the main
  loop built S10 s1 by hand (USER ruling 10-05, as in O62 and O68), in
  5 sessions: the baseline and the port script, the port and the host
  rows, `cast.lang` and the gate, the mutants, and the record. The
  record fixed a wrong cite: `cast.lang` and `test/sigmatool.c` gave
  `(O34)` for the bound ctx, but PLAN O34 is Q-S7-2 (a). The bound ctx
  is intent-lang O34. The review of the staged slice (2026-10-24) fixed
  two more record errors: the `law_uses` comment of `check.c` gave the
  def name `ZK` and the intent-lang cite "S7, Q-S7-1 (a)" (now
  `ZKProof`, S10 s1, O71), and O71 gave "15 calls and 1 comment" for
  the 12 calls and 3 comment lines of sigma.c.
- O75: S10 s2 (2026-10-25), the twin contract. The base is the USER
  commit 460fda6 on 76af1b9 (tree ec8644a, the staged S10 s1 tree).
  Thus there is no USER edit. The main loop built s2 by hand (USER
  ruling 10-05) in 13 sessions. The facts:
  - The probes (no repo write). P1: `init : U256 -> State` checks, but
    the build refuses it (`src/lower.c`) and the run refuses it
    (`src/front/check.c`). P2: an entry takes at most 30 words with an
    8-character name (the 255-byte ABI string, EVM_SIGNATURE). Above 32
    words (ENTRY_PARAMS_MAX) the build drops the entry with no
    diagnostic and exits 0 (Q-S10-8). P3: `cast.lang` lines 1 to 168
    with `castSlot` (20 words) and `cast` (21 words) build at ring 3:
    init 8192 bytes, runtime 8172 bytes.
  - The side value (Q-S10-5 (a)). When `init` has an argument,
    `evm_build` (`src/evm.c`) copies the 32-byte word after the
    creation code (offset CODESIZE minus 32, CODECOPY) and stores it in
    field 0. The only new opcode is EVM_OP_CODESIZE = 0x38 in
    `src/asm.h`. A correction: the P1 design said that `src/asm.h` had
    all the opcodes of the change, but it did not have CODESIZE. The 5
    `evm_build` calls of `test/buildtool.c` give NULL (the same bytes).
    `langc --kit run` takes the word on the first script line, as `init
    7u`. A correction: the word is a U256 literal; `init 7` gives
    EVAL_ARGS. `test/evmchain.sh` `deploy` appends the word. Rows:
    `examples/side.lang`, `test/run/side.script`, the refusal
    `test/lower/init-two-args.lang` (REFUSE_LOWER), and the EVM side
    rows of `test/precompile.sh` (slot 0 is 7, `sideOf` gives 7). A
    correction: `test/build.sh` reads the rows of
    `test/lower/expect.txt` (not lowertool).
  - The mutants of the side value. M-s1 removes the SSTORE of the
    argument. M-s2 reads the word at offset CODESIZE minus 0. Each gives
    exactly 2 precompile failures (`side slot 0` and `sideOf`). The run
    row does not kill them: the guest run gets the word from the script.
    KILLED.
  - The price math (Q-S10-9 (a)). The kit primitives `u256Mul` (EVM
    MUL, a trap on overflow, IR_OP_MUL_TRAP) and `u256Div` (EVM DIV, a
    trap on 0, IR_OP_DIV) are in `src/front/core.h` (at the end of the
    Op enum, thus no value moves), `src/front/check.c`,
    `src/front/eval.c` and `src/lower.c`. `src/evm.c` did not change for
    them: the two IR ops already emit. Rows: 9 rows in
    `examples/precompile.lang` and 9 rows in `examples/enact.lang` (the
    fold defs `mul` and `divFloor` give the same values), 6 EVM steps of
    `test/precompile.sh` (`mulv` and `divv`), and 2 rows of
    `docs/host/README.md`. Mutants: M-s3 (MUL_TRAP to MUL) and M-s4 (DIV
    to MOD) each give 2 precompile failures. M-s5 (`u256_mul` to
    `u256_add`) gives 5 eval failures, and M-s6 (`u256_div` to
    `u256_sub`) gives 3. The eval rows do not kill M-s3 and M-s4, and
    the EVM rows do not kill M-s5 and M-s6. KILLED.
  - Row form corrections. `langc eval` takes arguments only for an
    entry (Nat or Flag parameters and a Nat or Flag result). Thus the
    value rows are closed defs. The EVM helper gives `trap` for the MUL
    and DIV traps, not `revert`. A closed def that traps prints `trap`
    with exit 0 and an empty stderr, but the eval loop of `test/gate.sh`
    needs `langc: EVAL_OVERFLOW` on stderr. Thus the 4 trap rows
    (`uMulTrap`, `uDivTrap`, `fMulTrap`, `fDivTrap`) are entries `(k :
    Nat) -> Nat`, and `flagIf` forces the word.
  - The claim ring signature (Q-S10-10, Q-S10-11, Q-S10-12).
    `zk_verify` (`src/front/eval.c`) unrolls the bLSAG check only for a
    closed ring of G1 constants (`zk_ring`). A ring from the entry
    arguments gives the opaque OP_ZK_VERIFY, and `src/lower.c` has no
    case for it. A probe with the claim ring `voters` (a constant)
    lowers, but its runtime is over EIP-170. Without a claim ring
    signature, the runtime of the probe is 23472 bytes. An open ring
    needs H_i = H_p(P_i) on the EVM: try and increment, up to 256
    counters, each a hash, a square root (a modexp) and a curve test. No
    lowering for it exists, and an unrolled form is far over EIP-170.
    H_i from the entry arguments is not sound: a prover can give a later
    counter, and another key image then gives a second claim. Q-S10-12
    (a) moves the open ring fix to the slice of Q-S10-11 (c).
  - `examples/twin.lang` (a row of `examples/kit.txt`): `init` (the
    side), `castSlot`, `cast`, `close`, `enact`, `deposit`, `seal`,
    `accept`, `claim` and the views. `langc --kit build`: init 23481
    bytes, runtime 23437 bytes, 1139 bytes under EIP-170. The size row
    of `test/gate.sh` builds it (`sized`, the shared tail of
    `ring_built`).
  - The run scripts `test/run/twin-home.script` (`init 0u`) and
    `test/run/twin-remote.script` (`init 1u`). `test/run.sh` runs
    `examples/NAME.lang` for a script `NAME-TAG.script`. The hand
    expects were written before the first run. One hand error: in the
    second claim of the remote run, the expect swapped the `outIn`
    arguments (floor (1091 * 10 / 1120) is 9, not 10; thus rx is 1082,
    not 1081). The run was correct. A map prints its keys in ascending
    order (`(mapOf [])`).
  - The mutants of twin.lang. M-t1 (the claim with the `voters` ring
    signature) fails the size row with EVM_SIZE. M-t2 (`accept` takes
    the attest of its own side) fails home row 10 and remote row 6. M-t3
    (the `enact` side test 0 to 1) fails remote row 2. M-t4 (the seal
    bound 60 to 0) fails home row 8. M-t5 (`claim` does not mark the
    key image) fails remote row 9. M-t6 (`deposit` pulls c, not the
    price) fails home row 2. M-t7 (`test/run.sh` runs
    `examples/NAME-TAG.lang`) fails the 2 twin scripts with RUN_SCRIPT.
    KILLED. Each restore is equal (`cmp`).
  - `attestMsg` has no domain tag (Q-S10-13).
  - The final gate (resume 11) found the R19 row
    `test/check/pruned-op.lang` (a kit row): it named `u256Mul`, a kit
    primitive since Q-S10-9 (a), thus `langc --kit check` gave `ok` and
    the gate failed. Resumes 7 to 10 ran only the precompile, eval and
    run gates after the src change. The row now names `natMul`
    (Q-S10-14 (a)): `langc --kit check` gives NAME_UNKNOWN, exit 1. In
    the base mode the type `Nat` gives REFUSE_KIT first, as the type
    `U256` did before. No count changes.

- O76: S10 s2 staged review (2026-10-25). Five findings were fixed:
  - Creation code now requires exactly one appended ABI word when it
    stores an init argument. Missing, partial and extra data revert;
    the argument also counts toward EIP-3860 (`src/asm.c`).
  - A close count must be at most 3, the voter count. The curve equation
    alone accepted 0 plus the subgroup order as a count, changing the
    majority test without changing the decrypted point.
  - Opening slot 0 freezes both `castSlot` and `cast` for the poll, so
    a stored count cannot become stale while later ballots change the
    tally.
  - A batch has exactly three deposits of one credit. Mixed credits,
    a fourth deposit, and sealing a partial or empty batch are refused;
    these shapes cannot be redeemed by the fixed three-key claim.
  - Each batch starts at `batchSeed n = hash 0x6261746368u n`. Repeated
    deposits in different batches now have different roots. `claim`
    takes the source batch number before the credit and keys.
  `test/twin.sh` adds 13 DSL rows, including positive controls. The
  constructor refusals run on the EVM in `test/precompile.sh`. The
  two run scripts use the new batch root and regenerated Schnorr
  attest B (nonce 29, key 7). The final size is init code 23972 bytes
  (24004 including its argument), runtime 23879 bytes, leaving 697
  bytes under EIP-170. O75 records the measurements before these
  fixes. Q-S10-11 (c), Q-S10-12 (a), Q-S10-8 and Q-S10-13 keep their
  recorded scope and status.
- O77: S10 s3 (2026-10-25), the two-deployment differential, the gas
  rows and the contract mutants. The base is the USER commit 5e4b34b
  (tree f9e91e4, the staged S10 s2 tree). The main loop built s3 by
  hand (USER ruling 10-05).
  - The entry arity (Q-S10-8 (a)). `residualize` (`src/lower.c`)
    counts the word arguments after ENTRY_PARAMS_MAX (32) and refuses
    the entry with EVM_ARITY. Before s3 the build dropped the entry
    with no diagnostic and exited 0. The row `test/lower/arity33.lang`
    (33 word arguments) gives one lower refusal and one build check.
    The row KILLS M-a1 (the refusal only when the extra count is more
    than ENTRY_PARAMS_MAX). A U256 entry takes at most 31 words: at 32
    words the ABI text is 258 bytes, more than the limit of 255
    (EVM_SIGNATURE). The P2 text of S10 s2 (30 words) stays as
    history.
  - The attest tags (Q-S10-13 (a)). `attestMsg` takes a tag as its
    first word: `hash (hash (hash dom side) n) d`. `enact` uses
    `enactTag` (ASCII enact, 0x656e616374) and `accept` uses
    `acceptTag` (ASCII accept, 0x616363657074). The form has 4 copies:
    `examples/twin.lang`, `examples/enact.lang`,
    `examples/elgamal.lang` and `test/check/enact-twice.lang`. The
    Schnorr words sA, sR, sB and sE change (STATUS `## S10 s3`). There
    are 3 cross rows: the evals `elgamal attestCrossTag => 0` and
    `enact attestCross => 0`, and step 12 of
    `test/run/twin-remote.script` (attest A on `accept`, revert).
    `test/run.sh` KILLS M-x1 (`examples/twin.lang`, the `accept` tag:
    step 12 gives `accept ok`), and the eval row `enact attestCross`
    KILLS M-x2 (`examples/enact.lang`, the tag). The tags add 53 bytes:
    init code 24025, init code plus argument 24057, runtime 23932, 644
    bytes free under EIP-170 (VALIDATION).
  - The differential (D4, PLAN 7). Part 3 of `test/diff.sh` runs
    `examples/twin.lang` twice in one geth chain state: side 0 (home)
    at the receiver, side 1 (remote) at the address remote, and the
    mock in mode 0 at the token. The steps are
    `test/run/twin-d4-home.script` (25 steps) and
    `test/run/twin-d4-remote.script` (9 steps). Each step must give the
    result of `langc run`. The vectors: the cast words of
    `build/sigmatool cast` (key 7, Q-S10-4 (a)), the ring words of
    `zkSign` at eval time, and the DLEQ proofs of the close shares 12
    and 17 (nonces 31, 37, 41 and 43). In `test/evmchain.sh` a set
    variable `to` is the address of the call in place of the receiver;
    each old caller gives the same result. The 5 rows: 2 script rows
    (the steps and the storage of each side), the mock row (the mock
    balances equal the sums of the pull and pay rows of both runs) and
    2 guest rows (`rxOf` and `ryOf` of each side equal `homeAdd` of
    `examples/enact.lang`, `pair 1100u 1100u`). `test/run.sh` runs the
    2 scripts too (runs 8 to 10).
  - The gas rows (O17). The function `gas` of `test/evmchain.sh` runs
    the prestate of each step again with `evm run --statdump`, with no
    intrinsic gas. `test/run/twin-d4.gas` gives one bound for each of
    the 13 entries: the largest gas of the entry in the first run. Each
    entry is one row (13 rows, VALIDATION). The `claim` of s3 has no
    ring signature (Q-S10-11 (c)), thus no ring size bounds its gas
    yet; s4 takes a new bound from its first run.
  - Q-S10-16 (a). No row called `castSlot` on side 1, thus M-d3b was
    LIVE. Step 6 of `test/run/twin-d4-remote.script` is a `castSlot`
    on side 1 with the slot 0 words of voter 0 of the home script, want
    revert (gas 2567, under the bound 82143). `test/run.sh` KILLS
    M-d3b.
  - The mutants (scratch copies, `cp` + `cmp` restore, `make -B` for
    src): M-a1, M-x1, M-x2, M-d1, M-d2, M-d3b, M-g1, M-d4, M-d5, M-d6
    and M-g2 KILLED; M-d3 EQUIVALENT (STATUS `## S10 s3`).
  - Counts: evals 353 to 355, lower refusals 17 to 18, build checks 34
    to 35, runs 8 to 10, diff gate 15 to 33 rows. Under Q-S10-15 (a)
    s4 gives the bLSAG slice and s5 closes S10; the DEVIATION of s2
    stays open into s4.
- O78: S10 s4 (2026-10-25), the bLSAG slice. The base is the USER
  commit 29cd010 (the S10 s3 commit). The main loop built s4 by hand
  (USER ruling 10-05).
  - The routine path (`src/ir.h`, `src/lower.c`, `src/evm.c`). A def
    named `shared` plus an uppercase letter, with the view shape of
    `residualize` role 2, lowers once as a routine; each entry calls it
    (IR_STMT_ROUTINE, `lower_routine_call`, `evm_routine`). `cast` and
    `claim` call `sharedRing`. Deviations from DESIGN.md: the rule is
    the name only (no ORIGIN_PROGRAM check; core.h has no such name);
    phase 2 clears all def values and sets the shared def k to
    `val_var(ROUTINE_LEVEL + k)`, phase 3 RESTORES the saved values (not
    a second clear), and with no shared def the old path runs unchanged;
    `e.routine_frame` starts at 64 (the smallest entry frame end), thus
    a routine frame is never 0; the call refuses (REFUSE_LOWER) a spine
    whose args 0 and 1 are not VAR 0 and VAR 1, and a word that can trap
    or revert (`fields_may_trap`, or `block_may_trap` over the statements
    that the args push).
  - The rows: `test/lower/shared-shape.lang`, `shared-arg.lang` and
    `shared-call.lang` (new). Lower refusals 18 to 20, build checks 35 to
    40 (2 rows and 3 expect checks). In s4 the refuse text of a routine
    call kept the describer prefix of `refuse`, which names an entry
    word. S10 s5 fixes both routine call refusals and checks the exact
    text of `shared-arg.lang` and `shared-state.lang` (O79).
  - The check-clang trap. The IR change adds fields; 13 positional
    initializer sites in 6 files (`src/evm.c` and the test tools) leave
    them out. tcc (`-std=c99 -Wall -Werror`) accepts that; clang
    `-Wextra -Werror` gives -Wmissing-field-initializers. The sites now
    give all fields. Run `make check-clang` after each IR struct change.
  - The H_i source (Q-S10-17 (b)): the closed key table of (P, H_p(P))
    pairs, as `voters`. The cast through `sharedRing` takes the runtime
    from 23932 to 23900 bytes. Risk 7 PASS: the `abi` and `check` output
    do not change.
  - The claim size (Q-S10-18 (a)). langc gives no size past EIP-170
    (it refuses with EVM_SIZE and `abi` exits 1), thus a differential
    build measures it (remove `enact` and `close` from each copy; true =
    23900 + (E - 16104)); the direct build of B2c (24166) equals the
    differential value. (b1) gives EVM_SIZE. The (b2) table is in
    VALIDATION `## The size of the twin contract (S10 s4)`. Under (a):
    the ring map fields `ring0` to `ring3` (and `ringT0` to `ringT3`)
    keyed by the member index i, the claimed key (I, n), `init` moved
    before `sharedRing`, `claimTag` from B1.lang, the claim selector
    0xaf3c21e4 (11 args).
  - The vectors (a generator in s10s4/step4/, `langc --kit eval` over a
    copy of `examples/twin.lang`). The deposits use the table keys. The
    attest B words change (STATUS `## S10 s4`).
  - The claim rows of `test/run/twin-remote.script`: 8 ok (pay 9u,
    event Claimed); 9 revert (the claimed key (I, 0)); 10 revert (the
    accept check: no batch hash with d 20u); 11 revert: the key image of
    key 1 (a point on BN254) with the words of the key 0 signature is
    fresh in `claimed`, but the ring check refuses it. The key image
    depends on the key only, not on the poll or on d. A first row 11
    with the image (5u, 6u) trapped: (5, 6) is not on BN254 and `ecMul`
    traps.
  - The twin rows (`test/twin.lang`, 13 to 14 rows): `claimBatchZero`
    1, `claimBatchOne` 0, `claimBadSig` 0 (`claimKeyOne`, the key image
    of key 1). Traps: fold is a right fold, thus `claimSigWord l k` is
    the word k from the END of l (the first form read the wrong words
    and gave EVAL_OVERFLOW); the first name `wordAt` gave REFUSE_NAME R4
    (a domain field).
  - The gas (O17, from the first run): `cast` 372761 to 403491 (+30730,
    the 4 ring fields), `claim` 76543 to 189658 (the ring signature).
  - Mutants. M1 (`examples/twin.lang` claim: the `sharedRing` check to
    `u256Le d d`) KILLED: `test/run.sh` 1 failure (row 11 `claim ok`),
    `test/twin.sh` 1 failure (`claimBadSig` want 0, got 1). The gas row
    cannot kill M1 (a removed check lowers the gas). M2 (`src/evm.c`
    IR_STMT_ROUTINE arg store, arg slots 0 and 1 swapped) KILLED for
    `cast` and `claim`: `test/diff.sh` 16 failures of 33 rows.

- O79: S10 s5 (2026-10-25), the close audit. The base is the USER
  commit fe1e366; its tree is f2ea2ea717aae741b978c5e8d2b53aa2747f04e4.
  The clean baseline passed with the 41 count lines of S10 s4.
  The main loop makes the changes by hand, with no commit or push.
  - Both refusals in `lower_routine_call` name a shared routine call.
    The entry word refusal text stays the same. `test/build.sh`
    checks exit 1 and the full message of `shared-arg.lang` (a word
    that can trap) and of `shared-state.lang` (a new state in place of
    the state of the entry). Lower refusals rise from 20 to 21 and
    build checks from 40 to 45. The separate check-clang passed.
  - STATUS `S10 close` maps each exit to its slice and evidence.
    Amendment in the twin bytecode is OPEN (Q-S10-19). The twin
    `enact` supports only keep, addLiq and removeLiq. The guest
    `amend` and separate DAO table writer do not add that effect to
    this bytecode. No scope ruling that removes it was found.
  - O17 is measured for ring size 3 only: the claim bound is 189658
    execution gas on the recorded steps. Other ring sizes have no
    ABI entry or measured bound. This is not a bound for all prestates.
  - After the diagnostic fix, direct builds give runtime 24166 bytes
    (410 free under EIP-170), init code 25062 bytes, and init plus the
    side argument 25094 bytes (under EIP-3860). See VALIDATION.
  - The s2 DEVIATION stays CLOSED. The key table, four ring map
    fields and claimed key of Q-S10-17 (b) and Q-S10-18 (a) stay as
    ruled. S10 stays OPEN until amendment is implemented or the USER
    rules a scope change. S11 remains the mutant and project close
    slice. No new scope ruling is inferred from this audit.
  - Review of the s5 stage (2026-10-25): the `shared-state.lang` row,
    the S10 row text, the VALIDATION size source and the gate results
    in STATUS are fixed. The serial review gate is
    `bridge-lang-work/S10-s5-review-gate.log`.
- O80: S10 s6 (2026-10-26), amendment in the twin bytecode (Q-S10-19
  (a)). The base is the USER commit 51902c9; its tree is
  bf670eefe8412121494c40f9e9c20d9e4f055907. The serial baseline passed
  with the S10 s5 counts. The main loop makes the changes by hand, with
  no commit or push.
  - The design: two new State fields, `poll` and `charter`. Amend is the
    `enact` tag 3: dx is the menu index and dy is 0. The menu is the
    vote quota that `close` reads: index k needs k + 1 of 3 votes, k 0
    to 2 (Q-S10-20 (a)). Init stores poll 1 and charter 1; the
    constructor keeps one argument, the side (Q-S10-21 (a)). One poll is
    live: castSlot, cast, close and enact need n = poll, and each enact
    sets poll + 1 (Q-S10-23 (a)). Tag 3 also installs the charter dx. A
    remote attest is enacted only in poll order. The tally keys of poll
    + 1 are fresh, thus they are 0 when the poll opens, with no clear
    stores (Q-S10-22 (a)). The views `pollOf` and `charterOf` read the
    two fields (Q-S10-25 (a)).
  - The size probe (runtime bytes, direct build): s5 24166 (410 free), A
    24412 (the fields, the guards, the amend tag and the quota menu, no
    views), B 24472 (A plus the two views, 104 free) and C 24524 (B with
    poll id 0 and the gates n = poll + 1, 52 free). B is taken. Init
    code plus the side argument is 25410 bytes (under EIP-3860). See
    VALIDATION.
  - Poll id 1 (Q-S10-24 (a)): orbit-lang stores poll id 0, and the twin
    numbers polls from 1. This is a DEVIATION in name only. The s2 to s5
    test data stay.
  - `build/sigmatool cast` fixes poll 1. The poll 2 cast words of the
    twin scripts come from a scratch copy with poll 2u
    (`bridge-lang-work/s10s6/d4/sigmatool2`). That copy is not in the
    repo.
  - Gas (Q-S10-26 (a)): `test/run/twin-d4.gas` has new bounds from the
    first S10 s6 run: cast 403491 to 405645, castSlot 82143 to 84298,
    charterOf 2517 (new row), claim 189658 to 189661, close 145009 to
    149301, enact 52506 to 59946, pollOf 2495 (new row). The other 8
    rows do not change.
  - Mutants of the guest program, 5 of 5 KILLED by their own twin rows:
    amendMenuOut (`u256Le dx 2u` to 3u), amendPoll (`u256Add (poll s)
    1u` to `poll s`), amendCharter (install `dx` to `charter s`),
    amendOldPoll (the enact poll gate to flagYes) and quotaThreeOfThree
    (`u256Add (charter s) 2u` to 3u). Each restore cmp is true.
    Evidence: `bridge-lang-work/s10s6/mutants.json`.
  - Counts: lower refusals 21, build checks 45, twin rows 22, diff gate
    35 rows, gate 0 failures. s6 has no src change. Each exit of PLAN 7
    is DONE (STATUS `S10 close`), thus S10 is DONE. S11 is the mutant
    and project close slice.
- O81: S11 (2026-10-26), the contract mutant matrix. The base is the
  USER commit a99d3d8 (S10 s6). The serial baseline
  (`bridge-lang-work/S11-baseline.log`) exits 0 with the s6 counts.
  - Method: each guest mutant changes one guard of
    `examples/twin.lang`. A script applies it, runs `test/twin.sh`,
    `test/run.sh` and `test/diff.sh`, and restores the file by `cp`.
    Each restore `cmp` is true, and the last `cmp` against HEAD is 0.
    Evidence: `bridge-lang-work/s11/matrix.md` and
    `bridge-lang-work/s11/mutants*.json`.
  - Matrix: 29 mutants, 28 KILLED, 1 EQUIVALENT. The 19 mutants of
    O77, O78 and O80 do not change (M-d3 is EQUIVALENT: `slots` has
    one writer). S11 adds 10 mutants, all KILLED: castReplay (the used
    key image check to flagYes; `test/diff.sh` and `test/run.sh`),
    acceptReplay and claimReplay (the replay checks to flagYes; the
    `test/run.sh` output rows), depositFull (`batchSize` 2u to 3u;
    twin fourthDeposit), and closeOrder, sealBound, closeDleq12,
    castSum, castSlot0 and depositPool (new twin rows, below).
  - New twin rows, because 6 mutants were LIVE before them:
    closeOneFirst 0 and sealEarly 0 (closeOrder, sealBound),
    sealAtBound 1 (the seal bound itself), closeBadDleq12 0
    (closeDleq12: share 12 `dleqOk` to `dleqOkAny`), castBadSum 0
    (castSum: `sumPf` to `sumPfAny`), slotBadProof 0 (castSlot0: the
    slot proof check to flagYes), depositPoolBound 1 and
    depositPoolOut 0 (depositPool: `u256Le (c + 1) (ry s)` to
    flagYes). Under depositPool, depositPoolOut gives 1, thus this
    mutant is not EQUIVALENT.
  - Test helpers: `ballot` and `slotBallot` are eta wrappers of
    `ballotZ` and `slotBallotZ`, which take the proof z as a
    parameter. The depositPool rows use `poolAt y` (`makeState`, an
    empty batch, ry = y). The reachable chain from `init` (nine
    deposits of 100u and three seals) did not end in `langc eval` in
    240 s, thus the rows start from the direct state.
  - A control with the `dleqOkAny` and `sumPfAny` defs and no call
    change passes `test/twin.sh`, `test/run.sh` and `test/diff.sh`,
    thus the defs alone change nothing.
  - Not mutated: `openIs`, the close m bound and the claim index
    bounds. `openIs` and the accepted hash possibly make them
    EQUIVALENT. No row shows this.
  - Counts: twin rows 22 to 30. The other counts are the s6 counts:
    lower refusals 21, build checks 45, diff gate 35 rows, gate 0
    failures. S11 changes only `test/twin.lang` and `test/twin.txt`:
    no src change, no domain change, no size or gas change.
  - The S11 close is OPEN. The section 11 questions Q-S7-3, Q-S9-1,
    Q-S9-2, Q-S9-3 and Q-S9-4 have taken answers and no USER ruling.
    When the USER rules them, S11 is DONE and the plan is CLOSED.
- O82: S11 close (2026-10-26), the USER rulings and the plan close. The
  base is the USER commit 9eebfae (S11 mutants, tree 7c8e2e4d).
  - The USER RULED the five section 11 questions with the taken
    answers: Q-S7-3 (a), Q-S9-1 (a), Q-S9-2 (a), Q-S9-3 (a) and Q-S9-4
    (b). No ruling is different from the taken answer, thus no slice
    is added. No question in section 11 is OPEN.
  - S11 is DONE and the plan is CLOSED.
  - The close changes only `docs/PLAN.md` and `docs/STATUS.md`: no src
    change, no domain change and no test change. The serial final gate
    (`bridge-lang-work/S11-close-final-gate.log`) exits 0 with the S11
    counts: twin rows 30, lower refusals 21, build checks 45, diff gate
    35 rows, gate 0 failures.
  - Remaining limits (STATUS `S11 close`): ring size 3 only; `openIs`,
    the close m bound and the claim index bounds are not mutated.

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

### S7 s2 questions (RULED)

- Q-S7-3 (the guest `open` after the port). The sealed `Enc` makes the
  S7 s1 guest `open`, `openLaw`, `decEta` and `openAt` law-only, and
  `open`, `decEta` and `openAt` have no law type (`REFUSE_LAW`, O56).
  (a) move `Quorum`, `open`, `openLaw`, `decEta` and `openAt` (with a
  copy of `two`) to the kit example `examples/enc-ideal.lang` (the
  trusted scope, as the intent-lang `enc-ideal.lang`); the eval rows
  become `enc-ideal decEta` and `enc-ideal openAt`; no src change and
  no domain change; the port of intent-lang S6 later replaces the kit
  `Quorum` and `open` with the domain `family Quorum` and `law def
  open`. RECOMMENDED, taken (O56). (b) port the two domain lines of
  intent-lang S6 now and remove the local `Quorum` and `open` (a domain
  change before the S6 port). (c) the guest `open` returns `Trunc1 A`
  (`observe`), and `openLaw` is a Path in `Trunc1 A`. This changes the
  meaning of `open`. RULED: (a) (USER, 2026-10-26).

Q-S7-3 (a) is taken. The USER RULED Q-S7-3 (a) (2026-10-26, O82).

### S9 questions (RULED)

- Q-S9-1 (the ballot signature). The domain `Ballot_priv` is
  `castPrivate m c` over a plain Choice (`zk_source`). An encrypted
  signed ballot in the domain is a src change. (a) s1 keeps the
  encrypted ballot as a guest `Enc Votes`, and s2 pairs it with the S8
  ring signature in the kit (no src change). RECOMMENDED, taken (O60).
  (b) a domain `Ballot_enc` with an `Enc` payload in `zk_source` (a src
  change before S10). RULED: (a) (USER, 2026-10-26).
- Q-S9-2 (the S9 split). (a) s1 is the tally, the tally law and the
  liquidity Decisions; s2 is the remote enactment and the signed
  ballot. RECOMMENDED, taken (O60). (b) one slice. RULED: (a)
  (USER, 2026-10-26).

Q-S9-1 (a) and Q-S9-2 (a) are taken. The USER RULED both (a)
(2026-10-26, O82).

### S9 s2 questions (RULED)

- Q-S9-3 (the ballot word). (a) the ring signature signs a ciphertext
  word w, an input in s2; the S10 `cast` hashes the stored ElGamal
  ciphertext. RECOMMENDED, taken (O65). (b) a kit `encWord : Enc Votes
  -> U256` (a sealed eliminator into words; it is law-only).
  RULED: (a) (USER, 2026-10-26).
- Q-S9-4 (the host tally row). (a) add it in s2 (`test/elgamaltool.c`).
  (b) defer it to S10 with the one-hot proof. Taken (O68), because s2
  did not build the host row. (a) is still possible: S10 can add the
  row first. RULED: (b) (USER, 2026-10-26).

Q-S9-3 (a) and Q-S9-4 (b) are taken. The USER RULED Q-S9-3 (a) and
Q-S9-4 (b) (2026-10-26, O82). No question in this section is OPEN.

### S10 questions (RULED)

- Q-S10-1 (the port scope). (a) port the parts of intent-lang ef5abe8
  that are not secp256k1: the check.c walk skip, sigma.{c,h}, the 11
  domain.lang lines (a domain change, as intent-lang Q-S7-1 and Q-S7-2
  (a)), zkproof.lang, onehot.lang, and the check, eval, fronttool and
  precompile rows. RECOMMENDED, taken (O71). (b) kit only: onehot.lang
  and the sigma host, no domain ZKProof (the contract checks Flags
  only).
- Q-S10-2 (the contract route). (a) a hand-written kit contract
  `examples/twin.lang` built by `langc --kit build`; the writer `langc
  contract` stays the DAO table writer, unchanged. RECOMMENDED, for
  s2. (b) writer.c writes the 7 entries from the guest programs (a
  large src change).
- Q-S10-3 (the cast arity). (a) the contract splits cast: `castSlot`
  (k calls, one OR proof each at the bound ctx) then `cast` (ring
  signature, sum proof, tally add); no src change; one entry more than
  PLAN 7. RECOMMENDED, for s2. (b) raise EVM_SIGNATURE (evm.c:12,
  lower.c:169) and keep one `cast` of about 43 words (a src change; s2
  probes the stack depth).
- Q-S10-4 (the committee key). (a) key 7 (elgamal.lang and enact.lang)
  for ElGamal, the opening and the attest (O13); test/sigmatool.c gets
  a `cast` mode that prints the S10 ballot proofs for key 7 at the
  bound ctx; the ported default vectors (blsag_key 5) stay for the 9
  port rows. RECOMMENDED, taken (O72). (b) recompute the elgamal and
  enact literals for blsag_key 5.
- Q-S10-5 (the side value). (a) a src change: `init` takes the side as
  a constructor argument (lower.c:931 reads it from the initcode
  tail), evmchain.sh appends the word, and `langc --kit run` takes it
  in the script; s2 probes it first. RECOMMENDED (PLAN 7), for s2. (b)
  a one-shot `setSide` entry (kit only; a deployment race). (c) two
  `init` constants (two bytecodes, against PLAN 7).
- Q-S10-6 (the seal bound). (a) `seal` needs `now` >= the stored bound
  (Env `now`, no prelude change). RECOMMENDED, for s2. (b) a block
  number in Env (a prelude and lower change).
- Q-S10-7 (the proposal and close). (a) the poll word binds the
  proposal word p (`pollWord n p`); the first `cast` of poll n stores
  p, later casts must match; `close j m D1 P1 D2 P2` opens one choice
  slot per call (two shares with DLEQ proofs, `lag12`, the `m G`
  check) and the last slot stores the Decision word (p when yes
  reaches the level, else keep); `enact` checks `decisionWord d`
  against it (home) or the attest (remote). RECOMMENDED; s1 takes the
  poll word (O72), s2 takes the stored p and `close`. (b) a `propose`
  entry and one `close` with all slots (above the arity limit).

- Q-S10-8 (the silent entry drop, P2 of s2). (a) the build refuses an
  entry with more than ENTRY_PARAMS_MAX word arguments with a
  diagnostic (`EVM_ARITY`, a small src change in `src/lower.c`, one
  refusal row). RECOMMENDED: a dropped entry is a contract that builds
  and does not do its job. (b) keep it and record the trap in STATUS.
  RULED (a) (2026-10-25, O77). s2 records the trap; each twin.lang
  entry has 30 words at most.
- Q-S10-9 (the pool price math does not lower). (a) a builder change
  before twin.lang (as Q-S10-5 (a)): the kit primitives `u256Mul` (EVM
  MUL, a trap on overflow) and `u256Div` (EVM DIV, a trap on 0), rows
  that tie them to the fold defs of `enact.lang`, and a mutant for each
  new opcode. RECOMMENDED. (b) twin.lang without the price math on the
  EVM (deposit at 1:1). RULED (a) (O75).
- Q-S10-10 (the claim ring signature does not lower). (a) find the
  cause and fix it in s2 (a `zk_unroll` form for open ring points). (b)
  the claim without the ring signature on the EVM (the key image from
  the arguments only). RULED: a probe first, then (a). Q-S10-12 (a)
  moves (a) to a later slice (O75).
- Q-S10-11 (twin.lang with a claim ring signature is over EIP-170 at
  ring 3, also on a constant ring). (a) Q-S10-10 (b) for good; the claim
  ring signature stays in the kit eval. (b) two contracts on each side
  (vote and pool); the home `enact` takes the Schnorr attest. (c) s2
  under Q-S10-10 (b), and a later slice gives one shared unrolled bLSAG
  routine for `cast` and `claim`, then the open ring fix, then the claim
  ring signature on the EVM. RECOMMENDED. RULED (c): a temporary
  DEVIATION in s2 (O75).
- Q-S10-12 (the open ring needs H_i = H_p(P_i) on the EVM, and no
  lowering for it exists). (a) move the open ring fix of Q-S10-10 (a)
  to the slice of Q-S10-11 (c); that slice rules the H_i source, (b) or
  (c). RECOMMENDED. (b) in s2: the ring by index into a closed key
  table of (P, H_p(P)) pairs, as `voters` is for `cast`. (c) in s2: a
  zkHp lowering (try and increment over modexp, precompile 5), with a
  large size risk. RULED (a) (O75).
- Q-S10-13 (the attest has no domain tag). The attest of a Decision
  word (`enact`) and the attest of a batch hash (`accept`) have the
  same message form `hash (hash side n) word`. A cross use needs a hash
  preimage of a small tag, thus it is not open in practice. (a) a
  domain tag in `attestMsg` in s3 (the Schnorr words of the run rows
  change). RECOMMENDED. (b) keep it and record why. RULED (a)
  (2026-10-25, O77): one tag for each use (`enact` and `accept`).
- Q-S10-14 (the R19 row names a kit primitive). The S2 row
  `test/check/pruned-op.lang` (R19, a kit row) said that `u256Mul` and
  `u256Div` are not in the language. Q-S10-9 (a) made them kit
  primitives, thus the final gate failed on the row. (a) aim the row at
  a name that is still pruned (`natMul`); the rows of
  `test/check/kit.txt` and `test/check/expect.txt` stay. RECOMMENDED.
  (b) keep `u256Mul`, drop the kit row and expect REFUSE_KIT. (c) give
  the kit primitives new names. RULED (a) (2026-10-25, O75).
- Q-S10-15 (the place of the shared bLSAG slice of Q-S10-11 (c): one
  shared unrolled bLSAG routine for `cast` and `claim`, the open ring
  fix of Q-S10-10 (a) and the H_i source of Q-S10-12). (a) before the
  S10 close: s3 gives the differential, the gas rows and the mutants,
  s4 gives the bLSAG slice, s5 closes S10. The claim of PLAN 7 then
  includes the claim ring signature on the EVM, and the DEVIATION of
  s2 closes in S10. RECOMMENDED. (b) after the S10 close: s3 also
  closes S10, and the DEVIATION stays open into a new slice S11. After
  the review fixes of O76 the runtime has 697 free bytes (O75: 1139);
  s4 stops and asks if the shared routine does not fit. RULED (a)
  (2026-10-25, O77).
- Q-S10-16 (the LIVE mutant M-d3b: no gate row calls `castSlot` on
  side 1, thus the side check of `castSlot` has no test). (a) one row
  in `test/run/twin-d4-remote.script`: a `castSlot` on side 1 with the
  slot 0 words of voter 0 of `test/run/twin-d4-home.script`, want
  revert. RECOMMENDED. (b) record M-d3b LIVE as a known gap and put the
  row in s4. (c) an eval row in `test/twin.txt` on a side 1 state.
  RULED (a) (2026-10-25, O77).
- Q-S10-17 (the source of H_i = H_p(P_i) for the open ring on the EVM,
  Q-S10-12 (a)). (b) the closed key table: the contract keeps the
  (P, H_p(P)) pairs of the voters, as `voters`. (c) a zkHp lowering.
  RULED (b) (2026-10-25, O78).
- Q-S10-18 (the claim ring signature as DESIGN.md section 6, one map
  `ring` keyed by `hash i j`, is 25649 bytes, over EIP-170 by 1073).
  (a) B2c: 4 ring map fields keyed by i and the claimed key (I, n)
  (24166 bytes, 410 free). (b) no claim ring signature on the EVM. (c)
  other. RULED (a) (2026-10-25, O78).

- Q-S10-19 (RULED (a), amendment in PLAN 7). The twin `enact` accepts
  only tags 0 to 2 (keep, addLiq, removeLiq). It has no constitution
  installation or poll reset. Orbit-lang PLAN 7 requires amendment
  to install the selected constitution, increment the poll and clear
  the tally. The guest prelude and separate table writer keep
  amendment, but the twin bytecode does not. (a) keep S10 OPEN until
  this effect is implemented or an existing scope ruling is verified.
  RECOMMENDED. (b) move EVM amendment support to S11 and close S10
  with that explicit scope change. RULED (a) (2026-10-26, USER).
  S10 s6 implements the effect (O80).

- Q-S10-20 (the menu). (a) the vote quota that `close` reads: index k
  needs k + 1 of 3 votes, k 0 to 2, bound `u256Le dx 2u`. RECOMMENDED.
  (b) a 2-entry menu, bound 1. (c) other. RULED (a) (2026-10-26, O80).

- Q-S10-21 (the constructor charter index). (a) init stores charter 1
  (the rule of today); the constructor keeps one argument (the side).
  RECOMMENDED. (b) a second init argument. RULED (a) (2026-10-26, O80).

- Q-S10-22 (the tally clear). (a) fresh keys: the 8 tally words of
  poll + 1 are 0 when it opens; 0 bytes. RECOMMENDED. (b) an explicit
  clear of the 8 words (8 stores). RULED (a) (2026-10-26, O80).

- Q-S10-23 (the poll gate). (a) one live poll: castSlot, cast, close and
  enact need n = poll; each enact sets poll + 1; tag 3 also installs the
  charter. A remote attest is enacted only in poll order. RECOMMENDED.
  (b) a window n >= poll. (c) one live poll at home, a window on the
  remote side. RULED (a) (2026-10-26, O80).

- Q-S10-24 (the first poll id). (a) init poll 1; the s2 to s5 test data
  stay. Orbit-lang stores poll id 0: the twin numbers polls from 1, a
  DEVIATION in name only. RECOMMENDED. (b) poll id 0 and gates
  n = poll + 1 (52 bytes free). (c) poll id 0 and new test data.
  RULED (a) (2026-10-26, O80).

- Q-S10-25 (views). (a) `pollOf` and `charterOf` (60 bytes).
  RECOMMENDED. (b) no views. RULED (a) (2026-10-26, O80).

- Q-S10-26 (the gas bounds of `test/run/twin-d4.gas`). The S10 s6
  program has more gas than the S10 s3 bounds in cast, castSlot, claim,
  close and enact. (a) new bounds for these entries and the new rows
  charterOf and pollOf: the largest gas of the first S10 s6 run.
  RECOMMENDED. (b) keep the S10 s3 bounds and cut the gas. (c) (a) plus
  a margin. RULED (a) (2026-10-26, O80).

Q-S10-1 (a) and Q-S10-4 (a) are taken in s1. Q-S10-2 (a), Q-S10-3 (a),
Q-S10-5 (a), Q-S10-6 (a) and Q-S10-7 (a) are taken in s2 (O75). The
USER ruled Q-S10-9 (a), Q-S10-10 (a), Q-S10-11 (c), Q-S10-12 (a) and
Q-S10-14 (a) (2026-10-25), and Q-S10-8 (a), Q-S10-13 (a), Q-S10-15
(a) and Q-S10-16 (a) (2026-10-25, s3), and Q-S10-17 (b) and Q-S10-18
(a) (2026-10-25, s4), and Q-S10-19 (a) to Q-S10-26 (a) (2026-10-26,
s6, O80). Each exit of PLAN 7 is DONE (STATUS `S10 close`), thus S10
is DONE.
