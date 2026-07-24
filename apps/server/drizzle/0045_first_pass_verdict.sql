-- Two-pass moderation: a first-pass reviewer's verdict (approve / request
-- changes / ban) is only a PROPOSAL. We store what they proposed so the final
-- reviewer can confirm it or overturn it. NULL once the project leaves review.
--
-- Values: 'approved' | 'needs_changes' | 'banned'.
-- Run this in the Supabase SQL editor. Safe to run more than once.

ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS first_pass_verdict TEXT;
