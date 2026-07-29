///|
test "privacy scanner redacts secret keys" {
  let result = redact_line("level=info api_token=supersecret msg=ready")
  inspect(result.finding_count(), content="1")
  inspect(result.redacted_count(), content="1")
  inspect(result.findings()[0].kind() == SensitiveCredential, content="true")
  inspect(result.safe_line().contains("supersecret"), content="false")
  inspect(result.safe_line().contains("[REDACTED]"), content="true")
}

///|
test "privacy scanner redacts password fields as secrets" {
  let result = redact_line("username=alice password=hunter2")
  inspect(result.finding_count(), content="2")
  inspect(result.findings()[1].kind() == SensitiveSecret, content="true")
  inspect(result.critical_count(), content="1")
}

///|
test "privacy scanner recognizes email values without sensitive keys" {
  let result = redact_line("contact=developer@example.com event=signup")
  inspect(result.finding_count(), content="1")
  inspect(result.findings()[0].kind() == SensitivePersonal, content="true")
  inspect(result.safe_line().contains("developer@example.com"), content="false")
}

///|
test "privacy scanner recognizes bearer values" {
  let result = redact_line("header=\"Bearer abcdefghijklmnopqrstuvwxyz123456\"")
  inspect(result.finding_count(), content="1")
  inspect(result.findings()[0].kind() == SensitiveCredential, content="true")
}

///|
test "privacy scanner recognizes provider key prefixes" {
  let result = redact_line("value=ghp_ABCdef0123456789XYZxyz987654321")
  inspect(result.finding_count(), content="1")
  inspect(result.decision(), content="sanitize")
}

///|
test "privacy scanner recognizes jwt-shaped values" {
  let result = redact_line("assertion=abcdefghij.klmnopqrst.uvwxyz123456")
  inspect(result.finding_count(), content="1")
  inspect(
    result.findings()[0].reason().contains("three-segment"),
    content="true",
  )
}

///|
test "privacy scanner validates payment card checksum" {
  let result = redact_line("candidate=\"4242 4242 4242 4242\"")
  inspect(result.finding_count(), content="1")
  inspect(result.findings()[0].kind() == SensitivePayment, content="true")
}

///|
test "privacy scanner ignores invalid payment checksum" {
  let result = redact_line("candidate=\"4242 4242 4242 4241\"")
  inspect(result.finding_count(), content="0")
}

///|
test "privacy scanner recognizes formatted phone numbers" {
  let result = redact_line("contact=\"+1 (415) 555-2671\"")
  inspect(result.finding_count(), content="1")
  inspect(result.findings()[0].kind() == SensitivePersonal, content="true")
}

///|
test "default privacy policy does not redact ordinary ipv4 values" {
  let result = redact_line("peer=10.0.0.8")
  inspect(result.finding_count(), content="0")
}

///|
test "strict privacy policy redacts ipv4 values" {
  let result = redact_line("peer=10.0.0.8", policy=RedactionPolicy::strict())
  inspect(result.finding_count(), content="1")
  inspect(result.findings()[0].kind() == SensitiveNetwork, content="true")
}

///|
test "allow list suppresses an intentional sensitive key" {
  let policy = RedactionPolicy::default().with_allow_keys(["session"])
  let result = redact_line("session=public-demo", policy~)
  inspect(result.finding_count(), content="0")
  inspect(result.safe_line(), content="session=public-demo")
}

///|
test "key-only policy disables value heuristics" {
  let result = redact_line(
    "contact=developer@example.com",
    policy=RedactionPolicy::key_only(),
  )
  inspect(result.finding_count(), content="0")
}

///|
test "keep-last-four mode preserves only a suffix" {
  let policy = RedactionPolicy::default().with_mode(RedactKeepLastFour)
  let result = redact_line("api_token=abcdefghijklmnop", policy~)
  inspect(result.safe_line().contains("lmnop"), content="false")
  inspect(result.safe_line().contains("***mnop"), content="true")
}

///|
test "stable-token mode is deterministic" {
  let policy = RedactionPolicy::strict()
  let first = redact_line("token=abcdefghijk", policy~)
  let second = redact_line("token=abcdefghijk", policy~)
  let third = redact_line("token=different-value", policy~)
  inspect(first.safe_line() == second.safe_line(), content="true")
  inspect(first.safe_line() == third.safe_line(), content="false")
}

///|
test "privacy result deduplicates redacted key inventory" {
  let result = redact_line("token=one token=two")
  inspect(result.finding_count(), content="2")
  inspect(result.redacted_count(), content="1")
}

///|
test "privacy report never includes original sensitive value" {
  let result = redact_line("password=TOP-SECRET-VALUE")
  inspect(result.text_report().contains("TOP-SECRET-VALUE"), content="false")
  inspect(result.json_report().contains("TOP-SECRET-VALUE"), content="false")
  inspect(
    result.json_report().contains("\"decision\":\"sanitize\""),
    content="true",
  )
}

///|
test "privacy scanner preserves safe quoted fields" {
  let result = redact_line("msg=\"service ready\" level=info")
  inspect(result.finding_count(), content="0")
  inspect(result.safe_line(), content="msg=\"service ready\" level=info")
}

///|
test "privacy scanner preserves safe flags" {
  let result = redact_line("level=info dry_run")
  inspect(result.finding_count(), content="0")
  inspect(result.safe_line(), content="level=info dry_run")
}

///|
test "high entropy detector catches mixed generated secrets" {
  let result = redact_line("opaque=aB3_defGHIjklMNOpqrSTUvwxYZ987654")
  inspect(result.finding_count(), content="1")
  inspect(result.findings()[0].kind() == SensitiveCredential, content="true")
}
