///|
test "python parse #0" {
  let u = @moonuuid.parse("c232ab00-9414-11ec-b3c8-9f6bdeced846")
  assert_eq(u.to_string(), "c232ab00-9414-11ec-b3c8-9f6bdeced846")
  assert_eq(u.hex(), "c232ab00941411ecb3c89f6bdeced846")
  assert_eq(u.urn(), "urn:uuid:c232ab00-9414-11ec-b3c8-9f6bdeced846")
  assert_eq(u.version(), Some(1))
  assert_eq(u.variant(), @moonuuid.Rfc)
  assert_eq(u.time(), 138648505420000000L)
  assert_eq(u.clock_seq(), 13256)
  assert_eq(u.node(), 175285648414790L)
  assert_eq(
    u.bytes(),
    b"\xc2\x32\xab\x00\x94\x14\x11\xec\xb3\xc8\x9f\x6b\xde\xce\xd8\x46",
  )
}

///|
test "python parse #1" {
  let u = @moonuuid.parse("{C232AB00-9414-11EC-B3C8-9F6BDECED846}")
  assert_eq(u.to_string(), "c232ab00-9414-11ec-b3c8-9f6bdeced846")
  assert_eq(u.hex(), "c232ab00941411ecb3c89f6bdeced846")
  assert_eq(u.urn(), "urn:uuid:c232ab00-9414-11ec-b3c8-9f6bdeced846")
  assert_eq(u.version(), Some(1))
  assert_eq(u.variant(), @moonuuid.Rfc)
  assert_eq(u.time(), 138648505420000000L)
  assert_eq(u.clock_seq(), 13256)
  assert_eq(u.node(), 175285648414790L)
  assert_eq(
    u.bytes(),
    b"\xc2\x32\xab\x00\x94\x14\x11\xec\xb3\xc8\x9f\x6b\xde\xce\xd8\x46",
  )
}

///|
test "python parse #2" {
  let u = @moonuuid.parse("urn:uuid:1ec9414c-232a-6b00-b3c8-9f6bdeced846")
  assert_eq(u.to_string(), "1ec9414c-232a-6b00-b3c8-9f6bdeced846")
  assert_eq(u.hex(), "1ec9414c232a6b00b3c89f6bdeced846")
  assert_eq(u.urn(), "urn:uuid:1ec9414c-232a-6b00-b3c8-9f6bdeced846")
  assert_eq(u.version(), Some(6))
  assert_eq(u.variant(), @moonuuid.Rfc)
  assert_eq(u.time(), 138648505420000000L)
  assert_eq(u.clock_seq(), 13256)
  assert_eq(u.node(), 175285648414790L)
  assert_eq(
    u.bytes(),
    b"\x1e\xc9\x41\x4c\x23\x2a\x6b\x00\xb3\xc8\x9f\x6b\xde\xce\xd8\x46",
  )
}

///|
test "python parse #3" {
  let u = @moonuuid.parse("017f22e279b07cc398c4dc0c0c07398f")
  assert_eq(u.to_string(), "017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
  assert_eq(u.hex(), "017f22e279b07cc398c4dc0c0c07398f")
  assert_eq(u.urn(), "urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f")
  assert_eq(u.version(), Some(7))
  assert_eq(u.variant(), @moonuuid.Rfc)
  assert_eq(u.time(), 1645557742000L)
  assert_eq(u.clock_seq(), 6340)
  assert_eq(u.node(), 241944299518351L)
  assert_eq(
    u.bytes(),
    b"\x01\x7f\x22\xe2\x79\xb0\x7c\xc3\x98\xc4\xdc\x0c\x0c\x07\x39\x8f",
  )
}

///|
test "python parse #4" {
  let u = @moonuuid.parse("5df41881-3aed-3515-88a7-2f4a814cf09e")
  assert_eq(u.to_string(), "5df41881-3aed-3515-88a7-2f4a814cf09e")
  assert_eq(u.hex(), "5df418813aed351588a72f4a814cf09e")
  assert_eq(u.urn(), "urn:uuid:5df41881-3aed-3515-88a7-2f4a814cf09e")
  assert_eq(u.version(), Some(3))
  assert_eq(u.variant(), @moonuuid.Rfc)
  assert_eq(u.time(), 366263735858501761L)
  assert_eq(u.clock_seq(), 2215)
  assert_eq(u.node(), 51997043388574L)
  assert_eq(
    u.bytes(),
    b"\x5d\xf4\x18\x81\x3a\xed\x35\x15\x88\xa7\x2f\x4a\x81\x4c\xf0\x9e",
  )
}

///|
test "python parse #5" {
  let u = @moonuuid.parse("2ed6657d-e927-568b-95e1-2665a8aea6a2")
  assert_eq(u.to_string(), "2ed6657d-e927-568b-95e1-2665a8aea6a2")
  assert_eq(u.hex(), "2ed6657de927568b95e12665a8aea6a2")
  assert_eq(u.urn(), "urn:uuid:2ed6657d-e927-568b-95e1-2665a8aea6a2")
  assert_eq(u.version(), Some(5))
  assert_eq(u.variant(), @moonuuid.Rfc)
  assert_eq(u.time(), 471726940489147773L)
  assert_eq(u.clock_seq(), 5601)
  assert_eq(u.node(), 42218063570594L)
  assert_eq(
    u.bytes(),
    b"\x2e\xd6\x65\x7d\xe9\x27\x56\x8b\x95\xe1\x26\x65\xa8\xae\xa6\xa2",
  )
}

///|
test "python parse #6" {
  let u = @moonuuid.parse("00000000-0000-0000-0000-000000000000")
  assert_eq(u.to_string(), "00000000-0000-0000-0000-000000000000")
  assert_eq(u.hex(), "00000000000000000000000000000000")
  assert_eq(u.urn(), "urn:uuid:00000000-0000-0000-0000-000000000000")
  assert_eq(u.version(), None)
  assert_eq(u.variant(), @moonuuid.Ncs)
  assert_eq(u.time(), 0L)
  assert_eq(u.clock_seq(), 0)
  assert_eq(u.node(), 0L)
  assert_eq(
    u.bytes(),
    b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
  )
}

///|
test "python parse #7" {
  let u = @moonuuid.parse("ffffffff-ffff-ffff-ffff-ffffffffffff")
  assert_eq(u.to_string(), "ffffffff-ffff-ffff-ffff-ffffffffffff")
  assert_eq(u.hex(), "ffffffffffffffffffffffffffffffff")
  assert_eq(u.urn(), "urn:uuid:ffffffff-ffff-ffff-ffff-ffffffffffff")
  assert_eq(u.version(), None)
  assert_eq(u.variant(), @moonuuid.Future)
  assert_eq(u.time(), 1152921504606846975L)
  assert_eq(u.clock_seq(), 16383)
  assert_eq(u.node(), 281474976710655L)
  assert_eq(
    u.bytes(),
    b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
  )
}

///|
test "python parse #8" {
  let u = @moonuuid.parse("12345678-1234-5678-1234-567812345678")
  assert_eq(u.to_string(), "12345678-1234-5678-1234-567812345678")
  assert_eq(u.hex(), "12345678123456781234567812345678")
  assert_eq(u.urn(), "urn:uuid:12345678-1234-5678-1234-567812345678")
  assert_eq(u.version(), None)
  assert_eq(u.variant(), @moonuuid.Ncs)
  assert_eq(u.time(), 466142576285865592L)
  assert_eq(u.clock_seq(), 4660)
  assert_eq(u.node(), 95073701484152L)
  assert_eq(
    u.bytes(),
    b"\x12\x34\x56\x78\x12\x34\x56\x78\x12\x34\x56\x78\x12\x34\x56\x78",
  )
}

///|
test "python parse #9" {
  let u = @moonuuid.parse("12345678-1234-5678-d234-567812345678")
  assert_eq(u.to_string(), "12345678-1234-5678-d234-567812345678")
  assert_eq(u.hex(), "1234567812345678d234567812345678")
  assert_eq(u.urn(), "urn:uuid:12345678-1234-5678-d234-567812345678")
  assert_eq(u.version(), None)
  assert_eq(u.variant(), @moonuuid.Microsoft)
  assert_eq(u.time(), 466142576285865592L)
  assert_eq(u.clock_seq(), 4660)
  assert_eq(u.node(), 95073701484152L)
  assert_eq(
    u.bytes(),
    b"\x12\x34\x56\x78\x12\x34\x56\x78\xd2\x34\x56\x78\x12\x34\x56\x78",
  )
}

///|
test "python parse #10" {
  let u = @moonuuid.parse("12345678-1234-5678-f234-567812345678")
  assert_eq(u.to_string(), "12345678-1234-5678-f234-567812345678")
  assert_eq(u.hex(), "1234567812345678f234567812345678")
  assert_eq(u.urn(), "urn:uuid:12345678-1234-5678-f234-567812345678")
  assert_eq(u.version(), None)
  assert_eq(u.variant(), @moonuuid.Future)
  assert_eq(u.time(), 466142576285865592L)
  assert_eq(u.clock_seq(), 12852)
  assert_eq(u.node(), 95073701484152L)
  assert_eq(
    u.bytes(),
    b"\x12\x34\x56\x78\x12\x34\x56\x78\xf2\x34\x56\x78\x12\x34\x56\x78",
  )
}

///|
test "python parse #11" {
  let u = @moonuuid.parse("uuid:6ba7b810-9dad-11d1-80b4-00c04fd430c8")
  assert_eq(u.to_string(), "6ba7b810-9dad-11d1-80b4-00c04fd430c8")
  assert_eq(u.hex(), "6ba7b8109dad11d180b400c04fd430c8")
  assert_eq(u.urn(), "urn:uuid:6ba7b810-9dad-11d1-80b4-00c04fd430c8")
  assert_eq(u.version(), Some(1))
  assert_eq(u.variant(), @moonuuid.Rfc)
  assert_eq(u.time(), 131059232331511824L)
  assert_eq(u.clock_seq(), 180)
  assert_eq(u.node(), 825973027016L)
  assert_eq(
    u.bytes(),
    b"\x6b\xa7\xb8\x10\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8",
  )
}

///|
test "python parse #12" {
  let u = @moonuuid.parse("{{6ba7b811-9dad-11d1-80b4-00c04fd430c8}}")
  assert_eq(u.to_string(), "6ba7b811-9dad-11d1-80b4-00c04fd430c8")
  assert_eq(u.hex(), "6ba7b8119dad11d180b400c04fd430c8")
  assert_eq(u.urn(), "urn:uuid:6ba7b811-9dad-11d1-80b4-00c04fd430c8")
  assert_eq(u.version(), Some(1))
  assert_eq(u.variant(), @moonuuid.Rfc)
  assert_eq(u.time(), 131059232331511825L)
  assert_eq(u.clock_seq(), 180)
  assert_eq(u.node(), 825973027016L)
  assert_eq(
    u.bytes(),
    b"\x6b\xa7\xb8\x11\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8",
  )
}

///|
test "python parse #13" {
  let u = @moonuuid.parse("6ba7-b812-9dad-11d1-80b4-00c0-4fd4-30c8")
  assert_eq(u.to_string(), "6ba7b812-9dad-11d1-80b4-00c04fd430c8")
  assert_eq(u.hex(), "6ba7b8129dad11d180b400c04fd430c8")
  assert_eq(u.urn(), "urn:uuid:6ba7b812-9dad-11d1-80b4-00c04fd430c8")
  assert_eq(u.version(), Some(1))
  assert_eq(u.variant(), @moonuuid.Rfc)
  assert_eq(u.time(), 131059232331511826L)
  assert_eq(u.clock_seq(), 180)
  assert_eq(u.node(), 825973027016L)
  assert_eq(
    u.bytes(),
    b"\x6b\xa7\xb8\x12\x9d\xad\x11\xd1\x80\xb4\x00\xc0\x4f\xd4\x30\xc8",
  )
}

///|
test "python malformed #0" {
  let ok = try {
    ignore(@moonuuid.parse(""))
    true
  } catch {
    _ => false
  }
  assert_eq(ok, false)
}

///|
test "python malformed #1" {
  let ok = try {
    ignore(@moonuuid.parse("c232ab00"))
    true
  } catch {
    _ => false
  }
  assert_eq(ok, false)
}

///|
test "python malformed #2" {
  let ok = try {
    ignore(@moonuuid.parse("c232ab00-9414-11ec-b3c8-9f6bdeced84g"))
    true
  } catch {
    _ => false
  }
  assert_eq(ok, false)
}

///|
test "python malformed #3" {
  let ok = try {
    ignore(@moonuuid.parse("c232ab00-9414-11ec-b3c8-9f6bdeced8466"))
    true
  } catch {
    _ => false
  }
  assert_eq(ok, false)
}

///|
test "python malformed #4" {
  let ok = try {
    ignore(@moonuuid.parse("urn:uuid:"))
    true
  } catch {
    _ => false
  }
  assert_eq(ok, false)
}

///|
test "python malformed #5" {
  let ok = try {
    ignore(@moonuuid.parse("{c232ab00-9414-11ec-b3c8-9f6bdeced846"))
    true
  } catch {
    _ => false
  }
  assert_eq(ok, true)
}

///|
test "python v3 v5 #0" {
  assert_eq(
    @moonuuid.v3(@moonuuid.namespace_dns, "www.example.com").to_string(),
    "5df41881-3aed-3515-88a7-2f4a814cf09e",
  )
  assert_eq(
    @moonuuid.v5(@moonuuid.namespace_dns, "www.example.com").to_string(),
    "2ed6657d-e927-568b-95e1-2665a8aea6a2",
  )
}

///|
test "python v3 v5 #1" {
  assert_eq(
    @moonuuid.v3(@moonuuid.namespace_dns, "python.org").to_string(),
    "6fa459ea-ee8a-3ca4-894e-db77e160355e",
  )
  assert_eq(
    @moonuuid.v5(@moonuuid.namespace_dns, "python.org").to_string(),
    "886313e1-3b8a-5372-9b90-0c9aee199e5d",
  )
}

///|
test "python v3 v5 #2" {
  assert_eq(
    @moonuuid.v3(@moonuuid.namespace_url, "http://python.org/").to_string(),
    "9fe8e8c4-aaa8-32a9-a55c-4535a88b748d",
  )
  assert_eq(
    @moonuuid.v5(@moonuuid.namespace_url, "http://python.org/").to_string(),
    "4c565f0d-3f5a-5890-b41b-20cf47701c5e",
  )
}

///|
test "python v3 v5 #3" {
  assert_eq(
    @moonuuid.v3(@moonuuid.namespace_oid, "1.3.6.1").to_string(),
    "dd1a1cef-13d5-368a-ad82-eca71acd4cd1",
  )
  assert_eq(
    @moonuuid.v5(@moonuuid.namespace_oid, "1.3.6.1").to_string(),
    "1447fa61-5277-5fef-a9b3-fbc6e44f4af3",
  )
}

///|
test "python v3 v5 #4" {
  assert_eq(
    @moonuuid.v3(@moonuuid.namespace_x500, "c=ca").to_string(),
    "658d3002-db6b-3040-a1d1-8ddd7d189a4d",
  )
  assert_eq(
    @moonuuid.v5(@moonuuid.namespace_x500, "c=ca").to_string(),
    "cc957dd1-a972-5349-98cd-874190002798",
  )
}

///|
test "python v3 v5 #5" {
  assert_eq(
    @moonuuid.v3(@moonuuid.namespace_dns, "").to_string(),
    "c87ee674-4ddc-3efe-a74e-dfe25da5d7b3",
  )
  assert_eq(
    @moonuuid.v5(@moonuuid.namespace_dns, "").to_string(),
    "4ebd0208-8328-5d69-8c44-ec50939c0967",
  )
}

///|
test "python v3 v5 #6" {
  assert_eq(
    @moonuuid.v3(@moonuuid.namespace_dns, "\u540d\u524d.\u4f8b").to_string(),
    "8c382116-7a0f-3168-af5a-ae79cae4478b",
  )
  assert_eq(
    @moonuuid.v5(@moonuuid.namespace_dns, "\u540d\u524d.\u4f8b").to_string(),
    "a46e3405-ceba-5147-a51f-54221e784683",
  )
}

///|
test "python v4 #0" {
  assert_eq(
    @moonuuid.v4(
      b"\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f",
    ).to_string(),
    "00010203-0405-4607-8809-0a0b0c0d0e0f",
  )
}

///|
test "python v4 #1" {
  assert_eq(
    @moonuuid.v4(
      b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
    ).to_string(),
    "ffffffff-ffff-4fff-bfff-ffffffffffff",
  )
}

///|
test "python v4 #2" {
  assert_eq(
    @moonuuid.v4(
      b"\x0f\x1e\x2d\x3c\x4b\x5a\x69\x78\x87\x96\xa5\xb4\xc3\xd2\xe1\xf0",
    ).to_string(),
    "0f1e2d3c-4b5a-4978-8796-a5b4c3d2e1f0",
  )
}

///|
test "python v1 v6 #0" {
  let ticks = @moonuuid.ticks_of(1700000000123456789L)
  assert_eq(
    @moonuuid.v1(ticks~, clock_seq=13256, node=175285648414790L).to_string(),
    "04c29687-833b-11ee-b3c8-9f6bdeced846",
  )
  assert_eq(
    @moonuuid.v6(ticks~, clock_seq=13256, node=175285648414790L).to_string(),
    "1ee833b0-4c29-6687-b3c8-9f6bdeced846",
  )
}

///|
test "python v1 v6 #1" {
  let ticks = @moonuuid.ticks_of(0L)
  assert_eq(
    @moonuuid.v1(ticks~, clock_seq=0, node=0L).to_string(),
    "13814000-1dd2-11b2-8000-000000000000",
  )
  assert_eq(
    @moonuuid.v6(ticks~, clock_seq=0, node=0L).to_string(),
    "1b21dd21-3814-6000-8000-000000000000",
  )
}

///|
test "python v1 v6 #2" {
  let ticks = @moonuuid.ticks_of(1234567890000000001L)
  assert_eq(
    @moonuuid.v1(ticks~, clock_seq=16383, node=281474976710655L).to_string(),
    "70d9b500-fa26-11dd-bfff-ffffffffffff",
  )
  assert_eq(
    @moonuuid.v6(ticks~, clock_seq=16383, node=281474976710655L).to_string(),
    "1ddfa267-0d9b-6500-bfff-ffffffffffff",
  )
}

///|
test "python v1 v6 #3" {
  let ticks = @moonuuid.ticks_of(2000000000000000000L)
  assert_eq(
    @moonuuid.v1(ticks~, clock_seq=12345, node=1108152157446L).to_string(),
    "f3034000-2bb6-11f9-b039-010203040506",
  )
  assert_eq(
    @moonuuid.v6(ticks~, clock_seq=12345, node=1108152157446L).to_string(),
    "1f92bb6f-3034-6000-b039-010203040506",
  )
}

///|
test "python v8 #0" {
  assert_eq(
    @moonuuid.v8(
      b"\x12\x34\x56\x78\x9a\xbc\x0d\xef\x12\x34\x56\x78\x9a\xbc\xde\xf0",
    ).to_string(),
    "12345678-9abc-8def-9234-56789abcdef0",
  )
}

///|
test "python v8 #1" {
  assert_eq(
    @moonuuid.v8(
      b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
    ).to_string(),
    "00000000-0000-8000-8000-000000000000",
  )
}

///|
test "python v8 #2" {
  assert_eq(
    @moonuuid.v8(
      b"\xff\xff\xff\xff\xff\xff\x0f\xff\x3f\xff\xff\xff\xff\xff\xff\xff",
    ).to_string(),
    "ffffffff-ffff-8fff-bfff-ffffffffffff",
  )
}

///|
test "python generator v7 steady" {
  let clock = [
    1700000000000000000L, 1700000000001000000L, 1700000000002000000L, 1700000000003000000L,
  ]
  let draws : Array[Bytes] = [
    b"\x00\x0b\x16\x21\x2c\x37\x42\x4d\x58\x63", b"\x25\x30\x3b\x46\x51\x5c\x67\x72\x7d\x88",
    b"\x4a\x55\x60\x6b\x76\x81\x8c\x97\xa2\xad", b"\x6f\x7a\x85\x90\x9b\xa6\xb1\xbc\xc7\xd2",
  ]
  let t = Ref(0)
  let r = Ref(0)
  let gen = @moonuuid.Generator::new(
    clock=() => {
      t.val += 1
      clock[t.val - 1]
    },
    random=_ => {
      r.val += 1
      draws[r.val - 1]
    },
  )
  let got = []
  for _ in clock {
    got.push(gen.v7().to_string())
  }
  assert_eq(got, [
    "018bcfe5-6800-702c-9621-2c37424d5863", "018bcfe5-6801-74c0-bb46-515c67727d88",
    "018bcfe5-6802-7155-a06b-76818c97a2ad", "018bcfe5-6803-75ea-8590-9ba6b1bcc7d2",
  ])
}

///|
test "python generator v7 same millisecond" {
  let clock = [
    1700000000000000000L, 1700000000000000000L, 1700000000000000000L, 1700000000000000000L,
    1700000000000000000L,
  ]
  let draws : Array[Bytes] = [
    b"\x00\x0b\x16\x21\x2c\x37\x42\x4d\x58\x63", b"\x25\x30\x3b\x46", b"\x4a\x55\x60\x6b",
    b"\x6f\x7a\x85\x90", b"\x94\x9f\xaa\xb5",
  ]
  let t = Ref(0)
  let r = Ref(0)
  let gen = @moonuuid.Generator::new(
    clock=() => {
      t.val += 1
      clock[t.val - 1]
    },
    random=_ => {
      r.val += 1
      draws[r.val - 1]
    },
  )
  let got = []
  for _ in clock {
    got.push(gen.v7().to_string())
  }
  assert_eq(got, [
    "018bcfe5-6800-702c-9621-2c37424d5863", "018bcfe5-6800-702c-9621-2c3825303b46",
    "018bcfe5-6800-702c-9621-2c394a55606b", "018bcfe5-6800-702c-9621-2c3a6f7a8590",
    "018bcfe5-6800-702c-9621-2c3b949faab5",
  ])
}

///|
test "python generator v7 clock steps back" {
  let clock = [
    1700000000005000000L, 1700000000001000000L, 1700000000001000000L, 1700000000009000000L,
  ]
  let draws : Array[Bytes] = [
    b"\x00\x0b\x16\x21\x2c\x37\x42\x4d\x58\x63", b"\x25\x30\x3b\x46", b"\x4a\x55\x60\x6b",
    b"\x6f\x7a\x85\x90\x9b\xa6\xb1\xbc\xc7\xd2",
  ]
  let t = Ref(0)
  let r = Ref(0)
  let gen = @moonuuid.Generator::new(
    clock=() => {
      t.val += 1
      clock[t.val - 1]
    },
    random=_ => {
      r.val += 1
      draws[r.val - 1]
    },
  )
  let got = []
  for _ in clock {
    got.push(gen.v7().to_string())
  }
  assert_eq(got, [
    "018bcfe5-6805-702c-9621-2c37424d5863", "018bcfe5-6806-702c-9621-2c3825303b46",
    "018bcfe5-6807-702c-9621-2c394a55606b", "018bcfe5-6809-75ea-8590-9ba6b1bcc7d2",
  ])
}
