-- Two fixes bundled together:
--
-- 1. Niche items get a +10% price bump: Signed Org Photo, Random Desk
--    Object, Pixl Tamagotchi DIY Kit, PIXL Cookie Cutter, and Community
--    Meme Pack (same "niche asf" category as Signed Org Photo). The 3D
--    Printed Blahaj is excluded — it's the XP trophy, not a purchasable
--    item, so there's no price to bump.
--
-- 2. Bug fix: MacBook Neo's and MacBook Air M5's description text still
--    quoted the pre-0062-repricing alt-config prices (512GB for "11500 px"
--    and 24GB/1TB for "24250 px") even though 0062 already repriced them
--    to 11425 and 24275 — those are one-card-with-a-note items, so the alt
--    price only ever lived in free text, and 0062 forgot to update it.
--
-- Safe to run once. Re-running is a no-op (each row already matches).
-- Run this in the Supabase SQL editor.

UPDATE shop_items SET price = 110 WHERE name = 'Signed Org Photo' AND created_by = 'landing-sync';              -- +10% -> 2.2h
UPDATE shop_items SET price = 220 WHERE name = 'Random Desk Object' AND created_by = 'landing-sync';            -- +10% -> 4.4h
UPDATE shop_items SET price = 632 WHERE name = 'Pixl Tamagotchi DIY Kit' AND created_by = 'landing-sync';       -- +10% -> 12.64h
UPDATE shop_items SET price = 248 WHERE name = 'PIXL Cookie Cutter' AND created_by = 'landing-sync';            -- +10% -> 4.96h
UPDATE shop_items SET price = 110 WHERE name = 'Community Meme Pack (5-Pack)' AND created_by = 'landing-sync';  -- +10% -> 2.2h

UPDATE shop_items
SET description = 'A light, portable MacBook for code, art and everything in between. 256GB shown, add a note to pick 512GB for 11425 px.'
WHERE name = 'MacBook Neo' AND created_by = 'landing-sync';

UPDATE shop_items
SET description = 'Apple''s air laptop, 16GB/512GB shown, add a note to pick 24GB/1TB for 24275 px.'
WHERE name = 'MacBook Air M5' AND created_by = 'landing-sync';
