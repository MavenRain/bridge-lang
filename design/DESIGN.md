# bridge-lang domain design

> Paste the domain design below the line, verbatim. Do not edit it.

This file is the only source of the core types and the core operations of
bridge-lang. `SPEC.md` sections 5 and 6 cite its sections. Do not add a core
type or a core operation that this file does not give.

When the design changes, paste the new version. Then record the change as an
open item in `SPEC.md` section 9.

---

## The request (verbatim, 2026-10-22)

Let's write a new programming language with the following features:

As far as type constructors/higher-kinded types, admit only cell monads and their duals in a locally presentable locally cartesian closed $(\infty,1)$-category, as realized computationally in Cubical Type Theory.

As for the underlying types and operations, admit the minimal required to write a smart contract representing a ZK FHE MPC DAO (https://github.com/MavenRain/orbit-lang) governing a liquidity-based bridge leveraging AMM-style pools with the following denotational design:

## The pasted design (verbatim)

**Denotational design (Conal Elliott) of a ZK FHE MPC liquidity-based AMM bridge, in Cubical TT notation.**

Denotational design specifies a simple, precise mathematical meaning \(\mu\) for each type and operation so that the system *is* its meaning: an implementation is correct exactly when it agrees with \(\mu\). Meanings are compositional (the meaning of a composite depends only on the meanings of its parts). The type-class-morphism (TCM) principle—“the instance’s meaning is the meaning’s instance”—guarantees that algebraic laws transfer for free and that there are no abstraction leaks. Cubical type theory supplies the ambient language: the interval \(\mathbb{I}\) with endpoints \(i_0,i_1\), paths \(\mathrm{Path}\,A\,a\,b\) (or dependent \(\mathrm{PathP}\)), higher inductive types, computational univalence, and propositional truncation \(\lVert-\rVert\). Higher paths naturally encode the equational laws of cryptography (following the “Homotopical Approach to Cryptography” of Vivekanandan, in which HITs serve as front-ends whose path constructors become the domain-specific laws, transported by univalence to concrete implementations).

We work throughout with a suitable type \(\mathbb{R}^+\) of positive reals (or a constructive surrogate such as positive rationals closed under the needed operations). All constructions are homotopy-invariant by the nature of Cubical TT.

### Pool and AMM invariant

A constant-product pool of invariant \(k\) denotes the type of balanced reserve pairs:

\[
\mathrm{Pool}\,k \;\;\coloneqq\;\; \Sigma\,(x\,y:\mathbb{R}^+)\,(x\cdot y\equiv k).
\]

(The same pattern works for any other invariant, e.g. a weighted geometric mean; the constant-product case is the canonical illustration.) The meaning \(\mu(\mathrm{Pool}\,k)\) is simply this type (or its underlying space of points). Because equality is a path, the constraint is already a path in \(\mathbb{R}^+\).

A swap of size \(\mathrm{d}x>0\) is a path in the pool type. Write \(\mathrm{new}(x,y,\mathrm{d}x)\) for the unique positive solution of the invariant equation that yields the output amount \(\mathrm{d}y\). Then

\[
\mathrm{swap}\;:\;\mathrm{Pool}\,k\to\mathbb{R}^+\to\mathrm{Path}\,(\mathrm{Pool}\,k)\,p\,p'
\]

where \(p'\) is the pair of updated reserves and the path is constructed by transport (or \(\mathsf{hcomp}\)) along the equality that the product remains \(k\). By construction every point of the path satisfies the invariant, so

\[
\mu(\mathrm{swap}\,p\,\mathrm{d}x)\;=\;\text{a continuous trajectory inside the level set \(x\cdot y=k\)}.
\]

Adding or removing liquidity is likewise a path that scales both reserves by the same factor (preserving the product). Sequential operations compose by path composition \(_\bullet_\).

### Liquidity-based bridge

A liquidity-based bridge between two chains does not lock-and-mint; it maintains an AMM pool on each side and moves value by coordinated deposits/withdrawals (or swaps) that keep the two invariants consistent with a common notion of value. Denote the joint state by the product

\[
\mathrm{BridgeState}\,k_A\,k_B \;\;\coloneqq\;\; \mathrm{Pool}\,k_A\times\mathrm{Pool}\,k_B.
\]

A bridge transaction is a path in this product type (or, more precisely, a dependent path once asset types on the two chains are related by an equivalence). Concretely, a user who wishes to move an amount of asset \(A\) supplies liquidity (or swaps) into the source pool and simultaneously withdraws an equivalent amount from the destination pool; the two updates form a single path

\[
\mathrm{bridge}\;:\;\mathrm{Assets}_A\to\mathrm{Path}\,(\mathrm{BridgeState}\,k_A\,k_B)\,\mathit{init}\,\mathit{final}
\]

that preserves both invariants and the total “value” measured by the product (or by a price oracle expressed as a further path). Univalence identifies the equivalence of asset representations on the two chains with a path in the universe, so transport along that path realises the cross-chain correspondence without an operational “relayer” appearing in the denotation.

### Zero-knowledge, FHE and MPC as higher paths

Privacy and cryptographic correctness are expressed by higher-dimensional structure, following the HIT style of the homotopical cryptography literature.

Define a higher inductive type that packages public state together with the private computation that produces it:

```cubical
data ZKBridge (kA kB : ℝ⁺) : Type where
  public : BridgeState kA kB → ZKBridge kA kB
  privateComp : PrivateInputs → ZKBridge kA kB
  zkProof : (priv : PrivateInputs)
          → Path (ZKBridge kA kB)
                  (privateComp priv)
                  (public (result priv))
  -- higher path witnessing FHE homomorphism
  fheHom : (op : Op) (c1 c2 : Cipher)
         → PathP (λ i → Cipher)
                 (Enc (op (Dec c1) (Dec c2)))
                 (opHom (fheHom i) c1 c2)   -- schematic
  -- multi-party cube (MPC)
  mpcCube : (shares : Fin n → Share)
          → (I → I → ZKBridge kA kB)     -- square / cube of joint computation
          → Path (ZKBridge kA kB) (reconstruct shares) (public result)
```

- The path constructor \(\mathsf{zkProof}\) equates the private execution with the publicly observable final reserves and statement. Propositional truncation \(\lVert\mathrm{ZKBridge}\rVert\) yields a proposition that asserts mere existence of a correct private computation; the concrete path (and therefore the private inputs) is hidden.
- The higher path \(\mathsf{fheHom}\) is a homotopy witnessing that encryption is a homomorphism: \(\mathrm{Enc}(f(a,b))\equiv f_{\mathrm{Enc}}(\mathrm{Enc}\,a,\mathrm{Enc}\,b)\). All pool arithmetic is performed under this homotopy, so the denotation of an encrypted swap is the image of the clear-text path under \(\mathrm{Enc}\).
- The MPC constructor supplies a higher-dimensional path (a square or cube) whose faces are the individual parties’ share computations and whose diagonal reconstructs the joint result. Privacy follows because the public denotation sees only the reconstructed 0-dimensional face (or its truncation).

### Compositional system and TCM

The meaning of a complete bridge transaction is the path in public bridge state obtained by composing the AMM paths, the bridge path, and the 0-truncation of the ZK/FHE/MPC higher structure:

\[
\mu(\mathrm{tx})\;=\;\mathrm{bridgePath}\bullet\mathrm{swapPaths}\bullet\bigl\lVert\mathrm{zkProof}\bigr\rVert.
\]

Because path composition is associative and unital, and because every constructor stays inside the invariant level sets, the TCM principle holds automatically:

- \(\mu(\mathrm{id})=\mathrm{id}\),
- \(\mu(g\circ f)=\mu(g)\circ\mu(f)\),
- invariants are preserved (every path endpoint satisfies \(x\cdot y=k\)),
- the public denotation is independent of private data up to equivalence (parametricity / truncation).

Consequently the algebraic laws of monoids, categories and the AMM invariant hold for the implementation exactly when they hold for the simple mathematical model—the hallmark of denotational design.

The construction is parametric in the concrete invariant, the encryption scheme and the number of MPC parties; each may be substituted by a different HIT or equivalence without disturbing the surrounding path algebra. This yields a compact, compositional, and machine-checkable specification of a privacy-preserving liquidity bridge.

## The request, continued (verbatim)

The host language shall be TinyCC, and the compilation target shall be an EVM-compatible-chain-deployable bytecode of the contract.
