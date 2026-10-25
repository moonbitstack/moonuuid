name = "moonbitstack/moonuuid"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/moonbitstack/moonuuid"

license = "Apache-2.0"

keywords = [ "uuid", "guid", "identifier", "rfc9562", "moonbit" ]

description = "UUIDs: parse and write every spelling, make versions 1 to 8, and a generator over a clock and randomness you supply."

source = "src"

import {
  "moonbitstack/mooncrypt@0.4.3",
}

preferred_target = "wasm-gc"
