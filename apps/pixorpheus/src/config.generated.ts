// GENERATED from packages/config/pixl.json by `bun run config:sync` - do not edit
/* eslint-disable */
export const config = {
  "name": "Pixl",
  "tagline": "A retro 2D world where you level up by building real things",
  "launchDate": "2026-08-18T00:00:00Z",
  "hackatimeCutoff": "2026-08-18T00:00:00Z",
  "urls": {
    "site": "https://www.pixl.rsvp",
    "play": "https://play.pixl.rsvp",
    "docs": "https://pixl.rsvp/docs",
    "repo": "https://github.com/ridit-jangra/pixl"
  },
  "economy": {
    "pixelsPerHour": 50,
    "pixelValueUsd": 0.07
  },
  "team": [
    "Gabin",
    "Ridit",
    "Ricky"
  ]
} as const;

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
