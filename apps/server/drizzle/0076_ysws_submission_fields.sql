-- Hack Club's revised YSWS submission guidelines require birthday + mailing
-- address + first/last name on file for every approved project (for the
-- eventual push into their Unified Database), plus a per-project attestation
-- that it isn't a school assignment or paid Hack Club work (a hard exclusion
-- under "Project Exceptions"). None of this is collected today.
--
-- first_name/last_name mirror what auth.ts already gets from HCA identity
-- (previously only joined into real_name) so the CSV export doesn't have to
-- guess a split. birthday/address are filled in by the player later via the
-- new /account page — not backfillable, so they start empty/null.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name text NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name text NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS birthday date;
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_line1 text NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_line2 text NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_city text NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_state text NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_country text NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS address_postal text NOT NULL DEFAULT '';

-- Self-attested at ship time, same pattern as the existing other_ysws
-- disclosure checkbox (see 0013_ship_extras.sql).
ALTER TABLE projects ADD COLUMN IF NOT EXISTS eligibility_attested boolean NOT NULL DEFAULT false;
