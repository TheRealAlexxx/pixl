-- Link a shipped project back to the Trial it was built for, and seed Ridit's
-- onboarding Trial as a real starter row.
--
-- Until now a project had no way to say "this is my submission for a Trial", and
-- the Ridit NPC in the open world offered an inline "Claim Your Stake" quest that
-- wasn't a real sidequest record. This adds the project->sidequest link the ship
-- picker sets, and promotes "Claim Your Stake" to an actual starter Trial so the
-- link has something concrete to point at.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

-- ── projects: the Trial a project was shipped for (nullable = own idea) ──────
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS sidequest_id bigint REFERENCES sidequests(id);

CREATE INDEX IF NOT EXISTS idx_projects_sidequest ON projects(sidequest_id);

-- ── seed Ridit's onboarding Trial ───────────────────────────────────────────
-- The first Trial every Builder runs: create a project, keep a journal, ship it.
-- difficulty 1 (beginner), starter so the arrival flow can recommend it. Only
-- inserted if a starter of the same name doesn't already exist (re-run safe;
-- won't clobber dashboard edits). Mirrors the seed style in
-- 0050_trial_recommendation.sql.
INSERT INTO sidequests (name, region, npc, description, reward, difficulty, tags, starter, active, position)
SELECT v.name, v.region, v.npc, v.description, v.reward, v.difficulty, v.tags, true, true, v.position
FROM (VALUES
  ('Claim Your Stake', 'Dustline', 'Ridit',
   'Every pioneer stakes a claim: something they build with their own two hands. Create a project, give it a proper name, keep a journal of your work, and ship it. Your first mark on the frontier.',
   'Sticker Pack', 1::smallint, ARRAY['web']::text[], 0)
) AS v(name, region, npc, description, reward, difficulty, tags, position)
WHERE NOT EXISTS (
  SELECT 1 FROM sidequests s WHERE s.name = v.name AND s.starter = true
);
