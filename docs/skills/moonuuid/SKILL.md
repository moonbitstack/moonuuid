---
name: moonuuid
description: "Make and read UUIDs in MoonBit with moonbitstack/moonuuid: every version RFC 9562 defines (1, 3, 4, 5, 6, 7, 8), any spelling read back, the canonical one written, with the clock and the randomness passed in. Use when code needs a database key that sorts by time, a stable id derived from a name, a random id, or has to parse, compare or inspect an id it was given."
---

# moonuuid

```bash
moon add moonbitstack/moonuuid
moon add moonbitstack/moonseed   # the random source a generator draws from
```

```moonbit
// moon.pkg
import {
  "moonbitstack/moonuuid",
  "moonbitstack/moonseed/system",
}
```

## Pick a version

- A key that sorts in the order rows were made: version 7, from a `Generator`.
- The same id every time for the same name: version 5, `v5(namespace, name)`.
- Nothing to sort or derive: version 4.

## Time-ordered keys

```moonbit
fn keys() -> @moonuuid.Generator {
  @moonuuid.Generator::new(
    clock=() => (@env.now() * 1_000_000UL).reinterpret_as_int64(), // nanoseconds since 1970
    random=@system.source,
  )
}

fn next_key(gen : @moonuuid.Generator) -> String raise @moonuuid.Refused {
  gen.v7().to_string()
}
```

Ids made within one millisecond still count up, and if the clock steps back the next id takes the millisecond after the last one, so the order holds. A test passes its own `clock` and a fixed source instead.

## Ids from a name

```moonbit
fn page_id(url : String) -> String {
  @moonuuid.v5(@moonuuid.namespace_url, url).to_string()
}
```

The namespaces are `namespace_dns`, `namespace_url`, `namespace_oid` and `namespace_x500`; any `Uuid` serves as one.

## Reading an id

```moonbit
fn describe(text : String) -> String raise @moonuuid.Refused {
  let id = @moonuuid.parse(text) // canonical, any case, no hyphens, {braces}, urn:uuid:
  let version = match id.version() {
    Some(v) => v.to_string()
    None => "none"
  }
  "\{id.to_string()} version \{version}"
}
```

`to_string()` writes the canonical lowercase form, `hex()` the 32 digits, `urn()` the URN, `bytes()` the 16 bytes. Ids compare, hash and sort by their bytes, and `ToJson` writes the canonical text.

## Things that catch people out

- Nothing here reads a clock or a random source by itself: the generator takes `clock` and `random`, and the plain functions take the bytes or the time. That is what makes tests repeatable.
- `version()` answers `None` for an id that is not an RFC 9562 one, such as the nil id or a Microsoft GUID.
- `time()` counts 100-nanosecond intervals since 1582 for versions 1 and 6, and milliseconds since 1970 for version 7. `ticks_of` converts nanoseconds since 1970 into the former.
- Version 2 is reserved for DCE security and is not generated.
- `parse` raises `Malformed(at~, reason~)` with the offset where the text stopped being an id.
