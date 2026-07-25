-- Sets a real image for the "3D Printed Blahaj" trophy (the 100-XP milestone
-- item set up by 0032_shop_trophies.sql — unlock_xp=100, price=0). It's had no
-- image_url until now. Matched by exact name + unlock_xp>0 so this can never
-- touch the "Blahaj Plush" shop item (a different, purchasable row — 0048
-- named it distinctly to avoid exactly this kind of collision).
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

UPDATE shop_items
SET image_url = 'https://pixl.rsvp/shop/blahaj-3d-print.png'
WHERE name = '3D Printed Blahaj' AND unlock_xp > 0;
