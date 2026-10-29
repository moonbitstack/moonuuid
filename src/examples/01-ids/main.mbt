///|
/// A clock and a random source stand in for the host's: a server would pass
/// its real time and its system randomness.
fn main {
  let now = Ref(1_761_350_400_000_000_000L)
  let seed = Ref(7)
  let stream = Bytes::makei(256, i => {
    seed.val = (seed.val * 1103515245 + 12345) & 0x7FFFFFFF
    (seed.val >> (i % 3 * 8)).to_byte()
  })
  let gen = @moonuuid.Generator::new(
    clock=() => {
      now.val += 400_000L
      now.val
    },
    random=@moonrand.Replay::new(stream),
  )
  try {
    println("v7, in the order made:")
    for _ in 0..<4 {
      println("  \{gen.v7()}")
    }
    let name = @moonuuid.v5(
      @moonuuid.namespace_url, "https://moonbitstack.github.io/moonuuid/",
    )
    println("v5 of a URL: \{name}, version \{name.version().unwrap()}")
    let id = @moonuuid.parse("{C232AB00-9414-11EC-B3C8-9F6BDECED846}")
    println("parsed: \{id}  time \{id.time()}  node \{id.node()}")
    println("as JSON: \{Json(id).stringify()}")
  } catch {
    e => println("refused: \{e}")
  }
}
