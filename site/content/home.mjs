/**
 * Home-page copy. Numbers are the library's own; nothing here is a comparison.
 */

export const stats = [
  { num: "7", label: "versions", note: "every one the RFC defines" },
  { num: "128", label: "bits", note: "one fixed width" },
  { num: "5", label: "spellings", note: "read from text" },
  { num: "16", label: "octets", note: "kept in order" },
];

export const features = [
  {
    no: "01",
    title: "Every version, one type",
    text: `Time-based, name-based, random and custom identifiers all come back as the
      same <code>Uuid</code>. One parser and one set of writers cover every version.`,
  },
  {
    no: "02",
    title: "A generator you feed",
    text: `<code>Generator::new</code> takes a clock and a random source. It keeps the
      counters, so versions 1 and 6 never repeat and version 7 sorts in the order made.`,
  },
  {
    no: "03",
    title: "Fields you can read",
    text: `<code>version</code>, <code>variant</code>, <code>time</code>,
      <code>clock_seq</code> and <code>node</code> read the bits back as values, not as a
      string you slice.`,
  },
  {
    no: "04",
    title: "Text in, text out",
    text: `Canonical, plain hex, braces or <code>urn:uuid:</code>, in any case.
      <code>to_string</code>, <code>hex</code> and <code>urn</code> write it back.`,
  },
  {
    no: "05",
    title: "JSON without glue",
    text: `A UUID is a JSON string on the way out and any spelling on the way in, with no
      wrapper type to write.`,
  },
  {
    no: "06",
    title: "Refusals with reasons",
    text: `<code>Malformed</code> points at the character that stopped the parse.
      <code>Size</code> gives the two lengths. Nothing fails silently.`,
  },
];

export const anatomy = {
  uuid: "c232ab00-9414-11ec-b3c8-9f6bdeced846",
  groups: [
    { text: "c232ab00", field: 0, label: "time_low" },
    { text: "9414", field: 1, label: "time_mid" },
    { text: "11ec", field: 2, label: "version + time_hi" },
    { text: "b3c8", field: 3, label: "clock_seq" },
    { text: "9f6bdeced846", field: 4, label: "node" },
  ],
};
