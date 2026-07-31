-- Repricing pass: every shop item's real-world $ cost was re-reviewed
-- (Gabin's updated cost list), then converted at the shop's actual rate of
-- 1h = $3.5 = 50px, with hours rounded to the nearest 0.5h (so every price
-- stays a multiple of 25px, matching the existing convention). Previous
-- prices were mostly eyeballed/rounded by hand and had drifted from that
-- exact formula; this brings them back in line.
--
-- Left untouched on purpose:
--   - Signed Org Photo (100px/2h) — real cost is ~$4 (~1h), but kept at the
--     current price since it's a niche/cool item, not because of the formula
--   - Random Desk Object (200px/4h) — explicit override to add value beyond
--     the near-zero raw cost, not a formula price
--   - Framework 13 DIY / Framework 16 DIY — priced via the per-component
--     config_options configurator (0058/0059), not a flat price; their
--     $1199/$1249 base costs land within ~$25 of the current base_price
--     anyway, well inside rounding noise, so the configurators are untouched
--   - Everything else not listed below computed to the same price it
--     already had
--
-- Safe to run once. Re-running is a no-op (each row already matches).
-- Run this in the Supabase SQL editor.

UPDATE shop_items SET price = 575  WHERE name = 'Pixl Tamagotchi DIY Kit' AND created_by = 'landing-sync';       -- $40 -> 11.5h
UPDATE shop_items SET price = 225  WHERE name = 'PIXL Cookie Cutter' AND created_by = 'landing-sync';            -- $15 -> 4.5h
UPDATE shop_items SET price = 325  WHERE name = 'Aseprite License' AND created_by = 'landing-sync';              -- $22 -> 6.5h
UPDATE shop_items SET price = 225  WHERE name = 'Pixel Composer License' AND created_by = 'landing-sync';        -- $15 -> 4.5h
UPDATE shop_items SET price = 350  WHERE name = 'Indie Game of Your Choice' AND created_by = 'landing-sync';     -- $25 -> 7h
UPDATE shop_items SET price = 275  WHERE name = 'PIXL Poster' AND created_by = 'landing-sync';                   -- $20 -> 5.5h
UPDATE shop_items SET price = 225  WHERE name = 'PICO-8 License' AND created_by = 'landing-sync';                -- $15 -> 4.5h
UPDATE shop_items SET price = 725  WHERE name = 'PIXL Hoodie' AND created_by = 'landing-sync';                   -- $50 -> 14.5h
UPDATE shop_items SET price = 1425 WHERE name = 'GameMaker Pro' AND created_by = 'landing-sync';                 -- $99.99 -> 28.5h
UPDATE shop_items SET price = 475  WHERE name = 'ESP32 Starter Kit' AND created_by = 'landing-sync';             -- $33 -> 9.5h
UPDATE shop_items SET price = 725  WHERE name = 'Wacom Intuos (Small)' AND created_by = 'landing-sync';          -- $50 -> 14.5h
UPDATE shop_items SET price = 1025 WHERE name = 'Epomaker x Aula S75 Pro' AND created_by = 'landing-sync';       -- $72 -> 20.5h
UPDATE shop_items SET price = 3575 WHERE name = 'Sony WH-1000XM5' AND created_by = 'landing-sync';               -- $250 -> 71.5h
UPDATE shop_items SET price = 6425 WHERE name = 'AirPods Max 2' AND created_by = 'landing-sync';                 -- $450 -> 128.5h
UPDATE shop_items SET price = 4275 WHERE name = 'Bambu Lab A1' AND created_by = 'landing-sync';                  -- $300 -> 85.5h
UPDATE shop_items SET price = 5725 WHERE name = 'Bambu Lab A1 Combo' AND created_by = 'landing-sync';            -- $400 -> 114.5h
UPDATE shop_items SET price = 5150 WHERE name = 'Centauri Carbon' AND created_by = 'landing-sync';               -- $360 -> 103h
UPDATE shop_items SET price = 2725 WHERE name = 'Creality Ender 3 V3' AND created_by = 'landing-sync';           -- $190 -> 54.5h
UPDATE shop_items SET price = 3725 WHERE name = 'Creality Sparkx i7' AND created_by = 'landing-sync';            -- $260 -> 74.5h
UPDATE shop_items SET price = 22425 WHERE name = 'Mac Mini (24GB/512GB)' AND created_by = 'landing-sync';        -- $1570 -> 448.5h
UPDATE shop_items SET price = 1425 WHERE name = 'Monitor Grant (Stackable)' AND created_by = 'landing-sync';     -- $100 -> 28.5h
UPDATE shop_items SET price = 5725 WHERE name = 'iPad (11th gen)' AND created_by = 'landing-sync';               -- $400 -> 114.5h
UPDATE shop_items SET price = 150  WHERE name = 'Art Supply Grant' AND created_by = 'landing-sync';              -- $10 -> 3h
UPDATE shop_items SET price = 150  WHERE name = 'Music Grant' AND created_by = 'landing-sync';                   -- $10 -> 3h
UPDATE shop_items SET price = 3275 WHERE name = 'Samsung T7 External SSD (1TB)' AND created_by = 'landing-sync'; -- $230 -> 65.5h
UPDATE shop_items SET price = 2850 WHERE name = 'AirPods Pro 3' AND created_by = 'landing-sync';                 -- $200 -> 57h
UPDATE shop_items SET price = 575  WHERE name = 'Blahaj Plush' AND created_by = 'landing-sync';                  -- $40 -> 11.5h
UPDATE shop_items SET price = 5725 WHERE name = 'Samsung Galaxy S24' AND created_by = 'landing-sync';            -- $400 -> 114.5h
UPDATE shop_items SET price = 150  WHERE name = 'Hardware Grant' AND created_by = 'landing-sync';                -- $10 -> 3h
UPDATE shop_items SET price = 150  WHERE name = 'Hosting Grant' AND created_by = 'landing-sync';                 -- $10 -> 3h
UPDATE shop_items SET price = 1425 WHERE name = 'Steam License' AND created_by = 'landing-sync';                 -- $100 -> 28.5h
UPDATE shop_items SET price = 1425 WHERE name = 'Apple Developer License' AND created_by = 'landing-sync';       -- $100 -> 28.5h
UPDATE shop_items SET price = 725  WHERE name = 'CPU Grant' AND created_by = 'landing-sync';                     -- $50 -> 14.5h
UPDATE shop_items SET price = 725  WHERE name = 'GPU Grant' AND created_by = 'landing-sync';                     -- $50 -> 14.5h
UPDATE shop_items SET price = 725  WHERE name = 'RAM Grant' AND created_by = 'landing-sync';                     -- $50 -> 14.5h
UPDATE shop_items SET price = 225  WHERE name = 'Soldering Iron' AND created_by = 'landing-sync';                -- $15 -> 4.5h
UPDATE shop_items SET price = 150  WHERE name = 'Food Grant' AND created_by = 'landing-sync';                    -- $10 -> 3h

-- New item (siren-flagged in the source list). Position continues at 59
-- (after 0054's 58). Image needs to be created/uploaded to
-- pixl.rsvp/shop/nintendo-switch-2.png before this goes live in-game.
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Nintendo Switch 2', 'Nintendo''s newest handheld/console hybrid. Play your builds and everything else on the go or on the big screen.', 7150, 'https://pixl.rsvp/shop/nintendo-switch-2.png', '[]'::jsonb, true, 59, 'landing-sync', 0);
-- $500 -> 143h
