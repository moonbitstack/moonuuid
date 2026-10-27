import {
  describe,
  make,
  segments,
  nibbles,
  timestamp,
  nodeColon,
  bytes,
  special,
  versionLabel,
  hasClockFields,
  NAMESPACES,
  type Info,
} from "./lib";

const V = (globalThis as any).Vue as typeof Vue | undefined;
const SAMPLE = "c232ab00-9414-11ec-b3c8-9f6bdeced846";

function fallback(): void {
  const el = document.getElementById("anatomy-app");
  if (!el) return;
  el.removeAttribute("v-cloak");
  el.innerHTML =
    '<p class="demo__note">The interactive anatomy needs JavaScript.</p>';
}

function mount(V: typeof Vue): void {
  const { createApp, ref, computed } = V;

  createApp({
    setup() {
      const input = ref(SAMPLE);
      const space = ref("dns");
      const name = ref("moonuuid");
      const info = ref<Info | null>(null);
      const error = ref("");
      const last = ref("v1");

      function read(text: string): void {
        const trimmed = text.trim();
        if (!trimmed) {
          info.value = null;
          error.value = "";
          return;
        }
        const result = describe(trimmed);
        if (result.ok) {
          info.value = result;
          error.value = "";
        } else {
          info.value = null;
          error.value = result.error;
        }
      }

      function refresh(): void {
        read(input.value);
      }

      function load(uuid: string): void {
        input.value = uuid;
        read(uuid);
      }

      function generate(version: string): void {
        last.value = version;
        const result = make(version, {
          space: NAMESPACES[space.value],
          name: name.value,
        });
        if (result.ok) {
          input.value = result.uuid;
          info.value = result;
          error.value = "";
        } else {
          info.value = null;
          error.value = result.error;
        }
      }

      const seg = computed(() =>
        info.value ? segments(info.value) : { parts: [], legend: [] }
      );
      const bits = computed(() => (info.value ? nibbles(info.value) : []));
      const stamp = computed(() => (info.value ? timestamp(info.value) : null));
      const cells = computed(() => (info.value ? bytes(info.value) : []));
      const version = computed(() => (info.value ? versionLabel(info.value) : "—"));
      const node = computed(() => (info.value ? nodeColon(info.value) : "—"));
      const tag = computed(() => (info.value ? special(info.value) : ""));
      const clockFields = computed(() =>
        info.value ? hasClockFields(info.value) : false
      );

      const makers = [
        { id: "v1", label: "v1" },
        { id: "v3", label: "v3" },
        { id: "v4", label: "v4" },
        { id: "v5", label: "v5" },
        { id: "v6", label: "v6" },
        { id: "v7", label: "v7" },
        { id: "v8", label: "v8" },
      ];

      const examples = [
        { label: "v1", uuid: SAMPLE },
        { label: "v4", uuid: "c2e9c2eb-9237-4ddb-958b-b6d7268b5db6" },
        { label: "v6", uuid: "1f1d1e52-c2cd-6e50-aa3b-001a2b3c4d5e" },
        { label: "v7", uuid: "01a17c99-00b6-7481-b57d-8230bbc62e2e" },
        { label: "nil", uuid: "00000000-0000-0000-0000-000000000000" },
        { label: "max", uuid: "ffffffff-ffff-ffff-ffff-ffffffffffff" },
      ];

      const notes: Record<string, string> = {
        v1: "timestamp, clock sequence and node; low time bits first",
        v3: "MD5 of a namespace and a name",
        v4: "122 random bits",
        v5: "SHA-1 of a namespace and a name",
        v6: "version 1's fields with the high time bits first",
        v7: "Unix milliseconds, a counter and random bits",
        v8: "122 bits of your own layout",
      };

      read(SAMPLE);

      return {
        input,
        space,
        name,
        info,
        error,
        last,
        seg,
        bits,
        stamp,
        cells,
        version,
        node,
        tag,
        clockFields,
        makers,
        examples,
        notes,
        refresh,
        load,
        generate,
      };
    },
  }).mount("#anatomy-app");
}

if (V) {
  mount(V);
} else {
  fallback();
}
