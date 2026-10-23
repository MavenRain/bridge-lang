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
