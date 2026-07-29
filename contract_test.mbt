///|
test "service contract accepts a conformant line" {
  let report = validate_contract(
    "level=info msg=\"service ready\" service=api duration=25ms status=200",
    LogContract::service(),
  )
  inspect(report.is_conformant(), content="true")
  inspect(report.decision(), content="accept")
}

///|
test "service contract reports missing required fields" {
  let report = validate_contract(
    "level=info service=api",
    LogContract::service(),
  )
  inspect(report.critical_count(), content="1")
  inspect(report.violations()[0].kind() == ContractMissingField, content="true")
  inspect(report.violations()[0].key(), content="msg")
}

///|
test "service contract validates allowed levels" {
  let report = validate_contract(
    "level=verbose msg=ready service=api",
    LogContract::service(),
  )
  inspect(report.critical_count(), content="1")
  inspect(
    report.violations()[0].kind() == ContractValueNotAllowed,
    content="true",
  )
}

///|
test "contract detects semantic type mismatch" {
  let contract = LogContract::new(
    "typed",
    [FieldRule::typed("status", ValueInteger, required=true)],
    unknown_fields=UnknownReject,
  )
  let report = validate_contract("status=ok", contract)
  inspect(report.critical_count(), content="1")
  inspect(report.violations()[0].kind() == ContractWrongType, content="true")
  inspect(report.violations()[0].actual(), content="identifier")
}

///|
test "decimal rule accepts integer values" {
  let contract = LogContract::new("numeric", [
    FieldRule::typed("load", ValueDecimal, required=true),
  ])
  inspect(validate_contract("load=2", contract).is_conformant(), content="true")
}

///|
test "unknown warn contract requests review" {
  let contract = LogContract::new(
    "known",
    [FieldRule::text("msg", required=true)],
    unknown_fields=UnknownWarn,
  )
  let report = validate_contract("msg=ready extra=value", contract)
  inspect(report.warning_count(), content="1")
  inspect(report.decision(), content="review")
}

///|
test "unknown reject contract blocks undeclared fields" {
  let contract = LogContract::new(
    "strict",
    [FieldRule::text("msg", required=true)],
    unknown_fields=UnknownReject,
  )
  let report = validate_contract("msg=ready extra=value", contract)
  inspect(report.critical_count(), content="1")
  inspect(report.decision(), content="reject")
}

///|
test "unknown allow contract ignores undeclared fields" {
  let contract = LogContract::new(
    "open",
    [FieldRule::text("msg", required=true)],
    unknown_fields=UnknownAllow,
  )
  inspect(
    validate_contract("msg=ready extra=value", contract).is_conformant(),
    content="true",
  )
}

///|
test "contract distinguishes blank values and flags" {
  let contract = LogContract::new("explicit", [
    FieldRule::text("msg"),
    FieldRule::typed("dry_run", ValueBoolean),
  ])
  let report = validate_contract("msg= dry_run", contract)
  inspect(report.critical_count(), content="2")
  inspect(
    report.violations()[0].kind() == ContractBlankDisallowed,
    content="true",
  )
  inspect(
    report.violations()[1].kind() == ContractFlagDisallowed,
    content="true",
  )
}

///|
test "contract can explicitly allow blank values and flags" {
  let contract = LogContract::new("permissive", [
    FieldRule::text("msg").with_blank(true),
    FieldRule::typed("dry_run", ValueBoolean).with_flag(true),
  ])
  inspect(
    validate_contract("msg= dry_run", contract).is_conformant(),
    content="true",
  )
}

///|
test "contract enforces field length" {
  let contract = LogContract::new("short", [
    FieldRule::text("msg", required=true).with_max_length(5),
  ])
  let report = validate_contract("msg=\"too long\"", contract)
  inspect(report.warning_count(), content="1")
  inspect(report.violations()[0].kind() == ContractValueTooLong, content="true")
}

///|
test "contract rejects duplicate fields" {
  let contract = LogContract::new("single", [
    FieldRule::text("msg", required=true),
  ])
  let report = validate_contract("msg=one msg=two", contract)
  inspect(report.critical_count(), content="1")
  inspect(
    report.violations()[0].kind() == ContractDuplicateField,
    content="true",
  )
}

///|
test "contract carries parser errors into the report" {
  let report = validate_contract(
    "msg=\"unterminated",
    LogContract::new("syntax", [FieldRule::text("msg")]),
  )
  inspect(report.critical_count(), content="1")
  inspect(report.violations()[0].kind() == ContractSyntaxError, content="true")
}

///|
test "contract enforces maximum field count" {
  let contract = LogContract::new(
    "tiny",
    [FieldRule::text("a"), FieldRule::text("b")],
    unknown_fields=UnknownAllow,
    max_fields=2,
  )
  let report = validate_contract("a=1 b=2 c=3", contract)
  inspect(report.critical_count(), content="1")
  inspect(report.violations()[0].kind() == ContractFieldLimit, content="true")
}

///|
test "contract report renders text and json" {
  let report = validate_contract(
    "level=info msg=ready service=api",
    LogContract::service(),
  )
  inspect(
    report.text_report().contains("contract: service-log"),
    content="true",
  )
  inspect(report.json_report().contains("\"conformant\":true"), content="true")
}

///|
test "schema inference discovers required typed fields" {
  let inference = infer_schema([
    "level=info status=200 duration=12ms", "level=warn status=503 duration=1.5s",
    "level=info status=201 duration=9ms",
  ])
  inspect(inference.valid_lines(), content="3")
  inspect(inference.invalid_lines(), content="0")
  match inference.profile_for("status") {
    Some(profile) => {
      inspect(profile.dominant_kind() == ValueInteger, content="true")
      inspect(profile.type_confidence(), content="100")
      inspect(profile.prevalence_percent(3), content="100")
    }
    None => fail("status profile should exist")
  }
  inspect(inference.contract().required_count(), content="3")
}

///|
test "schema inference skips malformed lines" {
  let inference = infer_schema([
    "level=info msg=ready", "level=warn msg=\"unterminated",
  ])
  inspect(inference.total_lines(), content="2")
  inspect(inference.valid_lines(), content="1")
  inspect(inference.invalid_lines(), content="1")
}

///|
test "schema inference falls back to text for mixed values" {
  let inference = infer_schema(
    ["value=1", "value=true", "value=worker"],
    policy=InferencePolicy::strict(),
  )
  match inference.profile_for("value") {
    Some(profile) => inspect(profile.type_confidence(), content="33")
    None => fail("value profile should exist")
  }
  inspect(
    inference.contract().rules()[0].expected_kind() == ValueText,
    content="true",
  )
}

///|
test "schema inference preserves small identifier vocabulary" {
  let inference = infer_schema([
    "level=info", "level=warn", "level=info", "level=error",
  ])
  let rule = inference.contract().rules()[0]
  inspect(rule.allowed_values().length(), content="3")
  inspect(rule.allowed_values().contains("warn"), content="true")
}

///|
test "inferred contract validates a compatible future line" {
  let inference = infer_schema([
    "level=info status=200", "level=warn status=500",
  ])
  let report = validate_contract("level=info status=201", inference.contract())
  inspect(report.is_conformant(), content="true")
}
