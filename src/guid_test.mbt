///|
test "the GUID byte order swaps the first three fields" {
  let id = @moonuuid.parse("{C232AB00-9414-11EC-B3C8-9F6BDECED846}")
  let le = id.bytes_le()
  assert_eq(le.length(), 16)
  assert_eq(le[0], b'\x00')
  assert_eq(le[1], b'\xAB')
  assert_eq(le[2], b'\x32')
  assert_eq(le[3], b'\xC2')
  assert_eq(le[4], b'\x14')
  assert_eq(le[5], b'\x94')
  assert_eq(le[6], b'\xEC')
  assert_eq(le[7], b'\x11')
  assert_eq(le[8], b'\xB3')
  assert_eq(le[15], b'\x46')
  assert_eq(
    le, b"\x00\xab\x32\xc2\x14\x94\xec\x11\xb3\xc8\x9f\x6b\xde\xce\xd8\x46",
  )
}

///|
test "the little-endian form reads back" {
  let id = @moonuuid.parse("c232ab00-9414-11ec-b3c8-9f6bdeced846")
  assert_eq(@moonuuid.Uuid::of_bytes_le(id.bytes_le()), id)
  assert_false(@moonuuid.Uuid::of_bytes_le(id.bytes()) == id)
  assert_eq(
    @moonuuid.Uuid::of_bytes_le(
      b"\x00\xab\x32\xc2\x14\x94\xec\x11\xb3\xc8\x9f\x6b\xde\xce\xd8\x46",
    ),
    id,
  )
}

///|
test "the two byte orders agree on the tail" {
  let id = @moonuuid.namespace_dns
  let be = id.bytes()
  let le = id.bytes_le()
  for i in 8..<16 {
    assert_eq(le[i], be[i])
  }
  assert_eq(be[0], b'\x6B')
  assert_eq(le[0], b'\x10')
}

///|
test "sixteen bytes or nothing" {
  let short = try {
    ignore(@moonuuid.Uuid::of_bytes_le(b"\x01\x02\x03"))
    "made"
  } catch {
    e => e.to_string()
  }
  assert_eq(short, "16 bytes wanted, 3 given")
}

///|
test "the little-endian form of nil and max" {
  assert_eq(@moonuuid.nil.bytes_le(), Bytes::make(16, 0))
  assert_eq(@moonuuid.max.bytes_le(), Bytes::make(16, b'\xFF'))
  assert_eq(@moonuuid.Uuid::of_bytes_le(Bytes::make(16, 0)), @moonuuid.nil)
}
