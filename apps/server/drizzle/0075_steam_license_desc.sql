-- Simplify the Steam License description to just say what it's for.
--
-- Safe to run once. Re-running is a no-op.
-- Run this in the Supabase SQL editor.

UPDATE shop_items
SET description = 'A grant for publishing your game on Steam.'
WHERE name = 'Steam License' AND created_by = 'landing-sync';
