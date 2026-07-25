-- 0047 was run against Supabase before signed-photo.svg/mystery-box.svg were
-- swapped for real signed-photo.png (fanned polaroid of the 3 orgs) and
-- mystery-box.png (generated ribboned crate icon), so those two rows still
-- point at the old, now-deleted .svg files. Fix their image_url in place.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

UPDATE shop_items
SET image_url = 'https://pixl.rsvp/shop/signed-photo.png'
WHERE name = 'Signed Org Photo' AND created_by = 'landing-sync';

UPDATE shop_items
SET image_url = 'https://pixl.rsvp/shop/mystery-box.png'
WHERE name = 'Random Desk Object' AND created_by = 'landing-sync';
