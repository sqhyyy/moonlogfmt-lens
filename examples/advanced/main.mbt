///|
fn main {
  let lines = [
    "level=info msg=started service=api status=200 duration=12ms", "level=warn msg=slow service=api status=503 duration=1.5s",
    "level=error msg=failed service=worker status=500 duration=80ms",
  ]
  let batch = @lens.analyze_batch(lines, policy=@lens.BatchPolicy::ci())
  println(batch.text_report())
  println("")
  let contract = @lens.contract_from_batch(
    batch,
    name="observed-service-v1",
    unknown_fields=@lens.UnknownReject,
  )
  println(contract.describe())
  println(
    @lens.validate_contract(
      "level=info msg=healthy service=api status=204 duration=9ms", contract,
    ).text_report(),
  )
}
