///|
/// Semantic value families recognized by MoonLogfmt Lens.
///
/// The classifier is intentionally deterministic and dependency-free. It does
/// not try to replace a full date, network, or identity parser. Its purpose is
/// to give contract inference and drift analysis a stable vocabulary.
pub(all) enum ValueKind {
  ValueFlag
  ValueEmpty
  ValueBoolean
  ValueInteger
  ValueDecimal
  ValueDuration
  ValueByteSize
  ValueTimestamp
  ValueIPv4
  ValueUuid
  ValueEmail
  ValueHex
  ValueIdentifier
  ValueText
} derive(Eq, Debug)

///|
pub fn ValueKind::label(self : ValueKind) -> String {
  match self {
    ValueFlag => "flag"
    ValueEmpty => "empty"
    ValueBoolean => "boolean"
    ValueInteger => "integer"
    ValueDecimal => "decimal"
    ValueDuration => "duration"
    ValueByteSize => "byte_size"
    ValueTimestamp => "timestamp"
    ValueIPv4 => "ipv4"
    ValueUuid => "uuid"
    ValueEmail => "email"
    ValueHex => "hex"
    ValueIdentifier => "identifier"
    ValueText => "text"
  }
}

///|
/// Returns true when values of `actual` are accepted by a rule for `expected`.
///
/// Integer values are accepted by decimal rules, while every value can be
/// represented as text. Empty and flag values remain explicit so callers can
/// decide whether they are allowed.
pub fn ValueKind::accepts(self : ValueKind, actual : ValueKind) -> Bool {
  if self == actual {
    true
  } else {
    match self {
      ValueDecimal => actual == ValueInteger
      ValueText => actual != ValueFlag
      _ => false
    }
  }
}

///|
/// A compact distribution of value kinds.
pub struct ValueDistribution {
  flag_count : Int
  empty_count : Int
  boolean_count : Int
  integer_count : Int
  decimal_count : Int
  duration_count : Int
  byte_size_count : Int
  timestamp_count : Int
  ipv4_count : Int
  uuid_count : Int
  email_count : Int
  hex_count : Int
  identifier_count : Int
  text_count : Int
} derive(Eq, Debug)

///|
pub fn ValueDistribution::empty() -> ValueDistribution {
  {
    flag_count: 0,
    empty_count: 0,
    boolean_count: 0,
    integer_count: 0,
    decimal_count: 0,
    duration_count: 0,
    byte_size_count: 0,
    timestamp_count: 0,
    ipv4_count: 0,
    uuid_count: 0,
    email_count: 0,
    hex_count: 0,
    identifier_count: 0,
    text_count: 0,
  }
}

///|
pub fn ValueDistribution::total(self : ValueDistribution) -> Int {
  self.flag_count +
  self.empty_count +
  self.boolean_count +
  self.integer_count +
  self.decimal_count +
  self.duration_count +
  self.byte_size_count +
  self.timestamp_count +
  self.ipv4_count +
  self.uuid_count +
  self.email_count +
  self.hex_count +
  self.identifier_count +
  self.text_count
}

///|
pub fn ValueDistribution::count(
  self : ValueDistribution,
  kind : ValueKind,
) -> Int {
  match kind {
    ValueFlag => self.flag_count
    ValueEmpty => self.empty_count
    ValueBoolean => self.boolean_count
    ValueInteger => self.integer_count
    ValueDecimal => self.decimal_count
    ValueDuration => self.duration_count
    ValueByteSize => self.byte_size_count
    ValueTimestamp => self.timestamp_count
    ValueIPv4 => self.ipv4_count
    ValueUuid => self.uuid_count
    ValueEmail => self.email_count
    ValueHex => self.hex_count
    ValueIdentifier => self.identifier_count
    ValueText => self.text_count
  }
}

///|
pub fn ValueDistribution::with_kind(
  self : ValueDistribution,
  kind : ValueKind,
) -> ValueDistribution {
  let flag_delta = if kind == ValueFlag { 1 } else { 0 }
  let empty_delta = if kind == ValueEmpty { 1 } else { 0 }
  let boolean_delta = if kind == ValueBoolean { 1 } else { 0 }
  let integer_delta = if kind == ValueInteger { 1 } else { 0 }
  let decimal_delta = if kind == ValueDecimal { 1 } else { 0 }
  let duration_delta = if kind == ValueDuration { 1 } else { 0 }
  let byte_size_delta = if kind == ValueByteSize { 1 } else { 0 }
  let timestamp_delta = if kind == ValueTimestamp { 1 } else { 0 }
  let ipv4_delta = if kind == ValueIPv4 { 1 } else { 0 }
  let uuid_delta = if kind == ValueUuid { 1 } else { 0 }
  let email_delta = if kind == ValueEmail { 1 } else { 0 }
  let hex_delta = if kind == ValueHex { 1 } else { 0 }
  let identifier_delta = if kind == ValueIdentifier { 1 } else { 0 }
  let text_delta = if kind == ValueText { 1 } else { 0 }
  {
    flag_count: self.flag_count + flag_delta,
    empty_count: self.empty_count + empty_delta,
    boolean_count: self.boolean_count + boolean_delta,
    integer_count: self.integer_count + integer_delta,
    decimal_count: self.decimal_count + decimal_delta,
    duration_count: self.duration_count + duration_delta,
    byte_size_count: self.byte_size_count + byte_size_delta,
    timestamp_count: self.timestamp_count + timestamp_delta,
    ipv4_count: self.ipv4_count + ipv4_delta,
    uuid_count: self.uuid_count + uuid_delta,
    email_count: self.email_count + email_delta,
    hex_count: self.hex_count + hex_delta,
    identifier_count: self.identifier_count + identifier_delta,
    text_count: self.text_count + text_delta,
  }
}

///|
pub fn ValueDistribution::dominant_kind(self : ValueDistribution) -> ValueKind {
  let order = [
    ValueFlag,
    ValueEmpty,
    ValueBoolean,
    ValueInteger,
    ValueDecimal,
    ValueDuration,
    ValueByteSize,
    ValueTimestamp,
    ValueIPv4,
    ValueUuid,
    ValueEmail,
    ValueHex,
    ValueIdentifier,
    ValueText,
  ]
  let mut best = ValueText
  let mut best_count = -1
  for kind in order {
    let count = self.count(kind)
    if count > best_count {
      best = kind
      best_count = count
    }
  }
  best
}

///|
pub fn ValueDistribution::dominant_percent(self : ValueDistribution) -> Int {
  if self.total() == 0 {
    0
  } else {
    self.count(self.dominant_kind()) * 100 / self.total()
  }
}

///|
pub fn ValueDistribution::distinct_kind_count(self : ValueDistribution) -> Int {
  let order = [
    ValueFlag,
    ValueEmpty,
    ValueBoolean,
    ValueInteger,
    ValueDecimal,
    ValueDuration,
    ValueByteSize,
    ValueTimestamp,
    ValueIPv4,
    ValueUuid,
    ValueEmail,
    ValueHex,
    ValueIdentifier,
    ValueText,
  ]
  let mut count = 0
  for kind in order {
    if self.count(kind) > 0 {
      count = count + 1
    }
  }
  count
}

///|
pub fn ValueDistribution::summary(self : ValueDistribution) -> String {
  let parts : Array[String] = []
  let order = [
    ValueFlag,
    ValueEmpty,
    ValueBoolean,
    ValueInteger,
    ValueDecimal,
    ValueDuration,
    ValueByteSize,
    ValueTimestamp,
    ValueIPv4,
    ValueUuid,
    ValueEmail,
    ValueHex,
    ValueIdentifier,
    ValueText,
  ]
  for kind in order {
    let count = self.count(kind)
    if count > 0 {
      parts.push(kind.label() + "=" + count.to_string())
    }
  }
  parts.join(",")
}

///|
/// Classifies a parsed field while preserving the distinction between an
/// implicit flag and an explicit boolean value.
pub fn classify_field(field : Field) -> ValueKind {
  if field.is_flag() {
    ValueFlag
  } else {
    classify_value(field.value())
  }
}

///|
/// Classifies one logfmt value using a stable, ordered set of recognizers.
pub fn classify_value(value : String) -> ValueKind {
  if value == "" {
    ValueEmpty
  } else if profile_is_boolean(value) {
    ValueBoolean
  } else if profile_is_integer(value) {
    ValueInteger
  } else if profile_is_decimal(value) {
    ValueDecimal
  } else if profile_is_duration(value) {
    ValueDuration
  } else if profile_is_byte_size(value) {
    ValueByteSize
  } else if profile_is_timestamp(value) {
    ValueTimestamp
  } else if profile_is_ipv4(value) {
    ValueIPv4
  } else if profile_is_uuid(value) {
    ValueUuid
  } else if profile_is_email(value) {
    ValueEmail
  } else if profile_is_hex(value) {
    ValueHex
  } else if profile_is_identifier(value) {
    ValueIdentifier
  } else {
    ValueText
  }
}

///|
pub fn profile_values(values : Array[String]) -> ValueDistribution {
  let mut distribution = ValueDistribution::empty()
  for value in values {
    distribution = distribution.with_kind(classify_value(value))
  }
  distribution
}

///|
fn profile_ascii_lower(input : String) -> String {
  let output : Array[Char] = []
  for char in input.to_array() {
    if char >= 'A' && char <= 'Z' {
      output.push((char.to_int() + 32).unsafe_to_char())
    } else {
      output.push(char)
    }
  }
  String::from_array(output)
}

///|
fn profile_is_boolean(value : String) -> Bool {
  let lower = profile_ascii_lower(value)
  lower == "true" ||
  lower == "false" ||
  lower == "yes" ||
  lower == "no" ||
  lower == "on" ||
  lower == "off"
}

///|
fn profile_is_integer(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() == 0 {
    return false
  }
  let mut index = 0
  if chars[0] == '+' || chars[0] == '-' {
    if chars.length() == 1 {
      return false
    }
    index = 1
  }
  while index < chars.length() {
    if !profile_is_digit(chars[index]) {
      return false
    }
    index = index + 1
  }
  true
}

///|
fn profile_is_decimal(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() < 3 {
    return false
  }
  let mut index = 0
  if chars[0] == '+' || chars[0] == '-' {
    index = 1
  }
  let mut dots = 0
  let mut digits_before = 0
  let mut digits_after = 0
  while index < chars.length() {
    let char = chars[index]
    if char == '.' {
      dots = dots + 1
      if dots > 1 {
        return false
      }
    } else if profile_is_digit(char) {
      if dots == 0 {
        digits_before = digits_before + 1
      } else {
        digits_after = digits_after + 1
      }
    } else {
      return false
    }
    index = index + 1
  }
  dots == 1 && digits_before > 0 && digits_after > 0
}

///|
fn profile_is_duration(value : String) -> Bool {
  let lower = profile_ascii_lower(value)
  let suffixes = ["ns", "us", "ms", "s", "m", "h", "d"]
  for suffix in suffixes {
    if profile_has_suffix(lower, suffix) {
      let chars = lower.to_array()
      let suffix_length = suffix.to_array().length()
      let number = String::from_array(chars[0:chars.length() - suffix_length])
      return profile_is_integer(number) || profile_is_decimal(number)
    }
  }
  false
}

///|
fn profile_is_byte_size(value : String) -> Bool {
  let lower = profile_ascii_lower(value)
  let suffixes = ["kib", "mib", "gib", "tib", "kb", "mb", "gb", "tb", "b"]
  for suffix in suffixes {
    if profile_has_suffix(lower, suffix) {
      let chars = lower.to_array()
      let suffix_length = suffix.to_array().length()
      let number = String::from_array(chars[0:chars.length() - suffix_length])
      return profile_is_integer(number) || profile_is_decimal(number)
    }
  }
  false
}

///|
fn profile_is_timestamp(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() < 10 {
    return false
  }
  if chars[4] != '-' || chars[7] != '-' {
    return false
  }
  let digit_positions = [0, 1, 2, 3, 5, 6, 8, 9]
  for position in digit_positions {
    if !profile_is_digit(chars[position]) {
      return false
    }
  }
  if chars.length() == 10 {
    return true
  }
  if chars.length() < 16 || (chars[10] != 'T' && chars[10] != ' ') {
    return false
  }
  profile_is_digit(chars[11]) &&
  profile_is_digit(chars[12]) &&
  chars[13] == ':' &&
  profile_is_digit(chars[14]) &&
  profile_is_digit(chars[15])
}

///|
fn profile_is_ipv4(value : String) -> Bool {
  let chars = value.to_array()
  let mut groups = 0
  let mut digits = 0
  let mut number = 0
  for char in chars {
    if profile_is_digit(char) {
      digits = digits + 1
      if digits > 3 {
        return false
      }
      number = number * 10 + char.to_int() - '0'.to_int()
      if number > 255 {
        return false
      }
    } else if char == '.' {
      if digits == 0 {
        return false
      }
      groups = groups + 1
      digits = 0
      number = 0
    } else {
      return false
    }
  }
  groups == 3 && digits > 0
}

///|
fn profile_is_uuid(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() != 36 {
    return false
  }
  for index = 0; index < chars.length(); index = index + 1 {
    if index == 8 || index == 13 || index == 18 || index == 23 {
      if chars[index] != '-' {
        return false
      }
    } else if !profile_is_hex_digit(chars[index]) {
      return false
    }
  }
  true
}

///|
fn profile_is_email(value : String) -> Bool {
  let chars = value.to_array()
  let mut at = -1
  let mut dot_after = false
  for index = 0; index < chars.length(); index = index + 1 {
    let char = chars[index]
    if char == '@' {
      if at >= 0 || index == 0 || index == chars.length() - 1 {
        return false
      }
      at = index
    } else if char == '.' && at >= 0 && index > at + 1 {
      dot_after = true
    } else if is_space(char) {
      return false
    }
  }
  at > 0 && dot_after
}

///|
fn profile_is_hex(value : String) -> Bool {
  let chars = value.to_array()
  let mut start = 0
  if chars.length() >= 3 &&
    (profile_has_prefix(value, "0x") || profile_has_prefix(value, "0X")) {
    start = 2
  } else if chars.length() < 8 {
    return false
  }
  if start >= chars.length() {
    return false
  }
  for index = start; index < chars.length(); index = index + 1 {
    if !profile_is_hex_digit(chars[index]) {
      return false
    }
  }
  true
}

///|
fn profile_is_identifier(value : String) -> Bool {
  let chars = value.to_array()
  if chars.length() == 0 {
    return false
  }
  let mut has_letter = false
  for char in chars {
    if (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') {
      has_letter = true
    } else if !profile_is_digit(char) &&
      char != '_' &&
      char != '-' &&
      char != '.' &&
      char != '/' &&
      char != ':' {
      return false
    }
  }
  has_letter
}

///|
fn profile_is_digit(char : Char) -> Bool {
  char >= '0' && char <= '9'
}

///|
fn profile_is_hex_digit(char : Char) -> Bool {
  profile_is_digit(char) ||
  (char >= 'a' && char <= 'f') ||
  (char >= 'A' && char <= 'F')
}

///|
fn profile_has_prefix(value : String, prefix : String) -> Bool {
  let chars = value.to_array()
  let prefix_chars = prefix.to_array()
  if prefix_chars.length() > chars.length() {
    return false
  }
  for index = 0; index < prefix_chars.length(); index = index + 1 {
    if chars[index] != prefix_chars[index] {
      return false
    }
  }
  true
}

///|
fn profile_has_suffix(value : String, suffix : String) -> Bool {
  let chars = value.to_array()
  let suffix_chars = suffix.to_array()
  if suffix_chars.length() > chars.length() {
    return false
  }
  let start = chars.length() - suffix_chars.length()
  for index = 0; index < suffix_chars.length(); index = index + 1 {
    if chars[start + index] != suffix_chars[index] {
      return false
    }
  }
  true
}
