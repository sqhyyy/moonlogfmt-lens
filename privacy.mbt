///|
/// Categories used by the privacy scanner.
pub(all) enum SensitiveKind {
  SensitiveSecret
  SensitiveCredential
  SensitivePersonal
  SensitivePayment
  SensitiveNetwork
} derive(Eq, Debug)

///|
pub fn SensitiveKind::label(self : SensitiveKind) -> String {
  match self {
    SensitiveSecret => "secret"
    SensitiveCredential => "credential"
    SensitivePersonal => "personal"
    SensitivePayment => "payment"
    SensitiveNetwork => "network"
  }
}

///|
pub fn SensitiveKind::severity(self : SensitiveKind) -> Severity {
  match self {
    SensitiveSecret => Critical
    SensitiveCredential => Critical
    SensitivePersonal => Warning
    SensitivePayment => Critical
    SensitiveNetwork => Warning
  }
}

///|
/// How a sensitive value should be represented in safe output.
pub(all) enum RedactionMode {
  RedactFull
  RedactKeepLastFour
  RedactStableToken
} derive(Eq, Debug)

///|
pub fn RedactionMode::label(self : RedactionMode) -> String {
  match self {
    RedactFull => "full"
    RedactKeepLastFour => "keep_last_four"
    RedactStableToken => "stable_token"
  }
}

///|
/// Privacy rules for key-aware and value-aware redaction.
pub struct RedactionPolicy {
  mode : RedactionMode
  secret_key_fragments : Array[String]
  personal_key_fragments : Array[String]
  payment_key_fragments : Array[String]
  network_key_fragments : Array[String]
  allow_keys : Array[String]
  detect_values : Bool
  redact_network_values : Bool
} derive(Debug)

///|
pub fn RedactionPolicy::default() -> RedactionPolicy {
  {
    mode: RedactFull,
    secret_key_fragments: [
      "password", "passwd", "secret", "token", "api_key", "apikey", "access_key",
      "authorization", "credential", "private_key", "cookie", "session",
    ],
    personal_key_fragments: [
      "email", "e_mail", "phone", "mobile", "username", "user_name",
    ],
    payment_key_fragments: [
      "card_number", "credit_card", "iban", "account_number", "payment_token",
    ],
    network_key_fragments: [
      "client_ip", "remote_ip", "source_ip", "destination_ip",
    ],
    allow_keys: [],
    detect_values: true,
    redact_network_values: false,
  }
}

///|
pub fn RedactionPolicy::strict() -> RedactionPolicy {
  {
    ..RedactionPolicy::default(),
    mode: RedactStableToken,
    redact_network_values: true,
  }
}

///|
pub fn RedactionPolicy::key_only() -> RedactionPolicy {
  { ..RedactionPolicy::default(), detect_values: false }
}

///|
pub fn RedactionPolicy::mode(self : RedactionPolicy) -> RedactionMode {
  self.mode
}

///|
pub fn RedactionPolicy::with_mode(
  self : RedactionPolicy,
  mode : RedactionMode,
) -> RedactionPolicy {
  { ..self, mode, }
}

///|
pub fn RedactionPolicy::with_allow_keys(
  self : RedactionPolicy,
  allow_keys : Array[String],
) -> RedactionPolicy {
  { ..self, allow_keys, }
}

///|
pub fn RedactionPolicy::with_value_detection(
  self : RedactionPolicy,
  detect_values : Bool,
) -> RedactionPolicy {
  { ..self, detect_values, }
}

///|
pub fn RedactionPolicy::with_network_values(
  self : RedactionPolicy,
  redact_network_values : Bool,
) -> RedactionPolicy {
  { ..self, redact_network_values, }
}

///|
pub struct PrivacyFinding {
  key : String
  kind : SensitiveKind
  reason : String
  offset : Int
} derive(Eq, Debug)

///|
pub fn PrivacyFinding::key(self : PrivacyFinding) -> String {
  self.key
}

///|
pub fn PrivacyFinding::kind(self : PrivacyFinding) -> SensitiveKind {
  self.kind
}

///|
pub fn PrivacyFinding::reason(self : PrivacyFinding) -> String {
  self.reason
}

///|
pub fn PrivacyFinding::offset(self : PrivacyFinding) -> Int {
  self.offset
}

///|
pub fn PrivacyFinding::severity(self : PrivacyFinding) -> Severity {
  self.kind.severity()
}

///|
/// The privacy-safe projection of one parsed line.
///
/// Reports never include the original sensitive values. The original source is
/// retained only through the parsed result for in-process callers and is not
/// serialized by the report methods.
pub struct RedactionResult {
  parsed : ParseResult
  safe_line : String
  findings : Array[PrivacyFinding]
  redacted_keys : Array[String]
} derive(Debug)

///|
pub fn RedactionResult::parsed(self : RedactionResult) -> ParseResult {
  self.parsed
}

///|
pub fn RedactionResult::safe_line(self : RedactionResult) -> String {
  self.safe_line
}

///|
pub fn RedactionResult::findings(
  self : RedactionResult,
) -> Array[PrivacyFinding] {
  self.findings
}

///|
pub fn RedactionResult::redacted_keys(self : RedactionResult) -> Array[String] {
  self.redacted_keys
}

///|
pub fn RedactionResult::finding_count(self : RedactionResult) -> Int {
  self.findings.length()
}

///|
pub fn RedactionResult::redacted_count(self : RedactionResult) -> Int {
  self.redacted_keys.length()
}

///|
pub fn RedactionResult::is_safe(self : RedactionResult) -> Bool {
  self.findings.length() == 0
}

///|
pub fn RedactionResult::critical_count(self : RedactionResult) -> Int {
  let mut count = 0
  for finding in self.findings {
    if finding.severity() == Critical {
      count = count + 1
    }
  }
  count
}

///|
pub fn RedactionResult::decision(self : RedactionResult) -> String {
  if self.critical_count() > 0 {
    "sanitize"
  } else if self.finding_count() > 0 {
    "review"
  } else {
    "accept"
  }
}

///|
pub fn RedactionResult::text_report(self : RedactionResult) -> String {
  let mut output = "MoonLogfmt privacy report\n"
  output = output + "findings: " + self.finding_count().to_string() + "\n"
  output = output +
    "redacted_fields: " +
    self.redacted_count().to_string() +
    "\n"
  output = output + "decision: " + self.decision() + "\n"
  output = output + "safe_line: " + self.safe_line + "\n"
  if self.findings.length() == 0 {
    return output + "\nNo sensitive fields detected."
  }
  output = output + "\nFindings:\n"
  for finding in self.findings {
    output = output +
      "- [" +
      finding.severity().label() +
      "] " +
      finding.kind().label() +
      " key=" +
      finding.key() +
      ": " +
      finding.reason() +
      "\n"
  }
  output
}

///|
pub fn RedactionResult::json_report(self : RedactionResult) -> String {
  let mut output = "{"
  output = output + "\"safe_line\":\"" + escape_json(self.safe_line) + "\","
  output = output + "\"findings\":" + self.finding_count().to_string() + ","
  output = output +
    "\"redacted_fields\":" +
    self.redacted_count().to_string() +
    ","
  output = output + "\"decision\":\"" + self.decision() + "\","
  output = output + "\"items\":["
  for index = 0; index < self.findings.length(); index = index + 1 {
    let finding = self.findings[index]
    if index > 0 {
      output = output + ","
    }
    output = output + "{"
    output = output + "\"key\":\"" + escape_json(finding.key()) + "\","
    output = output + "\"kind\":\"" + finding.kind().label() + "\","
    output = output + "\"severity\":\"" + finding.severity().label() + "\","
    output = output + "\"reason\":\"" + escape_json(finding.reason()) + "\","
    output = output + "\"offset\":" + finding.offset().to_string()
    output = output + "}"
  }
  output + "]}"
}

///|
pub fn redact_line(
  line : String,
  policy? : RedactionPolicy = RedactionPolicy::default(),
) -> RedactionResult {
  redact_parsed(parse(line), policy)
}

///|
pub fn redact_parsed(
  parsed : ParseResult,
  policy : RedactionPolicy,
) -> RedactionResult {
  let findings : Array[PrivacyFinding] = []
  let redacted_keys : Array[String] = []
  let safe_parts : Array[String] = []
  for field in parsed.fields() {
    let sensitive = privacy_classify_field(field, policy)
    if sensitive.found {
      findings.push({
        key: field.key(),
        kind: sensitive.kind,
        reason: sensitive.reason,
        offset: field.offset(),
      })
      if !redacted_keys.contains(field.key()) {
        redacted_keys.push(field.key())
      }
      let replacement = privacy_redact_value(field.value(), policy.mode())
      safe_parts.push(privacy_render_pair(field.key(), replacement))
    } else if field.is_flag() {
      safe_parts.push(field.key())
    } else {
      safe_parts.push(privacy_render_pair(field.key(), field.value()))
    }
  }
  { parsed, safe_line: safe_parts.join(" "), findings, redacted_keys }
}

///|
/// Scans without changing policy defaults. The returned safe line can be used
/// directly in diagnostics, fixtures, or support bundles.
pub fn scan_privacy(line : String) -> RedactionResult {
  redact_line(line)
}

///|
priv struct SensitiveMatch {
  found : Bool
  kind : SensitiveKind
  reason : String
}

///|
fn privacy_no_match() -> SensitiveMatch {
  { found: false, kind: SensitivePersonal, reason: "" }
}

///|
fn privacy_classify_field(
  field : Field,
  policy : RedactionPolicy,
) -> SensitiveMatch {
  if policy.allow_keys.contains(field.key()) {
    return privacy_no_match()
  }
  let lower_key = profile_ascii_lower(field.key())
  if privacy_contains_any(lower_key, policy.payment_key_fragments) {
    return {
      found: true,
      kind: SensitivePayment,
      reason: "field name matches a payment-data pattern",
    }
  }
  if privacy_contains_any(lower_key, policy.secret_key_fragments) {
    let kind = if lower_key.contains("password") ||
      lower_key.contains("secret") ||
      lower_key.contains("private_key") {
      SensitiveSecret
    } else {
      SensitiveCredential
    }
    return {
      found: true,
      kind,
      reason: "field name matches a secret or credential pattern",
    }
  }
  if privacy_contains_any(lower_key, policy.personal_key_fragments) {
    return {
      found: true,
      kind: SensitivePersonal,
      reason: "field name matches a personal-data pattern",
    }
  }
  if privacy_contains_any(lower_key, policy.network_key_fragments) {
    return {
      found: true,
      kind: SensitiveNetwork,
      reason: "field name matches a network-identity pattern",
    }
  }
  if !policy.detect_values {
    return privacy_no_match()
  }
  privacy_classify_value(field.value(), policy)
}

///|
fn privacy_classify_value(
  value : String,
  policy : RedactionPolicy,
) -> SensitiveMatch {
  let lower = profile_ascii_lower(value)
  if profile_has_prefix(lower, "bearer ") {
    return {
      found: true,
      kind: SensitiveCredential,
      reason: "value resembles a bearer credential",
    }
  }
  if profile_has_prefix(lower, "basic ") && value.to_array().length() > 12 {
    return {
      found: true,
      kind: SensitiveCredential,
      reason: "value resembles a basic authorization credential",
    }
  }
  if profile_has_prefix(lower, "sk-") ||
    profile_has_prefix(lower, "ghp_") ||
    profile_has_prefix(lower, "github_pat_") ||
    profile_has_prefix(lower, "akia") {
    return {
      found: true,
      kind: SensitiveCredential,
      reason: "value resembles a provider access key",
    }
  }
  if lower.contains("private key") {
    return {
      found: true,
      kind: SensitiveSecret,
      reason: "value contains a private-key marker",
    }
  }
  if privacy_is_jwt(value) {
    return {
      found: true,
      kind: SensitiveCredential,
      reason: "value resembles a three-segment token",
    }
  }
  if privacy_is_payment_card(value) {
    return {
      found: true,
      kind: SensitivePayment,
      reason: "value passes a payment-card checksum",
    }
  }
  if classify_value(value) == ValueEmail {
    return {
      found: true,
      kind: SensitivePersonal,
      reason: "value resembles an email address",
    }
  }
  if privacy_is_phone(value) {
    return {
      found: true,
      kind: SensitivePersonal,
      reason: "value resembles a formatted phone number",
    }
  }
  if policy.redact_network_values && classify_value(value) == ValueIPv4 {
    return {
      found: true,
      kind: SensitiveNetwork,
      reason: "strict policy treats IP addresses as sensitive",
    }
  }
  if privacy_is_high_entropy_secret(value) {
    return {
      found: true,
      kind: SensitiveCredential,
      reason: "long mixed-character value resembles a generated secret",
    }
  }
  privacy_no_match()
}

///|
fn privacy_contains_any(value : String, fragments : Array[String]) -> Bool {
  for fragment in fragments {
    if value.contains(fragment) {
      return true
    }
  }
  false
}

///|
fn privacy_render_pair(key : String, value : String) -> String {
  if needs_quote(value) {
    key + "=\"" + escape_logfmt(value) + "\""
  } else {
    key + "=" + value
  }
}

///|
fn privacy_redact_value(value : String, mode : RedactionMode) -> String {
  match mode {
    RedactFull => "[REDACTED]"
    RedactKeepLastFour => {
      let chars = value.to_array()
      if chars.length() <= 4 {
        "****"
      } else {
        "***" + String::from_array(chars[chars.length() - 4:chars.length()])
      }
    }
    RedactStableToken => "redacted_" + privacy_stable_hash(value).to_string()
  }
}

///|
fn privacy_stable_hash(value : String) -> Int {
  let mut hash = 17
  for char in value.to_array() {
    hash = (hash * 131 + char.to_int()) % 1000003
  }
  if hash < 0 {
    -hash
  } else {
    hash
  }
}

///|
fn privacy_is_jwt(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() < 24 {
    return false
  }
  let mut dots = 0
  let mut segment_length = 0
  for char in chars {
    if char == '.' {
      if segment_length < 4 {
        return false
      }
      dots = dots + 1
      segment_length = 0
    } else if privacy_is_token_char(char) {
      segment_length = segment_length + 1
    } else {
      return false
    }
  }
  dots == 2 && segment_length >= 4
}

///|
fn privacy_is_token_char(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  profile_is_digit(char) ||
  char == '-' ||
  char == '_' ||
  char == '+' ||
  char == '/' ||
  char == '='
}

///|
fn privacy_is_payment_card(value : String) -> Bool {
  let digits : Array[Int] = []
  for char in value.to_array() {
    if profile_is_digit(char) {
      digits.push(char.to_int() - '0'.to_int())
    } else if char != ' ' && char != '-' {
      return false
    }
  }
  if digits.length() < 13 || digits.length() > 19 {
    return false
  }
  let mut sum = 0
  let mut double_digit = false
  for index = digits.length() - 1; index >= 0; index = index - 1 {
    let mut digit = digits[index]
    if double_digit {
      digit = digit * 2
      if digit > 9 {
        digit = digit - 9
      }
    }
    sum = sum + digit
    double_digit = !double_digit
  }
  sum % 10 == 0
}

///|
fn privacy_is_phone(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() < 10 || chars.length() > 24 {
    return false
  }
  let mut digits = 0
  let mut formatted = false
  for index = 0; index < chars.length(); index = index + 1 {
    let char = chars[index]
    if profile_is_digit(char) {
      digits = digits + 1
    } else if char == '+' && index == 0 {
      formatted = true
    } else if char == ' ' || char == '-' || char == '(' || char == ')' {
      formatted = true
    } else {
      return false
    }
  }
  formatted && digits >= 10 && digits <= 15
}

///|
fn privacy_is_high_entropy_secret(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() < 28 || chars.length() > 256 {
    return false
  }
  let mut lower = false
  let mut upper = false
  let mut digit = false
  let mut symbol = false
  let mut spaces = false
  for char in chars {
    if char >= 'a' && char <= 'z' {
      lower = true
    } else if char >= 'A' && char <= 'Z' {
      upper = true
    } else if profile_is_digit(char) {
      digit = true
    } else if is_space(char) {
      spaces = true
    } else {
      symbol = true
    }
  }
  let mut classes = 0
  if lower {
    classes = classes + 1
  }
  if upper {
    classes = classes + 1
  }
  if digit {
    classes = classes + 1
  }
  if symbol {
    classes = classes + 1
  }
  !spaces && classes >= 3
}
