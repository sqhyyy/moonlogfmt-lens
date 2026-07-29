# Changelog

## 0.2.0

- Added deterministic semantic value classification for booleans, numbers,
  durations, byte sizes, timestamps, IPv4 values, UUIDs, email addresses,
  hexadecimal values, identifiers, text, blanks, and flags.
- Added executable `LogContract` schemas with typed fields, required fields,
  controlled vocabularies, length limits, unknown-field policies, and detailed
  contract reports.
- Added schema inference with prevalence, type confidence, value distribution,
  bounded vocabulary discovery, and candidate contract generation.
- Added key-aware and value-aware privacy scanning with full masking,
  last-four masking, stable tokens, allow lists, and safe reports.
- Added value-free structural templates, canonical shape fingerprints, batch
  profiles, risk summaries, error budgets, and CI gate decisions.
- Added baseline-to-current drift reports for field additions/removals, semantic
  type changes, prevalence changes, length growth, new/retired shapes, invalid
  rates, and aggregate risk.
- Expanded the CLI to audit, contract, privacy, profile, and template modes.
- Added privacy and drift examples.
- Expanded the suite to 95 passing tests.

## 0.1.0

- Initial MoonBit implementation of logfmt parsing, field inspection, audit
  findings, examples, tests, and submission materials.
