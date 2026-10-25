///|
/// 100-nanosecond intervals between 1582-10-15, where version 1 and 6
/// timestamps start, and 1970-01-01.
pub let gregorian_offset : Int64 = 0x01b21dd213814000L

///|
/// A version 1 or 6 timestamp from nanoseconds since 1970.
pub fn ticks_of(unix_nanos : Int64) -> Int64 {
  unix_nanos / 100L + gregorian_offset
}

///|
/// Version and variant written over the bits they occupy.
fn stamp(hi : UInt64, lo : UInt64, version : Int32) -> Uuid {
  Uuid::of_parts(
    (hi & 0xFFFFFFFFFFFF0FFFUL) | (version.to_uint64() << 12),
    (lo & 0x3FFFFFFFFFFFFFFFUL) | 0x8000000000000000UL,
  )
}

///|
/// Time-based: a 60-bit timestamp from `ticks_of`, a 14-bit clock sequence
/// and a 48-bit node, laid out with the low time bits first.
pub fn v1(ticks~ : Int64, clock_seq~ : Int32, node~ : Int64) -> Uuid {
  let t = ticks.reinterpret_as_uint64()
  let hi = ((t & 0xFFFFFFFFUL) << 32) |
    (((t >> 32) & 0xFFFFUL) << 16) |
    ((t >> 48) & 0x0FFFUL)
  let lo = ((clock_seq.to_uint64() & 0x3FFFUL) << 48) |
    (node.reinterpret_as_uint64() & 0xFFFFFFFFFFFFUL)
  stamp(hi, lo, 1)
}

///|
/// Version 1's fields with the timestamp's high bits first, so the
/// identifiers sort in time order.
pub fn v6(ticks~ : Int64, clock_seq~ : Int32, node~ : Int64) -> Uuid {
  let t = ticks.reinterpret_as_uint64()
  let hi = (((t >> 12) & 0xFFFFFFFFFFFFUL) << 16) | (t & 0x0FFFUL)
  let lo = ((clock_seq.to_uint64() & 0x3FFFUL) << 48) |
    (node.reinterpret_as_uint64() & 0xFFFFFFFFFFFFUL)
  stamp(hi, lo, 6)
}

///|
fn of_digest(digest : Bytes, version : Int32) -> Uuid {
  let (hi, lo) = of16(digest[0:16]).parts()
  stamp(hi, lo, version)
}

///|
/// Name-based with MD5: the same namespace and name always give the same
/// identifier. The name is hashed as UTF-8.
pub fn v3(space : Uuid, name : StringView) -> Uuid {
  let h = @md5.Hasher::new()
  h.write(space.bytes())
  h.write(@utf8.encode(name))
  of_digest(h.finish(), 3)
}

///|
/// Name-based with SHA-1, preferred over version 3.
pub fn v5(space : Uuid, name : StringView) -> Uuid {
  let h = @sha1.Hasher::new()
  h.write(space.bytes())
  h.write(@utf8.encode(name))
  of_digest(h.finish(), 5)
}

///|
/// Random: 122 of the 16 bytes given are kept.
pub fn v4(random : BytesView) -> Uuid raise Refused {
  let id = Uuid::of_bytes(random)
  let (hi, lo) = id.parts()
  stamp(hi, lo, 4)
}

///|
/// Milliseconds since 1970 in the top 48 bits, then 74 bits from the 10
/// random bytes given: a 42-bit counter whose top bit starts clear, so a
/// generator can count up within a millisecond, and 32 random bits.
pub fn v7(millis~ : Int64, random : BytesView) -> Uuid raise Refused {
  if random.length() != 10 {
    raise Size(want=10, got=random.length())
  }
  let (counter, tail) = counter_and_tail(random)
  seven(millis.reinterpret_as_uint64(), counter, tail)
}

///|
/// The first six bytes as the counter, top bit clear; the last four as the
/// tail.
fn counter_and_tail(random : BytesView) -> (UInt64, UInt64) {
  let mut head = 0UL
  for i in 0..<6 {
    head = (head << 8) | random[i].to_uint64()
  }
  let mut tail = 0UL
  for i in 6..<10 {
    tail = (tail << 8) | random[i].to_uint64()
  }
  (head & 0x1FFFFFFFFFFUL, tail)
}

///|
/// Version 7 from its three parts: milliseconds, the 42-bit counter split
/// across the version and variant bits, and the 32-bit tail.
fn seven(millis : UInt64, counter : UInt64, tail : UInt64) -> Uuid {
  let hi = ((millis & 0xFFFFFFFFFFFFUL) << 16) | ((counter >> 30) & 0x0FFFUL)
  let lo = ((counter & 0x3FFFFFFFUL) << 32) | (tail & 0xFFFFFFFFUL)
  stamp(hi, lo, 7)
}

///|
/// Custom: 122 bits of the 16 bytes given, laid out as the caller likes;
/// only version and variant are written over.
pub fn v8(custom : BytesView) -> Uuid raise Refused {
  let id = Uuid::of_bytes(custom)
  let (hi, lo) = id.parts()
  stamp(hi, lo, 8)
}
