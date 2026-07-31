-- Track a player's progress through the cross-app onboarding so the in-game
-- first-run guide and the web dashboard tour hand off to each other instead of
-- running as two disconnected first-run experiences. One shared, forward-only
-- counter, keyed off the same account (token) both apps already carry:
--   0 = brand new, nothing seen
--   1 = in-game intro + story done, dashboard tour still pending
--   2 = dashboard tour finished (fully onboarded)
--
-- Written/read by apps/game/scripts/guide_hud.gd and apps/game/web/pixl.js via
-- /api/profile/onboarding. Run this in the Supabase SQL editor. Safe to run
-- more than once.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS onboarding_step INT NOT NULL DEFAULT 0;
