-- Real market-price research pass on the 30 non-grant/non-trophy shop items
-- (US, EU, India), applied three ways:
--   1. US prices updated to match the new research, using the standard
--      formula: hours = price_usd / 3.5, rounded to the nearest half hour,
--      pixels = hours * 50.
--   2. Two new items showed up in the research that don't exist in the
--      catalog yet — MacBook Pro M5, and two items that are conceptually
--      different from existing similarly-named items (see note below) —
--      inserted fresh into US.
--   3. EUROPE and INDIA are now stocked for the first time. The 30
--      researched items get their own researched price per region (0 = no
--      price shown yet, when research came back UNAVAILABLE for that
--      region). Everything else in the catalog (grants, niche/collectible
--      items — anything not part of this price research) gets copied into
--      EUROPE and INDIA at the exact same price it has in US.
--
-- Notes on judgment calls:
--   - "Steam Gift Card ($100)" and "Google Play Gift Card ($25)" from the
--     research are consumer gift cards — different from the existing "Steam
--     License" / "Google Play Developer License" items, which are developer
--     publishing-fee grants (see 0075's description rewrite). Both existing
--     items are left untouched; the two gift cards are new items.
--   - "Epomaker x Aula F75 Pro" / "Bambu Lab A1 Standalone" / "Elegoo
--     Centauri Carbon" in the research are the same products as the
--     catalog's "Epomaker x Aula S75 Pro" / "Bambu Lab A1" / "Centauri
--     Carbon" — repriced in place, names unchanged.
--   - Framework 16 DIY came back UNAVAILABLE in every region researched (it's
--     a build-to-order product, not a fixed retail SKU) — left completely
--     untouched, and NOT copied into EUROPE/INDIA, since its config_options
--     groups reference a US-specific spec sheet URL that hasn't been
--     verified for other regions. Framework 13 DIY has the same concern and
--     is excluded from the EUROPE/INDIA bulk-copy for the same reason.
--   - Trophies (unlock_xp > 0) are never region-scoped at all (see the
--     region-filter fix from earlier this project) — not touched here.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

-- ── 1. US price updates (26 existing items) ──
UPDATE shop_items SET price = 100   WHERE name = 'Soldering Iron' AND region = 'US';
UPDATE shop_items SET price = 3275  WHERE name = 'Samsung T7 External SSD (1TB)' AND region = 'US';
UPDATE shop_items SET price = 1150  WHERE name = 'Raspberry Pi 5' AND region = 'US';
UPDATE shop_items SET price = 250   WHERE name = 'ESP32 Starter Kit' AND region = 'US';
UPDATE shop_items SET price = 1475  WHERE name = 'Sony WH-CH720N' AND region = 'US';
UPDATE shop_items SET price = 11425 WHERE name = 'Mac Mini (24GB/512GB)' AND region = 'US';
UPDATE shop_items SET price = 275   WHERE name = 'Electric Screwdriver Set' AND region = 'US';
UPDATE shop_items SET price = 850   WHERE name = 'Epomaker x Aula S75 Pro' AND region = 'US';
UPDATE shop_items SET price = 6425  WHERE name = 'Nintendo Switch 2' AND region = 'US';
UPDATE shop_items SET price = 5425  WHERE name = 'Nothing Phone (4a) Pro' AND region = 'US';
UPDATE shop_items SET price = 10700 WHERE name = 'iPad Air (M4, 128GB)' AND region = 'US';
UPDATE shop_items SET price = 4975  WHERE name = 'iPad (11th gen)' AND region = 'US';
UPDATE shop_items SET price = 1850  WHERE name = 'Apple Pencil Pro' AND region = 'US';
UPDATE shop_items SET price = 3125  WHERE name = 'Bambu Lab A1 Mini' AND region = 'US';
UPDATE shop_items SET price = 3350  WHERE name = 'Sony WH-1000XM5' AND region = 'US';
UPDATE shop_items SET price = 500   WHERE name = 'FURYCUBE 68%' AND region = 'US';
UPDATE shop_items SET price = 9700  WHERE name = 'MacBook Neo' AND region = 'US';
UPDATE shop_items SET price = 2850  WHERE name = 'Creality Ender 3 V3' AND region = 'US';
UPDATE shop_items SET price = 5700  WHERE name = 'Bambu Lab A1' AND region = 'US';
UPDATE shop_items SET price = 575   WHERE name = 'Wacom Intuos (Small)' AND region = 'US';
UPDATE shop_items SET price = 5975  WHERE name = 'Bambu Lab A1 Combo' AND region = 'US';
UPDATE shop_items SET price = 3550  WHERE name = 'AirPods Pro 3' AND region = 'US';
UPDATE shop_items SET price = 7850  WHERE name = 'AirPods Max 2' AND region = 'US';
UPDATE shop_items SET price = 5125  WHERE name = 'Samsung Galaxy S24' AND region = 'US';
UPDATE shop_items SET price = 3275  WHERE name = 'Creality Sparkx i7' AND region = 'US';
UPDATE shop_items SET price = 5125  WHERE name = 'Centauri Carbon' AND region = 'US';

-- ── 2. New US items (3) ──
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp, region)
SELECT 'Steam Gift Card ($100)', 'A $100 Steam gift card to spend on any game in your library.', 1425,
  'https://pixl.rsvp/shop/steam-giftcard.png', '[]'::jsonb, true, 61, 'landing-sync', 0, 'US'
WHERE NOT EXISTS (SELECT 1 FROM shop_items WHERE name = 'Steam Gift Card ($100)' AND region = 'US');

INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp, region)
SELECT 'Google Play Gift Card ($25)', 'A $25 Google Play gift card to spend on apps, games or media.', 350,
  'https://pixl.rsvp/shop/google-play-giftcard.png', '[]'::jsonb, true, 62, 'landing-sync', 0, 'US'
WHERE NOT EXISTS (SELECT 1 FROM shop_items WHERE name = 'Google Play Gift Card ($25)' AND region = 'US');

INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp, region)
SELECT 'MacBook Pro M5 (16GB/512GB)', 'Apple''s pro laptop, M5 chip, 16GB/512GB. For serious code, art and everything in between.', 28550,
  'https://pixl.rsvp/shop/macbook-pro-m5.png', '[]'::jsonb, true, 63, 'landing-sync', 0, 'US'
WHERE NOT EXISTS (SELECT 1 FROM shop_items WHERE name = 'MacBook Pro M5 (16GB/512GB)' AND region = 'US');

-- ── 3. EUROPE rows for the 29 researched items (0 = no price shown yet) ──
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp, config_options, region)
SELECT name, description, v.price, image_url, options, active, position, created_by, unlock_xp, config_options, 'EUROPE'
FROM shop_items s
JOIN (VALUES
  ('Soldering Iron', 0),
  ('Samsung T7 External SSD (1TB)', 2625),
  ('Raspberry Pi 5', 2450),
  ('ESP32 Starter Kit', 600),
  ('Sony WH-CH720N', 1825),
  ('Mac Mini (24GB/512GB)', 8425),
  ('Electric Screwdriver Set', 600),
  ('Epomaker x Aula S75 Pro', 975),
  ('Nintendo Switch 2', 7725),
  ('Nothing Phone (4a) Pro', 7325),
  ('iPad Air (M4, 128GB)', 11975),
  ('iPad (11th gen)', 7375),
  ('Apple Pencil Pro', 1475),
  ('Bambu Lab A1 Mini', 3100),
  ('Sony WH-1000XM5', 0),
  ('FURYCUBE 68%', 550),
  ('MacBook Neo', 13125),
  ('Creality Ender 3 V3', 0),
  ('Bambu Lab A1', 5575),
  ('Wacom Intuos (Small)', 0),
  ('Bambu Lab A1 Combo', 7975),
  ('AirPods Pro 3', 3450),
  ('AirPods Max 2', 0),
  ('Samsung Galaxy S24', 0),
  ('Creality Sparkx i7', 0),
  ('Centauri Carbon', 0),
  ('Steam Gift Card ($100)', 0),
  ('Google Play Gift Card ($25)', 0),
  ('MacBook Pro M5 (16GB/512GB)', 30075)
) AS v(name, price) ON v.name = s.name
WHERE s.region = 'US'
  AND NOT EXISTS (SELECT 1 FROM shop_items e WHERE e.name = s.name AND e.region = 'EUROPE');

-- ── 4. INDIA rows for the same 29 items (India USD-equivalent == US price for every one of them) ──
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp, config_options, region)
SELECT name, description, price, image_url, options, active, position, created_by, unlock_xp, config_options, 'INDIA'
FROM shop_items s
WHERE s.region = 'US'
  AND s.name IN (
    'Soldering Iron', 'Samsung T7 External SSD (1TB)', 'Raspberry Pi 5', 'ESP32 Starter Kit',
    'Sony WH-CH720N', 'Mac Mini (24GB/512GB)', 'Electric Screwdriver Set', 'Epomaker x Aula S75 Pro',
    'Nintendo Switch 2', 'Nothing Phone (4a) Pro', 'iPad Air (M4, 128GB)', 'iPad (11th gen)',
    'Apple Pencil Pro', 'Bambu Lab A1 Mini', 'Sony WH-1000XM5', 'FURYCUBE 68%', 'MacBook Neo',
    'Creality Ender 3 V3', 'Bambu Lab A1', 'Wacom Intuos (Small)', 'Bambu Lab A1 Combo',
    'AirPods Pro 3', 'AirPods Max 2', 'Samsung Galaxy S24', 'Creality Sparkx i7', 'Centauri Carbon',
    'Steam Gift Card ($100)', 'Google Play Gift Card ($25)', 'MacBook Pro M5 (16GB/512GB)'
  )
  AND NOT EXISTS (SELECT 1 FROM shop_items i WHERE i.name = s.name AND i.region = 'INDIA');

-- ── 5. Everything else (grants, niche items, MacBook Air M5, etc — anything
--    not part of this price research, not a trophy, not a DIY configurator)
--    copied into EUROPE and INDIA at the same price it has in US. ──
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp, config_options, region)
SELECT name, description, price, image_url, options, active, position, created_by, unlock_xp, config_options, 'EUROPE'
FROM shop_items s
WHERE s.region = 'US' AND s.active = true AND coalesce(s.unlock_xp, 0) = 0 AND s.config_options IS NULL
  AND s.name NOT IN (
    'Soldering Iron', 'Samsung T7 External SSD (1TB)', 'Raspberry Pi 5', 'ESP32 Starter Kit',
    'Sony WH-CH720N', 'Mac Mini (24GB/512GB)', 'Electric Screwdriver Set', 'Epomaker x Aula S75 Pro',
    'Nintendo Switch 2', 'Nothing Phone (4a) Pro', 'iPad Air (M4, 128GB)', 'iPad (11th gen)',
    'Apple Pencil Pro', 'Bambu Lab A1 Mini', 'Sony WH-1000XM5', 'FURYCUBE 68%', 'MacBook Neo',
    'Creality Ender 3 V3', 'Bambu Lab A1', 'Wacom Intuos (Small)', 'Bambu Lab A1 Combo',
    'AirPods Pro 3', 'AirPods Max 2', 'Samsung Galaxy S24', 'Creality Sparkx i7', 'Centauri Carbon',
    'Steam Gift Card ($100)', 'Google Play Gift Card ($25)', 'MacBook Pro M5 (16GB/512GB)'
  )
  AND NOT EXISTS (SELECT 1 FROM shop_items e WHERE e.name = s.name AND e.region = 'EUROPE');

INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp, config_options, region)
SELECT name, description, price, image_url, options, active, position, created_by, unlock_xp, config_options, 'INDIA'
FROM shop_items s
WHERE s.region = 'US' AND s.active = true AND coalesce(s.unlock_xp, 0) = 0 AND s.config_options IS NULL
  AND s.name NOT IN (
    'Soldering Iron', 'Samsung T7 External SSD (1TB)', 'Raspberry Pi 5', 'ESP32 Starter Kit',
    'Sony WH-CH720N', 'Mac Mini (24GB/512GB)', 'Electric Screwdriver Set', 'Epomaker x Aula S75 Pro',
    'Nintendo Switch 2', 'Nothing Phone (4a) Pro', 'iPad Air (M4, 128GB)', 'iPad (11th gen)',
    'Apple Pencil Pro', 'Bambu Lab A1 Mini', 'Sony WH-1000XM5', 'FURYCUBE 68%', 'MacBook Neo',
    'Creality Ender 3 V3', 'Bambu Lab A1', 'Wacom Intuos (Small)', 'Bambu Lab A1 Combo',
    'AirPods Pro 3', 'AirPods Max 2', 'Samsung Galaxy S24', 'Creality Sparkx i7', 'Centauri Carbon',
    'Steam Gift Card ($100)', 'Google Play Gift Card ($25)', 'MacBook Pro M5 (16GB/512GB)'
  )
  AND NOT EXISTS (SELECT 1 FROM shop_items i WHERE i.name = s.name AND i.region = 'INDIA');
