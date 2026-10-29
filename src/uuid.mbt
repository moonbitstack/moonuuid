///|
/// A 128-bit identifier as RFC 9562 lays it out. Compared, hashed and
/// ordered by its bytes, so a sorted list of time-ordered ids is in time
/// order.
pub struct Uuid {
  priv hi : UInt64
  priv lo : UInt64
} derive(Eq, Compare, Hash, Debug)

///|
pub extend Uuid with Eq::{equal, not_equal}

///|
pub extend Uuid with Compare::{compare, op_lt, op_le, op_ge, op_gt}

///|
pub extend Uuid with Hash::{hash, hash_combine}

///|
pub extend Uuid with Debug::{to_repr}

///|
/// Why text or bytes are not a UUID.
pub(all) suberror Refused {
  /// Text that is not 32 hexadecimal digits once braces, hyphens and the
  /// `urn:uuid:` prefix are set aside; `at` is the offending character.
  Malformed(at~ : Int32, reason~ : String)
  /// Bytes of the wrong length.
  Size(want~ : Int32, got~ : Int32)
  /// The generator's random source could not give what an identifier needs.
  Random(@moonrand.Unavailable)
} derive(Eq, Debug)

///|
pub extend Refused with Eq::{equal, not_equal}

///|
pub extend Refused with Debug::{to_repr}

///|
pub impl Show for Refused with fn output(self, logger) {
  logger.write_string(
    match self {
      Malformed(at~, reason~) => "\{reason} at \{at}"
      Size(want~, got~) => "\{want} bytes wanted, \{got} given"
      Random(why) => "no randomness: \{why}"
    },
  )
}

///|
pub extend Refused with Show::{output, to_string}

///|
/// Who an identifier's variant bits say it belongs to.
pub(all) enum Variant {
  /// Reserved for NCS backward compatibility.
  Ncs
  /// RFC 9562, the variant every version here writes.
  Rfc
  /// Reserved for Microsoft backward compatibility.
  Microsoft
  /// Reserved for future definition.
  Future
} derive(Eq, Debug)

///|
pub extend Variant with Eq::{equal, not_equal}

///|
pub extend Variant with Debug::{to_repr}

///|
pub impl Show for Variant with fn output(self, logger) {
  logger.write_string(
    match self {
      Ncs => "Ncs"
      Rfc => "Rfc"
      Microsoft => "Microsoft"
      Future => "Future"
    },
  )
}

///|
pub extend Variant with Show::{output, to_string}

///|
/// The identifier from its high and low 64 bits.
pub fn Uuid::of_parts(hi : UInt64, lo : UInt64) -> Uuid {
  { hi, lo, }
}

///|
/// The high and low 64 bits.
pub fn Uuid::parts(self : Uuid) -> (UInt64, UInt64) {
  (self.hi, self.lo)
}

///|
/// The identifier from its 16 bytes, most significant first.
pub fn Uuid::of_bytes(bytes : BytesView) -> Uuid raise Refused {
  if bytes.length() != 16 {
    raise Size(want=16, got=bytes.length())
  }
  of16(bytes)
}

///|
fn of16(bytes : BytesView) -> Uuid {
  let mut hi = 0UL
  let mut lo = 0UL
  for i in 0..<8 {
    hi = (hi << 8) | bytes[i].to_uint64()
    lo = (lo << 8) | bytes[i + 8].to_uint64()
  }
  { hi, lo, }
}

///|
/// The 16 bytes, most significant first.
pub fn Uuid::bytes(self : Uuid) -> Bytes {
  Bytes::makei(16, i => {
    let word = if i < 8 { self.hi } else { self.lo }
    (word >> (8 * (7 - i % 8))).to_byte()
  })
}

///|
let hex_digits : String = "0123456789abcdef"

///|
/// The 32 hexadecimal digits, lowercase, without hyphens.
pub fn Uuid::hex(self : Uuid) -> String {
  let out = StringBuilder()
  for word in [self.hi, self.lo] {
    for shift = 60; shift >= 0; shift = shift - 4 {
      out.write_char(
        hex_digits[((word >> shift) & 0xFUL).to_int()].unsafe_to_char(),
      )
    }
  }
  out.to_string()
}

///|
/// `urn:uuid:` and the canonical text, as RFC 9562 names an identifier.
pub fn Uuid::urn(self : Uuid) -> String {
  "urn:uuid:" + self.to_string()
}

///|
/// The canonical text: 8-4-4-4-12 lowercase hexadecimal digits.
pub impl Show for Uuid with fn output(self, logger) {
  let h = self.hex()
  logger.write_string(
    "\{h[0:8]}-\{h[8:12]}-\{h[12:16]}-\{h[16:20]}-\{h[20:32]}",
  )
}

///|
pub extend Uuid with Show::{output, to_string}

///|
fn hex_value(c : Char) -> Int32? {
  match c {
    '0'..<='9' => Some(c.to_int() - '0'.to_int())
    'a'..<='f' => Some(c.to_int() - 'a'.to_int() + 10)
    'A'..<='F' => Some(c.to_int() - 'A'.to_int() + 10)
    _ => None
  }
}

///|
/// Text in any of the spellings in use: canonical, with or without
/// hyphens, in braces, with the `urn:uuid:` prefix; any case.
pub fn parse(text : StringView) -> Uuid raise Refused {
  let chars = text.iter().collect()
  let mut start = 0
  let mut end = chars.length()
  for prefix in ["urn:", "uuid:"] {
    if end - start >= prefix.length() &&
      String::from_array(chars[start:start + prefix.length()]).to_lower() ==
      prefix {
      start += prefix.length()
    }
  }
  while start < end && chars[start] == '{' {
    start += 1
  }
  while end > start && chars[end - 1] == '}' {
    end -= 1
  }
  let mut hi = 0UL
  let mut lo = 0UL
  let mut digits = 0
  for i in start..<end {
    let c = chars[i]
    if c == '-' {
      continue
    }
    guard hex_value(c) is Some(v) else {
      raise Malformed(
        at=i,
        reason="\{c.to_string().escape()} is not a hexadecimal digit",
      )
    }
    if digits >= 32 {
      raise Malformed(at=i, reason="more than 32 hexadecimal digits")
    }
    if digits < 16 {
      hi = (hi << 4) | v.to_uint64()
    } else {
      lo = (lo << 4) | v.to_uint64()
    }
    digits += 1
  }
  if digits != 32 {
    raise Malformed(at=end, reason="\{digits} hexadecimal digits, not 32")
  }
  { hi, lo, }
}

///|
/// The variant its bits name.
pub fn Uuid::variant(self : Uuid) -> Variant {
  let bits = self.lo >> 61
  if (bits & 0b100UL) == 0UL {
    Ncs
  } else if (bits & 0b010UL) == 0UL {
    Rfc
  } else if (bits & 0b001UL) == 0UL {
    Microsoft
  } else {
    Future
  }
}

///|
/// The version, 1 to 8 for the ones RFC 9562 defines; `None` when the
/// variant is not RFC 9562's, where the version bits mean nothing.
pub fn Uuid::version(self : Uuid) -> Int32? {
  if self.variant() == Rfc {
    Some(((self.hi >> 12) & 0xFUL).to_int())
  } else {
    None
  }
}

///|
/// The timestamp the fields hold: 100-nanosecond intervals since
/// 1582-10-15 for versions 1 and 6, milliseconds since 1970 for version 7,
/// the version 1 reading of the fields otherwise.
pub fn Uuid::time(self : Uuid) -> Int64 {
  let time_mid = (self.hi >> 16) & 0xFFFFUL
  let t = match self.version() {
    Some(6) => (self.hi >> 32 << 28) | (time_mid << 12) | (self.hi & 0xFFFUL)
    Some(7) => self.hi >> 16
    _ => ((self.hi & 0xFFFUL) << 48) | (time_mid << 32) | (self.hi >> 32)
  }
  t.reinterpret_as_int64()
}

///|
/// The 14-bit clock sequence of versions 1 and 6.
pub fn Uuid::clock_seq(self : Uuid) -> Int32 {
  ((self.lo >> 48) & 0x3FFFUL).to_int()
}

///|
/// The 48-bit node of versions 1 and 6.
pub fn Uuid::node(self : Uuid) -> Int64 {
  (self.lo & 0xFFFFFFFFFFFFUL).reinterpret_as_int64()
}

///|
/// The nil identifier, all zeros.
pub let nil : Uuid = { hi: 0UL, lo: 0UL, }

///|
/// The max identifier, all ones.
pub let max : Uuid = { hi: 0xFFFFFFFFFFFFFFFFUL, lo: 0xFFFFFFFFFFFFFFFFUL, }

///|
/// The namespaces RFC 9562 assigns for names that are domain names, URLs,
/// ISO OIDs and X.500 distinguished names.
pub let namespace_dns : Uuid = {
  hi: 0x6ba7b8109dad11d1UL,
  lo: 0x80b400c04fd430c8UL,
}

///|
pub let namespace_url : Uuid = {
  hi: 0x6ba7b8119dad11d1UL,
  lo: 0x80b400c04fd430c8UL,
}

///|
pub let namespace_oid : Uuid = {
  hi: 0x6ba7b8129dad11d1UL,
  lo: 0x80b400c04fd430c8UL,
}

///|
pub let namespace_x500 : Uuid = {
  hi: 0x6ba7b8149dad11d1UL,
  lo: 0x80b400c04fd430c8UL,
}

///|
/// The canonical text.
pub impl ToJson for Uuid with fn to_json(self) {
  Json::string(self.to_string())
}

///|
/// Any spelling `parse` reads.
pub impl @json.FromJson for Uuid with fn from_json(json, path) {
  guard json is String(text) else {
    raise @json.JsonDecodeError((path, "a UUID is written as text"))
  }
  parse(text) catch {
    e => raise @json.JsonDecodeError((path, e.to_string()))
  }
}

///|
pub extend Uuid with ToJson::{to_json}

///|
pub extend Uuid with @json.FromJson::{from_json}
