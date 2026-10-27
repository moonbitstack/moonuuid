import {
  make,
  segments,
  timestamp,
  versionLabel,
  nodeColon,
  NAMESPACES,
  type Info,
  type Result,
} from "./lib";

const V = (globalThis as any).Vue as typeof Vue | undefined;

function fallback(): void {
  const el = document.getElementById("generator");
  if (!el) return;
  el.removeAttribute("v-cloak");
  el.innerHTML = '<p class="demo__note">The live demo needs JavaScript.</p>';
}

function mount(V: typeof Vue): void {
  const { createApp, ref, computed } = V;

  createApp({
    setup() {
      const info = ref<Info | null>(null);
      const error = ref("");
      const last = ref("v7");
      const makers = [
        { id: "v7", label: "v7" },
        { id: "v4", label: "v4" },
        { id: "v6", label: "v6" },
        { id: "v1", label: "v1" },
        { id: "v5", label: "v5" },
      ];

      function apply(result: Result): void {
        if (result.ok) {
          info.value = result;
          error.value = "";
        } else {
          info.value = null;
          error.value = result.error;
        }
      }

      function pick(version: string): void {
        last.value = version;
        apply(make(version, { space: NAMESPACES.dns, name: "moonuuid" }));
      }

      const parts = computed(() => (info.value ? segments(info.value).parts : []));
      const version = computed(() => (info.value ? versionLabel(info.value) : "—"));
      const node = computed(() => (info.value ? nodeColon(info.value) : "—"));
      const timeText = computed(() => {
        if (!info.value) return "—";
        const stamp = timestamp(info.value);
        return stamp ? stamp.iso : "—";
      });

      pick("v7");

      return { info, error, last, makers, pick, parts, version, node, timeText };
    },
  }).mount("#generator");
}

if (V) {
  mount(V);
} else {
  fallback();
}
