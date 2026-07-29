///|
fn usage() -> String {
  (
    #|MoonLogfmt Lens
    #|
    #|Usage:
    #|  moon run cmd/main -- audit <logfmt line>
    #|  moon run cmd/main -- contract <logfmt line>
    #|  moon run cmd/main -- privacy <logfmt line>
    #|  moon run cmd/main -- profile <logfmt line>
    #|  moon run cmd/main -- template <logfmt line>
    #|
    #|Examples:
    #|  moon run cmd/main -- audit level=info msg="service ready"
    #|  moon run cmd/main -- contract level=info msg=ready service=api
    #|  moon run cmd/main -- privacy level=info api_token=secret
    #|
    #|For compatibility, omitting the mode runs `audit`.
  )
}

///|
fn join_args_from(args : Array[String], start : Int) -> String {
  let parts : Array[String] = []
  for index = start; index < args.length(); index = index + 1 {
    parts.push(args[index])
  }
  parts.join(" ")
}

///|
fn run_audit(line : String) -> Unit {
  let parsed = @lens.parse(line)
  println(parsed.summary())
  if parsed.is_valid() {
    println("normalized: " + parsed.normalized())
  } else {
    for err in parsed.errors() {
      println(
        "parse_error: " +
        err.kind().label() +
        " offset=" +
        err.offset().to_string() +
        " " +
        err.message(),
      )
    }
  }
  println("")
  println(@lens.audit(parsed, @lens.AuditPolicy::ci()).text_report())
}

///|
fn run_contract(line : String) -> Unit {
  let report = @lens.validate_contract(line, @lens.LogContract::service())
  println(report.text_report())
}

///|
fn run_privacy(line : String) -> Unit {
  let report = @lens.redact_line(line, policy=@lens.RedactionPolicy::strict())
  println(report.text_report())
}

///|
fn run_profile(line : String) -> Unit {
  let parsed = @lens.parse(line)
  println(parsed.summary())
  for field in parsed.fields() {
    println(
      field.key() +
      ": " +
      @lens.classify_field(field).label() +
      " length=" +
      field.value().to_array().length().to_string(),
    )
  }
}

///|
fn run_template(line : String) -> Unit {
  println("template: " + @lens.structural_template(line))
  let shape = @lens.structural_shape(@lens.parse(line))
  println("shape: " + shape)
  println("fingerprint: " + @lens.shape_fingerprint(shape))
}

///|
fn main {
  let args = @env.args()
  if args.length() <= 1 || args[1] == "--help" || args[1] == "-h" {
    println(usage())
    return
  }
  let known_mode = args[1] == "audit" ||
    args[1] == "contract" ||
    args[1] == "privacy" ||
    args[1] == "profile" ||
    args[1] == "template"
  let mode = if known_mode { args[1] } else { "audit" }
  let start = if known_mode { 2 } else { 1 }
  if args.length() <= start {
    println(usage())
    return
  }
  let line = join_args_from(args, start)
  match mode {
    "contract" => run_contract(line)
    "privacy" => run_privacy(line)
    "profile" => run_profile(line)
    "template" => run_template(line)
    _ => run_audit(line)
  }
}
