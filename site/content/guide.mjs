/**
 * The guide, as data. Every block is a program that compiles against this
 * package, and every `out` is copied from a real run of it.
 */

export const sections = [
  {
    id: "install",
    no: "01",
    title: "Install",
    body: `<p>Add the package, then import it where you use it. The module is
      <code>moonbitstack/moonuuid</code>, and the import brings it in as
      <code>@moonuuid</code>.</p>`,
    blocks: [
      { lang: "shell", code: `moon add moonbitstack/moonuuid`, caption: "shell" },
      {
        lang: "moonbit",
        caption: "moon.pkg",
        code: `import {
  "moonbitstack/moonuuid",
}`,
      },
    ],
  },
  {
    id: "read",
    no: "02",
    title: "Read one",
    body: `<p><code>parse</code> takes text and returns a <code>Uuid</code>. Text that is not an
      identifier comes back as a <code>Refused</code>, so a function that parses has to say
      what it does with that. <code>fn main raise</code> lets the refusal out.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main raise {
  let id = @moonuuid.parse("c232ab00-9414-11ec-b3c8-9f6bdeced846")
  println(id)
}`,
        out: `c232ab00-9414-11ec-b3c8-9f6bdeced846`,
      },
    ],
  },
  {
    id: "spellings",
    no: "03",
    title: "Every spelling",
    body: `<p>Hyphens are optional. Case does not matter. Braces and the
      <code>urn:uuid:</code> prefix are set aside before the digits are read.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main raise {
  for text in [
    "c232ab00-9414-11ec-b3c8-9f6bdeced846",
    "C232AB00941411ECB3C89F6BDECED846",
    "{C232AB00-9414-11EC-B3C8-9F6BDECED846}",
    "urn:uuid:c232ab00-9414-11ec-b3c8-9f6bdeced846",
  ] {
    println(@moonuuid.parse(text))
  }
}`,
        out: `c232ab00-9414-11ec-b3c8-9f6bdeced846
c232ab00-9414-11ec-b3c8-9f6bdeced846
c232ab00-9414-11ec-b3c8-9f6bdeced846
c232ab00-9414-11ec-b3c8-9f6bdeced846`,
      },
    ],
  },
  {
    id: "write",
    no: "04",
    title: "Write it back",
    body: `<p><code>to_string</code> gives the canonical form. <code>hex</code> drops the
      hyphens. <code>urn</code> adds the prefix. All three write lowercase.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main raise {
  let id = @moonuuid.parse("c232ab00-9414-11ec-b3c8-9f6bdeced846")
  println(id.to_string())
  println(id.hex())
  println(id.urn())
}`,
        out: `c232ab00-9414-11ec-b3c8-9f6bdeced846
c232ab00941411ecb3c89f6bdeced846
urn:uuid:c232ab00-9414-11ec-b3c8-9f6bdeced846`,
      },
    ],
  },
  {
    id: "fields",
    no: "05",
    title: "Look inside",
    body: `<p>An identifier answers with the fields its bits name. <code>time</code> is
      100-nanosecond intervals since 1582 for versions 1 and 6, and milliseconds since
      1970 for version 7. <code>version</code> is <code>None</code> when the variant is not
      RFC 9562's, where the version bits mean nothing.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main raise {
  let id = @moonuuid.parse("c232ab00-9414-11ec-b3c8-9f6bdeced846")
  println(id.version())    // Some(1)
  println(id.variant())    // Rfc
  println(id.time())       // 138648505420000000
  println(id.clock_seq())  // 13256
  println(id.node())       // 175285648414790
}`,
        out: `Some(1)
Rfc
138648505420000000
13256
175285648414790`,
      },
    ],
  },
  {
    id: "generator",
    no: "06",
    title: "A clock and a random source",
    body: `<p>The library never reaches for the clock or for randomness.
      <code>Generator::new</code> takes a clock that gives nanoseconds since 1970 and a
      source that gives a number of random bytes. It keeps what the time-based versions
      need between calls. Here both are fixed, so every run prints the same lines.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main raise {
  let gen = @moonuuid.Generator::new(
    clock=() => 1_761_350_400_000_000_000L,
    random=n => Bytes::makei(n, i => (i * 37 + 11).to_byte()),
  )
  println(gen.v4())
}`,
        out: `0b30557a-9fc4-490e-b358-7da2c7ec1136`,
      },
      {
        lang: "moonbit",
        code: `fn main raise {
  let gen = @moonuuid.Generator::new(
    clock=() => 1_761_350_400_000_000_000L,
    random=n => Bytes::makei(n, i => (i * 37 + 11).to_byte()),
  )
  for _ in 0..<3 {
    println(gen.v7())
  }
}`,
        out: `019a18aa-3800-74c1-957a-9fc4e90e3358
019a18aa-3800-74c1-957a-9fc50b30557a
019a18aa-3800-74c1-957a-9fc60b30557a`,
        note: `Within one millisecond the counter goes up with a fresh random tail. A clock
          that steps back uses the millisecond after the last one, so the order holds.`,
      },
    ],
  },
  {
    id: "time",
    no: "07",
    title: "Time-based, field by field",
    body: `<p><code>ticks_of</code> turns nanoseconds since 1970 into the 100-nanosecond
      intervals since 1582 that versions 1 and 6 count. Version 6 lays the timestamp's
      high bits first, so identifiers sort in the order they were made; version 1 keeps
      the older layout.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main {
  let ticks = @moonuuid.ticks_of(1_761_350_400_000_000_000L)
  println(@moonuuid.v1(ticks~, clock_seq=0x2A3B, node=0x001A2B3C4D5EL))
  println(@moonuuid.v6(ticks~, clock_seq=0x2A3B, node=0x001A2B3C4D5EL))
}`,
        out: `8cacc000-b135-11f0-aa3b-001a2b3c4d5e
1f0b1358-cacc-6000-aa3b-001a2b3c4d5e`,
      },
    ],
  },
  {
    id: "names",
    no: "08",
    title: "From a name",
    body: `<p>Versions 3 and 5 hash a namespace and a name: MD5 for version 3, SHA-1 for
      version 5. The same pair always gives the same identifier. The name is hashed as
      UTF-8, so text in any language is fine.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main {
  println(@moonuuid.v5(@moonuuid.namespace_url, "https://example.org/"))
  println(@moonuuid.v5(@moonuuid.namespace_dns, "李雷"))
}`,
        out: `527dda32-a0de-5105-a042-cb475b5f7d11
97ce974b-b58a-513c-994e-06af9b649d7f`,
        note: `namespace_dns, namespace_url, namespace_oid and namespace_x500 are the four
          namespaces RFC 9562 assigns.`,
      },
    ],
  },
  {
    id: "custom",
    no: "09",
    title: "Your own layout",
    body: `<p>Version 8 keeps 122 bits of the sixteen bytes you pass and writes only the
      version and variant over them, so the layout is yours.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main raise {
  let custom = Bytes::makei(16, i => (i * 17 + 3).to_byte())
  println(@moonuuid.v8(custom))
}`,
        out: `03142536-4758-897a-8b9c-adbecfe0f102`,
      },
    ],
  },
  {
    id: "refused",
    no: "10",
    title: "When it refuses",
    body: `<p><code>Refused</code> says what was wrong. <code>Malformed</code> points at the
      character that stopped the parse; <code>Size</code> gives the two lengths.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main {
  try {
    ignore(@moonuuid.parse("not-a-uuid"))
  } catch {
    e => println(e)
  }
  try {
    ignore(@moonuuid.v4(Bytes::make(3, 0)))
  } catch {
    e => println(e)
  }
}`,
        out: `"n" is not a hexadecimal digit at 0
16 bytes wanted, 3 given`,
      },
    ],
  },
  {
    id: "json",
    no: "11",
    title: "JSON",
    body: `<p>An identifier writes itself as the canonical string, and reads any spelling
      back. This section needs <code>moonbitlang/core/json</code> in the package's
      imports.</p>`,
    blocks: [
      {
        lang: "moonbit",
        code: `fn main raise {
  let id = @moonuuid.parse("c232ab00-9414-11ec-b3c8-9f6bdeced846")
  let j = Json(id)
  println(j.stringify())
  let back : @moonuuid.Uuid = @json.from_json(j)
  println(back)
}`,
        out: `"c232ab00-9414-11ec-b3c8-9f6bdeced846"
c232ab00-9414-11ec-b3c8-9f6bdeced846`,
      },
    ],
  },
];
