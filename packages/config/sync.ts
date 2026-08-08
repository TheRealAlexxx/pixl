/**
 * Pushes pixl.json into the two consumers that cannot import a workspace
 * package: the Godot game (runs from an exported PCK) and the game's web pages
 * (plain <script>-tag JS, no bundler).
 *
 *   bun run config:sync
 *
 * Both targets are committed - the game needs them at runtime - but they are
 * generated. Hand-edits get overwritten on the next run. See README.md.
 */
import { readFile, writeFile } from "node:fs/promises";

const ROOT = new URL("../../", import.meta.url).pathname;
const SOURCE = `${ROOT}packages/config/pixl.json`;
const GODOT_TARGET = `${ROOT}apps/game/pixl.json`;
const WEB_TARGET = `${ROOT}apps/game/web/pixl.js`;

const NOTE = "GENERATED from packages/config/pixl.json by `bun run config:sync` - do not edit";
const OPEN = "  // <pixl-config>";
const CLOSE = "  // </pixl-config>";

const raw = await readFile(SOURCE, "utf8");
const config = JSON.parse(raw);

// Godot reads this straight off res:// via scripts/pixl_config.gd. JSON has no
// comment syntax, so the "do not edit" warning has to ride along as a key.
await writeFile(GODOT_TARGET, `${JSON.stringify({ _generated: NOTE, ...config }, null, 2)}\n`);

// pixl.js is loaded by all 14 web pages, so injecting one block there reaches
// every one of them without touching a single HTML file.
const web = await readFile(WEB_TARGET, "utf8");
const start = web.indexOf(OPEN);
const end = web.indexOf(CLOSE);
if (start === -1 || end === -1) {
  console.error(`[config:sync] missing ${OPEN} / ${CLOSE} markers in ${WEB_TARGET}`);
  process.exit(1);
}

const block = [
  OPEN,
  `  // ${NOTE}`,
  `  const config = ${JSON.stringify(config, null, 2).replace(/\n/g, "\n  ")};`,
  CLOSE,
].join("\n");

await writeFile(WEB_TARGET, web.slice(0, start) + block + web.slice(end + CLOSE.length));

console.log(`[config:sync] wrote ${GODOT_TARGET} and the generated block in ${WEB_TARGET}`);
