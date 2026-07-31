-- Store the player's real name from Hack Club OAuth, separately from the
-- in-game display_name they can freely change.
--
-- Until now the HCA first_name + last_name was only used to seed display_name on
-- first login, then thrown away , so once a player renamed themselves in-game the
-- dashboard/moderation tools had no way to see who they actually are. This adds a
-- dedicated column the auth flow keeps in sync on every login (it can't be
-- backfilled for existing users , we never stored their name , so it fills in as
-- each player next signs in; the dashboard falls back to display_name until then).
--
-- Run this in the Supabase SQL editor. Safe to run more than once.
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS real_name text NOT NULL DEFAULT '';
  