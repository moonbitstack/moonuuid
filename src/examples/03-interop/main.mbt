///|
/// This library's side of a cross-check with other implementations of
/// RFC 9562, in tab-separated lines that any of them can print and any of
/// them can read:
///
/// - `make` writes one `label<TAB>identifier` line per identifier it makes
///   from a fixed input, so two runs print the same lines.
/// - `now` writes the ones it makes from the clock, which differ per run.
/// - `read <text>...` writes one line per text:
///   `text<TAB>canonical<TAB>version<TAB>variant<TAB>time<TAB>clock
///   sequence<TAB>node<TAB>hex<TAB>urn`, with `-` where the version
///   carries no such field and `!` when the text is refused.
///
/// Time is 100-nanosecond intervals since 1582 for versions 1 and 6 and
/// milliseconds since 1970 for version 7. Run it with no argument to see
/// what this library makes.
fn main raise {
  let args = @env.args()
  // The first argument is the program itself, not the mode.
  let given = if args.length() > 1 { args[1:] } else { [] }
  let mode = if given.length() > 0 { given[0] } else { "make" }
  match mode {
    "read" => given[1:].each(text => println(describe(text)))
    "now" => made_now().each(line => println(line))
    _ => made().each(line => println(line))
  }
}

///|
/// One line per identifier, labelled by what made it.
fn made() -> Array[String] raise {
  let ticks = 0x1EC9414C232AB00L
  let counting = Bytes::makei(16, i => i.to_byte())
  let rows = [
    ("v1-rfc", @moonuuid.v1(ticks~, clock_seq=0x33C8, node=0x9F6BDECED846L)),
    ("v6-rfc", @moonuuid.v6(ticks~, clock_seq=0x33C8, node=0x9F6BDECED846L)),
    ("v3-dns-www", @moonuuid.v3(@moonuuid.namespace_dns, "www.example.com")),
    ("v5-dns-www", @moonuuid.v5(@moonuuid.namespace_dns, "www.example.com")),
    (
      "v5-url-example",
      @moonuuid.v5(@moonuuid.namespace_url, "https://example.org/"),
    ),
    ("v4-zero", @moonuuid.v4(Bytes::make(16, 0))),
    ("v4-count", @moonuuid.v4(counting)),
    ("v7-fixed", @moonuuid.v7(millis=0x017F22E279B0L, counting[:10])),
    ("v8-count", @moonuuid.v8(counting)),
  ]
  labelled(rows)
}

///|
/// The identifiers a generator makes from a clock and a fixed random source:
/// the same clock readings every run, so the sequence is the same too, but
/// the millisecond is not the one an `make` line carries.
fn made_now() -> Array[String] raise {
  let gen = @moonuuid.Generator::new(
    clock=() => 1_761_350_400_000_000_000L,
    random=@moonseed.Replay::new(Bytes::makei(64, i => (i * 37 + 11).to_byte())),
  )
  labelled([
    ("gen-v1", gen.v1(node=0x001A2B3C4D5EL)),
    ("gen-v6", gen.v6(node=0x001A2B3C4D5EL)),
    ("gen-v4", gen.v4()),
    ("gen-v7-0", gen.v7()),
    ("gen-v7-1", gen.v7()),
    ("gen-v7-2", gen.v7()),
  ])
}

///|
fn labelled(rows : Array[(String, @moonuuid.Uuid)]) -> Array[String] {
  let out : Array[String] = []
  for (tag, id) in rows {
    out.push(tag + "\t" + id.to_string())
  }
  out
}

///|
/// What one text says, in the line format above.
fn describe(text : String) -> String {
  let id = @moonuuid.parse(text) catch { _ => return "\{text}\t!" }
  let version = id.version()
  let variant = match id.variant() {
    Ncs => "Ncs"
    Rfc => "Rfc"
    Microsoft => "Microsoft"
    Future => "Future"
  }
  let timed = match version {
    Some(1) | Some(6) | Some(7) => true
    _ => false
  }
  let fielded = match version {
    Some(1) | Some(6) => true
    _ => false
  }
  [
    text,
    id.to_string(),
    match version {
      Some(v) => v.to_string()
      None => "-"
    },
    variant,
    if timed {
      id.time().to_string()
    } else {
      "-"
    },
    if fielded {
      id.clock_seq().to_string()
    } else {
      "-"
    },
    if fielded {
      id.node().to_string()
    } else {
      "-"
    },
    id.hex(),
    id.urn(),
  ].join("\t")
}
