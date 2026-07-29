///|
/// Severity assigned to an audit finding.
pub(all) enum Severity {
  Info
  Warning
  Critical
} derive(Eq, Debug)

///|
pub fn Severity::label(self : Severity) -> String {
  match self {
    Info => "info"
    Warning => "warning"
    Critical => "critical"
  }
}

///|
pub fn Severity::score(self : Severity) -> Int {
  match self {
    Info => 1
    Warning => 4
    Critical => 10
  }
}

///|
/// Syntax problems found while parsing one logfmt line.
pub(all) enum ParseErrorKind {
  EmptyKey
  InvalidKey
  UnexpectedEquals
  UnterminatedQuote
  BareQuote
} derive(Eq, Debug)

///|
pub fn ParseErrorKind::label(self : ParseErrorKind) -> String {
  match self {
    EmptyKey => "empty_key"
    InvalidKey => "invalid_key"
    UnexpectedEquals => "unexpected_equals"
    UnterminatedQuote => "unterminated_quote"
    BareQuote => "bare_quote"
  }
}

///|
pub struct ParseError {
  kind : ParseErrorKind
  message : String
  offset : Int
} derive(Eq, Debug)

///|
pub fn ParseError::kind(self : ParseError) -> ParseErrorKind {
  self.kind
}

///|
pub fn ParseError::message(self : ParseError) -> String {
  self.message
}

///|
pub fn ParseError::offset(self : ParseError) -> Int {
  self.offset
}

///|
/// One parsed logfmt field.
pub struct Field {
  key : String
  value : String
  quoted : Bool
  flag : Bool
  offset : Int
} derive(Eq, Debug)

///|
pub fn Field::new(
  key : String,
  value : String,
  quoted? : Bool = false,
  flag? : Bool = false,
  offset? : Int = 0,
) -> Field {
  { key, value, quoted, flag, offset }
}

///|
pub fn Field::key(self : Field) -> String {
  self.key
}

///|
pub fn Field::value(self : Field) -> String {
  self.value
}

///|
pub fn Field::quoted(self : Field) -> Bool {
  self.quoted
}

///|
pub fn Field::is_flag(self : Field) -> Bool {
  self.flag
}

///|
pub fn Field::offset(self : Field) -> Int {
  self.offset
}

///|
pub fn Field::pair(self : Field) -> String {
  self.key + "=" + self.value
}

///|
pub struct ParseResult {
  source : String
  fields : Array[Field]
  errors : Array[ParseError]
} derive(Debug)

///|
pub fn ParseResult::source(self : ParseResult) -> String {
  self.source
}

///|
pub fn ParseResult::fields(self : ParseResult) -> Array[Field] {
  self.fields
}

///|
pub fn ParseResult::errors(self : ParseResult) -> Array[ParseError] {
  self.errors
}

///|
pub fn ParseResult::field_count(self : ParseResult) -> Int {
  self.fields.length()
}

///|
pub fn ParseResult::error_count(self : ParseResult) -> Int {
  self.errors.length()
}

///|
pub fn ParseResult::is_valid(self : ParseResult) -> Bool {
  self.errors.length() == 0
}

///|
pub fn ParseResult::get(self : ParseResult, key : String) -> String {
  for field in self.fields {
    if field.key() == key {
      return field.value()
    }
  }
  ""
}

///|
pub fn ParseResult::has_key(self : ParseResult, key : String) -> Bool {
  for field in self.fields {
    if field.key() == key {
      return true
    }
  }
  false
}

///|
pub fn ParseResult::summary(self : ParseResult) -> String {
  "fields=\{self.field_count()} errors=\{self.error_count()}"
}

///|
pub fn ParseResult::normalized(self : ParseResult) -> String {
  let parts : Array[String] = []
  for field in self.fields {
    if field.is_flag() {
      parts.push(field.key())
    } else if needs_quote(field.value()) {
      parts.push(field.key() + "=\"" + escape_logfmt(field.value()) + "\"")
    } else {
      parts.push(field.pair())
    }
  }
  parts.join(" ")
}

///|
/// Audit finding kinds for logfmt quality and CI review.
pub(all) enum FindingKind {
  SyntaxError
  DuplicateKey
  RequiredKeyMissing
  TooManyFields
  ValueTooLong
  BlankValue
  FlagField
  ControlCharacter
} derive(Eq, Debug)

///|
pub fn FindingKind::label(self : FindingKind) -> String {
  match self {
    SyntaxError => "syntax_error"
    DuplicateKey => "duplicate_key"
    RequiredKeyMissing => "required_key_missing"
    TooManyFields => "too_many_fields"
    ValueTooLong => "value_too_long"
    BlankValue => "blank_value"
    FlagField => "flag_field"
    ControlCharacter => "control_character"
  }
}

///|
pub struct Finding {
  kind : FindingKind
  severity : Severity
  key : String
  message : String
  offset : Int
} derive(Eq, Debug)

///|
pub fn Finding::new(
  kind : FindingKind,
  severity : Severity,
  key : String,
  message : String,
  offset? : Int = 0,
) -> Finding {
  { kind, severity, key, message, offset }
}

///|
pub fn Finding::kind(self : Finding) -> FindingKind {
  self.kind
}

///|
pub fn Finding::severity(self : Finding) -> Severity {
  self.severity
}

///|
pub fn Finding::key(self : Finding) -> String {
  self.key
}

///|
pub fn Finding::message(self : Finding) -> String {
  self.message
}

///|
pub fn Finding::offset(self : Finding) -> Int {
  self.offset
}

///|
pub struct AuditPolicy {
  max_fields : Int
  max_value_length : Int
  flag_duplicate_keys : Bool
  flag_blank_values : Bool
  flag_flag_fields : Bool
  required_keys : Array[String]
} derive(Debug)

///|
pub fn AuditPolicy::default() -> AuditPolicy {
  {
    max_fields: 24,
    max_value_length: 120,
    flag_duplicate_keys: true,
    flag_blank_values: true,
    flag_flag_fields: true,
    required_keys: [],
  }
}

///|
pub fn AuditPolicy::ci() -> AuditPolicy {
  {
    max_fields: 16,
    max_value_length: 80,
    flag_duplicate_keys: true,
    flag_blank_values: true,
    flag_flag_fields: true,
    required_keys: ["level", "msg"],
  }
}

///|
pub fn AuditPolicy::relaxed() -> AuditPolicy {
  {
    max_fields: 48,
    max_value_length: 240,
    flag_duplicate_keys: true,
    flag_blank_values: false,
    flag_flag_fields: false,
    required_keys: [],
  }
}

///|
pub fn AuditPolicy::with_required_keys(
  self : AuditPolicy,
  keys : Array[String],
) -> AuditPolicy {
  {
    max_fields: self.max_fields,
    max_value_length: self.max_value_length,
    flag_duplicate_keys: self.flag_duplicate_keys,
    flag_blank_values: self.flag_blank_values,
    flag_flag_fields: self.flag_flag_fields,
    required_keys: keys,
  }
}

///|
pub struct AuditReport {
  parsed : ParseResult
  findings : Array[Finding]
} derive(Debug)

///|
pub fn AuditReport::parsed(self : AuditReport) -> ParseResult {
  self.parsed
}

///|
pub fn AuditReport::findings(self : AuditReport) -> Array[Finding] {
  self.findings
}

///|
pub fn AuditReport::finding_count(self : AuditReport) -> Int {
  self.findings.length()
}

///|
pub fn AuditReport::count_severity(
  self : AuditReport,
  severity : Severity,
) -> Int {
  let mut count = 0
  for finding in self.findings {
    if finding.severity() == severity {
      count = count + 1
    }
  }
  count
}

///|
pub fn AuditReport::critical_count(self : AuditReport) -> Int {
  self.count_severity(Critical)
}

///|
pub fn AuditReport::warning_count(self : AuditReport) -> Int {
  self.count_severity(Warning)
}

///|
pub fn AuditReport::info_count(self : AuditReport) -> Int {
  self.count_severity(Info)
}

///|
pub fn AuditReport::risk_score(self : AuditReport) -> Int {
  let mut score = 0
  for finding in self.findings {
    score = score + finding.severity().score()
  }
  score
}

///|
pub fn AuditReport::risk_level(self : AuditReport) -> String {
  let score = self.risk_score()
  if self.critical_count() > 0 || score >= 30 {
    "high"
  } else if score >= 10 {
    "medium"
  } else if score > 0 {
    "low"
  } else {
    "clean"
  }
}

///|
pub fn AuditReport::recommended_action(self : AuditReport) -> String {
  if self.critical_count() > 0 {
    "fix_before_release"
  } else if self.warning_count() > 0 {
    "review"
  } else {
    "accept"
  }
}

///|
pub fn AuditReport::text_report(self : AuditReport) -> String {
  let mut output = "MoonLogfmt Lens report\n"
  output = output + "fields: " + self.parsed.field_count().to_string() + "\n"
  output = output + "findings: " + self.finding_count().to_string() + "\n"
  output = output +
    "risk: " +
    self.risk_level() +
    " (score=" +
    self.risk_score().to_string() +
    ")\n"
  output = output + "recommendation: " + self.recommended_action() + "\n"
  if self.findings.length() == 0 {
    output + "\nNo findings."
  } else {
    output = output + "\nFindings:\n"
    for finding in self.findings {
      output = output +
        "- [" +
        finding.severity().label() +
        "] " +
        finding.kind().label()
      if finding.key() != "" {
        output = output + " key=" + finding.key()
      }
      output = output +
        " offset=" +
        finding.offset().to_string() +
        ": " +
        finding.message() +
        "\n"
    }
    output
  }
}

///|
pub fn AuditReport::json_report(self : AuditReport) -> String {
  let mut output = "{"
  output = output + "\"fields\":" + self.parsed.field_count().to_string() + ","
  output = output + "\"findings\":" + self.finding_count().to_string() + ","
  output = output + "\"risk_level\":\"" + escape_json(self.risk_level()) + "\","
  output = output + "\"risk_score\":" + self.risk_score().to_string() + ","
  output = output +
    "\"recommended_action\":\"" +
    escape_json(self.recommended_action()) +
    "\","
  output = output + "\"items\":["
  for index = 0; index < self.findings.length(); index = index + 1 {
    let finding = self.findings[index]
    if index > 0 {
      output = output + ","
    }
    output = output + "{"
    output = output +
      "\"kind\":\"" +
      escape_json(finding.kind().label()) +
      "\","
    output = output +
      "\"severity\":\"" +
      escape_json(finding.severity().label()) +
      "\","
    output = output + "\"key\":\"" + escape_json(finding.key()) + "\","
    output = output + "\"offset\":" + finding.offset().to_string() + ","
    output = output + "\"message\":\"" + escape_json(finding.message()) + "\""
    output = output + "}"
  }
  output + "]}"
}

///|
pub fn parse(line : String) -> ParseResult {
  let chars = line.to_array()
  let fields : Array[Field] = []
  let errors : Array[ParseError] = []
  let mut index = 0
  while index < chars.length() {
    while index < chars.length() && is_space(chars[index]) {
      index = index + 1
    }
    if index >= chars.length() {
      break
    }
    if chars[index] == '=' {
      errors.push({
        kind: UnexpectedEquals,
        message: "field cannot start with `=`",
        offset: index,
      })
      index = skip_token(chars, index + 1)
      continue
    }
    let key_start = index
    while index < chars.length() &&
          !is_space(chars[index]) &&
          chars[index] != '=' {
      index = index + 1
    }
    let key = String::from_array(chars[key_start:index])
    if key == "" {
      errors.push({
        kind: EmptyKey,
        message: "field key is empty",
        offset: key_start,
      })
      index = index + 1
      continue
    }
    if !valid_key(key) {
      errors.push({
        kind: InvalidKey,
        message: "invalid key `" + key + "`",
        offset: key_start,
      })
    }
    if index < chars.length() && chars[index] == '=' {
      index = index + 1
      if index < chars.length() && chars[index] == '"' {
        let value_start = index
        let step = parse_quoted(chars, index + 1)
        fields.push({
          key,
          value: step.value,
          quoted: true,
          flag: false,
          offset: key_start,
        })
        index = step.index
        if !step.ok {
          errors.push({
            kind: UnterminatedQuote,
            message: "quoted value is missing closing quote",
            offset: value_start,
          })
        }
      } else {
        let value_start = index
        while index < chars.length() && !is_space(chars[index]) {
          if chars[index] == '"' {
            errors.push({
              kind: BareQuote,
              message: "quote inside bare value should be escaped or quoted",
              offset: index,
            })
          }
          index = index + 1
        }
        fields.push({
          key,
          value: String::from_array(chars[value_start:index]),
          quoted: false,
          flag: false,
          offset: key_start,
        })
      }
    } else {
      fields.push({
        key,
        value: "true",
        quoted: false,
        flag: true,
        offset: key_start,
      })
    }
  }
  { source: line, fields, errors }
}

///|
pub fn is_valid(line : String) -> Bool {
  parse(line).is_valid()
}

///|
pub fn audit_line(line : String) -> AuditReport {
  audit_line_with_policy(line, AuditPolicy::default())
}

///|
pub fn audit_line_with_policy(
  line : String,
  policy : AuditPolicy,
) -> AuditReport {
  audit(parse(line), policy)
}

///|
pub fn audit(parsed : ParseResult, policy : AuditPolicy) -> AuditReport {
  let findings : Array[Finding] = []
  for err in parsed.errors() {
    findings.push(
      Finding::new(
        SyntaxError,
        Critical,
        "",
        err.message(),
        offset=err.offset(),
      ),
    )
  }
  if parsed.field_count() > policy.max_fields {
    findings.push(
      Finding::new(
        TooManyFields,
        Warning,
        "",
        "line has " +
        parsed.field_count().to_string() +
        " fields; configured limit is " +
        policy.max_fields.to_string(),
      ),
    )
  }
  for key in policy.required_keys {
    if !parsed.has_key(key) {
      findings.push(
        Finding::new(
          RequiredKeyMissing,
          Critical,
          key,
          "required key `" + key + "` is missing",
        ),
      )
    }
  }
  for index = 0; index < parsed.fields.length(); index = index + 1 {
    let field = parsed.fields[index]
    if policy.flag_duplicate_keys {
      for prev = 0; prev < index; prev = prev + 1 {
        if parsed.fields[prev].key() == field.key() {
          findings.push(
            Finding::new(
              DuplicateKey,
              Warning,
              field.key(),
              "key appears more than once; later values may hide earlier ones",
              offset=field.offset(),
            ),
          )
        }
      }
    }
    if field.value().to_array().length() > policy.max_value_length {
      findings.push(
        Finding::new(
          ValueTooLong,
          Warning,
          field.key(),
          "value length exceeds configured limit",
          offset=field.offset(),
        ),
      )
    }
    if policy.flag_blank_values && !field.is_flag() && field.value() == "" {
      findings.push(
        Finding::new(
          BlankValue,
          Warning,
          field.key(),
          "explicit blank value may be hard to distinguish from missing data",
          offset=field.offset(),
        ),
      )
    }
    if policy.flag_flag_fields && field.is_flag() {
      findings.push(
        Finding::new(
          FlagField,
          Info,
          field.key(),
          "flag field has no explicit value",
          offset=field.offset(),
        ),
      )
    }
    if has_control(field.value()) {
      findings.push(
        Finding::new(
          ControlCharacter,
          Critical,
          field.key(),
          "field value contains a control character",
          offset=field.offset(),
        ),
      )
    }
  }
  { parsed, findings }
}

///|
priv struct QuotedStep {
  ok : Bool
  index : Int
  value : String
}

///|
fn parse_quoted(chars : Array[Char], start : Int) -> QuotedStep {
  let output : Array[Char] = []
  let mut index = start
  while index < chars.length() {
    let char = chars[index]
    if char == '"' {
      return { ok: true, index: index + 1, value: String::from_array(output) }
    } else if char == '\\' && index + 1 < chars.length() {
      let next = chars[index + 1]
      if next == 'n' {
        output.push('\n')
      } else if next == 't' {
        output.push('\t')
      } else if next == 'r' {
        output.push('\r')
      } else {
        output.push(next)
      }
      index = index + 2
    } else {
      output.push(char)
      index = index + 1
    }
  }
  { ok: false, index, value: String::from_array(output) }
}

///|
fn skip_token(chars : Array[Char], start : Int) -> Int {
  let mut index = start
  while index < chars.length() && !is_space(chars[index]) {
    index = index + 1
  }
  index
}

///|
fn valid_key(key : String) -> Bool {
  let chars = key.to_array()
  if chars.length() == 0 {
    return false
  }
  for char in chars {
    if !is_key_char(char) {
      return false
    }
  }
  true
}

///|
fn is_key_char(char : Char) -> Bool {
  is_ascii_alnum(char) || char == '_' || char == '-' || char == '.'
}

///|
fn is_ascii_alnum(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9')
}

///|
fn is_space(char : Char) -> Bool {
  char == ' ' || char == '\t'
}

///|
fn needs_quote(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() == 0 {
    return true
  }
  for char in chars {
    if is_space(char) ||
      char == '"' ||
      char == '=' ||
      char == '\n' ||
      char == '\r' {
      return true
    }
  }
  false
}

///|
fn has_control(value : String) -> Bool {
  for char in value.to_array() {
    if char < ' ' && char != '\t' {
      return true
    }
  }
  false
}

///|
fn escape_logfmt(input : String) -> String {
  let output : Array[Char] = []
  for char in input.to_array() {
    if char == '"' {
      output.push('\\')
      output.push('"')
    } else if char == '\\' {
      output.push('\\')
      output.push('\\')
    } else if char == '\n' {
      output.push('\\')
      output.push('n')
    } else if char == '\r' {
      output.push('\\')
      output.push('r')
    } else if char == '\t' {
      output.push('\\')
      output.push('t')
    } else {
      output.push(char)
    }
  }
  String::from_array(output)
}

///|
fn escape_json(input : String) -> String {
  let output : Array[Char] = []
  for char in input.to_array() {
    if char == '"' {
      output.push('\\')
      output.push('"')
    } else if char == '\\' {
      output.push('\\')
      output.push('\\')
    } else if char == '\n' {
      output.push('\\')
      output.push('n')
    } else if char == '\r' {
      output.push('\\')
      output.push('r')
    } else if char == '\t' {
      output.push('\\')
      output.push('t')
    } else {
      output.push(char)
    }
  }
  String::from_array(output)
}
