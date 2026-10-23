# bridge-lang

bridge-lang is a Cubical TT language for two parts of one system: a
zero-knowledge, homomorphically encrypted, multi-party DAO (the DAO of
MavenRain/orbit-lang), and the liquidity bridge with AMM pools that the DAO
governs. The bridge follows the denotational design in `design/DESIGN.md`.
The only type constructors are cell monads and their duals. The host is
TinyCC. The compiler writes EVM bytecode that deploys to any EVM chain. The
same contract deploys on each side of the bridge.

bridge-lang comes from lang-template with the tcc-evm-contract host.

- `design/DESIGN.md`: the request and the domain design, verbatim. It is the
  only source of the core types and the core operations.
- `docs/PLAN.md`: the rulings, the reading of the type-former ruling, the
  readings of the design, the minimal base signature, the chain fragment,
  the kernel route, the contract, the slices, the open items and the
  questions.
- `SPEC.md`: the specification. Fill each section.
- `formers/FORMERS.md`: the type formers. `formers/tcc-evm-contract.md` gives their
  status on the tcc-evm-contract host.
- `probe/CAPABILITY.md`: the host probe.
- `docs/STATUS.md` and `docs/VALIDATION.md`: the status and the gate results.
- `docs/host/README.md`: how to build and test the host kit, and how to
  replace the sample domain in `domain/`.
