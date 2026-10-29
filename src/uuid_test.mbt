///|
test "RFC 9562 appendix A" {
  let ticks = 0x1EC9414C232AB00L
  assert_eq(
    @moonuuid.v1(ticks~, clock_seq=0x33C8, node=0x9F6BDECED846L).to_string(),
    "c232ab00-9414-11ec-b3c8-9f6bdeced846",
  )
  assert_eq(
    @moonuuid.v6(ticks~, clock_seq=0x33C8, node=0x9F6BDECED846L).to_string(),
    "1ec9414c-232a-6b00-b3c8-9f6bdeced846",
  )
  assert_eq(
    @moonuuid.v3(@moonuuid.namespace_dns, "www.example.com").to_string(),
    "5df41881-3aed-3515-88a7-2f4a814cf09e",
  )
  assert_eq(
    @moonuuid.v5(@moonuuid.namespace_dns, "www.example.com").to_string(),
    "2ed6657d-e927-568b-95e1-2665a8aea6a2",
  )
  let seven = @moonuuid.parse("017F22E2-79B0-7CC3-98C4-DC0C0C07398F")
  assert_eq(seven.version(), Some(7))
  assert_eq(seven.time(), 0x017F22E279B0L)
  assert_eq(
    @moonuuid.parse("1ec9414c-232a-6b00-b3c8-9f6bdeced846").time(),
    ticks,
  )
}

///|
test "nil, max and the namespaces" {
  assert_eq(@moonuuid.nil.to_string(), "00000000-0000-0000-0000-000000000000")
  assert_eq(@moonuuid.max.to_string(), "ffffffff-ffff-ffff-ffff-ffffffffffff")
  assert_eq(@moonuuid.nil.version(), None)
  assert_eq(@moonuuid.max.variant(), @moonuuid.Future)
  assert_eq(
    @moonuuid.namespace_url.to_string(),
    "6ba7b811-9dad-11d1-80b4-00c04fd430c8",
  )
  assert_eq(@moonuuid.namespace_oid.version(), Some(1))
  assert_eq(@moonuuid.namespace_x500.node(), 0x00C04FD430C8L)
}

///|
test "bytes and parts round trip" {
  let id = @moonuuid.parse("0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0")
  assert_eq(@moonuuid.Uuid::of_bytes(id.bytes()), id)
  let (hi, lo) = id.parts()
  assert_eq(@moonuuid.Uuid::of_parts(hi, lo), id)
  assert_eq(hi, 0x0f1e2d3c4b5a6978UL)
  let short = try {
    ignore(@moonuuid.Uuid::of_bytes(b"\x01\x02"))
    "made"
  } catch {
    e => e.to_string()
  }
  assert_eq(short, "16 bytes wanted, 2 given")
}

///|
test "malformed text says where" {
  let why = (text : String) => {
    try {
      ignore(@moonuuid.parse(text))
      "parsed"
    } catch {
      e => e.to_string()
    }
  }
  assert_eq(
    why("c232ab00-9414-11ec-b3c8-9f6bdeced84g"),
    "\"g\" is not a hexadecimal digit at 35",
  )
  assert_eq(why("c232ab00"), "8 hexadecimal digits, not 32 at 8")
  assert_eq(
    why("c232ab00-9414-11ec-b3c8-9f6bdeced8466"),
    "more than 32 hexadecimal digits at 36",
  )
  assert_eq(why("URN:UUID:{c232ab00-9414-11ec-b3c8-9f6bdeced846}"), "parsed")
}

///|
test "identifiers order by their bytes and work as map keys" {
  let a = @moonuuid.parse("00000000-0000-7000-8000-000000000001")
  let b = @moonuuid.parse("00000000-0001-7000-8000-000000000000")
  assert_true(a < b)
  assert_eq(a.compare(b), -1)
  let seen : Map[@moonuuid.Uuid, Int32] = Map([(a, 1), (b, 2)])
  assert_eq(seen.get(b), Some(2))
}

///|
test "JSON is the canonical text" {
  let id = @moonuuid.namespace_dns
  assert_eq(Json(id).stringify(), "\"6ba7b810-9dad-11d1-80b4-00c04fd430c8\"")
  let back : @moonuuid.Uuid = @json.from_json(
    Json::string("{6BA7B810-9DAD-11D1-80B4-00C04FD430C8}"),
  )
  assert_eq(back, id)
  let bad : Result[@moonuuid.Uuid, Error] = Ok(
    @json.from_json(Json::number(1.0)),
  ) catch {
    e => Err(e)
  }
  assert_true(bad is Err(_))
}

///|
test "random and custom versions keep only their payload bits" {
  let ones = Bytes::make(16, b'\xFF')
  assert_eq(
    @moonuuid.v4(ones).to_string(),
    "ffffffff-ffff-4fff-bfff-ffffffffffff",
  )
  assert_eq(
    @moonuuid.v8(ones).to_string(),
    "ffffffff-ffff-8fff-bfff-ffffffffffff",
  )
  let wrong = try {
    ignore(@moonuuid.v7(millis=0L, b"\x00"))
    "made"
  } catch {
    e => e.to_string()
  }
  assert_eq(wrong, "10 bytes wanted, 1 given")
}

///|
test "a generator's time-based ids never repeat a timestamp" {
  let gen = @moonuuid.Generator::new(
    clock=() => 1_000_000_000L,
    random=@moonrand.Replay::new(Bytes::make(64, b'\x5A')),
  )
  let a = gen.v1(node=1L)
  let b = gen.v1(node=1L)
  assert_eq(b.time() - a.time(), 1L)
  assert_eq(a.clock_seq(), 0x1A5A)
  let c = gen.v6(node=2L, clock_seq=7)
  let d = gen.v6(node=2L, clock_seq=7)
  assert_true(c < d)
  assert_eq(d.clock_seq(), 7)
  assert_eq(gen.v4().version(), Some(4))
}

///|
test "a random source that runs dry is refused" {
  let gen = @moonuuid.Generator::new(
    clock=() => 0L,
    random=@moonrand.Replay::new(b"\x01"),
  )
  let got = try {
    ignore(gen.v7())
    "made"
  } catch {
    e => e.to_string()
  }
  assert_eq(got, "no randomness: the replay source is exhausted")
}
