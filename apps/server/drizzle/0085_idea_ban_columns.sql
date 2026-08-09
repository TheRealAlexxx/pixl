-- Idea moderation: ban_reason/ban_by alongside 0084's banned_at, matching
-- the projects.banned_at/ban_reason/ban_by shape (0017) so the dashboard can
-- show who banned an idea and why.
--
-- Run in the Supabase SQL editor. Safe to re-run.

ALTER TABLE "ideas" ADD COLUMN IF NOT EXISTS "ban_reason" text NOT NULL DEFAULT '';
ALTER TABLE "ideas" ADD COLUMN IF NOT EXISTS "ban_by" text NOT NULL DEFAULT '';
