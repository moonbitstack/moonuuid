"""Python 3.15's uuid module, with its clock and random source replaced by
fixed sequences, writes src/python_test.mbt. Usage: python_vectors.py <out>."""
import json, os, sys, time, uuid

lines = []


def test(name, body):
    lines.append("///|\ntest %s {\n%s\n}\n" % (json.dumps(name), body))


def lit(s):
    return json.dumps(s)


def hexbytes(b):
    return lit(b.hex())


# Spellings, fields and the variant bits.
SAMPLES = [
    "c232ab00-9414-11ec-b3c8-9f6bdeced846", "{C232AB00-9414-11EC-B3C8-9F6BDECED846}", "urn:uuid:1ec9414c-232a-6b00-b3c8-9f6bdeced846",
    "017f22e279b07cc398c4dc0c0c07398f", "5df41881-3aed-3515-88a7-2f4a814cf09e", "2ed6657d-e927-568b-95e1-2665a8aea6a2",
    "00000000-0000-0000-0000-000000000000", "ffffffff-ffff-ffff-ffff-ffffffffffff", "12345678-1234-5678-1234-567812345678",
    "12345678-1234-5678-d234-567812345678", "12345678-1234-5678-f234-567812345678", "uuid:6ba7b810-9dad-11d1-80b4-00c04fd430c8",
    "{{6ba7b811-9dad-11d1-80b4-00c04fd430c8}}", "6ba7-b812-9dad-11d1-80b4-00c0-4fd4-30c8",
]
for i, s in enumerate(SAMPLES):
    u = uuid.UUID(s)
    v = "None" if u.version is None else "Some(%d)" % u.version
    var = {uuid.RESERVED_NCS: "Ncs", uuid.RFC_4122: "Rfc", uuid.RESERVED_MICROSOFT: "Microsoft", uuid.RESERVED_FUTURE: "Future"}[u.variant]
    test("python parse #%d" % i, "\n".join([
        "  let u = @moonuuid.parse(%s)" % lit(s),
        "  assert_eq(u.to_string(), %s)" % lit(str(u)),
        "  assert_eq(u.hex(), %s)" % lit(u.hex),
        "  assert_eq(u.urn(), %s)" % lit(u.urn),
        "  assert_eq(u.version(), %s)" % v,
        "  assert_eq(u.variant(), @moonuuid.%s)" % var,
        "  assert_eq(u.time(), %dL)" % u.time,
        "  assert_eq(u.clock_seq(), %d)" % u.clock_seq,
        "  assert_eq(u.node(), %dL)" % u.node,
        "  assert_eq(u.bytes(), b\"%s\")" % "".join("\\x%02x" % c for c in u.bytes),
    ]))
for i, s in enumerate(["", "c232ab00", "c232ab00-9414-11ec-b3c8-9f6bdeced84g", "c232ab00-9414-11ec-b3c8-9f6bdeced8466", "urn:uuid:", "{c232ab00-9414-11ec-b3c8-9f6bdeced846"]):
    try:
        uuid.UUID(s)
        ok = True
    except ValueError:
        ok = False
    test("python malformed #%d" % i, "  let ok = try { ignore(@moonuuid.parse(%s)); true } catch { _ => false }\n  assert_eq(ok, %s)" % (lit(s), "true" if ok else "false"))

# Name-based.
for i, (space, name) in enumerate([("dns", "www.example.com"), ("dns", "python.org"), ("url", "http://python.org/"), ("oid", "1.3.6.1"), ("x500", "c=ca"), ("dns", ""), ("dns", "名前.例")]):
    ns = getattr(uuid, "NAMESPACE_" + space.upper())
    test("python v3 v5 #%d" % i, "\n".join([
        "  assert_eq(@moonuuid.v3(@moonuuid.namespace_%s, %s).to_string(), %s)" % (space, lit(name), lit(str(uuid.uuid3(ns, name)))),
        "  assert_eq(@moonuuid.v5(@moonuuid.namespace_%s, %s).to_string(), %s)" % (space, lit(name), lit(str(uuid.uuid5(ns, name)))),
    ]))

# Fixed clock and random bytes.
real_ns, real_urandom = time.time_ns, os.urandom


def fixed(clock, randoms):
    clock = list(clock)
    randoms = list(randoms)
    time.time_ns = lambda: clock.pop(0)
    os.urandom = lambda n: randoms.pop(0)[:n]


for i, r in enumerate([bytes(range(16)), bytes([0xFF] * 16), bytes.fromhex("0f1e2d3c4b5a69788796a5b4c3d2e1f0")]):
    fixed([], [r])
    u = uuid.uuid4()
    test("python v4 #%d" % i, "  assert_eq(@moonuuid.v4(b\"%s\").to_string(), %s)" % ("".join("\\x%02x" % c for c in r), lit(str(u))))

for i, (ns, seq, node) in enumerate([(1_700_000_000_123_456_789, 0x33C8, 0x9F6BDECED846), (0, 0, 0), (1_234_567_890_000_000_001, 0x3FFF, 0xFFFFFFFFFFFF), (2_000_000_000_000_000_000, 12345, 0x010203040506)]):
    uuid._last_timestamp = None
    uuid._last_timestamp_v6 = None
    fixed([ns, ns], [])
    a = uuid.uuid1(node=node, clock_seq=seq)
    b = uuid.uuid6(node=node, clock_seq=seq)
    test("python v1 v6 #%d" % i, "\n".join([
        "  let ticks = @moonuuid.ticks_of(%dL)" % ns,
        "  assert_eq(@moonuuid.v1(ticks~, clock_seq=%d, node=%dL).to_string(), %s)" % (seq, node, lit(str(a))),
        "  assert_eq(@moonuuid.v6(ticks~, clock_seq=%d, node=%dL).to_string(), %s)" % (seq, node, lit(str(b))),
    ]))

for i, (a, b_, c) in enumerate([(0x123456789ABC, 0xDEF, 0x123456789ABCDEF0), (0, 0, 0), ((1 << 48) - 1, 0xFFF, (1 << 62) - 1)]):
    u = uuid.uuid8(a, b_, c)
    raw = ((a << 80) | (b_ << 64) | c).to_bytes(16)
    test("python v8 #%d" % i, "  assert_eq(@moonuuid.v8(b\"%s\").to_string(), %s)" % ("".join("\\x%02x" % x for x in raw), lit(str(u))))

# A generator: the same clock readings and random bytes as Python's module.
SCENARIOS = [
    ("steady", [1_700_000_000_000_000_000 + k * 1_000_000 for k in range(4)]),
    ("same millisecond", [1_700_000_000_000_000_000] * 5),
    ("clock steps back", [1_700_000_000_005_000_000, 1_700_000_000_001_000_000, 1_700_000_000_001_000_000, 1_700_000_000_009_000_000]),
]
for name, clock in SCENARIOS:
    stream = [bytes([(k * 37 + j * 11) & 0xFF for j in range(10)]) for k in range(len(clock) * 2)]
    uuid._last_timestamp_v7 = None
    uuid._last_counter_v7 = 0
    used = []

    def draw(n, stream=stream, used=used):
        b = stream.pop(0)[:n]
        used.append(b)
        return b

    clk = list(clock)
    time.time_ns = lambda clk=clk: clk.pop(0)
    os.urandom = draw
    ids = [str(uuid.uuid7()) for _ in clock]
    body = ["  let clock = %s" % json.dumps(clock).replace(",", "L,").replace("]", "L]"),
            "  let draws : Array[Bytes] = [%s]" % ", ".join('b"%s"' % "".join("\\x%02x" % c for c in b) for b in used),
            "  let t = Ref(0)",
            "  let r = Ref(0)",
            "  let gen = @moonuuid.Generator::new(clock=() => { t.val += 1; clock[t.val - 1] }, random=_ => { r.val += 1; draws[r.val - 1] })",
            "  let got = []",
            "  for _ in clock {",
            "    got.push(gen.v7().to_string())",
            "  }",
            "  assert_eq(got, %s)" % json.dumps(ids)]
    test("python generator v7 %s" % name, "\n".join(body))
time.time_ns, os.urandom = real_ns, real_urandom

open(sys.argv[1], "w", encoding="utf-8", newline="\n").write("\n".join(lines))
print(len(lines))
