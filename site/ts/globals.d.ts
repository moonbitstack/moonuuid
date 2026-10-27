// The subset of the Vue global build this site touches. The browser bundle is
// loaded from a CDN, so the shape is declared here instead of imported. Only
// what the pages actually call is listed; anything else would be dead weight.
interface VueRef<T> {
  value: T;
}

interface VueApp {
  mount(selector: string): void;
}

declare const Vue: {
  createApp(options: { setup(): Record<string, unknown> }): VueApp;
  ref<T>(value: T): VueRef<T>;
  computed<T>(getter: () => T): VueRef<T>;
};
