///|
test "a counter that runs out moves to the next millisecond" {
  let gen = Generator::new(
    clock=() => 5_000_000L,
    random=@moonrand.Replay::new(Bytes::make(32, b'\x00')),
  )
  ignore(gen.v7())
  gen.last_counter = 0x3FFFFFFFFFFUL
  let id = gen.v7()
  assert_eq(id.time(), 6L)
  assert_eq(gen.last_counter, 0UL)
}
