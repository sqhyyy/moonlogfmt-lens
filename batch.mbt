///|
/// Controls batch analysis without introducing file-system or process I/O.
pub struct BatchPolicy {
  audit_policy : AuditPolicy
  skip_blank_lines : Bool
  max_distinct_shapes : Int
} derive(Debug)

///|
pub fn BatchPolicy::default() -> BatchPolicy {
  {
    audit_policy: AuditPolicy::default(),
    skip_blank_lines: true,
    max_distinct_shapes: 64,
  }
}

///|
pub fn BatchPolicy::ci() -> BatchPolicy {
  {
    audit_policy: AuditPolicy::ci(),
    skip_blank_lines: true,
    max_distinct_shapes: 24,
  }
}

///|
pub fn BatchPolicy::exploratory() -> BatchPolicy {
  {
    audit_policy: AuditPolicy::relaxed(),
    skip_blank_lines: true,
    max_distinct_shapes: 128,
  }
}

///|
pub fn BatchPolicy::with_audit_policy(
  self : BatchPolicy,
  audit_policy : AuditPolicy,
) -> BatchPolicy {
  { ..self, audit_policy, }
}

///|
pub fn BatchPolicy::with_blank_lines(
  self : BatchPolicy,
  skip_blank_lines : Bool,
) -> BatchPolicy {
  { ..self, skip_blank_lines, }
}

///|
pub fn BatchPolicy::with_shape_limit(
  self : BatchPolicy,
  max_distinct_shapes : Int,
) -> BatchPolicy {
  { ..self, max_distinct_shapes, }
}

///|
/// A value-free structural cluster. Shape strings contain only field names,
/// semantic kinds, and flag markers.
pub struct ShapeStat {
  shape : String
  fingerprint : String
  count : Int
  first_line : Int
} derive(Eq, Debug)

///|
pub fn ShapeStat::shape(self : ShapeStat) -> String {
  self.shape
}

///|
pub fn ShapeStat::fingerprint(self : ShapeStat) -> String {
  self.fingerprint
}

///|
pub fn ShapeStat::count(self : ShapeStat) -> Int {
  self.count
}

///|
pub fn ShapeStat::first_line(self : ShapeStat) -> Int {
  self.first_line
}

///|
pub fn ShapeStat::summary(self : ShapeStat) -> String {
  self.fingerprint +
  " count=" +
  self.count.to_string() +
  " first_line=" +
  self.first_line.to_string() +
  " shape=" +
  self.shape
}

///|
/// Per-line analysis intentionally omits the original source text.
pub struct LineReview {
  line_number : Int
  shape : String
  fingerprint : String
  report : AuditReport
} derive(Debug)

///|
pub fn LineReview::line_number(self : LineReview) -> Int {
  self.line_number
}

///|
pub fn LineReview::shape(self : LineReview) -> String {
  self.shape
}

///|
pub fn LineReview::fingerprint(self : LineReview) -> String {
  self.fingerprint
}

///|
pub fn LineReview::report(self : LineReview) -> AuditReport {
  self.report
}

///|
pub fn LineReview::is_valid(self : LineReview) -> Bool {
  self.report.parsed().is_valid()
}

///|
pub fn LineReview::risk_level(self : LineReview) -> String {
  self.report.risk_level()
}

///|
pub struct BatchReport {
  input_lines : Int
  processed_lines : Int
  skipped_blank_lines : Int
  valid_lines : Int
  invalid_lines : Int
  clean_lines : Int
  low_risk_lines : Int
  medium_risk_lines : Int
  high_risk_lines : Int
  aggregate_risk_score : Int
  reviews : Array[LineReview]
  profiles : Array[FieldProfile]
  shapes : Array[ShapeStat]
  shape_limit_exceeded : Bool
} derive(Debug)

///|
pub fn BatchReport::input_lines(self : BatchReport) -> Int {
  self.input_lines
}

///|
pub fn BatchReport::processed_lines(self : BatchReport) -> Int {
  self.processed_lines
}

///|
pub fn BatchReport::skipped_blank_lines(self : BatchReport) -> Int {
  self.skipped_blank_lines
}

///|
pub fn BatchReport::valid_lines(self : BatchReport) -> Int {
  self.valid_lines
}

///|
pub fn BatchReport::invalid_lines(self : BatchReport) -> Int {
  self.invalid_lines
}

///|
pub fn BatchReport::clean_lines(self : BatchReport) -> Int {
  self.clean_lines
}

///|
pub fn BatchReport::low_risk_lines(self : BatchReport) -> Int {
  self.low_risk_lines
}

///|
pub fn BatchReport::medium_risk_lines(self : BatchReport) -> Int {
  self.medium_risk_lines
}

///|
pub fn BatchReport::high_risk_lines(self : BatchReport) -> Int {
  self.high_risk_lines
}

///|
pub fn BatchReport::aggregate_risk_score(self : BatchReport) -> Int {
  self.aggregate_risk_score
}

///|
pub fn BatchReport::reviews(self : BatchReport) -> Array[LineReview] {
  self.reviews
}

///|
pub fn BatchReport::profiles(self : BatchReport) -> Array[FieldProfile] {
  self.profiles
}

///|
pub fn BatchReport::shapes(self : BatchReport) -> Array[ShapeStat] {
  self.shapes
}

///|
pub fn BatchReport::shape_count(self : BatchReport) -> Int {
  self.shapes.length()
}

///|
pub fn BatchReport::shape_limit_exceeded(self : BatchReport) -> Bool {
  self.shape_limit_exceeded
}

///|
pub fn BatchReport::invalid_percent(self : BatchReport) -> Int {
  if self.processed_lines == 0 {
    0
  } else {
    self.invalid_lines * 100 / self.processed_lines
  }
}

///|
pub fn BatchReport::high_risk_percent(self : BatchReport) -> Int {
  if self.processed_lines == 0 {
    0
  } else {
    self.high_risk_lines * 100 / self.processed_lines
  }
}

///|
pub fn BatchReport::average_risk_score(self : BatchReport) -> Int {
  if self.processed_lines == 0 {
    0
  } else {
    self.aggregate_risk_score / self.processed_lines
  }
}

///|
pub fn BatchReport::profile_for(
  self : BatchReport,
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
pub fn BatchReport::shape_for_fingerprint(
  self : BatchReport,
  fingerprint : String,
) -> ShapeStat? {
  for shape in self.shapes {
    if shape.fingerprint() == fingerprint {
      return Some(shape)
    }
  }
  None
}

///|
pub fn BatchReport::most_common_shape(self : BatchReport) -> ShapeStat? {
  if self.shapes.length() == 0 {
    return None
  }
  let mut best = self.shapes[0]
  for index = 1; index < self.shapes.length(); index = index + 1 {
    if self.shapes[index].count() > best.count() {
      best = self.shapes[index]
    }
  }
  Some(best)
}

///|
pub fn BatchReport::text_report(self : BatchReport) -> String {
  let mut output = "MoonLogfmt batch report\n"
  output = output + "input_lines: " + self.input_lines.to_string() + "\n"
  output = output +
    "processed_lines: " +
    self.processed_lines.to_string() +
    "\n"
  output = output +
    "skipped_blank_lines: " +
    self.skipped_blank_lines.to_string() +
    "\n"
  output = output + "valid_lines: " + self.valid_lines.to_string() + "\n"
  output = output +
    "invalid_lines: " +
    self.invalid_lines.to_string() +
    " (" +
    self.invalid_percent().to_string() +
    "%)\n"
  output = output +
    "risk_lines: clean=" +
    self.clean_lines.to_string() +
    " low=" +
    self.low_risk_lines.to_string() +
    " medium=" +
    self.medium_risk_lines.to_string() +
    " high=" +
    self.high_risk_lines.to_string() +
    "\n"
  output = output +
    "aggregate_risk_score: " +
    self.aggregate_risk_score.to_string() +
    "\n"
  output = output + "distinct_shapes: " + self.shape_count().to_string() + "\n"
  if self.shape_limit_exceeded {
    output = output + "shape_limit: exceeded\n"
  }
  output = output + "\nShapes:\n"
  for shape in self.shapes {
    output = output + "- " + shape.summary() + "\n"
  }
  output = output + "\nField profiles:\n"
  for profile in self.profiles {
    output = output + "- " + profile.summary(self.valid_lines) + "\n"
  }
  output
}

///|
pub fn BatchReport::json_report(self : BatchReport) -> String {
  let mut output = "{"
  output = output + "\"input_lines\":" + self.input_lines.to_string() + ","
  output = output +
    "\"processed_lines\":" +
    self.processed_lines.to_string() +
    ","
  output = output +
    "\"skipped_blank_lines\":" +
    self.skipped_blank_lines.to_string() +
    ","
  output = output + "\"valid_lines\":" + self.valid_lines.to_string() + ","
  output = output + "\"invalid_lines\":" + self.invalid_lines.to_string() + ","
  output = output +
    "\"invalid_percent\":" +
    self.invalid_percent().to_string() +
    ","
  output = output +
    "\"high_risk_lines\":" +
    self.high_risk_lines.to_string() +
    ","
  output = output +
    "\"aggregate_risk_score\":" +
    self.aggregate_risk_score.to_string() +
    ","
  output = output + "\"shapes\":["
  for index = 0; index < self.shapes.length(); index = index + 1 {
    let shape = self.shapes[index]
    if index > 0 {
      output = output + ","
    }
    output = output + "{"
    output = output + "\"fingerprint\":\"" + shape.fingerprint() + "\","
    output = output + "\"count\":" + shape.count().to_string() + ","
    output = output + "\"first_line\":" + shape.first_line().to_string() + ","
    output = output + "\"shape\":\"" + escape_json(shape.shape()) + "\""
    output = output + "}"
  }
  output = output + "],\"profiles\":["
  for index = 0; index < self.profiles.length(); index = index + 1 {
    let profile = self.profiles[index]
    if index > 0 {
      output = output + ","
    }
    output = output + "{"
    output = output + "\"key\":\"" + escape_json(profile.key()) + "\","
    output = output + "\"kind\":\"" + profile.dominant_kind().label() + "\","
    output = output +
      "\"prevalence\":" +
      profile.prevalence_percent(self.valid_lines).to_string() +
      ","
    output = output + "\"confidence\":" + profile.type_confidence().to_string()
    output = output + "}"
  }
  output + "]}"
}

///|
pub struct BatchGatePolicy {
  max_invalid_percent : Int
  max_high_risk_percent : Int
  max_average_risk_score : Int
  reject_shape_overflow : Bool
  required_keys : Array[String]
  min_required_prevalence : Int
} derive(Eq, Debug)

///|
pub fn BatchGatePolicy::default() -> BatchGatePolicy {
  {
    max_invalid_percent: 0,
    max_high_risk_percent: 5,
    max_average_risk_score: 6,
    reject_shape_overflow: true,
    required_keys: [],
    min_required_prevalence: 100,
  }
}

///|
pub fn BatchGatePolicy::ci() -> BatchGatePolicy {
  {
    max_invalid_percent: 0,
    max_high_risk_percent: 0,
    max_average_risk_score: 3,
    reject_shape_overflow: true,
    required_keys: ["level", "msg"],
    min_required_prevalence: 100,
  }
}

///|
pub fn BatchGatePolicy::with_required_keys(
  self : BatchGatePolicy,
  required_keys : Array[String],
  min_prevalence? : Int = 100,
) -> BatchGatePolicy {
  { ..self, required_keys, min_required_prevalence: min_prevalence }
}

///|
pub fn BatchGatePolicy::with_error_budget(
  self : BatchGatePolicy,
  max_invalid_percent : Int,
  max_high_risk_percent : Int,
) -> BatchGatePolicy {
  { ..self, max_invalid_percent, max_high_risk_percent }
}

///|
pub struct BatchDecision {
  accepted : Bool
  reasons : Array[String]
} derive(Eq, Debug)

///|
pub fn BatchDecision::accepted(self : BatchDecision) -> Bool {
  self.accepted
}

///|
pub fn BatchDecision::reasons(self : BatchDecision) -> Array[String] {
  self.reasons
}

///|
pub fn BatchDecision::label(self : BatchDecision) -> String {
  if self.accepted {
    "accept"
  } else {
    "reject"
  }
}

///|
pub fn BatchDecision::text_report(self : BatchDecision) -> String {
  let mut output = "batch_gate: " + self.label() + "\n"
  for reason in self.reasons {
    output = output + "- " + reason + "\n"
  }
  output
}

///|
pub fn evaluate_batch(
  report : BatchReport,
  policy? : BatchGatePolicy = BatchGatePolicy::default(),
) -> BatchDecision {
  let reasons : Array[String] = []
  if report.processed_lines() == 0 {
    reasons.push("batch has no processable logfmt records")
  }
  if report.invalid_percent() > policy.max_invalid_percent {
    reasons.push(
      "invalid line rate " +
      report.invalid_percent().to_string() +
      "% exceeds " +
      policy.max_invalid_percent.to_string() +
      "%",
    )
  }
  if report.high_risk_percent() > policy.max_high_risk_percent {
    reasons.push(
      "high-risk line rate " +
      report.high_risk_percent().to_string() +
      "% exceeds " +
      policy.max_high_risk_percent.to_string() +
      "%",
    )
  }
  if report.average_risk_score() > policy.max_average_risk_score {
    reasons.push(
      "average risk score " +
      report.average_risk_score().to_string() +
      " exceeds " +
      policy.max_average_risk_score.to_string(),
    )
  }
  if policy.reject_shape_overflow && report.shape_limit_exceeded() {
    reasons.push("distinct structural shapes exceed the configured limit")
  }
  for key in policy.required_keys {
    match report.profile_for(key) {
      None =>
        reasons.push("required batch key `" + key + "` was never observed")
      Some(profile) => {
        let prevalence = profile.prevalence_percent(report.valid_lines())
        if prevalence < policy.min_required_prevalence {
          reasons.push(
            "required batch key `" +
            key +
            "` prevalence " +
            prevalence.to_string() +
            "% is below " +
            policy.min_required_prevalence.to_string() +
            "%",
          )
        }
      }
    }
  }
  { accepted: reasons.length() == 0, reasons }
}

///|
pub fn analyze_batch(
  lines : Array[String],
  policy? : BatchPolicy = BatchPolicy::default(),
) -> BatchReport {
  let reviews : Array[LineReview] = []
  let profile_lines : Array[String] = []
  let shape_builders : Array[ShapeBuilder] = []
  let mut skipped_blank_lines = 0
  let mut valid_lines = 0
  let mut invalid_lines = 0
  let mut clean_lines = 0
  let mut low_risk_lines = 0
  let mut medium_risk_lines = 0
  let mut high_risk_lines = 0
  let mut aggregate_risk_score = 0
  let mut shape_limit_exceeded = false
  for index = 0; index < lines.length(); index = index + 1 {
    let line = lines[index]
    if policy.skip_blank_lines && batch_is_blank(line) {
      skipped_blank_lines = skipped_blank_lines + 1
      continue
    }
    profile_lines.push(line)
    let parsed = parse(line)
    let report = audit(parsed, policy.audit_policy)
    let shape = structural_shape(parsed)
    let fingerprint = shape_fingerprint(shape)
    reviews.push({ line_number: index + 1, shape, fingerprint, report })
    if parsed.is_valid() {
      valid_lines = valid_lines + 1
    } else {
      invalid_lines = invalid_lines + 1
    }
    aggregate_risk_score = aggregate_risk_score + report.risk_score()
    match report.risk_level() {
      "clean" => clean_lines = clean_lines + 1
      "low" => low_risk_lines = low_risk_lines + 1
      "medium" => medium_risk_lines = medium_risk_lines + 1
      _ => high_risk_lines = high_risk_lines + 1
    }
    let shape_index = batch_shape_builder_index(shape_builders, shape)
    if shape_index >= 0 {
      shape_builders[shape_index].count = shape_builders[shape_index].count + 1
    } else if shape_builders.length() < policy.max_distinct_shapes {
      shape_builders.push({
        shape,
        fingerprint,
        count: 1,
        first_line: index + 1,
      })
    } else {
      shape_limit_exceeded = true
    }
  }
  let shapes : Array[ShapeStat] = []
  for builder in shape_builders {
    shapes.push({
      shape: builder.shape,
      fingerprint: builder.fingerprint,
      count: builder.count,
      first_line: builder.first_line,
    })
  }
  let inference = infer_schema(
    profile_lines,
    policy=InferencePolicy::exploratory(),
  )
  {
    input_lines: lines.length(),
    processed_lines: reviews.length(),
    skipped_blank_lines,
    valid_lines,
    invalid_lines,
    clean_lines,
    low_risk_lines,
    medium_risk_lines,
    high_risk_lines,
    aggregate_risk_score,
    reviews,
    profiles: inference.profiles(),
    shapes,
    shape_limit_exceeded,
  }
}

///|
/// Returns a value-free template in original field order.
pub fn structural_template(line : String) -> String {
  let parsed = parse(line)
  let parts : Array[String] = []
  for field in parsed.fields() {
    if field.is_flag() {
      parts.push(field.key() + "=<flag>")
    } else {
      parts.push(field.key() + "=<" + classify_field(field).label() + ">")
    }
  }
  if parsed.is_valid() {
    parts.join(" ")
  } else {
    "<invalid> " + parts.join(" ")
  }
}

///|
/// Returns a canonical shape independent of field order and field values.
pub fn structural_shape(parsed : ParseResult) -> String {
  let parts : Array[String] = []
  for field in parsed.fields() {
    let entry = field.key() + ":" + classify_field(field).label()
    if !parts.contains(entry) {
      parts.push(entry)
    }
  }
  let sorted = batch_sort_strings(parts)
  let prefix = if parsed.is_valid() { "valid|" } else { "invalid|" }
  prefix + sorted.join("|")
}

///|
/// Stable, non-cryptographic identifier for a value-free structural shape.
pub fn shape_fingerprint(shape : String) -> String {
  "shape-" + privacy_stable_hash(shape).to_string()
}

///|
priv struct ShapeBuilder {
  shape : String
  fingerprint : String
  mut count : Int
  first_line : Int
}

///|
fn batch_shape_builder_index(
  builders : Array[ShapeBuilder],
  shape : String,
) -> Int {
  for index = 0; index < builders.length(); index = index + 1 {
    if builders[index].shape == shape {
      return index
    }
  }
  -1
}

///|
fn batch_is_blank(line : String) -> Bool {
  for char in line.to_array() {
    if char != ' ' && char != '\t' && char != '\r' && char != '\n' {
      return false
    }
  }
  true
}

///|
fn batch_sort_strings(values : Array[String]) -> Array[String] {
  let output : Array[String] = []
  for value in values {
    let mut inserted = false
    for index = 0; index < output.length(); index = index + 1 {
      if batch_compare_strings(value, output[index]) < 0 {
        output.insert(index, value)
        inserted = true
        break
      }
    }
    if !inserted {
      output.push(value)
    }
  }
  output
}

///|
fn batch_compare_strings(left : String, right : String) -> Int {
  let left_chars = left.to_array()
  let right_chars = right.to_array()
  let limit = if left_chars.length() < right_chars.length() {
    left_chars.length()
  } else {
    right_chars.length()
  }
  for index = 0; index < limit; index = index + 1 {
    let left_code = left_chars[index].to_int()
    let right_code = right_chars[index].to_int()
    if left_code < right_code {
      return -1
    }
    if left_code > right_code {
      return 1
    }
  }
  if left_chars.length() < right_chars.length() {
    -1
  } else if left_chars.length() > right_chars.length() {
    1
  } else {
    0
  }
}
