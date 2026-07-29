///|
/// Explainable changes detected between two logfmt batches.
pub(all) enum DriftKind {
  DriftAddedField
  DriftRemovedField
  DriftTypeChanged
  DriftTypeConfidenceDrop
  DriftPrevalenceIncrease
  DriftPrevalenceDecrease
  DriftValueLengthGrowth
  DriftNewShape
  DriftRetiredShape
  DriftInvalidRateIncrease
  DriftRiskIncrease
} derive(Eq, Debug)

///|
pub fn DriftKind::label(self : DriftKind) -> String {
  match self {
    DriftAddedField => "added_field"
    DriftRemovedField => "removed_field"
    DriftTypeChanged => "type_changed"
    DriftTypeConfidenceDrop => "type_confidence_drop"
    DriftPrevalenceIncrease => "prevalence_increase"
    DriftPrevalenceDecrease => "prevalence_decrease"
    DriftValueLengthGrowth => "value_length_growth"
    DriftNewShape => "new_shape"
    DriftRetiredShape => "retired_shape"
    DriftInvalidRateIncrease => "invalid_rate_increase"
    DriftRiskIncrease => "risk_increase"
  }
}

///|
pub struct DriftPolicy {
  prevalence_delta : Int
  confidence_drop : Int
  max_length_growth : Int
  invalid_rate_delta : Int
  average_risk_delta : Int
  min_field_prevalence : Int
  report_retired_shapes : Bool
} derive(Eq, Debug)

///|
pub fn DriftPolicy::default() -> DriftPolicy {
  {
    prevalence_delta: 20,
    confidence_drop: 20,
    max_length_growth: 32,
    invalid_rate_delta: 5,
    average_risk_delta: 3,
    min_field_prevalence: 10,
    report_retired_shapes: false,
  }
}

///|
pub fn DriftPolicy::ci() -> DriftPolicy {
  {
    prevalence_delta: 10,
    confidence_drop: 10,
    max_length_growth: 16,
    invalid_rate_delta: 0,
    average_risk_delta: 1,
    min_field_prevalence: 5,
    report_retired_shapes: true,
  }
}

///|
pub fn DriftPolicy::exploratory() -> DriftPolicy {
  {
    prevalence_delta: 30,
    confidence_drop: 30,
    max_length_growth: 64,
    invalid_rate_delta: 10,
    average_risk_delta: 5,
    min_field_prevalence: 25,
    report_retired_shapes: false,
  }
}

///|
pub fn DriftPolicy::with_prevalence_delta(
  self : DriftPolicy,
  prevalence_delta : Int,
) -> DriftPolicy {
  { ..self, prevalence_delta, }
}

///|
pub fn DriftPolicy::with_invalid_budget(
  self : DriftPolicy,
  invalid_rate_delta : Int,
) -> DriftPolicy {
  { ..self, invalid_rate_delta, }
}

///|
pub fn DriftPolicy::with_retired_shapes(
  self : DriftPolicy,
  report_retired_shapes : Bool,
) -> DriftPolicy {
  { ..self, report_retired_shapes, }
}

///|
pub struct DriftFinding {
  kind : DriftKind
  severity : Severity
  subject : String
  baseline : String
  current : String
  message : String
} derive(Eq, Debug)

///|
pub fn DriftFinding::kind(self : DriftFinding) -> DriftKind {
  self.kind
}

///|
pub fn DriftFinding::severity(self : DriftFinding) -> Severity {
  self.severity
}

///|
pub fn DriftFinding::subject(self : DriftFinding) -> String {
  self.subject
}

///|
pub fn DriftFinding::baseline(self : DriftFinding) -> String {
  self.baseline
}

///|
pub fn DriftFinding::current(self : DriftFinding) -> String {
  self.current
}

///|
pub fn DriftFinding::message(self : DriftFinding) -> String {
  self.message
}

///|
pub struct DriftReport {
  baseline_lines : Int
  current_lines : Int
  findings : Array[DriftFinding]
} derive(Eq, Debug)

///|
pub fn DriftReport::baseline_lines(self : DriftReport) -> Int {
  self.baseline_lines
}

///|
pub fn DriftReport::current_lines(self : DriftReport) -> Int {
  self.current_lines
}

///|
pub fn DriftReport::findings(self : DriftReport) -> Array[DriftFinding] {
  self.findings
}

///|
pub fn DriftReport::finding_count(self : DriftReport) -> Int {
  self.findings.length()
}

///|
pub fn DriftReport::critical_count(self : DriftReport) -> Int {
  let mut count = 0
  for finding in self.findings {
    if finding.severity() == Critical {
      count = count + 1
    }
  }
  count
}

///|
pub fn DriftReport::warning_count(self : DriftReport) -> Int {
  let mut count = 0
  for finding in self.findings {
    if finding.severity() == Warning {
      count = count + 1
    }
  }
  count
}

///|
pub fn DriftReport::risk_score(self : DriftReport) -> Int {
  let mut score = 0
  for finding in self.findings {
    score = score + finding.severity().score()
  }
  score
}

///|
pub fn DriftReport::decision(self : DriftReport) -> String {
  if self.critical_count() > 0 {
    "reject"
  } else if self.warning_count() > 0 {
    "review"
  } else {
    "accept"
  }
}

///|
pub fn DriftReport::text_report(self : DriftReport) -> String {
  let mut output = "MoonLogfmt drift report\n"
  output = output + "baseline_lines: " + self.baseline_lines.to_string() + "\n"
  output = output + "current_lines: " + self.current_lines.to_string() + "\n"
  output = output + "findings: " + self.finding_count().to_string() + "\n"
  output = output + "risk_score: " + self.risk_score().to_string() + "\n"
  output = output + "decision: " + self.decision() + "\n"
  if self.findings.length() == 0 {
    return output + "\nNo material drift detected."
  }
  output = output + "\nChanges:\n"
  for finding in self.findings {
    output = output +
      "- [" +
      finding.severity().label() +
      "] " +
      finding.kind().label() +
      " subject=" +
      finding.subject()
    if finding.baseline() != "" {
      output = output + " baseline=" + finding.baseline()
    }
    if finding.current() != "" {
      output = output + " current=" + finding.current()
    }
    output = output + ": " + finding.message() + "\n"
  }
  output
}

///|
pub fn DriftReport::json_report(self : DriftReport) -> String {
  let mut output = "{"
  output = output +
    "\"baseline_lines\":" +
    self.baseline_lines.to_string() +
    ","
  output = output + "\"current_lines\":" + self.current_lines.to_string() + ","
  output = output + "\"findings\":" + self.finding_count().to_string() + ","
  output = output + "\"risk_score\":" + self.risk_score().to_string() + ","
  output = output + "\"decision\":\"" + self.decision() + "\","
  output = output + "\"items\":["
  for index = 0; index < self.findings.length(); index = index + 1 {
    let finding = self.findings[index]
    if index > 0 {
      output = output + ","
    }
    output = output + "{"
    output = output + "\"kind\":\"" + finding.kind().label() + "\","
    output = output + "\"severity\":\"" + finding.severity().label() + "\","
    output = output + "\"subject\":\"" + escape_json(finding.subject()) + "\","
    output = output +
      "\"baseline\":\"" +
      escape_json(finding.baseline()) +
      "\","
    output = output + "\"current\":\"" + escape_json(finding.current()) + "\","
    output = output + "\"message\":\"" + escape_json(finding.message()) + "\""
    output = output + "}"
  }
  output + "]}"
}

///|
pub fn compare_batches(
  baseline : BatchReport,
  current : BatchReport,
  policy? : DriftPolicy = DriftPolicy::default(),
) -> DriftReport {
  let findings : Array[DriftFinding] = []
  drift_compare_profiles(baseline, current, policy, findings)
  drift_compare_shapes(baseline, current, policy, findings)
  let invalid_delta = current.invalid_percent() - baseline.invalid_percent()
  if invalid_delta > policy.invalid_rate_delta {
    findings.push({
      kind: DriftInvalidRateIncrease,
      severity: Critical,
      subject: "batch",
      baseline: baseline.invalid_percent().to_string() + "%",
      current: current.invalid_percent().to_string() + "%",
      message: "invalid logfmt rate increased beyond the configured budget",
    })
  }
  let risk_delta = current.average_risk_score() - baseline.average_risk_score()
  if risk_delta > policy.average_risk_delta {
    findings.push({
      kind: DriftRiskIncrease,
      severity: Warning,
      subject: "batch",
      baseline: baseline.average_risk_score().to_string(),
      current: current.average_risk_score().to_string(),
      message: "average audit risk increased beyond the configured budget",
    })
  }
  {
    baseline_lines: baseline.processed_lines(),
    current_lines: current.processed_lines(),
    findings,
  }
}

///|
/// Freezes a reusable contract from a previously analyzed baseline.
pub fn contract_from_batch(
  report : BatchReport,
  name? : String = "batch-baseline",
  required_percent? : Int = 95,
  unknown_fields? : UnknownFieldPolicy = UnknownWarn,
) -> LogContract {
  let rules : Array[FieldRule] = []
  for profile in report.profiles() {
    let required = profile.prevalence_percent(report.valid_lines()) >=
      required_percent
    let mut kind = profile.dominant_kind()
    if profile.type_confidence() < 80 {
      kind = ValueText
    }
    let mut rule = FieldRule::typed(profile.key(), kind, required~).with_max_length(
      profile.max_length(),
    )
    if profile.distribution().count(ValueEmpty) > 0 {
      rule = rule.with_blank(true)
    }
    if profile.distribution().count(ValueFlag) > 0 {
      rule = rule.with_flag(true)
    }
    if profile.distinct_values().length() > 0 &&
      profile.distinct_values().length() <= 8 &&
      contract_can_infer_enum(profile.key(), kind) {
      rule = rule.with_allowed_values(profile.distinct_values())
    }
    rules.push(rule)
  }
  let max_fields = if rules.length() < 8 { 8 } else { rules.length() + 4 }
  LogContract::new(name, rules, unknown_fields~, max_fields~)
}

///|
fn drift_compare_profiles(
  baseline : BatchReport,
  current : BatchReport,
  policy : DriftPolicy,
  findings : Array[DriftFinding],
) -> Unit {
  for current_profile in current.profiles() {
    match baseline.profile_for(current_profile.key()) {
      None => {
        let prevalence = current_profile.prevalence_percent(
          current.valid_lines(),
        )
        if prevalence >= policy.min_field_prevalence {
          findings.push({
            kind: DriftAddedField,
            severity: Warning,
            subject: current_profile.key(),
            baseline: "absent",
            current: prevalence.to_string() + "%",
            message: "field appeared with material prevalence",
          })
        }
      }
      Some(baseline_profile) => {
        let baseline_prevalence = baseline_profile.prevalence_percent(
          baseline.valid_lines(),
        )
        let current_prevalence = current_profile.prevalence_percent(
          current.valid_lines(),
        )
        let prevalence_delta = current_prevalence - baseline_prevalence
        if prevalence_delta >= policy.prevalence_delta {
          findings.push({
            kind: DriftPrevalenceIncrease,
            severity: Info,
            subject: current_profile.key(),
            baseline: baseline_prevalence.to_string() + "%",
            current: current_prevalence.to_string() + "%",
            message: "field became materially more common",
          })
        } else if prevalence_delta <= -policy.prevalence_delta {
          findings.push({
            kind: DriftPrevalenceDecrease,
            severity: Warning,
            subject: current_profile.key(),
            baseline: baseline_prevalence.to_string() + "%",
            current: current_prevalence.to_string() + "%",
            message: "field became materially less common",
          })
        }
        if baseline_profile.dominant_kind() != current_profile.dominant_kind() &&
          baseline_profile.type_confidence() >= 70 &&
          current_profile.type_confidence() >= 70 {
          findings.push({
            kind: DriftTypeChanged,
            severity: Critical,
            subject: current_profile.key(),
            baseline: baseline_profile.dominant_kind().label(),
            current: current_profile.dominant_kind().label(),
            message: "dominant semantic value type changed",
          })
        }
        let confidence_delta = baseline_profile.type_confidence() -
          current_profile.type_confidence()
        if confidence_delta >= policy.confidence_drop {
          findings.push({
            kind: DriftTypeConfidenceDrop,
            severity: Warning,
            subject: current_profile.key(),
            baseline: baseline_profile.type_confidence().to_string() + "%",
            current: current_profile.type_confidence().to_string() + "%",
            message: "field values became less type-consistent",
          })
        }
        let length_delta = current_profile.max_length() -
          baseline_profile.max_length()
        if length_delta > policy.max_length_growth {
          findings.push({
            kind: DriftValueLengthGrowth,
            severity: Warning,
            subject: current_profile.key(),
            baseline: baseline_profile.max_length().to_string(),
            current: current_profile.max_length().to_string(),
            message: "maximum observed value length grew materially",
          })
        }
      }
    }
  }
  for baseline_profile in baseline.profiles() {
    match current.profile_for(baseline_profile.key()) {
      Some(_) => ()
      None => {
        let prevalence = baseline_profile.prevalence_percent(
          baseline.valid_lines(),
        )
        if prevalence >= policy.min_field_prevalence {
          findings.push({
            kind: DriftRemovedField,
            severity: Critical,
            subject: baseline_profile.key(),
            baseline: prevalence.to_string() + "%",
            current: "absent",
            message: "previously material field disappeared",
          })
        }
      }
    }
  }
}

///|
fn drift_compare_shapes(
  baseline : BatchReport,
  current : BatchReport,
  policy : DriftPolicy,
  findings : Array[DriftFinding],
) -> Unit {
  for shape in current.shapes() {
    match baseline.shape_for_fingerprint(shape.fingerprint()) {
      Some(existing) =>
        if existing.shape() != shape.shape() {
          findings.push({
            kind: DriftNewShape,
            severity: Critical,
            subject: shape.fingerprint(),
            baseline: existing.shape(),
            current: shape.shape(),
            message: "shape fingerprint collision detected",
          })
        }
      None =>
        findings.push({
          kind: DriftNewShape,
          severity: Warning,
          subject: shape.fingerprint(),
          baseline: "absent",
          current: shape.shape(),
          message: "new value-free record shape appeared",
        })
    }
  }
  if policy.report_retired_shapes {
    for shape in baseline.shapes() {
      match current.shape_for_fingerprint(shape.fingerprint()) {
        Some(_) => ()
        None =>
          findings.push({
            kind: DriftRetiredShape,
            severity: Info,
            subject: shape.fingerprint(),
            baseline: shape.shape(),
            current: "absent",
            message: "baseline record shape was not observed",
          })
      }
    }
  }
}
