name = "moonbitstack/moonuuid"

version = "0.1.1"

readme = "README.md"

repository = "https://github.com/moonbitstack/moonuuid"

license = "Apache-2.0"

keywords = [ "uuid", "guid", "identifier", "rfc9562", "moonbit" ]

description = "UUIDs for MoonBit: parsing and versions 1 to 8."

source = "src"

import {
  "moonbitstack/mooncrypt@0.4.4",
  "moonbitstack/moonrand@0.1.0",
}

preferred_target = "wasm-gc"
