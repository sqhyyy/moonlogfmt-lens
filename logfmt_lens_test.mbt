///|
test "parses basic key value fields" {
  let parsed = parse("level=info msg=started request_id=abc123")
  inspect(parsed.is_valid(), content="true")
  inspect(parsed.field_count(), content="3")
  inspect(parsed.get("level"), content="info")
  inspect(parsed.get("msg"), content="started")
  inspect(
    parsed.normalized(),
    content="level=info msg=started request_id=abc123",
  )
}

///|
test "parses quoted values with spaces" {
  let parsed = parse("level=error msg=\"disk full\" path=/var/log")
  inspect(parsed.is_valid(), content="true")
  inspect(parsed.get("msg"), content="disk full")
  inspect(parsed.fields()[1].quoted(), content="true")
  inspect(
    parsed.normalized(),
    content="level=error msg=\"disk full\" path=/var/log",
  )
}

///|
test "unescapes quoted values" {
  let parsed = parse("msg=\"line\\nnext\" quote=\"a\\\"b\"")
  inspect(parsed.is_valid(), content="true")
  inspect(parsed.get("msg").contains("\n"), content="true")
  inspect(parsed.get("quote"), content="a\"b")
  inspect(parsed.normalized(), content="msg=\"line\\nnext\" quote=\"a\\\"b\"")
}

///|
test "supports flag fields" {
  let parsed = parse("level=info dry_run msg=ok")
  inspect(parsed.is_valid(), content="true")
  inspect(parsed.fields()[1].is_flag(), content="true")
  inspect(parsed.get("dry_run"), content="true")
}

///|
test "reports unexpected equals" {
  let parsed = parse("=broken level=info")
  inspect(parsed.is_valid(), content="false")
  inspect(parsed.error_count(), content="1")
  inspect(parsed.errors()[0].kind() == UnexpectedEquals, content="true")
}

///|
test "reports unterminated quotes" {
  let parsed = parse("level=info msg=\"still open")
  inspect(parsed.is_valid(), content="false")
  inspect(parsed.errors()[0].kind() == UnterminatedQuote, content="true")
}

///|
test "reports invalid key characters" {
  let parsed = parse("bad/key=value good_key=ok")
  inspect(parsed.is_valid(), content="false")
  inspect(parsed.errors()[0].kind() == InvalidKey, content="true")
}

///|
test "audits duplicate keys" {
  let report = audit_line("level=info msg=one msg=two")
  inspect(report.warning_count(), content="1")
  inspect(report.findings()[0].kind() == DuplicateKey, content="true")
  inspect(report.recommended_action(), content="review")
}

///|
test "ci policy requires level and msg" {
  let report = audit_line_with_policy("event=boot", AuditPolicy::ci())
  inspect(report.critical_count(), content="2")
  inspect(report.risk_level(), content="high")
  inspect(report.recommended_action(), content="fix_before_release")
}

///|
test "audits blank values and flags" {
  let report = audit_line("level=info msg= ready")
  inspect(report.warning_count(), content="1")
  inspect(report.info_count(), content="1")
}

///|
test "accepts ordinary short lines" {
  let report = audit_line_with_policy(
    "a=1 b=2 c=3",
    AuditPolicy::default().with_required_keys([]),
  )
  inspect(report.finding_count(), content="0")
}

///|
test "audits value length with ci policy" {
  let report = audit_line_with_policy(
    "level=info msg=abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabc",
    AuditPolicy::ci(),
  )
  inspect(report.warning_count(), content="1")
  inspect(report.findings()[0].kind() == ValueTooLong, content="true")
}

///|
test "detects control characters" {
  let report = audit_line("level=info msg=\"bad\\nline\"")
  inspect(report.critical_count(), content="1")
  inspect(report.findings()[0].kind() == ControlCharacter, content="true")
}

///|
test "builds text and json reports" {
  let report = audit_line("level=info msg=ok")
  inspect(
    report.text_report().contains("MoonLogfmt Lens report"),
    content="true",
  )
  inspect(
    report.json_report().contains("\"risk_level\":\"clean\""),
    content="true",
  )
}

///|
test "custom required keys can pass" {
  let policy = AuditPolicy::relaxed().with_required_keys(["service"])
  let report = audit_line_with_policy("service=api msg=ready", policy)
  inspect(report.critical_count(), content="0")
}

///|
test "summary describes parse result" {
  let parsed = parse("level=info msg=ok")
  inspect(parsed.summary(), content="fields=2 errors=0")
}
