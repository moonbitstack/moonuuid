name = "moonbitstack/moonuuid"

version = "0.1.4"

readme = "README.md"

repository = "https://github.com/moonbitstack/moonuuid"

license = "Apache-2.0"

keywords = [
  "uuid",
  "guid",
  "identifier",
  "id",
  "unique-id",
  "rfc9562",
  "rfc4122",
  "uuidv1",
  "uuidv3",
  "uuidv4",
  "uuidv5",
  "uuidv6",
  "uuidv7",
  "uuidv8",
  "moonbit",
]

description = "UUIDs for MoonBit: parsing and versions 1 to 8."

source = "src"

import {
  "moonbitstack/mooncrypt@0.4.6",
  "moonbitstack/moonseed@0.1.0",
}

preferred_target = "wasm-gc"
