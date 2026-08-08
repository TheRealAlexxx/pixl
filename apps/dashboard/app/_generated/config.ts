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
    "pixelValueUsd": 0.07,
    "sponsorRateUsd": 8.5,
    "basePayoutUsd": 3.5,
    "maxPayoutUsd": 6,
    "reForMaxPayout": 5000,
    "tierRePerHour": [
      5,
      10,
      15,
      25
    ],
    "levelBands": [
      {
        "throughLevel": 10,
        "rePerLevel": 10
      },
      {
        "throughLevel": 50,
        "rePerLevel": 35
      },
      {
        "throughLevel": 100,
        "rePerLevel": 70
      }
    ]
  },
  "team": [
    "Gabin",
    "Ridit",
    "Ricky"
  ]
} as const;

const E = config.economy;

/** Max player level - the top of the last level band. */
export const MAX_LEVEL = E.levelBands[E.levelBands.length - 1].throughLevel;

/** Restoration Energy earned per hour at a given project tier (1-4). */
export function rePerHour(tier: number): number {
  const t = Math.min(Math.max(Math.trunc(tier) || 1, 1), E.tierRePerHour.length);
  return E.tierRePerHour[t - 1];
}

/** RE a project is worth: its hours at its tier's rate. */
export function reForHours(hours: number, tier: number): number {
  const h = Number.isFinite(hours) ? Math.max(hours, 0) : 0;
  return h * rePerHour(tier);
}

/**
 * Player level from lifetime RE. Levels are cosmetic - they never feed the
 * payout, which comes straight off RE. Early bands are cheap so a beginner on a
 * tier-1 project levels up within a couple of hours; later bands cost more.
 * Caps at MAX_LEVEL, though RE itself keeps accruing past it.
 */
export function levelForRe(re: number): number {
  let remaining = Number.isFinite(re) ? Math.max(re, 0) : 0;
  let level = 0;
  let prevTop = 0;
  for (const band of E.levelBands) {
    const span = band.throughLevel - prevTop;
    const cost = span * band.rePerLevel;
    if (remaining < cost) return level + Math.floor(remaining / band.rePerLevel);
    remaining -= cost;
    level = band.throughLevel;
    prevTop = band.throughLevel;
  }
  return level;
}

/** Total RE needed to reach a given level - the inverse of levelForRe. */
export function reForLevel(level: number): number {
  let re = 0;
  let prevTop = 0;
  for (const band of E.levelBands) {
    const top = Math.min(level, band.throughLevel);
    if (top > prevTop) re += (top - prevTop) * band.rePerLevel;
    prevTop = band.throughLevel;
    if (level <= band.throughLevel) break;
  }
  return re;
}

/**
 * Dollars per hour for a player holding this much lifetime RE. Ramps linearly
 * from basePayoutUsd to maxPayoutUsd, hitting the ceiling at reForMaxPayout.
 */
export function payoutUsdPerHour(re: number): number {
  const progress = Math.min(Math.max(re, 0) / E.reForMaxPayout, 1);
  return E.basePayoutUsd + progress * (E.maxPayoutUsd - E.basePayoutUsd);
}

/** Same rate expressed in pixels, which is what payouts are actually credited in. */
export function pxPerHourFor(re: number): number {
  return payoutUsdPerHour(re) / E.pixelValueUsd;
}

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
