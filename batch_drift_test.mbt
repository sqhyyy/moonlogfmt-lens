///|
test "structural template removes concrete values" {
  let template = structural_template(
    "level=info status=200 duration=12ms dry_run",
  )
  inspect(template.contains("info"), content="false")
  inspect(template.contains("200"), content="false")
  inspect(template.contains("level=<identifier>"), content="true")
  inspect(template.contains("status=<integer>"), content="true")
  inspect(template.contains("dry_run=<flag>"), content="true")
}

///|
test "structural shape is independent of field order" {
  let first = structural_shape(parse("level=info status=200 msg=ready"))
  let second = structural_shape(parse("msg=started level=warn status=500"))
  inspect(first == second, content="true")
  inspect(shape_fingerprint(first) == shape_fingerprint(second), content="true")
}

///|
test "structural shape marks invalid records" {
  let shape = structural_shape(parse("level=info msg=\"open"))
  inspect(shape.contains("invalid|"), content="true")
}

///|
test "batch analysis skips blank lines" {
  let report = analyze_batch([
    "level=info msg=ready", "", "   ", "level=warn msg=slow",
  ])
  inspect(report.input_lines(), content="4")
  inspect(report.processed_lines(), content="2")
  inspect(report.skipped_blank_lines(), content="2")
}

///|
test "batch analysis counts valid and invalid lines" {
  let report = analyze_batch([
    "level=info msg=ready", "level=error msg=\"unterminated",
  ])
  inspect(report.valid_lines(), content="1")
  inspect(report.invalid_lines(), content="1")
  inspect(report.invalid_percent(), content="50")
}

///|
test "batch analysis clusters equal shapes" {
  let report = analyze_batch([
    "level=info msg=ready status=200", "status=500 msg=failed level=error", "level=warn msg=slow",
  ])
  inspect(report.shape_count(), content="2")
  match report.most_common_shape() {
    Some(shape) => inspect(shape.count(), content="2")
    None => fail("a common shape should exist")
  }
}

///|
test "batch analysis computes field profiles" {
  let report = analyze_batch([
    "level=info status=200", "level=warn status=500", "level=error status=503",
  ])
  match report.profile_for("status") {
    Some(profile) => {
      inspect(profile.dominant_kind() == ValueInteger, content="true")
      inspect(profile.prevalence_percent(report.valid_lines()), content="100")
    }
    None => fail("status profile should exist")
  }
}

///|
test "batch analysis tracks risk bands" {
  let report = analyze_batch(
    ["level=info msg=ready", "level=warn msg=one msg=two", "event=boot"],
    policy=BatchPolicy::ci(),
  )
  inspect(report.clean_lines(), content="1")
  inspect(report.low_risk_lines(), content="1")
  inspect(report.high_risk_lines(), content="1")
}

///|
test "batch analysis protects shape cardinality" {
  let policy = BatchPolicy::default().with_shape_limit(1)
  let report = analyze_batch(["a=1", "b=true", "c=3ms"], policy~)
  inspect(report.shape_count(), content="1")
  inspect(report.shape_limit_exceeded(), content="true")
}

///|
test "batch gate accepts a clean ci batch" {
  let report = analyze_batch(
    ["level=info msg=ready", "level=warn msg=slow"],
    policy=BatchPolicy::ci(),
  )
  let decision = evaluate_batch(report, policy=BatchGatePolicy::ci())
  inspect(decision.accepted(), content="true")
  inspect(decision.label(), content="accept")
}

///|
test "batch gate rejects invalid rate" {
  let report = analyze_batch([
    "level=info msg=ready", "level=warn msg=\"unterminated",
  ])
  let decision = evaluate_batch(report)
  inspect(decision.accepted(), content="false")
  inspect(decision.reasons()[0].contains("invalid line rate"), content="true")
}

///|
test "batch gate enforces required prevalence" {
  let report = analyze_batch(["level=info msg=ready", "level=warn event=slow"])
  let policy = BatchGatePolicy::default().with_required_keys(["msg"])
  let decision = evaluate_batch(report, policy~)
  inspect(decision.accepted(), content="false")
  inspect(decision.text_report().contains("prevalence"), content="true")
}

///|
test "batch reports render without source values" {
  let report = analyze_batch(["level=info msg=TOP-SECRET-MESSAGE"])
  inspect(report.text_report().contains("TOP-SECRET-MESSAGE"), content="false")
  inspect(report.json_report().contains("TOP-SECRET-MESSAGE"), content="false")
}

///|
test "drift detects a newly added field" {
  let baseline = analyze_batch(["level=info msg=ready", "level=warn msg=slow"])
  let current = analyze_batch([
    "level=info msg=ready region=us", "level=warn msg=slow region=eu",
  ])
  let report = compare_batches(baseline, current)
  inspect(
    report
    .findings()
    .iter()
    .any(finding => {
      finding.kind() == DriftAddedField && finding.subject() == "region"
    }),
    content="true",
  )
}

///|
test "drift detects a removed material field" {
  let baseline = analyze_batch([
    "level=info msg=ready service=api", "level=warn msg=slow service=api",
  ])
  let current = analyze_batch(["level=info msg=ready", "level=warn msg=slow"])
  let report = compare_batches(baseline, current)
  inspect(
    report
    .findings()
    .iter()
    .any(finding => {
      finding.kind() == DriftRemovedField && finding.subject() == "service"
    }),
    content="true",
  )
  inspect(report.decision(), content="reject")
}

///|
test "drift detects semantic type changes" {
  let baseline = analyze_batch([
    "status=200 level=info", "status=500 level=error",
  ])
  let current = analyze_batch([
    "status=ok level=info", "status=failed level=error",
  ])
  let report = compare_batches(baseline, current)
  inspect(
    report
    .findings()
    .iter()
    .any(finding => {
      finding.kind() == DriftTypeChanged && finding.subject() == "status"
    }),
    content="true",
  )
}

///|
test "drift detects prevalence decrease" {
  let baseline = analyze_batch([
    "level=info trace_id=a", "level=warn trace_id=b", "level=error trace_id=c", "level=info trace_id=d",
  ])
  let current = analyze_batch([
    "level=info trace_id=a", "level=warn", "level=error", "level=info",
  ])
  let report = compare_batches(
    baseline,
    current,
    policy=DriftPolicy::default().with_prevalence_delta(20),
  )
  inspect(
    report
    .findings()
    .iter()
    .any(finding => finding.kind() == DriftPrevalenceDecrease),
    content="true",
  )
}

///|
test "drift detects maximum value length growth" {
  let baseline = analyze_batch(["level=info msg=short", "level=warn msg=tiny"])
  let current = analyze_batch([
    "level=info msg=\"this message is substantially longer than the baseline value\"",
    "level=warn msg=tiny",
  ])
  let report = compare_batches(baseline, current, policy=DriftPolicy::ci())
  inspect(
    report
    .findings()
    .iter()
    .any(finding => {
      finding.kind() == DriftValueLengthGrowth && finding.subject() == "msg"
    }),
    content="true",
  )
}

///|
test "drift detects invalid-rate regression" {
  let baseline = analyze_batch(["level=info msg=ready", "level=warn msg=slow"])
  let current = analyze_batch([
    "level=info msg=ready", "level=warn msg=\"unterminated",
  ])
  let report = compare_batches(baseline, current, policy=DriftPolicy::ci())
  inspect(
    report
    .findings()
    .iter()
    .any(finding => finding.kind() == DriftInvalidRateIncrease),
    content="true",
  )
}

///|
test "drift reports new structural shapes" {
  let baseline = analyze_batch(["level=info msg=ready"])
  let current = analyze_batch(["level=info msg=ready duration=10ms"])
  let report = compare_batches(baseline, current)
  inspect(
    report.findings().iter().any(finding => finding.kind() == DriftNewShape),
    content="true",
  )
}

///|
test "drift can report retired shapes" {
  let baseline = analyze_batch([
    "level=info msg=ready", "level=info msg=ready duration=10ms",
  ])
  let current = analyze_batch(["level=info msg=ready"])
  let report = compare_batches(baseline, current, policy=DriftPolicy::ci())
  inspect(
    report.findings().iter().any(finding => finding.kind() == DriftRetiredShape),
    content="true",
  )
}

///|
test "identical batches produce no drift" {
  let first = analyze_batch([
    "level=info msg=ready status=200", "level=warn msg=slow status=503",
  ])
  let second = analyze_batch([
    "level=info msg=started status=201", "level=warn msg=delayed status=500",
  ])
  let report = compare_batches(first, second)
  inspect(report.finding_count(), content="0")
  inspect(report.decision(), content="accept")
}

///|
test "batch baseline can freeze a reusable contract" {
  let baseline = analyze_batch([
    "level=info msg=ready status=200", "level=warn msg=slow status=503",
  ])
  let contract = contract_from_batch(
    baseline,
    name="release-baseline",
    unknown_fields=UnknownReject,
  )
  inspect(contract.name(), content="release-baseline")
  inspect(contract.required_count(), content="3")
  inspect(
    validate_contract("level=error msg=failed status=500", contract).is_conformant(),
    content="false",
  )
}

///|
test "drift reports render text and json" {
  let baseline = analyze_batch(["level=info msg=ready"])
  let current = analyze_batch(["level=info msg=ready region=us"])
  let report = compare_batches(baseline, current)
  inspect(
    report.text_report().contains("MoonLogfmt drift report"),
    content="true",
  )
  inspect(
    report.json_report().contains("\"decision\":\"review\""),
    content="true",
  )
}
