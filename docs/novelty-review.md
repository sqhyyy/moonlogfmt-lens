# Novelty Review

Last reviewed: 2026-07-29

## Project

- Name: MoonLogfmt Lens
- Folder: `D:\Moonbit\projects\project-person-sqh`
- Package: `sqhyyy/moonlogfmt-lens`
- Public repository: `https://github.com/sqhyyy/moonlogfmt-lens`

## Local Collision Check

Existing local projects were reviewed before implementation:

- `moonansi-guard`: terminal control sequence sanitizer and audit library.
- `mooncidr-audit`: IPv4/CIDR rule parser and configuration audit library.
- `project-person-3`: SPDX license expression and source-header validator.
- `archive/moon-eventbus`: archived event bus idea.

MoonLogfmt Lens does not reuse those identities, subjects, package names,
repository names, implementation files, examples, or application materials.

## Rejected Candidate

The first candidate was a cron-expression lens. It was rejected after GitHub
repository search found `cxh04/Cron-Mbt`, a public MoonBit cron parser
repository. The final project therefore avoids cron, scheduling, and time-wheel
topics.

## Ecosystem Search

Searches were performed across Mooncakes, GitHub repository search, and public
code search. The review was repeated before the version `0.2.0` expansion using
these terms:

- `MoonBit logfmt`
- `MoonBit log format parser`
- `MoonBit structured log parser`
- `MoonBit key value log parser`
- `MoonBit log schema drift redaction`
- `MoonBit structured log audit`
- `language:MoonBit log parser`
- `site:moonbitlang.github.io/OSC2026 log MoonBit logging parser`
- `site:github.com "OSC 2026" MoonBit logging`
- `site:mooncakes.io logfmt MoonBit`
- `site:github.com "moon.mod" "logfmt"`

Relevant adjacent results:

- Mooncakes has
  [`Yoorkin/logr_moonbit`](https://mooncakes.io/docs/Yoorkin/logr_moonbit), a
  MoonBit implementation of go-logr. It provides logging APIs and formatting
  helpers, not a standalone logfmt consumer, contract engine, or drift tool.
- Mooncakes has
  [`moonbit-community/opentelemetry`](https://mooncakes.io/docs/moonbit-community/opentelemetry),
  which is observability infrastructure rather than logfmt validation.
- Mooncakes contains general parser packages such as HTML, SQL parser, and
  lexer packages; these do not target logfmt.
- GitHub repository search found
  [`Suquster/moonbit-infra-suite`](https://github.com/Suquster/moonbit-infra-suite).
  Its README describes a collection of infrastructure practice skeletons,
  including a general logging direction. It does not present a logfmt-specific
  parser, inferred contract, privacy scanner, structural fingerprint, or
  baseline drift workflow.
- GitHub repository search found
  [`ushironoko/claude-logs-moon`](https://github.com/ushironoko/claude-logs-moon).
  Its public README only identifies the repository and does not claim the
  logfmt contract and drift scope implemented here.
- GitHub repository search found
  [`zhzh12345678/MoonTraceKit`](https://github.com/zhzh12345678/MoonTraceKit),
  but the repository was empty when reviewed.
- Outside MoonBit, OpenTelemetry Collector has a
  [redaction processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/redactionprocessor/README.md).
  That validates the practical need for redaction but operates on telemetry
  records inside the Collector. MoonLogfmt Lens is a dependency-free MoonBit
  library for raw logfmt text and combines privacy review with inference and
  drift analysis.

No searched result showed a MoonBit package whose main purpose is parsing and
auditing logfmt records with all of the following:

- semantic value classification;
- executable typed log contracts;
- schema inference from observed records;
- key-aware and value-aware privacy-safe redaction;
- value-free structural templates and fingerprints;
- batch quality gates;
- explainable baseline-to-current schema drift.

Search cannot mathematically prove that no private or unindexed implementation
exists. It does establish that the project does not collide with the public
MoonBit packages, repositories, and submitted-project signals discoverable by
the queries above on the review date.

## Differentiation

MoonLogfmt Lens is not a logging API. It is a consumer-side data-governance
layer for text that already exists. That makes it complementary to logging
frameworks:

- Logging package: emits structured logs.
- Telemetry package: transports and exports records.
- MoonLogfmt Lens: reads raw logfmt text, infers a contract, removes sensitive
  values, fingerprints value-free structures, and explains changes before logs
  are accepted by CI or downstream tools.

## Innovation Boundary

The project deliberately avoids competing with broad observability systems.
Its distinct contribution is the closed loop:

1. Parse existing logfmt records.
2. Learn field prevalence and semantic value types.
3. Freeze the observations into an executable contract.
4. Produce privacy-safe structural fingerprints.
5. Compare a new release against the baseline and explain material drift.

The same value taxonomy is shared by inference, contract validation, redaction,
batch clustering, and drift analysis. This integration is more than a bundle of
unrelated utilities: each stage produces evidence consumed by the next stage.

## Value

The project is useful because logfmt is common in service logs, build output,
and command-line diagnostics. Beyond syntax failures, production risks include
silent type changes, unstable field sets, credential leakage, exploding shape
cardinality, and release-to-release schema drift. A MoonBit-first library gives
future tools a reusable way to detect these risks before logs leave CI.

## Non-Goals

- No log collection daemon.
- No telemetry exporter.
- No JSON parser.
- No general logging framework.
- No file system scanning.
- No network transport.
- No runtime logger API.
- No OpenTelemetry exporter or collector processor.
- No cryptographic claim for structural fingerprints or stable redaction
  tokens.
