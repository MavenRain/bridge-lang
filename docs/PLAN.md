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

Builder calls (NOT ruled; section 10 gives each one, section 11 gives the
questions):

- O1: the name bridge-lang.
- O2: the kit is hosts/tcc-evm-contract (U256, Addr, Env, `pay`, `pull`,
  events). The cubical kernel, the BN254 host and the bLSAG ring signatures
  come from orbit-lang at 2162fb2 (section 6).
- Tests are guest-language files plus `langc run` scripts. The kit gate
  scripts stay. We add no new harness.

## 2. The reading of R1

R1 has the same text as in intent-lang. This plan proposes the reading that
intent-lang ruled on 2026-10-22 (intent-lang Q1 (a), Q2 (a)). Here it is not
ruled yet (Q1).

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
| Pos | defined | `(n : U256) * Le 1 n`, the surrogate of `R+` (section 4.2) |
| Pool k | defined | `(x : Pos) * (y : Pos) * Le k (x * y)` (section 4.2) |
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
| S1 | USER rulings on the questions of section 11; record them in this plan | PLANNED |
| S2 | Kernel port from orbit-lang 2162fb2 (section 6); the gate counts of orbit-lang | PLANNED |
| S3 | R1 narrowing: `REFUSE_CELL`, the free monoid, the former matrix as CM and CC rows (port from intent-lang S3 when it exists) | PLANNED |
| S4 | `Trace` as the free category CM in a slice; the category laws; the meaning functor; `Stream` of batches (CC) | PLANNED |
| S5 | Part P: `Pos`, `Pool k`, `swapIn`, `swapOut`, the least-solution law, `addLiq`, `removeLiq`, the overflow bound | PLANNED |
| S6 | Part B: credit, `InFlight`, `deposit`, `seal`, `accept`, `claim` on the guest side; conservation; `ua e` transport | PLANNED |
| S7 | `Enc`, `decrypt`, `open`, Schnorr attestation verify; host and precompile rows (port from intent-lang S5 and S6 when they exist) | PLANNED |
| S8 | `ZKBridge` as the mapping cylinder; `ZKBridge ≃ BridgeState`; bLSAG claim rings and key images | PLANNED |
| S9 | Part D: encrypted ballots, `tallyEnc`, the tally law, liquidity Decisions, the remote enactment | PLANNED |
| S10 | The contract of section 7: writer, two-deployment differential, gas and size rows | PLANNED |
| S11 | Mutants and close | PLANNED |

## 10. Open items

- O1: the name bridge-lang. Builder call.
- O2: the kit and the kernel route (section 6). Builder call.
- O3: the reading of R1 (section 2), as intent-lang ruled it. Q1.
- O4: `ZKBridge` has no type parameter, so R1 does not limit it (2.2).
  Builder call.
- O5: a swap, a liquidity change and a bridge transfer are morphisms of the
  free category `Trace`, not paths, because `Pool k` is a set (4.1). Q2.
- O6: `Pool k` holds `k ≤ x * y` over `U256`; swap outputs are the least
  solutions (4.2). Q3.
- O7: reserves stay below `2^128`; a larger value reverts. The S5 slice
  checks the kit `U256` overflow behavior. Builder call.
- O8: liquidity keeps the price, not the product; the DAO is the only
  liquidity provider (4.3). Q4.
- O9: the bridge model: virtual credit reserves, batches, attestation,
  claims (4.4). Q5.
- O10: privacy is the unlinkability of a deposit and its claim; amounts are
  public (4.5). Q7.
- O11: pool arithmetic is public; FHE is only in the DAO tally (4.5). Q7.
- O12: `fheHom` is a law of `decrypt`, not a constructor (3.4). Builder
  call.
- O13: one BN254 key for ElGamal and Schnorr (4.6). Q6.
- O14: the attested message names the side and the batch number. A second
  bridge with the same committee needs the chain id or the contract address
  in the message; the kit `Env` has neither. Builder call; S10 decides.
- O15: reuse of the intent-lang slices (section 6). Q9.
- O16: `Stream` of batches is the one CC instance of the plan. Builder
  call.
- O17: the ring size of a claim bounds its gas. S10 measures it. Builder
  call.
- O18: the dash check of `test/gate.sh` skips `design/DESIGN.md`, because
  the design is verbatim and holds two em-dashes (tile-lang ruling
  2026-10-09). Builder call.

## 11. Questions for the USER (S1)

- Q1 (O3): reading of R1. (a) as intent-lang ruled: ambient Pi, Sigma,
  Path, U unlimited; declared constructors only CM and CC; the syntactic
  cell criterion. RECOMMENDED. (b) another reading.
- Q2 (O5): the design's paths in `Pool k`. (a) morphisms of the free
  category `Trace` (a CM). RECOMMENDED. (b) a non-discrete carrier (real
  numbers as a HIT); it is still a set, so this does not help. (c) maps out
  of the interval into a topological carrier; not computable on the EVM.
- Q3 (O6): the invariant. (a) `k ≤ x * y` with least-solution outputs.
  RECOMMENDED. (b) exact rationals off the chain, integer settlement on the
  chain.
- Q4 (O8): liquidity. (a) keeps the price; the DAO is the only liquidity
  provider. RECOMMENDED. (b) liquidity shares for any user (one more token
  type).
- Q5 (O9): the bridge model. (a) virtual credit reserves, batches,
  attestation and claims (4.4). RECOMMENDED. (b) a two-asset pool on each
  side and a price oracle.
- Q6 (O13): the attestation. (a) one Schnorr signature on BN254 under the
  DAO threshold key (FROST off the chain). RECOMMENDED. (b) `t` of `n`
  `ecrecover` signatures of the members.
- Q7 (O10, O11): privacy. (a) unlinkability by denominations, one-time
  keys and bLSAG ring claims; amounts public; FHE in the DAO tally.
  RECOMMENDED. (b) no bridge privacy; ZK, FHE and MPC only in the DAO.
  (c) shielded notes with a SNARK verifier (`ecPairing`, 0x08); not minimal.
- Q8: the DAO home. (a) the DAO runs on side A; side B enacts an attested
  Decision. RECOMMENDED. (b) one DAO on each side.
- Q9 (O15): (a) port the intent-lang slices when they exist. RECOMMENDED.
  (b) build them again here.
- Q10: fee and minimum output. (a) none, because the design gives none.
  RECOMMENDED. (b) a minimum output on `claim`; it needs a refund path.
