///|
test "the two fixed identifiers recognise themselves" {
  assert_true(@moonuuid.nil.is_nil())
  assert_false(@moonuuid.nil.is_max())
  assert_true(@moonuuid.max.is_max())
  assert_false(@moonuuid.max.is_nil())
  assert_false(@moonuuid.namespace_dns.is_nil())
  assert_false(@moonuuid.namespace_dns.is_max())
  let almost = @moonuuid.parse("00000000-0000-0000-0000-000000000001")
  assert_false(almost.is_nil())
  assert_false(almost.is_max())
}
