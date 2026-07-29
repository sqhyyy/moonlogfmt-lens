///|
/// Policy used when a contract encounters a key it does not declare.
pub(all) enum UnknownFieldPolicy {
  UnknownAllow
  UnknownWarn
  UnknownReject
} derive(Eq, Debug)

///|
pub fn UnknownFieldPolicy::label(self : UnknownFieldPolicy) -> String {
  match self {
    UnknownAllow => "allow"
    UnknownWarn => "warn"
    UnknownReject => "reject"
  }
}

///|
/// One executable field rule in a log contract.
pub struct FieldRule {
  key : String
  expected_kind : ValueKind
  required : Bool
  allow_blank : Bool
  allow_flag : Bool
  max_length : Int
  allowed_values : Array[String]
} derive(Eq, Debug)

///|
pub fn FieldRule::typed(
  key : String,
  expected_kind : ValueKind,
  required? : Bool = false,
) -> FieldRule {
  {
    key,
    expected_kind,
    required,
    allow_blank: false,
    allow_flag: false,
    max_length: 0,
    allowed_values: [],
  }
}

///|
pub fn FieldRule::text(key : String, required? : Bool = false) -> FieldRule {
  FieldRule::typed(key, ValueText, required~)
}

///|
pub fn FieldRule::key(self : FieldRule) -> String {
  self.key
}

///|
pub fn FieldRule::expected_kind(self : FieldRule) -> ValueKind {
  self.expected_kind
}

///|
pub fn FieldRule::required(self : FieldRule) -> Bool {
  self.required
}

///|
pub fn FieldRule::allows_blank(self : FieldRule) -> Bool {
  self.allow_blank
}

///|
pub fn FieldRule::allows_flag(self : FieldRule) -> Bool {
  self.allow_flag
}

///|
pub fn FieldRule::max_length(self : FieldRule) -> Int {
  self.max_length
}

///|
pub fn FieldRule::allowed_values(self : FieldRule) -> Array[String] {
  self.allowed_values
}

///|
pub fn FieldRule::with_required(self : FieldRule, required : Bool) -> FieldRule {
  { ..self, required, }
}

///|
pub fn FieldRule::with_blank(self : FieldRule, allow_blank : Bool) -> FieldRule {
  { ..self, allow_blank, }
}

///|
pub fn FieldRule::with_flag(self : FieldRule, allow_flag : Bool) -> FieldRule {
  { ..self, allow_flag, }
}

///|
pub fn FieldRule::with_max_length(
  self : FieldRule,
  max_length : Int,
) -> FieldRule {
  { ..self, max_length, }
}

///|
pub fn FieldRule::with_allowed_values(
  self : FieldRule,
  allowed_values : Array[String],
) -> FieldRule {
  { ..self, allowed_values, }
}

///|
pub fn FieldRule::describe(self : FieldRule) -> String {
  let mut output = self.key + ":" + self.expected_kind.label()
  if self.required {
    output = output + " required"
  } else {
    output = output + " optional"
  }
  if self.allow_blank {
    output = output + " blank"
  }
  if self.allow_flag {
    output = output + " flag"
  }
  if self.max_length > 0 {
    output = output + " max=" + self.max_length.to_string()
  }
  if self.allowed_values.length() > 0 {
    output = output + " values=[" + self.allowed_values.join(",") + "]"
  }
  output
}

///|
/// A named, executable schema for logfmt records.
pub struct LogContract {
  name : String
  rules : Array[FieldRule]
  unknown_fields : UnknownFieldPolicy
  max_fields : Int
} derive(Debug)

///|
pub fn LogContract::new(
  name : String,
  rules : Array[FieldRule],
  unknown_fields? : UnknownFieldPolicy = UnknownWarn,
  max_fields? : Int = 32,
) -> LogContract {
  { name, rules, unknown_fields, max_fields }
}

///|
/// A practical contract for ordinary service logs.
pub fn LogContract::service() -> LogContract {
  LogContract::new(
    "service-log",
    [
      FieldRule::typed("level", ValueIdentifier, required=true).with_allowed_values([
          "trace", "debug", "info", "warn", "error", "fatal",
        ],
      ),
      FieldRule::text("msg", required=true).with_max_length(240),
      FieldRule::typed("service", ValueIdentifier, required=true).with_max_length(
        64,
      ),
      FieldRule::typed("request_id", ValueIdentifier).with_max_length(96),
      FieldRule::typed("duration", ValueDuration),
      FieldRule::typed("status", ValueInteger),
      FieldRule::typed("timestamp", ValueTimestamp),
    ],
    unknown_fields=UnknownWarn,
    max_fields=24,
  )
}

///|
/// A compact contract suited to build and CI logs.
pub fn LogContract::ci_event() -> LogContract {
  LogContract::new(
    "ci-event",
    [
      FieldRule::typed("level", ValueIdentifier, required=true).with_allowed_values([
          "debug", "info", "warn", "error",
        ],
      ),
      FieldRule::text("msg", required=true).with_max_length(200),
      FieldRule::typed("job", ValueIdentifier).with_max_length(80),
      FieldRule::typed("step", ValueIdentifier).with_max_length(80),
      FieldRule::typed("duration", ValueDuration),
      FieldRule::typed("success", ValueBoolean),
    ],
    unknown_fields=UnknownWarn,
    max_fields=18,
  )
}

///|
pub fn LogContract::name(self : LogContract) -> String {
  self.name
}

///|
pub fn LogContract::rules(self : LogContract) -> Array[FieldRule] {
  self.rules
}

///|
pub fn LogContract::unknown_field_policy(
  self : LogContract,
) -> UnknownFieldPolicy {
  self.unknown_fields
}

///|
pub fn LogContract::max_fields(self : LogContract) -> Int {
  self.max_fields
}

///|
pub fn LogContract::has_rule(self : LogContract, key : String) -> Bool {
  contract_rule_index(self, key) >= 0
}

///|
pub fn LogContract::rule_count(self : LogContract) -> Int {
  self.rules.length()
}

///|
pub fn LogContract::required_count(self : LogContract) -> Int {
  let mut count = 0
  for rule in self.rules {
    if rule.required() {
      count = count + 1
    }
  }
  count
}

///|
pub fn LogContract::describe(self : LogContract) -> String {
  let mut output = "contract " + self.name + "\n"
  output = output +
    "unknown_fields=" +
    self.unknown_fields.label() +
    " max_fields=" +
    self.max_fields.to_string() +
    "\n"
  for rule in self.rules {
    output = output + "- " + rule.describe() + "\n"
  }
  output
}

///|
pub(all) enum ContractViolationKind {
  ContractSyntaxError
  ContractMissingField
  ContractUnexpectedField
  ContractWrongType
  ContractBlankDisallowed
  ContractFlagDisallowed
  ContractValueTooLong
  ContractValueNotAllowed
  ContractDuplicateField
  ContractFieldLimit
} derive(Eq, Debug)

///|
pub fn ContractViolationKind::label(self : ContractViolationKind) -> String {
  match self {
    ContractSyntaxError => "syntax_error"
    ContractMissingField => "missing_field"
    ContractUnexpectedField => "unexpected_field"
    ContractWrongType => "wrong_type"
    ContractBlankDisallowed => "blank_disallowed"
    ContractFlagDisallowed => "flag_disallowed"
    ContractValueTooLong => "value_too_long"
    ContractValueNotAllowed => "value_not_allowed"
    ContractDuplicateField => "duplicate_field"
    ContractFieldLimit => "field_limit"
  }
}

///|
pub struct ContractViolation {
  kind : ContractViolationKind
  severity : Severity
  key : String
  expected : String
  actual : String
  message : String
  offset : Int
} derive(Eq, Debug)

///|
pub fn ContractViolation::kind(
  self : ContractViolation,
) -> ContractViolationKind {
  self.kind
}

///|
pub fn ContractViolation::severity(self : ContractViolation) -> Severity {
  self.severity
}

///|
pub fn ContractViolation::key(self : ContractViolation) -> String {
  self.key
}

///|
pub fn ContractViolation::expected(self : ContractViolation) -> String {
  self.expected
}

///|
pub fn ContractViolation::actual(self : ContractViolation) -> String {
  self.actual
}

///|
pub fn ContractViolation::message(self : ContractViolation) -> String {
  self.message
}

///|
pub fn ContractViolation::offset(self : ContractViolation) -> Int {
  self.offset
}

///|
pub struct ContractReport {
  contract_name : String
  parsed : ParseResult
  violations : Array[ContractViolation]
} derive(Debug)

///|
pub fn ContractReport::contract_name(self : ContractReport) -> String {
  self.contract_name
}

///|
pub fn ContractReport::parsed(self : ContractReport) -> ParseResult {
  self.parsed
}

///|
pub fn ContractReport::violations(
  self : ContractReport,
) -> Array[ContractViolation] {
  self.violations
}

///|
pub fn ContractReport::violation_count(self : ContractReport) -> Int {
  self.violations.length()
}

///|
pub fn ContractReport::critical_count(self : ContractReport) -> Int {
  let mut count = 0
  for violation in self.violations {
    if violation.severity() == Critical {
      count = count + 1
    }
  }
  count
}

///|
pub fn ContractReport::warning_count(self : ContractReport) -> Int {
  let mut count = 0
  for violation in self.violations {
    if violation.severity() == Warning {
      count = count + 1
    }
  }
  count
}

///|
pub fn ContractReport::is_conformant(self : ContractReport) -> Bool {
  self.violations.length() == 0
}

///|
pub fn ContractReport::decision(self : ContractReport) -> String {
  if self.critical_count() > 0 {
    "reject"
  } else if self.warning_count() > 0 {
    "review"
  } else {
    "accept"
  }
}

///|
pub fn ContractReport::text_report(self : ContractReport) -> String {
  let mut output = "MoonLogfmt contract report\n"
  output = output + "contract: " + self.contract_name + "\n"
  output = output + "fields: " + self.parsed.field_count().to_string() + "\n"
  output = output + "violations: " + self.violation_count().to_string() + "\n"
  output = output + "decision: " + self.decision() + "\n"
  if self.violations.length() == 0 {
    return output + "\nNo contract violations."
  }
  output = output + "\nViolations:\n"
  for violation in self.violations {
    output = output +
      "- [" +
      violation.severity().label() +
      "] " +
      violation.kind().label()
    if violation.key() != "" {
      output = output + " key=" + violation.key()
    }
    if violation.expected() != "" {
      output = output + " expected=" + violation.expected()
    }
    if violation.actual() != "" {
      output = output + " actual=" + violation.actual()
    }
    output = output + ": " + violation.message() + "\n"
  }
  output
}

///|
pub fn ContractReport::json_report(self : ContractReport) -> String {
  let mut output = "{"
  let conformant = if self.is_conformant() { "true" } else { "false" }
  output = output + "\"contract\":\"" + escape_json(self.contract_name) + "\","
  output = output + "\"conformant\":" + conformant
  output = output + ",\"decision\":\"" + self.decision() + "\","
  output = output + "\"violations\":" + self.violation_count().to_string() + ","
  output = output + "\"items\":["
  for index = 0; index < self.violations.length(); index = index + 1 {
    let violation = self.violations[index]
    if index > 0 {
      output = output + ","
    }
    output = output + "{"
    output = output + "\"kind\":\"" + violation.kind().label() + "\","
    output = output + "\"severity\":\"" + violation.severity().label() + "\","
    output = output + "\"key\":\"" + escape_json(violation.key()) + "\","
    output = output +
      "\"expected\":\"" +
      escape_json(violation.expected()) +
      "\","
    output = output + "\"actual\":\"" + escape_json(violation.actual()) + "\","
    output = output +
      "\"message\":\"" +
      escape_json(violation.message()) +
      "\","
    output = output + "\"offset\":" + violation.offset().to_string()
    output = output + "}"
  }
  output + "]}"
}

///|
pub fn validate_contract(
  line : String,
  contract : LogContract,
) -> ContractReport {
  validate_parsed_contract(parse(line), contract)
}

///|
pub fn validate_parsed_contract(
  parsed : ParseResult,
  contract : LogContract,
) -> ContractReport {
  let violations : Array[ContractViolation] = []
  for error in parsed.errors() {
    violations.push({
      kind: ContractSyntaxError,
      severity: Critical,
      key: "",
      expected: "valid_logfmt",
      actual: error.kind().label(),
      message: error.message(),
      offset: error.offset(),
    })
  }
  if contract.max_fields() > 0 && parsed.field_count() > contract.max_fields() {
    violations.push({
      kind: ContractFieldLimit,
      severity: Critical,
      key: "",
      expected: contract.max_fields().to_string(),
      actual: parsed.field_count().to_string(),
      message: "record exceeds the contract field limit",
      offset: 0,
    })
  }
  for rule in contract.rules() {
    if rule.required() && !parsed.has_key(rule.key()) {
      violations.push({
        kind: ContractMissingField,
        severity: Critical,
        key: rule.key(),
        expected: rule.expected_kind().label(),
        actual: "missing",
        message: "required contract field is missing",
        offset: 0,
      })
    }
  }
  for index = 0; index < parsed.fields().length(); index = index + 1 {
    let field = parsed.fields()[index]
    for previous = 0; previous < index; previous = previous + 1 {
      if parsed.fields()[previous].key() == field.key() {
        violations.push({
          kind: ContractDuplicateField,
          severity: Critical,
          key: field.key(),
          expected: "single_value",
          actual: "duplicate",
          message: "contract validation rejects ambiguous duplicate values",
          offset: field.offset(),
        })
      }
    }
    let rule_index = contract_rule_index(contract, field.key())
    if rule_index < 0 {
      match contract.unknown_field_policy() {
        UnknownAllow => ()
        UnknownWarn =>
          violations.push({
            kind: ContractUnexpectedField,
            severity: Warning,
            key: field.key(),
            expected: "declared_field",
            actual: "unknown",
            message: "field is not declared by the contract",
            offset: field.offset(),
          })
        UnknownReject =>
          violations.push({
            kind: ContractUnexpectedField,
            severity: Critical,
            key: field.key(),
            expected: "declared_field",
            actual: "unknown",
            message: "strict contract rejects undeclared fields",
            offset: field.offset(),
          })
      }
      continue
    }
    let rule = contract.rules()[rule_index]
    let actual_kind = classify_field(field)
    if field.is_flag() {
      if !rule.allows_flag() {
        violations.push({
          kind: ContractFlagDisallowed,
          severity: Critical,
          key: field.key(),
          expected: rule.expected_kind().label(),
          actual: ValueFlag.label(),
          message: "implicit flag is not allowed for this field",
          offset: field.offset(),
        })
      }
    } else if field.value() == "" {
      if !rule.allows_blank() {
        violations.push({
          kind: ContractBlankDisallowed,
          severity: Critical,
          key: field.key(),
          expected: rule.expected_kind().label(),
          actual: ValueEmpty.label(),
          message: "blank value is not allowed for this field",
          offset: field.offset(),
        })
      }
    } else if !rule.expected_kind().accepts(actual_kind) {
      violations.push({
        kind: ContractWrongType,
        severity: Critical,
        key: field.key(),
        expected: rule.expected_kind().label(),
        actual: actual_kind.label(),
        message: "field value does not match its semantic type",
        offset: field.offset(),
      })
    }
    if rule.max_length() > 0 &&
      field.value().to_array().length() > rule.max_length() {
      violations.push({
        kind: ContractValueTooLong,
        severity: Warning,
        key: field.key(),
        expected: "length<=" + rule.max_length().to_string(),
        actual: field.value().to_array().length().to_string(),
        message: "field value exceeds its contract length",
        offset: field.offset(),
      })
    }
    if rule.allowed_values().length() > 0 &&
      !rule.allowed_values().contains(field.value()) {
      violations.push({
        kind: ContractValueNotAllowed,
        severity: Critical,
        key: field.key(),
        expected: rule.allowed_values().join("|"),
        actual: field.value(),
        message: "field value is outside the declared vocabulary",
        offset: field.offset(),
      })
    }
  }
  { contract_name: contract.name(), parsed, violations }
}

///|
pub struct InferencePolicy {
  required_percent : Int
  type_confidence_percent : Int
  enum_cardinality_limit : Int
  unknown_fields : UnknownFieldPolicy
} derive(Eq, Debug)

///|
pub fn InferencePolicy::default() -> InferencePolicy {
  {
    required_percent: 95,
    type_confidence_percent: 85,
    enum_cardinality_limit: 8,
    unknown_fields: UnknownWarn,
  }
}

///|
pub fn InferencePolicy::strict() -> InferencePolicy {
  {
    required_percent: 100,
    type_confidence_percent: 95,
    enum_cardinality_limit: 6,
    unknown_fields: UnknownReject,
  }
}

///|
pub fn InferencePolicy::exploratory() -> InferencePolicy {
  {
    required_percent: 75,
    type_confidence_percent: 60,
    enum_cardinality_limit: 12,
    unknown_fields: UnknownAllow,
  }
}

///|
pub fn InferencePolicy::required_percent(self : InferencePolicy) -> Int {
  self.required_percent
}

///|
pub fn InferencePolicy::type_confidence_percent(self : InferencePolicy) -> Int {
  self.type_confidence_percent
}

///|
pub fn InferencePolicy::enum_cardinality_limit(self : InferencePolicy) -> Int {
  self.enum_cardinality_limit
}

///|
pub struct FieldProfile {
  key : String
  lines_seen : Int
  values_seen : Int
  max_length : Int
  distinct_values : Array[String]
  distribution : ValueDistribution
} derive(Eq, Debug)

///|
pub fn FieldProfile::key(self : FieldProfile) -> String {
  self.key
}

///|
pub fn FieldProfile::lines_seen(self : FieldProfile) -> Int {
  self.lines_seen
}

///|
pub fn FieldProfile::values_seen(self : FieldProfile) -> Int {
  self.values_seen
}

///|
pub fn FieldProfile::max_length(self : FieldProfile) -> Int {
  self.max_length
}

///|
pub fn FieldProfile::distinct_values(self : FieldProfile) -> Array[String] {
  self.distinct_values
}

///|
pub fn FieldProfile::distribution(self : FieldProfile) -> ValueDistribution {
  self.distribution
}

///|
pub fn FieldProfile::dominant_kind(self : FieldProfile) -> ValueKind {
  self.distribution.dominant_kind()
}

///|
pub fn FieldProfile::type_confidence(self : FieldProfile) -> Int {
  self.distribution.dominant_percent()
}

///|
pub fn FieldProfile::prevalence_percent(
  self : FieldProfile,
  valid_lines : Int,
) -> Int {
  if valid_lines == 0 {
    0
  } else {
    self.lines_seen * 100 / valid_lines
  }
}

///|
pub fn FieldProfile::summary(self : FieldProfile, valid_lines : Int) -> String {
  self.key +
  " kind=" +
  self.dominant_kind().label() +
  " confidence=" +
  self.type_confidence().to_string() +
  "% prevalence=" +
  self.prevalence_percent(valid_lines).to_string() +
  "% max_length=" +
  self.max_length.to_string() +
  " distribution=" +
  self.distribution.summary()
}

///|
pub struct SchemaInference {
  total_lines : Int
  valid_lines : Int
  invalid_lines : Int
  profiles : Array[FieldProfile]
  contract : LogContract
} derive(Debug)

///|
pub fn SchemaInference::total_lines(self : SchemaInference) -> Int {
  self.total_lines
}

///|
pub fn SchemaInference::valid_lines(self : SchemaInference) -> Int {
  self.valid_lines
}

///|
pub fn SchemaInference::invalid_lines(self : SchemaInference) -> Int {
  self.invalid_lines
}

///|
pub fn SchemaInference::profiles(self : SchemaInference) -> Array[FieldProfile] {
  self.profiles
}

///|
pub fn SchemaInference::contract(self : SchemaInference) -> LogContract {
  self.contract
}

///|
pub fn SchemaInference::profile_for(
  self : SchemaInference,
  key : String,
) -> FieldProfile? {
  for profile in self.profiles {
    if profile.key() == key {
      return Some(profile)
    }
  }
  None
}

///|
pub fn SchemaInference::text_report(self : SchemaInference) -> String {
  let mut output = "MoonLogfmt schema inference\n"
  output = output + "total_lines: " + self.total_lines.to_string() + "\n"
  output = output + "valid_lines: " + self.valid_lines.to_string() + "\n"
  output = output + "invalid_lines: " + self.invalid_lines.to_string() + "\n"
  output = output + "fields: " + self.profiles.length().to_string() + "\n"
  output = output + "\nProfiles:\n"
  for profile in self.profiles {
    output = output + "- " + profile.summary(self.valid_lines) + "\n"
  }
  output = output + "\nCandidate " + self.contract.describe()
  output
}

///|
pub fn SchemaInference::json_report(self : SchemaInference) -> String {
  let mut output = "{"
  output = output + "\"total_lines\":" + self.total_lines.to_string() + ","
  output = output + "\"valid_lines\":" + self.valid_lines.to_string() + ","
  output = output + "\"invalid_lines\":" + self.invalid_lines.to_string() + ","
  output = output + "\"profiles\":["
  for index = 0; index < self.profiles.length(); index = index + 1 {
    let profile = self.profiles[index]
    if index > 0 {
      output = output + ","
    }
    output = output + "{"
    output = output + "\"key\":\"" + escape_json(profile.key()) + "\","
    output = output + "\"kind\":\"" + profile.dominant_kind().label() + "\","
    output = output +
      "\"confidence\":" +
      profile.type_confidence().to_string() +
      ","
    output = output +
      "\"prevalence\":" +
      profile.prevalence_percent(self.valid_lines).to_string() +
      ","
    output = output + "\"max_length\":" + profile.max_length().to_string() + ","
    output = output +
      "\"distribution\":\"" +
      escape_json(profile.distribution().summary()) +
      "\""
    output = output + "}"
  }
  output = output + "],"
  output = output + "\"contract\":\"" + escape_json(self.contract.name()) + "\""
  output + "}"
}

///|
priv struct ProfileBuilder {
  key : String
  mut lines_seen : Int
  mut values_seen : Int
  mut max_length : Int
  distinct_values : Array[String]
  mut distribution : ValueDistribution
}

///|
pub fn infer_schema(
  lines : Array[String],
  policy? : InferencePolicy = InferencePolicy::default(),
) -> SchemaInference {
  let builders : Array[ProfileBuilder] = []
  let mut valid_lines = 0
  let mut invalid_lines = 0
  for line in lines {
    let parsed = parse(line)
    if !parsed.is_valid() {
      invalid_lines = invalid_lines + 1
      continue
    }
    valid_lines = valid_lines + 1
    let line_keys : Array[String] = []
    for field in parsed.fields() {
      let mut builder_index = profile_builder_index(builders, field.key())
      if builder_index < 0 {
        builders.push({
          key: field.key(),
          lines_seen: 0,
          values_seen: 0,
          max_length: 0,
          distinct_values: [],
          distribution: ValueDistribution::empty(),
        })
        builder_index = builders.length() - 1
      }
      let builder = builders[builder_index]
      if !line_keys.contains(field.key()) {
        builder.lines_seen = builder.lines_seen + 1
        line_keys.push(field.key())
      }
      builder.values_seen = builder.values_seen + 1
      let length = field.value().to_array().length()
      if length > builder.max_length {
        builder.max_length = length
      }
      if !builder.distinct_values.contains(field.value()) &&
        builder.distinct_values.length() <= policy.enum_cardinality_limit {
        builder.distinct_values.push(field.value())
      }
      builder.distribution = builder.distribution.with_kind(
        classify_field(field),
      )
    }
  }
  let profiles : Array[FieldProfile] = []
  let rules : Array[FieldRule] = []
  for builder in builders {
    let profile : FieldProfile = {
      key: builder.key,
      lines_seen: builder.lines_seen,
      values_seen: builder.values_seen,
      max_length: builder.max_length,
      distinct_values: builder.distinct_values,
      distribution: builder.distribution,
    }
    profiles.push(profile)
    let prevalence = profile.prevalence_percent(valid_lines)
    let required = prevalence >= policy.required_percent
    let inferred_kind = if profile.type_confidence() >=
      policy.type_confidence_percent {
      profile.dominant_kind()
    } else {
      ValueText
    }
    let mut rule = FieldRule::typed(profile.key(), inferred_kind, required~).with_max_length(
      profile.max_length(),
    )
    if profile.distribution().count(ValueEmpty) > 0 {
      rule = rule.with_blank(true)
    }
    if profile.distribution().count(ValueFlag) > 0 {
      rule = rule.with_flag(true)
    }
    if profile.distinct_values().length() > 0 &&
      profile.distinct_values().length() <= policy.enum_cardinality_limit &&
      contract_can_infer_enum(profile.key(), inferred_kind) {
      rule = rule.with_allowed_values(profile.distinct_values())
    }
    rules.push(rule)
  }
  let inferred_max_fields = if rules.length() < 8 {
    8
  } else {
    rules.length() + 4
  }
  let contract = LogContract::new(
    "inferred-logfmt",
    rules,
    unknown_fields=policy.unknown_fields,
    max_fields=inferred_max_fields,
  )
  {
    total_lines: lines.length(),
    valid_lines,
    invalid_lines,
    profiles,
    contract,
  }
}

///|
fn contract_rule_index(contract : LogContract, key : String) -> Int {
  for index = 0; index < contract.rules().length(); index = index + 1 {
    if contract.rules()[index].key() == key {
      return index
    }
  }
  -1
}

///|
fn profile_builder_index(builders : Array[ProfileBuilder], key : String) -> Int {
  for index = 0; index < builders.length(); index = index + 1 {
    if builders[index].key == key {
      return index
    }
  }
  -1
}

///|
fn contract_can_infer_enum(key : String, kind : ValueKind) -> Bool {
  if kind == ValueBoolean {
    return true
  }
  if kind != ValueIdentifier {
    return false
  }
  let lower = profile_ascii_lower(key)
  lower == "level" ||
  lower == "severity" ||
  lower == "env" ||
  lower == "environment" ||
  lower == "state" ||
  lower == "phase" ||
  lower == "outcome" ||
  lower == "result"
}
