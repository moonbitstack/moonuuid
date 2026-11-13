"""The Python standard library's side of the cross-implementation check.

It prints and reads the same tab-separated lines as the library's
src/examples/03-interop, so scripts/check_interop.py can compare the two.

    python main.py make
    python main.py read <text>...

Every line of `make` is `label<TAB>identifier`. Every line of `read` is
`text<TAB>canonical<TAB>version<TAB>variant<TAB>time<TAB>clock
sequence<TAB>node<TAB>hex<TAB>urn`, with `-` where the version carries no such
field and `!` when the text is refused.
"""

import sys
import time
import uuid

# Hundred-nanosecond ticks between 1582-10-15 and 1970-01-01.
GREGORIAN = 122_192_928_000_000_000
REAL_CLOCK = time.time_ns

# The clock and the byte source are replaced while `make` runs, so the lines
# are the same on every machine.
def fixed_clock(nanos):
    time.time_ns = lambda: nanos
    uuid._last_timestamp = None
    uuid._last_timestamp_v7 = None
    uuid._last_counter_v7 = 0


def variant_name(u):
    return {
        uuid.RESERVED_NCS: "Ncs",
        uuid.RFC_4122: "Rfc",
        uuid.RESERVED_MICROSOFT: "Microsoft",
        uuid.RESERVED_FUTURE: "Future",
    }[u.variant]


def stamp(u):
    # fields are time_low, time_mid, time_hi_and_version: the first 32 bits,
    # the next 16, and the 16 that carry the version and the next 12.
    a, b, c = u.fields[0], u.fields[1], u.fields[2]
    if u.variant != uuid.RFC_4122:
        return "-"
    if u.version == 1:
        return str(((c & 0x0FFF) << 48) | (b << 32) | a)
    if u.version == 6:
        return str((a << 28) | (b << 12) | (c & 0x0FFF))
    if u.version == 7:
        return str((a << 16) | b)
    return "-"


def describe(text):
    try:
        u = uuid.UUID(text)
    except ValueError:
        return "%s\t!" % text
    rfc = u.variant == uuid.RFC_4122
    fielded = rfc and u.version in (1, 6)
    return "\t".join(
        [
            text,
            str(u),
            str(u.version) if rfc else "-",
            variant_name(u),
            stamp(u),
            str(u.clock_seq & 0x3FFF) if fielded else "-",
            str(u.node) if fielded else "-",
            u.hex,
            u.urn,
        ]
    )


def made():
    counting = bytes(range(16))
    zero = bytes(16)
    # The RFC 9562 appendix example, as nanoseconds since 1970.
    rfc_ticks = 0x1EC9414C232AB00
    rows = [
        ("v3-dns-www", uuid.uuid3(uuid.NAMESPACE_DNS, "www.example.com")),
        ("v5-dns-www", uuid.uuid5(uuid.NAMESPACE_DNS, "www.example.com")),
        ("v5-url-example", uuid.uuid5(uuid.NAMESPACE_URL, "https://example.org/")),
        ("v4-zero", uuid.UUID(bytes=zero, version=4)),
        ("v4-count", uuid.UUID(bytes=counting, version=4)),
    ]
    # Versions 6, 7 and 8 arrived in the module after 3.13; the check uses
    # whichever ones this interpreter has.
    fixed_clock((rfc_ticks - GREGORIAN) * 100)
    rows.append(("v1-rfc", uuid.uuid1(node=0x9F6BDECED846, clock_seq=0x33C8)))
    if hasattr(uuid, "uuid6"):
        rows.append(("v6-rfc", uuid.uuid6(node=0x9F6BDECED846, clock_seq=0x33C8)))
    if hasattr(uuid, "uuid8"):
        rows.append(("py-v8", uuid.uuid8(0x123456789ABC, 0xDEF, 0x123456789ABCDEF0)))
    return [(label, str(u)) for label, u in rows]


def now():
    """The identifiers the module makes from the clock, different every run."""
    time.time_ns = REAL_CLOCK
    uuid._last_timestamp = None
    uuid._last_timestamp_v7 = None
    uuid._last_counter_v7 = 0
    rows = [("py-v1-now", uuid.uuid1(node=0x9F6BDECED846, clock_seq=0x33C8))]
    if hasattr(uuid, "uuid7"):
        rows.append(("py-v7-now", uuid.uuid7()))
    return [(label, str(u)) for label, u in rows]


def main(argv):
    mode = argv[0] if argv else "make"
    if mode == "read":
        for text in argv[1:]:
            print(describe(text))
        return 0
    for label, text in (now() if mode == "now" else made()):
        print("%s\t%s" % (label, text))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
