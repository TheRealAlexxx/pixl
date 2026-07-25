-- Third batch: 3 more shop items designed on the landing page (pixl.rsvp),
-- added into the real shop_items table alongside 0047/0048's items. Pure
-- data insert — no application code touched. Images reachable at
-- https://pixl.rsvp/shop/<file> (same reasoning as 0047/0048: the /shop
-- rewrite in vercel.json is exact-match only, so sub-paths like
-- /shop/<file>.png are served directly by the landing site, not proxied).
--
-- Positions continue at 55+ (after 0048's 44..54).
--
-- Safe to run once. Check first / undo with:
--   SELECT name FROM shop_items WHERE created_by = 'landing-sync';
--   DELETE FROM shop_items WHERE created_by = 'landing-sync' AND position >= 55;

INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Soldering Tools Grant', 'A stackable $10 grant for soldering tools and supplies.', 150, 'https://pixl.rsvp/shop/soldering-grant.png', '[]'::jsonb, true, 55, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Soldering Iron', 'A soldering iron kit with fresh tips and flux — handy for the Tamagotchi kit and other hardware builds.', 200, 'https://pixl.rsvp/shop/soldering-iron.png', '[]'::jsonb, true, 56, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Electric Screwdriver Set', 'An electric screwdriver set for building and fixing your hardware projects.', 425, 'https://pixl.rsvp/shop/screwdriver.png', '[]'::jsonb, true, 57, 'landing-sync', 0);
