# Architecture

## Purpose

MoonLogfmt Lens is organized as a pipeline whose stages share one semantic
model but remain independently usable.

```text
logfmt text
    |
    v
parser -----> syntax audit
    |
    v
semantic value classifier
    |
    +-----> executable contract validation
    |
    +-----> schema inference -----> frozen baseline contract
    |
    +-----> privacy scan ---------> safe logfmt projection
    |
    +-----> batch profile --------> structural fingerprints
                                      |
                                      v
                              baseline drift report
```

## Modules

### `logfmt_lens.mbt`

The original scanner and record-quality audit layer. It owns `Field`,
`ParseResult`, syntax errors, audit policies, findings, and text/JSON reports.

### `value_profile.mbt`

The common semantic vocabulary. Classification is ordered and deterministic so
the same value has the same type during contract inference, validation, batch
clustering, and drift comparison.

### `contract.mbt`

Executable field rules and schema inference. Contracts distinguish missing,
blank, and flag values and can enforce types, lengths, controlled vocabularies,
field limits, duplicate rejection, and unknown-field policy.

Inference records prevalence, type confidence, maximum observed length, and a
bounded set of distinct values. Enum inference is deliberately limited to known
categorical field names to avoid overfitting ordinary messages.

### `privacy.mbt`

Key-aware and value-aware sensitive-data detection. The safe output path never
serializes original sensitive values in text or JSON reports. Stable tokens are
deterministic identifiers for correlation, not cryptographic hashes.

### `batch.mbt`

In-memory analysis of multiple records. Concrete values are omitted from line
reviews and reports. Shapes are canonicalized by key and semantic type, sorted
independently of source field order, and assigned stable fingerprints.

### `drift.mbt`

Compares known-good and current `BatchReport` values. It explains field,
semantic type, prevalence, length, shape, syntax-rate, and aggregate-risk
changes. It can also freeze a batch profile into a reusable contract.

## Design Decisions

- No external runtime dependency keeps the package portable.
- Arrays and deterministic loops keep behavior consistent across backends.
- Reports expose evidence and decisions instead of a single boolean.
- Privacy reports contain keys and reasons but never sensitive values.
- Structural fingerprints operate on value-free shapes.
- Inference produces a candidate contract; callers retain control over whether
  to accept it.
- Batch APIs consume arrays of strings and avoid file or process permissions.

## Complexity

The scanner is linear in record length. Contract validation is linear in fields
times declared rules, which is appropriate for compact log records. Batch
profiling is linear in records with bounded distinct-shape storage. Shape
sorting uses insertion sort because record field counts are intentionally small
and this avoids a dependency.

## Trust Boundaries

The package is a validation aid, not a security boundary. Stable redaction
tokens are not cryptographic. The privacy scanner uses explainable heuristics
and allow lists; high-assurance deployments should combine it with upstream
secret management and downstream access controls.
