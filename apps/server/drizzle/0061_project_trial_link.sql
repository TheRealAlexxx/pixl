-- Link a shipped project back to the Trial it was built for, and seed the
-- onboarding Trial (Dustline L1 software) as a real starter row.
--
-- Until now a project had no way to say "this is my submission for a Trial", and
-- the Ridit NPC in the open world offered an inline quest that wasn't a real
-- sidequest record. This adds the project->sidequest link the ship picker sets,
-- and seeds the canon L1 web Trial "The Wall at the Sixteen Colors" so the link
-- has something concrete to point at. (Ridit hands it out in the onboarding flow;
-- the 7h minimum is descriptive for now — the per-Trial hour gate isn't built.)
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

-- ── projects: the Trial a project was shipped for (nullable = own idea) ──────
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS sidequest_id bigint REFERENCES sidequests(id);

CREATE INDEX IF NOT EXISTS idx_projects_sidequest ON projects(sidequest_id);

-- ── seed the onboarding Trial (Dustline L1 · web) ───────────────────────────
-- The first Trial every Builder runs: rebuild Mabel's saloon noticeboard as a
-- website. difficulty 1 (beginner), starter so the arrival flow can recommend it.
-- Only inserted if a starter of the same name doesn't already exist (re-run safe;
-- won't clobber dashboard edits). Mirrors the seed style in
-- 0050_trial_recommendation.sql.
INSERT INTO sidequests (name, region, npc, description, reward, difficulty, tags, starter, active, position)
SELECT v.name, v.region, v.npc, v.description, v.reward, v.difficulty, v.tags, true, true, v.position
FROM (VALUES
  ('The Wall at the Sixteen Colors', 'Dustline', 'Ridit',
   'Rebuild Mabel''s noticeboard as a website. Anyone can post a notice with a title, a description and who to contact. Visitors can browse them and filter by type: work, lost, found, wanted. Make it look like it belongs on a saloon wall. (Minimum 7h of tracked work.)',
   'Domain + Sticker Pack', 1::smallint, ARRAY['web']::text[], 0)
) AS v(name, region, npc, description, reward, difficulty, tags, position)
WHERE NOT EXISTS (
  SELECT 1 FROM sidequests s WHERE s.name = v.name AND s.starter = true
);
