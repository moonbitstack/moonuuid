import * as wasm from "moonuuid";

export interface Info {
  ok: true;
  uuid: string;
  hex: string;
  urn: string;
  version: number | null;
  variant: string;
  time: string | null;
  timeKind: "ticks" | "millis" | "none";
  clockSeq: number;
  node: string;
  bytes: number[];
  hi: string;
  lo: string;
}

export interface Bad {
  ok: false;
  error: string;
}

export type Result = Info | Bad;

export const NAMESPACES: Record<string, string> = {
  dns: "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
  url: "6ba7b811-9dad-11d1-80b4-00c04fd430c8",
  oid: "6ba7b812-9dad-11d1-80b4-00c04fd430c8",
  x500: "6ba7b814-9dad-11d1-80b4-00c04fd430c8",
};

function decode(raw: string): Result {
  return JSON.parse(raw) as Result;
}

export function describe(text: string): Result {
  return decode(wasm.describe(text));
}

export function make(
  version: string,
  options: { space?: string; name?: string } = {}
): Result {
  const space = options.space ?? NAMESPACES.dns;
  const name = options.name ?? "moonuuid";
  switch (version) {
    case "v1":
      return decode(wasm.make_v1());
    case "v3":
      return decode(wasm.make_v3(space, name));
    case "v4":
      return decode(wasm.make_v4());
    case "v5":
      return decode(wasm.make_v5(space, name));
    case "v6":
      return decode(wasm.make_v6());
    case "v7":
      return decode(wasm.make_v7());
    case "v8":
      return decode(wasm.make_v8());
    default:
      return { ok: false, error: "unknown version" };
  }
}

const GROUP_RANGES: Array<[number, number]> = [
  [0, 8],
  [8, 12],
  [12, 16],
  [16, 20],
  [20, 32],
];

const FALLBACK_LABELS = [
  "bits 0–31",
  "bits 32–47",
  "bits 48–63",
  "bits 64–79",
  "bits 80–127",
];

const LABELS: Record<number, string[]> = {
  1: ["time_low", "time_mid", "version + time_hi", "clock_seq", "node"],
  3: ["hash", "hash", "version", "variant + hash", "hash"],
  4: ["random", "random", "version", "variant + random", "random"],
  5: ["hash", "hash", "version", "variant + hash", "hash"],
  6: ["time_hi", "time_mid", "version + time_low", "clock_seq", "node"],
  7: ["unix_ts_ms", "unix_ts_ms", "version + rand_a", "variant + rand_b", "rand_b"],
  8: ["custom_a", "custom_b", "version", "variant + custom_c", "custom_d"],
};

export interface Segment {
  text: string;
  hyp: boolean;
  field: number;
  label: string;
}

export interface LegendItem {
  label: string;
  field: number;
}

export function segments(info: Info): { parts: Segment[]; legend: LegendItem[] } {
  const labels = LABELS[info.version ?? 0] ?? FALLBACK_LABELS;

  // One colour per distinct field name, in the order the fields appear, so a
  // field that spans more than one group stays one colour.
  const order: string[] = [];
  for (const label of labels) {
    if (!order.includes(label)) order.push(label);
  }
  const fieldOf = new Map<string, number>();
  order.forEach((label, index) => fieldOf.set(label, index % 5));

  const parts: Segment[] = [];
  for (let group = 0; group < 5; group++) {
    if (group > 0) {
      parts.push({ text: "-", hyp: true, field: -1, label: "" });
    }
    const [start, end] = GROUP_RANGES[group];
    parts.push({
      text: info.hex.slice(start, end),
      hyp: false,
      field: fieldOf.get(labels[group]) ?? 0,
      label: labels[group],
    });
  }

  const legend = order.map((label) => ({
    label,
    field: fieldOf.get(label) ?? 0,
  }));

  return { parts, legend };
}

export interface Nibble {
  ch: string;
  field: number;
}

/** The 32 hexadecimal digits, each with the field colour it belongs to. */
export function nibbles(info: Info): Nibble[] {
  const { parts } = segments(info);
  const out: Nibble[] = [];
  for (const part of parts) {
    if (part.hyp) continue;
    for (const ch of part.text) out.push({ ch, field: part.field });
  }
  return out;
}

const GREGORIAN_OFFSET = 122192928000000000n;

export interface Stamp {
  iso: string;
  raw: string;
  kind: string;
}

export function timestamp(info: Info): Stamp | null {
  if (!info.time || info.timeKind === "none") return null;
  let millis: number;
  if (info.timeKind === "millis") {
    millis = Number(info.time);
  } else {
    millis = Number((BigInt(info.time) - GREGORIAN_OFFSET) / 10000n);
  }
  const date = new Date(millis);
  if (Number.isNaN(date.getTime())) return null;
  return { iso: date.toISOString(), raw: info.time, kind: info.timeKind };
}

export function nodeColon(info: Info): string {
  const pairs = info.node.match(/.{2}/g);
  return pairs ? pairs.join(":") : info.node;
}

export interface ByteCell {
  hex: string;
  dec: number;
}

export function bytes(info: Info): ByteCell[] {
  return info.bytes.map((value) => ({
    hex: value.toString(16).padStart(2, "0"),
    dec: value,
  }));
}

export function special(info: Info): string {
  if (/^0+$/.test(info.hex)) return "nil";
  if (/^f+$/.test(info.hex)) return "max";
  return "";
}

export function versionLabel(info: Info): string {
  return info.version === null ? "—" : "v" + info.version;
}

/** Versions 1 and 6 carry a clock sequence and a node. */
export function hasClockFields(info: Info): boolean {
  return info.version === 1 || info.version === 6;
}
