-- Round the niche-asf items' hours up to the next half-hour, on top of the
-- +10% bump from 0071 (which left messy fractions like 12.64h/4.96h):
--   Signed Org Photo:        2.2h  -> 2.5h  (110px -> 125px)
--   Community Meme Pack:     2.2h  -> 2.5h  (110px -> 125px)
--   Random Desk Object:      4.4h  -> 4.5h  (220px -> 225px)
--   PIXL Cookie Cutter:      4.96h -> 5h    (248px -> 250px)
--   Pixl Tamagotchi DIY Kit: 12.64h -> 13h  (632px -> 650px)
--
-- Safe to run once. Re-running is a no-op.
-- Run this in the Supabase SQL editor, after 0071.

UPDATE shop_items SET price = 125 WHERE name = 'Signed Org Photo' AND created_by = 'landing-sync';
UPDATE shop_items SET price = 125 WHERE name = 'Community Meme Pack (5-Pack)' AND created_by = 'landing-sync';
UPDATE shop_items SET price = 225 WHERE name = 'Random Desk Object' AND created_by = 'landing-sync';
UPDATE shop_items SET price = 250 WHERE name = 'PIXL Cookie Cutter' AND created_by = 'landing-sync';
UPDATE shop_items SET price = 650 WHERE name = 'Pixl Tamagotchi DIY Kit' AND created_by = 'landing-sync';
