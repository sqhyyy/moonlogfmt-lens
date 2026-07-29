///|
fn main {
  let line = "level=info msg=\"service ready\" service=api request_id=req-42"
  let parsed = @lens.parse(line)
  println("input: " + line)
  println("valid: \{parsed.is_valid()}")
  println("service: " + parsed.get("service"))
  println("normalized: " + parsed.normalized())
}
