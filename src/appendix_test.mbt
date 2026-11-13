///|
test "RFC 9562 appendix A.3" {
  // The appendix starts from these 16 random bytes and lets the version and
  // variant bits overwrite what they land on.
  let random = @moonuuid.parse("919108f752d133205bacf847db4148a8")
  assert_eq(random.hex(), "919108f752d133205bacf847db4148a8")
  let id = @moonuuid.v4(random.bytes())
  assert_eq(id.to_string(), "919108f7-52d1-4320-9bac-f847db4148a8")
  assert_eq(id.version(), Some(4))
  assert_eq(id.variant(), @moonuuid.Rfc)
  assert_eq(id.hex(), "919108f752d143209bacf847db4148a8")
}

///|
test "RFC 9562 appendix A.6, field by field" {
  let id = @moonuuid.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
  assert_eq(id.time(), 0x017F22E279B0L)
  assert_eq(id.version(), Some(7))
  assert_eq(id.variant(), @moonuuid.Rfc)
  assert_eq(id.hex(), "017f22e279b07cc398c4dc0c0c07398f")
  assert_eq(id.urn(), "urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
}

///|
test "RFC 9562 appendix A.1, field by field" {
  let id = @moonuuid.parse("C232AB00-9414-11EC-B3C8-9F6BDECED846")
  assert_eq(id.time(), 0x1EC9414C232AB00L)
  assert_eq(id.clock_seq(), 0x33C8)
  assert_eq(id.node(), 0x9F6BDECED846L)
  assert_eq(@moonuuid.ticks_of(1_645_557_742_000_000_000L), id.time())
}
