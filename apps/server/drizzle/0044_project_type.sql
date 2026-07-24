-- Add a project "type" so reviewers know what kind of thing was shipped
-- (web game vs hardware vs CAD model, etc.). Set at ship time from a dropdown
-- in apps/game/web/projects and shown on the dashboard review page.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS project_type TEXT NOT NULL DEFAULT 'other';
