-- Rescales the two thresholds that were denominated in raw approved hours, now
-- that the economy runs on Restoration Energy.
--
-- WHY THIS IS NOT OPTIONAL: src/xp.ts's communityEnergy() used to sum approved
-- hours; it now sums tier-weighted RE (hours x 5/10/15/25 depending on the
-- project's tier). On the expected tier mix that is ~12.5x larger per hour. If
-- these rows are left alone, every vault level unlocks almost immediately -
-- level 1 would fire after ~20 hours of community work instead of 250.
--
-- Run this in the Supabase SQL editor. Safe to run more than once (the WHERE
-- clauses match only the pre-rescale values).

-- ── Core Vault: community RE thresholds ─────────────────────────────────────
-- x12.5, which preserves the difficulty these numbers were *meant* to express.
--
-- These were never calibrated in the first place - 0038 seeded them blind and
-- 0077 called them "a starting estimate (~1000h shipped, per Ridit)". Rescaling
-- keeps them honest relative to the old intent, but they still want real
-- numbers once there is usage data. Note the multiplier also drifts with the
-- tier mix: if players skew toward T3/T4 the average climbs to ~14.5 RE/hour.
UPDATE vault_levels SET energy_required = 3125  WHERE level = 1 AND energy_required = 250;
UPDATE vault_levels SET energy_required = 9375  WHERE level = 2 AND energy_required = 750;
UPDATE vault_levels SET energy_required = 22500 WHERE level = 3 AND energy_required = 1800;
UPDATE vault_levels SET energy_required = 43750 WHERE level = 4 AND energy_required = 3500;
UPDATE vault_levels SET energy_required = 75000 WHERE level = 5 AND energy_required = 6000;
UPDATE vault_levels SET energy_required = 12500 WHERE level = 6 AND energy_required = 1000;

-- ── Trophies: unlock_xp now holds a player LEVEL (1-100), not hours ──────────
-- src/routes/shop.ts compares unlock_xp against the player's level, which comes
-- from lifetime RE. "3D Printed Blahaj" is the only trophy left after 0091/0092
-- dropped the rest, and 0077 had stranded it at unlock_xp = 500 - unreachable
-- when that meant 500 approved hours, which made the whole trophy grid dead
-- content. It now means level 100: the top of the ladder, ~200h of tier-4 work.
UPDATE shop_items SET unlock_xp = 100 WHERE unlock_xp = 500;
