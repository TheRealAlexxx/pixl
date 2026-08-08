/**
 * Pushes pixl.json out to every app.
 *
 *   bun run config:sync
 *
 * This package is a *build-time* source of truth, not a runtime dependency.
 * Nothing imports "@pixl/config" at runtime, deliberately: both Railway services
 * build from a `/apps/<app>` root directory, so a workspace package sitting
 * outside that directory does not exist at install time and `bun install`
 * fails with "Workspace dependency @pixl/config not found". Generating a
 * self-contained file into each app sidesteps package resolution everywhere -
 * Railway, Vercel, the Godot export, and plain <script> tags all just work.
 *
 * Every target below is committed (the apps need them to build and run) but
 * generated. Hand-edits are overwritten on the next run. See README.md.
 */
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname } from "node:path";

const ROOT = new URL("../../", import.meta.url).pathname;
const SOURCE = `${ROOT}packages/config/pixl.json`;

const NOTE = "GENERATED from packages/config/pixl.json by `bun run config:sync` - do not edit";

const raw = await readFile(SOURCE, "utf8");
const config = JSON.parse(raw);
const pretty = JSON.stringify(config, null, 2);

const written: string[] = [];

async function write(path: string, contents: string) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, contents);
  written.push(path.replace(ROOT, ""));
}

// --- Godot: read off res:// by scripts/pixl_config.gd -----------------------
// JSON has no comment syntax, so the "do not edit" warning rides along as a key.
await write(
  `${ROOT}apps/game/pixl.json`,
  `${JSON.stringify({ _generated: NOTE, ...config }, null, 2)}\n`,
);

// --- The game's web pages ---------------------------------------------------
// pixl.js is loaded by all 14 pages, so one injected block reaches every one of
// them without touching a single HTML file.
const OPEN = "  // <pixl-config>";
const CLOSE = "  // </pixl-config>";
const WEB_TARGET = `${ROOT}apps/game/web/pixl.js`;
const web = await readFile(WEB_TARGET, "utf8");
const start = web.indexOf(OPEN);
const end = web.indexOf(CLOSE);
if (start === -1 || end === -1) {
  console.error(`[config:sync] missing ${OPEN} / ${CLOSE} markers in ${WEB_TARGET}`);
  process.exit(1);
}
const block = [OPEN, `  // ${NOTE}`, `  const config = ${pretty.replace(/\n/g, "\n  ")};`, CLOSE];
await write(WEB_TARGET, web.slice(0, start) + block.join("\n") + web.slice(end + CLOSE.length));

// --- TypeScript apps --------------------------------------------------------
// Self-contained on purpose: no import of this package, so each app's build only
// ever sees its own directory. The helpers are duplicated across the generated
// files, which is fine - nobody hand-maintains them.
const ts = `// ${NOTE}
/* eslint-disable */
export const config = ${pretty} as const;

export const launchDate = new Date(config.launchDate);
export const hackatimeCutoff = new Date(config.hackatimeCutoff);

/** Seconds since epoch - the shape Hackatime's API wants. */
export const hackatimeCutoffUnix = Math.floor(hackatimeCutoff.getTime() / 1000);

export const hasLaunched = (now: Date = new Date()): boolean => now >= launchDate;

/**
 * Always formats in UTC so every app agrees. Local time would put players either
 * side of the date line on different days, which is the drift this file exists
 * to stop.
 */
export function formatDate(
  date: Date,
  opts: Intl.DateTimeFormatOptions = { month: "short", day: "numeric" },
  locale = "en-US",
): string {
  return new Intl.DateTimeFormat(locale, { ...opts, timeZone: "UTC" }).format(date);
}

/** e.g. "Aug 18" - the short form the ship-eligibility copy uses. */
export const hackatimeCutoffLabel = formatDate(hackatimeCutoff);

/** e.g. "August 18, 2026" - the long form the marketing copy uses. */
export const launchDateLabel = formatDate(launchDate, {
  month: "long",
  day: "numeric",
  year: "numeric",
});
`;

for (const target of [
  "apps/server/src/config.generated.ts",
  "apps/pixorpheus/src/config.generated.ts",
  "apps/landing/app/_generated/config.ts",
]) {
  await write(`${ROOT}${target}`, ts);
}

console.log(`[config:sync] wrote:\n  ${written.join("\n  ")}`);
