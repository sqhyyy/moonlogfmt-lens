# Validation Evidence

## Current Scope

- Hand-written MoonBit source: 5,558 lines across 16 `.mbt` files after
  `moon fmt` (4,410 library lines, 976 test lines, and 172 CLI/example lines).
- MoonBit source modules: parser/audit, value profiling, contracts/inference,
  privacy, batch analysis, and drift comparison.
- CLI modes: audit, contract, privacy, profile, and template.
- Runnable examples: basic, advanced contract inference, privacy redaction, and
  release drift.
- Test suite: 95 cases.

## Verified Commands

The release checklist uses:

```powershell
moon fmt
moon check
moon build
moon test
moon package --list
moon info
```

Current local results:

- `moon fmt`: passed.
- Default `wasm-gc` `moon check`: passed with zero warnings.
- Default `moon build`: passed.
- Default `moon test`: 95 passed, 0 failed.
- `moon package --list`: passed and produced the `0.2.0` package without build
  caches.
- `moon info`: passed.
- JS and native checks reached the compiler but were blocked by missing
  toolchain core bundles under `D:\Moonbit\lib\core\_build`; the compiler
  reported zero project warnings and zero project errors before its internal
  missing-file failure. Those external toolchain files were not modified.

Runnable examples:

```powershell
moon run examples/basic
moon run examples/advanced
moon run examples/privacy
moon run examples/drift
```

## Behavioral Evidence

The tests cover:

- bare, quoted, escaped, blank, flag, malformed, and duplicate fields;
- all semantic value families and mixed distributions;
- required fields, controlled vocabularies, type compatibility, lengths,
  unknown keys, field limits, and inferred contracts;
- credential, personal, payment, and network-data findings;
- allow lists, key-only scanning, three redaction modes, and report leakage
  checks;
- order-independent shapes, stable fingerprints, cardinality limits, risk
  bands, invalid-rate budgets, and required-key prevalence;
- added/removed fields, type changes, prevalence changes, length growth,
  new/retired shapes, invalid-rate regressions, and no-change baselines.

## Known Limits

- The classifier is semantic and heuristic rather than a substitute for full
  RFC parsers.
- Privacy detection can produce false positives or false negatives; allow lists
  and policy modes make those decisions explicit.
- Stable tokens and shape fingerprints are non-cryptographic.
- Analysis is currently in-memory and does not read files or tail processes.
