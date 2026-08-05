import { supabase } from "./db/client.js";

// XP = 1 per approved hour; level = approved hours, capped at 100 (display
// only - separate from the rate tiers below, which run past 100h).
export const MAX_LEVEL = 100;

export function levelFor(xp: number): number {
  return Math.min(MAX_LEVEL, Math.floor(Math.max(xp, 0)));
}

// Restoration rate tiers: named milestones in cumulative lifetime approved
// hours where the per-hour payout steps up. Flat between tiers (no smooth
// ramp) so hitting one reads as an actual milestone, not a rounding blip.
// 1px = $0.07. Keep this table in sync with apps/dashboard/app/actions.ts's
// copy (that file can't import server code across apps) - this exact drift
// bit us once already (40/60 vs 50/79, fixed 2026-08-01).
export const RATE_TIERS: { hours: number; pxPerHour: number }[] = [
  { hours: 0, pxPerHour: 50 }, // $3.50/hr - base
  { hours: 25, pxPerHour: 57 }, // $4.00/hr
  { hours: 75, pxPerHour: 64 }, // $4.50/hr
  { hours: 175, pxPerHour: 71 }, // $5.00/hr
  { hours: 350, pxPerHour: 79 }, // $5.50/hr - old ceiling, now mid-tier
  { hours: 500, pxPerHour: 86 }, // $6.00/hr - rare top tier, pairs with the Blahaj trophy (drizzle/0032, now unlock_xp=500)
];

export function pxPerHourFor(xp: number): number {
  let rate = RATE_TIERS[0].pxPerHour;
  for (const tier of RATE_TIERS) {
    if (xp >= tier.hours) rate = tier.pxPerHour;
  }
  return rate;
}

export async function approvedHoursFor(
  userId: string,
  excludeProjectId?: number,
): Promise<number> {
  let q = supabase
    .from("projects")
    .select("id, approved_hours, hackatime_seconds")
    .eq("user_id", userId)
    .eq("status", "approved")
    .is("banned_at", null);
  if (excludeProjectId) q = q.neq("id", excludeProjectId);
  const { data } = await q;
  return (
    Math.round(
      (data ?? []).reduce((s, p) => {
        const h =
          p.approved_hours != null
            ? Number(p.approved_hours)
            : (Number(p.hackatime_seconds) || 0) / 3600;
        return s + (Number.isFinite(h) ? h : 0);
      }, 0) * 10,
    ) / 10
  );
}

// Total Restoration Energy pooled by the whole community: every approved hour
// shipped, summed across all players. Drives the Core Vault's community goals.
export async function communityEnergy(): Promise<number> {
  const { data } = await supabase
    .from("projects")
    .select("approved_hours, hackatime_seconds")
    .eq("status", "approved")
    .is("banned_at", null);
  const hours = (data ?? []).reduce((s, p) => {
    const h =
      p.approved_hours != null
        ? Number(p.approved_hours)
        : (Number(p.hackatime_seconds) || 0) / 3600;
    return s + (Number.isFinite(h) ? h : 0);
  }, 0);
  return Math.round(hours);
}
