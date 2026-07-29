///|
test "value classifier recognizes booleans" {
  inspect(classify_value("true") == ValueBoolean, content="true")
  inspect(classify_value("FALSE") == ValueBoolean, content="true")
  inspect(classify_value("yes") == ValueBoolean, content="true")
  inspect(classify_value("off") == ValueBoolean, content="true")
}

///|
test "value classifier recognizes integers and decimals" {
  inspect(classify_value("42") == ValueInteger, content="true")
  inspect(classify_value("-17") == ValueInteger, content="true")
  inspect(classify_value("+8") == ValueInteger, content="true")
  inspect(classify_value("3.14") == ValueDecimal, content="true")
  inspect(classify_value("-0.25") == ValueDecimal, content="true")
}

///|
test "value classifier rejects malformed numbers" {
  inspect(classify_value("-") == ValueText, content="true")
  inspect(classify_value("1.2.3") == ValueText, content="true")
  inspect(classify_value(".5") == ValueText, content="true")
}

///|
test "value classifier recognizes duration units" {
  inspect(classify_value("25ms") == ValueDuration, content="true")
  inspect(classify_value("1.5s") == ValueDuration, content="true")
  inspect(classify_value("12h") == ValueDuration, content="true")
  inspect(classify_value("900us") == ValueDuration, content="true")
}

///|
test "value classifier recognizes byte sizes" {
  inspect(classify_value("512B") == ValueByteSize, content="true")
  inspect(classify_value("2MiB") == ValueByteSize, content="true")
  inspect(classify_value("1.5gb") == ValueByteSize, content="true")
}

///|
test "value classifier recognizes timestamps" {
  inspect(classify_value("2026-07-29") == ValueTimestamp, content="true")
  inspect(
    classify_value("2026-07-29T12:30:00Z") == ValueTimestamp,
    content="true",
  )
  inspect(classify_value("2026-07-29 12:30") == ValueTimestamp, content="true")
}

///|
test "value classifier recognizes ipv4 values" {
  inspect(classify_value("127.0.0.1") == ValueIPv4, content="true")
  inspect(classify_value("255.255.255.255") == ValueIPv4, content="true")
  inspect(classify_value("256.1.1.1") == ValueText, content="true")
  inspect(classify_value("10.1.1") == ValueText, content="true")
}

///|
test "value classifier recognizes uuid values" {
  inspect(
    classify_value("550e8400-e29b-41d4-a716-446655440000") == ValueUuid,
    content="true",
  )
  inspect(
    classify_value("550e8400-e29b-41d4-a716") == ValueIdentifier,
    content="true",
  )
}

///|
test "value classifier recognizes email values" {
  inspect(classify_value("developer@example.com") == ValueEmail, content="true")
  inspect(classify_value("developer@example") == ValueText, content="true")
}

///|
test "value classifier recognizes hexadecimal values" {
  inspect(classify_value("0xdeadbeef") == ValueHex, content="true")
  inspect(classify_value("abcdef123456") == ValueHex, content="true")
  inspect(classify_value("abc123") == ValueIdentifier, content="true")
}

///|
test "value classifier separates identifiers and text" {
  inspect(classify_value("api-worker") == ValueIdentifier, content="true")
  inspect(classify_value("/health/live") == ValueIdentifier, content="true")
  inspect(classify_value("service ready") == ValueText, content="true")
  inspect(classify_value("") == ValueEmpty, content="true")
}

///|
test "classify field preserves implicit flags" {
  let parsed = parse("dry_run enabled=true")
  inspect(classify_field(parsed.fields()[0]) == ValueFlag, content="true")
  inspect(classify_field(parsed.fields()[1]) == ValueBoolean, content="true")
}

///|
test "value kind compatibility is intentionally asymmetric" {
  let decimal : ValueKind = ValueDecimal
  let integer : ValueKind = ValueInteger
  let text : ValueKind = ValueText
  inspect(decimal.accepts(ValueInteger), content="true")
  inspect(integer.accepts(ValueDecimal), content="false")
  inspect(text.accepts(ValueUuid), content="true")
  inspect(text.accepts(ValueFlag), content="false")
}

///|
test "distribution tracks dominant kind" {
  let distribution = profile_values(["1", "2", "3", "4.5", ""])
  inspect(distribution.total(), content="5")
  inspect(distribution.count(ValueInteger), content="3")
  inspect(distribution.count(ValueDecimal), content="1")
  inspect(distribution.count(ValueEmpty), content="1")
  inspect(distribution.dominant_kind() == ValueInteger, content="true")
  inspect(distribution.dominant_percent(), content="60")
}

///|
test "distribution reports mixed kinds" {
  let distribution = profile_values(["true", "false", "worker", "ready now"])
  inspect(distribution.distinct_kind_count(), content="3")
  inspect(distribution.summary().contains("boolean=2"), content="true")
  inspect(distribution.summary().contains("identifier=1"), content="true")
  inspect(distribution.summary().contains("text=1"), content="true")
}
