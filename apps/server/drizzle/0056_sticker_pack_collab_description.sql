-- 0047 already ran with the old description before this wording was added on
-- the landing page. Update the real shop row to match.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

UPDATE shop_items
SET description = 'An envelope of Hack Club and Pixl stickers, made in collaboration with several artists.'
WHERE name = 'Hack Club Sticker Pack' AND created_by = 'landing-sync';
