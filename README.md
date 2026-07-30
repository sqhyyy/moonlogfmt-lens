# MoonLogfmt Lens

MoonLogfmt Lens is a MoonBit-native data-contract and quality toolkit for
`logfmt` records. It parses existing log text, classifies semantic values,
checks executable contracts, removes sensitive data, profiles batches, and
explains schema drift without introducing a logging framework or telemetry
stack.

The package is designed for CI pipelines, command-line tools, support bundles,
build logs, and service diagnostics. It has no external runtime dependencies
and keeps all analysis deterministic across MoonBit targets.

## Why This Exists

Human-readable key/value logs are easy to emit but difficult to govern.
Duplicate keys can hide values, a field can silently change from an integer to
text, newly added fields can leak credentials, and one release can drift away
from the schema observed in the previous release.

MoonLogfmt Lens answers five separate questions:

- Is the record syntactically valid and unambiguous?
- Do its fields satisfy an executable log contract?
- Does it contain credentials, personal data, payment data, or network identity?
- What value-free shapes and semantic types occur in a batch?
- Did the current batch drift materially from a known-good baseline?

## Install

```bash
moon add sqhyyy/moonlogfmt-lens
```

The public repository is prepared for
[`sqhyyy/moonlogfmt-lens`](https://github.com/sqhyyy/moonlogfmt-lens), and the
Mooncakes owner is `sqhyyy`.

## Parse And Audit

```moonbit
let parsed = @lens.parse(
  "level=info msg=\"service ready\" request_id=req-42",
)

if parsed.is_valid() {
  println(parsed.get("msg"))
  println(parsed.normalized())
}

let audit = @lens.audit_line_with_policy(
  "level=warn msg=one msg=two dry_run",
  @lens.AuditPolicy::ci(),
)
println(audit.text_report())
```

The scanner supports bare values, quoted values, common escapes, explicit blank
values, and flag fields. It preserves field order and offsets and reports
malformed keys, unexpected equals signs, bare quotes, and unterminated strings.

## Semantic Values

```moonbit
inspect(@lens.classify_value("503"), content="ValueInteger")
inspect(@lens.classify_value("1.5s"), content="ValueDuration")
inspect(@lens.classify_value("2026-07-29T12:30:00Z"), content="ValueTimestamp")
```

The deterministic classifier recognizes flags, blanks, booleans, integers,
decimals, durations, byte sizes, timestamps, IPv4 values, UUIDs, email
addresses, hexadecimal values, identifiers, and free text. These types form the
shared vocabulary used by contract inference and drift analysis.

## Executable Contracts

```moonbit
let contract = @lens.LogContract::new(
  "api-service",
  [
    @lens.FieldRule::typed("level", @lens.ValueIdentifier, required=true)
    .with_allowed_values(["info", "warn", "error"]),
    @lens.FieldRule::text("msg", required=true).with_max_length(240),
    @lens.FieldRule::typed("status", @lens.ValueInteger),
    @lens.FieldRule::typed("duration", @lens.ValueDuration),
  ],
  unknown_fields=@lens.UnknownReject,
)

let report = @lens.validate_contract(
  "level=info msg=ready status=200 duration=12ms",
  contract,
)
println(report.decision())
```

Contracts support required fields, semantic types, blank/flag controls, maximum
lengths, controlled vocabularies, record field limits, duplicate rejection, and
allow/warn/reject policies for unknown fields. Built-in service and CI contracts
are available for quick adoption.

## Schema Inference

```moonbit
let inference = @lens.infer_schema([
  "level=info status=200 duration=12ms",
  "level=warn status=503 duration=1.5s",
  "level=info status=201 duration=9ms",
])

println(inference.text_report())
let candidate = inference.contract()
```

Inference reports field prevalence, type distribution, dominant type,
confidence, distinct sample values, and observed maximum length. It produces a
candidate contract while limiting enum inference to genuinely categorical
fields such as `level`, `environment`, `state`, and `outcome`.

## Privacy-Safe Logs

```moonbit
let result = @lens.redact_line(
  "level=info email=user@example.com api_token=secret peer=10.0.0.8",
  policy=@lens.RedactionPolicy::strict(),
)

println(result.safe_line())
println(result.json_report())
```

Privacy analysis combines key-aware rules with value-aware detection for bearer
credentials, provider access keys, three-segment tokens, private-key markers,
email addresses, formatted phone numbers, checksum-valid payment cards,
high-entropy secrets, and optional IP-address protection.

Redaction modes include full masking, last-four masking, and deterministic
stable tokens. Reports never serialize the original sensitive value.

## Batch Profiles

```moonbit
let batch = @lens.analyze_batch(
  [
    "level=info msg=ready status=200",
    "level=warn msg=slow status=503",
  ],
  policy=@lens.BatchPolicy::ci(),
)

let decision = @lens.evaluate_batch(
  batch,
  policy=@lens.BatchGatePolicy::ci(),
)
println(decision.label())
```

Batch analysis provides valid/invalid rates, risk bands, aggregate scores, field
profiles, and value-free structural clusters. Canonical shapes are independent
of field order, and stable fingerprints allow logs to be compared without
retaining their concrete values.

Batch gates support invalid-line budgets, high-risk budgets, average risk
limits, shape-cardinality limits, and required-key prevalence.

## Drift Detection

```moonbit
let baseline = @lens.analyze_batch([
  "level=info msg=ready status=200 duration=12ms",
  "level=warn msg=slow status=503 duration=80ms",
])

let current = @lens.analyze_batch([
  "level=info msg=ready status=ok region=us",
  "level=warn msg=slow status=failed region=eu",
])

let drift = @lens.compare_batches(
  baseline,
  current,
  policy=@lens.DriftPolicy::ci(),
)
println(drift.text_report())
```

Drift findings cover added and removed fields, semantic type changes, type
confidence drops, prevalence changes, value-length growth, new and retired
shapes, invalid-rate regressions, and aggregate-risk regressions. A known-good
batch can also be frozen into a reusable `LogContract`.

## CLI

```powershell
moon run cmd/main -- audit level=info msg="service ready"
moon run cmd/main -- contract level=info msg=ready service=api
moon run cmd/main -- privacy level=info api_token=secret
moon run cmd/main -- profile status=503 duration=12ms
moon run cmd/main -- template level=info msg=ready status=200
```

Omitting the mode keeps compatibility with the original audit command.

## Runnable Examples

```powershell
moon run examples/basic
moon run examples/advanced
moon run examples/privacy
moon run examples/drift
```

The advanced example infers and freezes a baseline contract. The privacy
example demonstrates stable-token redaction. The drift example intentionally
introduces a field-type regression, a removed field, a new field, a new shape,
and malformed input.

## Verification

```powershell
moon fmt
moon check
moon build
moon test
moon package --list
```

The current suite contains 95 tests covering parsing, auditing, semantic
classification, contracts, inference, redaction, batch gates, structural
fingerprints, and drift reports.

## Boundaries

MoonLogfmt Lens consumes in-memory logfmt records. It does not emit application
logs, tail files, collect telemetry, export OpenTelemetry data, parse JSON, or
replace logging frameworks. File readers, network collectors, and dashboards
can build on top of the dependency-free core.

## Contributing

Development and verification instructions are available in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache-2.0.
