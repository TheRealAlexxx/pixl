-- Shareable join codes for project collaboration: an alternative to the
-- name-search invite (0081_project_collaborators.sql) — the owner generates
-- a short code and shares it anywhere (Slack, DMs); anyone who redeems it
-- joins as an accepted collaborator immediately, no lookup needed.
--
-- Run in the Supabase SQL editor. Safe to re-run.

alter table projects add column if not exists join_code text;
create unique index if not exists projects_join_code_idx on projects(join_code) where join_code is not null;
