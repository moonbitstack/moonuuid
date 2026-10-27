///|
/// The bridge the documentation site imports in the browser. Every function
/// takes and returns plain JavaScript strings, so the page never has to know
/// how MoonBit lays its values out. `describe` is the one entry point: it
/// answers with a JSON object of fields, and every generator routes through
/// it, so a generated identifier and a pasted one describe themselves the
/// same way.
///
/// The clock is the host's `Date.now`, the randomness the host's
/// `crypto.getRandomValues`; nothing here is seeded, so the page shows the
/// same behaviour a real caller would get.

///|
/// Nanoseconds since 1970 from the host clock. `Int64` is a `BigInt` on this
/// backend, so the multiplication stays exact.
extern "js" fn now_nanos() -> Int64 =
  #| () => BigInt(Date.now()) * 1000000n

///|
/// `n` random bytes from the host's cryptographic source.
extern "js" fn host_random(n : Int32) -> Bytes =
  #| (n) => { const b = new Uint8Array(n); globalThis.crypto.getRandomValues(b); return b; }

///|
/// One generator for the page, over the host clock and randomness. Versions 1
/// and 6 keep their own last timestamp, version 7 counts within a
/// millisecond.
let gen : @moonuuid.Generator = @moonuuid.Generator::new(
  clock=() => now_nanos(),
  random=n => host_random(n),
)

///|
/// A JSON string literal for `s`, quoting and escaping as needed.
fn q(s : StringView) -> String {
  let out = StringBuilder()
  out.write_char('"')
  for c in s.iter() {
    if c == '"' {
      out.write_string("\\\"")
    } else if c == '\\' {
      out.write_string("\\\\")
    } else if c == '\n' {
      out.write_string("\\n")
    } else if c == '\r' {
      out.write_string("\\r")
    } else if c == '\t' {
      out.write_string("\\t")
    } else if c.to_int() < 0x20 {
      out.write_string("\\u00")
      out.write_string(c.to_int().to_string())
    } else {
      out.write_char(c)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
/// Whether the fields hold a timestamp worth reading, and in what unit:
/// `ticks` for the 100-nanosecond intervals of versions 1 and 6, `millis` for
/// version 7, `none` otherwise.
fn time_field(id : @moonuuid.Uuid) -> (String, String) {
  match id.version() {
    Some(1) => (q(id.time().to_string()), q("ticks"))
    Some(6) => (q(id.time().to_string()), q("ticks"))
    Some(7) => (q(id.time().to_string()), q("millis"))
    _ => ("null", q("none"))
  }
}

///|
/// The variant as the name it is written with.
fn variant_name(id : @moonuuid.Uuid) -> String {
  match id.variant() {
    @moonuuid.Ncs => "Ncs"
    @moonuuid.Rfc => "Rfc"
    @moonuuid.Microsoft => "Microsoft"
    @moonuuid.Future => "Future"
  }
}

///|
/// Every field of `id` as JSON. `time` is a string because the tick count
/// outgrows the exact range of a JavaScript number; `node` and the two halves
/// are hexadecimal; `bytes` is the 16 octets in order.
fn describe_json(id : @moonuuid.Uuid) -> String {
  let hex = id.hex()
  let (time_json, kind_json) = time_field(id)
  let version_json = match id.version() {
    Some(v) => v.to_string()
    None => "null"
  }
  let bs = StringBuilder()
  bs.write_char('[')
  let bytes = id.bytes()
  for i in 0..<16 {
    if i > 0 {
      bs.write_char(',')
    }
    bs.write_string(bytes[i].to_int().to_string())
  }
  bs.write_char(']')
  "{\"ok\":true" +
  ",\"uuid\":" +
  q(id.to_string()) +
  ",\"hex\":" +
  q(hex) +
  ",\"urn\":" +
  q(id.urn()) +
  ",\"version\":" +
  version_json +
  ",\"variant\":" +
  q(variant_name(id)) +
  ",\"time\":" +
  time_json +
  ",\"timeKind\":" +
  kind_json +
  ",\"clockSeq\":" +
  id.clock_seq().to_string() +
  ",\"node\":" +
  q(hex[20:32]) +
  ",\"bytes\":" +
  bs.to_string() +
  ",\"hi\":" +
  q(hex[0:16]) +
  ",\"lo\":" +
  q(hex[16:32]) +
  "}"
}

///|
/// A refusal as JSON, so the page can show why a string or a byte count did
/// not make an identifier.
fn refused_json(e : @moonuuid.Refused) -> String {
  "{\"ok\":false,\"error\":" + q(e.to_string()) + "}"
}

///|
/// Read any spelling and describe it.
#export_name("describe")
pub fn describe(text : String) -> String {
  describe_json(@moonuuid.parse(text)) catch {
    e => refused_json(e)
  }
}

///|
/// Version 1 from the host clock and a fixed node.
#export_name("make_v1")
pub fn make_v1() -> String {
  describe_json(gen.v1(node=0x001A2B3C4D5EL, clock_seq=0x2A3B)) catch {
    e => refused_json(e)
  }
}

///|
/// Version 3 from a namespace and a name.
#export_name("make_v3")
pub fn make_v3(space : String, name : String) -> String {
  describe_json(@moonuuid.v3(@moonuuid.parse(space), name)) catch {
    e => refused_json(e)
  }
}

///|
/// Version 4 from the host's randomness.
#export_name("make_v4")
pub fn make_v4() -> String {
  describe_json(gen.v4()) catch {
    e => refused_json(e)
  }
}

///|
/// Version 5 from a namespace and a name.
#export_name("make_v5")
pub fn make_v5(space : String, name : String) -> String {
  describe_json(@moonuuid.v5(@moonuuid.parse(space), name)) catch {
    e => refused_json(e)
  }
}

///|
/// Version 6 from the host clock and a fixed node.
#export_name("make_v6")
pub fn make_v6() -> String {
  describe_json(gen.v6(node=0x001A2B3C4D5EL, clock_seq=0x2A3B)) catch {
    e => refused_json(e)
  }
}

///|
/// Version 7 from the host clock and randomness.
#export_name("make_v7")
pub fn make_v7() -> String {
  describe_json(gen.v7()) catch {
    e => refused_json(e)
  }
}

///|
/// Version 8 from 16 random bytes, version and variant written over.
#export_name("make_v8")
pub fn make_v8() -> String {
  describe_json(@moonuuid.v8(host_random(16))) catch {
    e => refused_json(e)
  }
}
