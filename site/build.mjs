import { writeFile, mkdir, copyFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pug from "pug";
import * as sass from "sass";
import * as esbuild from "esbuild";
import { highlight } from "./highlight.mjs";
import * as guide from "./content/guide.mjs";
import * as home from "./content/home.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const docs = path.join(root, "docs");
const assets = path.join(docs, "assets");

await mkdir(assets, { recursive: true });

/* 1. stylesheet ---------------------------------------------------------- */
const css = sass.compile(path.join(here, "scss", "main.scss"), {
  style: "compressed",
});
await writeFile(path.join(assets, "style.css"), css.css + "\n", "utf8");

/* 2. interactive bundles ------------------------------------------------- */
await esbuild.build({
  entryPoints: {
    home: path.join(here, "ts", "home.ts"),
    showcase: path.join(here, "ts", "showcase.ts"),
  },
  outdir: assets,
  bundle: true,
  format: "esm",
  target: ["es2020"],
  minify: true,
  external: ["moonuuid"],
  legalComments: "none",
  logLevel: "warning",
});

/* 3. the small runtime script ------------------------------------------- */
await copyFile(path.join(here, "static", "theme.js"), path.join(assets, "theme.js"));

/* 4. the compiled library, if it has been built ------------------------- */
const candidates = [
  path.join(root, "_build", "js", "release", "build", "jsapi", "jsapi.js"),
  path.join(root, "_build", "js", "debug", "build", "jsapi", "jsapi.js"),
];
const lib = candidates.find((candidate) => existsSync(candidate));
if (lib) {
  await copyFile(lib, path.join(assets, "moonuuid.js"));
  console.log("lib   <- " + path.relative(root, lib));
} else {
  console.warn(
    "lib   ! jsapi not built. Run: moon build --target js --release src/jsapi"
  );
}

/* 5. pages --------------------------------------------------------------- */
const pages = [
  {
    file: "index.pug",
    out: "index.html",
    page: "home",
    title: "moonuuid — UUIDs for MoonBit",
    desc: "Read every spelling of a UUID, write the canonical one, and make ids from a name, a clock or random bytes you supply.",
  },
  {
    file: "guide.pug",
    out: "guide.html",
    page: "guide",
    title: "Guide — moonuuid",
    desc: "A short, runnable guide to parsing, writing, reading the fields, and generating UUIDs of every version.",
  },
  {
    file: "showcase.pug",
    out: "showcase.html",
    page: "showcase",
    title: "Anatomy — moonuuid",
    desc: "Paste a UUID or make one, and see the version, variant, timestamp, clock sequence and node in place.",
  },
];

for (const item of pages) {
  const html = pug.renderFile(path.join(here, "pug", item.file), {
    page: item.page,
    title: item.title,
    desc: item.desc,
    guide,
    home,
    highlight,
  });
  await writeFile(path.join(docs, item.out), html + "\n", "utf8");
}

console.log("pages <- " + pages.map((item) => item.out).join(", "));

/* 6. the reference ------------------------------------------------------- */
/* The body is generated from the package interface by scripts/gen_api.py. If
   it has not run, leave the last rendered api.html alone rather than replacing
   it with a placeholder. */
let apiBody = null;
try {
  apiBody = await import("./content/api-body.mjs");
} catch {
  console.warn(
    "api   ! site/content/api-body.mjs is missing. Run: python3 scripts/gen_api.py"
  );
}

if (apiBody) {
  const html = pug.renderFile(path.join(here, "pug", "api.pug"), {
    page: "api",
    title: "API reference — moonuuid",
    desc: "Every public value, function, type and method in moonbitstack/moonuuid.",
    apiBody: apiBody.body,
    apiFilter: apiBody.filter,
  });
  await writeFile(path.join(docs, "api.html"), html + "\n", "utf8");
  console.log("api   <- api.html");
}
