-- Second batch: 11 more shop items designed on the landing page (pixl.rsvp),
-- added into the real shop_items table alongside the 44 from
-- 0047_import_landing_shop_items.sql. Pure data insert — no application code
-- touched. Images reachable at https://pixl.rsvp/shop/<file> (same reasoning
-- as 0047: the /shop rewrite in vercel.json is exact-match only, so sub-paths
-- like /shop/<file>.png are served directly by the landing site, not proxied).
--
-- Positions continue at 44+ (after 0047's 0..43) rather than interleaving
-- with the existing rows, to avoid renumbering an already-pushed migration.
--
-- Safe to run once. Check first / undo with:
--   SELECT name FROM shop_items WHERE created_by = 'landing-sync';
--   DELETE FROM shop_items WHERE created_by = 'landing-sync' AND position >= 44;

INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Hardware Grant', 'A stackable $10 grant to spend on any hardware for your projects.', 175, 'https://pixl.rsvp/shop/hardware-grant.png', '[]'::jsonb, true, 44, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Domain Grant', 'A stackable $12 grant to register a domain for your project.', 175, 'https://pixl.rsvp/shop/domain-grant.png', '[]'::jsonb, true, 45, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Hosting Grant', 'A stackable $10 grant for hosting, like Railway or any cloud platform.', 175, 'https://pixl.rsvp/shop/hosting-grant.png', '[]'::jsonb, true, 46, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Google Play Developer License', 'A $25 grant for your Google Play developer license.', 350, 'https://pixl.rsvp/shop/google-play.png', '[]'::jsonb, true, 47, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('CPU Grant', 'A stackable $50 grant for CPU upgrades only.', 700, 'https://pixl.rsvp/shop/cpu-grant.png', '[]'::jsonb, true, 48, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('GPU Grant', 'A stackable $50 grant for GPU upgrades only.', 700, 'https://pixl.rsvp/shop/gpu-grant.png', '[]'::jsonb, true, 49, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('RAM Grant', 'A stackable $50 grant for RAM upgrades only.', 700, 'https://pixl.rsvp/shop/ram-grant.png', '[]'::jsonb, true, 50, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Steam License', 'A $100 grant for Steam, since games can''t always be sent as a direct gift.', 1450, 'https://pixl.rsvp/shop/steam-license.png', '[]'::jsonb, true, 51, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Apple Developer License', 'A $100 grant for your Apple Developer Program membership.', 1450, 'https://pixl.rsvp/shop/apple-dev.png', '[]'::jsonb, true, 52, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Apple Pencil Pro', 'Apple''s Pencil Pro, works great with our iPad for sketching and pixel art.', 1850, 'https://pixl.rsvp/shop/pencil-pro.png', '[]'::jsonb, true, 53, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('iPad Air (M4, 128GB)', 'A faster, roomier iPad with the M4 chip. Comes with pencil support for drawing and playtesting.', 10000, 'https://pixl.rsvp/shop/ipad-air-m4.png', '[]'::jsonb, true, 54, 'landing-sync', 0);
