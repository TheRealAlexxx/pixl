-- Provenance for projects pulled in from another YSWS via the ships archive.
-- These columns record where the project came from so reviewers see the prior
-- ship up front. They are deliberately NOT economy columns: prior hours are
-- context for the reviewer, never credit. Creditable time still comes from
-- Hackatime at ship time, exactly as it does for a project started here.
ALTER TABLE projects ADD COLUMN IF NOT EXISTS imported_ysws_entry_id text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS imported_from_ysws text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS imported_ysws_hours numeric;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS imported_ysws_approved_at timestamptz;

-- One import per archive entry per user: re-importing the same ship would let
-- someone spin up duplicate drafts off a single prior project.
CREATE UNIQUE INDEX IF NOT EXISTS projects_user_ysws_entry_idx
  ON projects (user_id, imported_ysws_entry_id)
  WHERE imported_ysws_entry_id IS NOT NULL;
