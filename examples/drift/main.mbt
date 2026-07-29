///|
fn main {
  let baseline = @lens.analyze_batch([
    "level=info msg=ready service=api status=200 duration=12ms", "level=warn msg=slow service=api status=503 duration=80ms",
    "level=error msg=failed service=worker status=500 duration=150ms",
  ])
  let current = @lens.analyze_batch([
    "level=info msg=ready service=api status=ok region=us", "level=warn msg=slow service=api status=degraded region=eu",
    "level=error msg=failed service=worker status=failed region=us", "level=warn msg=\"unterminated",
  ])
  let drift = @lens.compare_batches(
    baseline,
    current,
    policy=@lens.DriftPolicy::ci(),
  )
  println(drift.text_report())
}
