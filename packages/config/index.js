// Deliberately plain JavaScript, not TypeScript. apps/server compiles to dist/
// and runs on bare `node`, which cannot load a .ts entry point except via its
// experimental type-stripping - a version-dependent thing to hang a production
// boot on. Shipping .js + index.d.ts means every consumer (node, bun, Next's
// bundler, tsc) resolves this the same boring way, with no build step.
import raw from "./pixl.json" with { type: "json" };

export const config = raw;

export const launchDate = new Date(config.launchDate);
export const hackatimeCutoff = new Date(config.hackatimeCutoff);

/** Seconds since epoch - the shape Hackatime's API wants. */
export const hackatimeCutoffUnix = Math.floor(hackatimeCutoff.getTime() / 1000);

export const hasLaunched = (now = new Date()) => now >= launchDate;

/**
 * Human label for a config date, always rendered in UTC so every app agrees.
 * Formatting in local time would put players either side of the date line on
 * different days, which is the drift this package exists to stop.
 */
export function formatDate(date, opts = { month: "short", day: "numeric" }, locale = "en-US") {
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
