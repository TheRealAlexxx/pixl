-- First-Trial recommendation + coding-experience personalization.
--
-- Today (0031_sidequests) a sidequest is only { name, region, npc, description,
-- reward, active, position }. There is no difficulty, no tags, no "starter"
-- flag, and no per-player recommendation — so the onboarding can't point a new
-- Builder at a sensible first Trial. This adds the minimal columns the arrival
-- flow (Pixo's Trial Board) needs, seeds the three canon Chapter-I starters,
-- and stores the coding-experience answer Pixo asks for.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

-- ── sidequests: difficulty / tags / starter ────────────────────────────────
-- difficulty: 1 = beginner, 2 = intermediate, 3 = advanced (matches the three
--   experience answers). tags: freeform stack labels; keep the vocabulary the
--   same as projects.project_type (web, bot, game, ai, hardware, data, other)
--   so a shipped project can be matched back to a Trial later. starter: the
--   Chapter-I "first thaw" Trials Pixo can recommend on day 0.
ALTER TABLE sidequests
  ADD COLUMN IF NOT EXISTS difficulty smallint  NOT NULL DEFAULT 2,
  ADD COLUMN IF NOT EXISTS tags       text[]    NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS starter    boolean   NOT NULL DEFAULT false;

-- ── users: coding experience ───────────────────────────────────────────────
-- Nullable: null = "hasn't been asked yet" (Pixo asks during arrival).
-- Values: 'beginner' | 'intermediate' | 'advanced'.
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS coding_experience text;

-- ── seed the three canon Chapter-I starter Trials ──────────────────────────
-- Only inserted if a starter of the same name doesn't already exist, so this
-- is safe to re-run and won't clobber dashboard-authored edits.
INSERT INTO sidequests (name, region, npc, description, reward, difficulty, tags, starter, active, position)
SELECT v.name, v.region, v.npc, v.description, v.reward, v.difficulty, v.tags, true, true, v.position
FROM (VALUES
  ('Raise your Builder Page', 'The Hub', 'Pixo',
   'Build and ship a personal page that introduces you as a Builder. A single HTML/CSS site is enough — the Core just needs to know who joined the Restoration.',
   'Custom .pixl.rsvp subdomain', 1::smallint, ARRAY['web']::text[], 1),
  ('First Contact', 'The Hub', 'Pixo',
   'Ship a hello-world Slack or Discord bot that responds to a command. Communications across Pixl have been dark since the Static — bring one line back online.',
   'Bot hosting credit', 2::smallint, ARRAY['bot']::text[], 2),
  ('The Progress Beacon', 'The Hub', 'Pixo',
   'Build a small live tracker (a web app or script with a UI) that shows a number climbing toward a goal — a stand-in for the community Restoration meter.',
   'Domain of your choice', 3::smallint, ARRAY['web','data']::text[], 3)
) AS v(name, region, npc, description, reward, difficulty, tags, position)
WHERE NOT EXISTS (
  SELECT 1 FROM sidequests s WHERE s.name = v.name AND s.starter = true
);
