///|
fn main {
  let source =
    #|level=info msg="user login" email=developer@example.com
    #| api_token=ghp_ABCdef0123456789XYZxyz987654321 peer=10.0.0.8
  let policy = @lens.RedactionPolicy::strict()
  let result = @lens.redact_line(source, policy~)
  println(result.text_report())
  println("")
  println(result.json_report())
}
