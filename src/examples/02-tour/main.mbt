///|
/// A tour of the surface: read text, write it back, look at the fields, make
/// identifiers from a clock and a random source, and see what a refusal says.
/// The clock and the random source are fixed so every line prints the same
/// values on every machine.
fn main raise {
  // Reading: one canonical string.
  let id = @moonuuid.parse("c232ab00-9414-11ec-b3c8-9f6bdeced846")
  println("-- read --")
  println(id)

  // Every spelling the parser accepts.
  println("-- spellings --")
  for
    text in [
      "c232ab00-9414-11ec-b3c8-9f6bdeced846", "C232AB00941411ECB3C89F6BDECED846",
      "{C232AB00-9414-11EC-B3C8-9F6BDECED846}", "urn:uuid:c232ab00-9414-11ec-b3c8-9f6bdeced846",
    ] {
    println(@moonuuid.parse(text))
  }

  // Writing: three spellings out.
  println("-- write --")
  println(id.to_string())
  println(id.hex())
  println(id.urn())

  // Fields.
  println("-- fields --")
  match id.version() {
    Some(v) => println("Some(\{v})")
    None => println("None")
  }
  println(id.variant())
  println(id.time())
  println(id.clock_seq())
  println(id.node())

  // A generator over a fixed clock and a counting random source.
  let gen = @moonuuid.Generator::new(clock=() => 1_761_350_400_000_000_000L, random=n => {
    Bytes::makei(n, i => (i * 37 + 11).to_byte())
  })
  println("-- v4 --")
  println(gen.v4())
  println("-- v7 --")
  for _ in 0..<3 {
    println(gen.v7())
  }

  // Version 1 and 6 from a timestamp in 100-nanosecond ticks.
  let ticks = @moonuuid.ticks_of(1_761_350_400_000_000_000L)
  println("-- v1 --")
  let v1 = @moonuuid.v1(ticks~, clock_seq=0x2A3B, node=0x001A2B3C4D5EL)
  println(v1)
  println("-- v6 --")
  let v6 = @moonuuid.v6(ticks~, clock_seq=0x2A3B, node=0x001A2B3C4D5EL)
  println(v6)

  // Name-based: the same namespace and name always give the same id.
  println("-- v5 --")
  println(@moonuuid.v5(@moonuuid.namespace_url, "https://example.org/"))
  println(@moonuuid.v5(@moonuuid.namespace_dns, "李雷"))

  // Custom layout: sixteen bytes of your own.
  println("-- v8 --")
  try {
    let custom = Bytes::makei(16, i => (i * 17 + 3).to_byte())
    println(@moonuuid.v8(custom))
  } catch {
    e => println(e)
  }

  // Refusals.
  println("-- errors --")
  ignore(@moonuuid.parse("not-a-uuid")) catch {
    e => println(e)
  }
  ignore(@moonuuid.v4(Bytes::make(3, 0))) catch {
    e => println(e)
  }

  // JSON: text out, text back.
  println("-- json --")
  try {
    let j = Json(id)
    println(j.stringify())
    let back : @moonuuid.Uuid = @json.from_json(j)
    println(back)
  } catch {
    e => println(e)
  }
}
