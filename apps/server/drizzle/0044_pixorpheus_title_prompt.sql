-- Pixorpheus: track the "set a title" prompt message so it can be deleted later.
--
-- The title prompt is now posted as a real message in the ticket thread (it used
-- to be ephemeral, which Slack cannot delete after the fact). Its ts is stored
-- here so the bot can delete it when the user sets/skips the title or when the
-- ticket is resolved — even across bot restarts.
--
-- Run in the Supabase SQL editor. Safe to run more than once.

ALTER TABLE tickets ADD COLUMN IF NOT EXISTS title_prompt_ts TEXT;
