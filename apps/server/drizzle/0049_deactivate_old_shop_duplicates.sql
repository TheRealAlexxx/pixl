-- The real shop_items table had 23 items added by hand (via the dashboard,
-- created_by = 'landing import' / 'erm frog (U0ARC79GEAV)') before the
-- landing-page shop rebuild was synced in via 0047/0048. Almost all of them
-- are now stale duplicates of a renamed/re-priced item in the new 55-item
-- catalog (created_by = 'landing-sync'), so they'd otherwise show twice in
-- the shop with two different (one outdated) prices.
--
-- We deactivate rather than DELETE, so any shop_orders already placed
-- against these old item ids keep working / stay auditable.
--
-- id=9 "3D Printed Blahaj" is intentionally excluded: it's the XP trophy
-- (unlock_xp=100, price=0, set by 0032_shop_trophies.sql), not a purchasable
-- duplicate of the new "Blahaj Plush" shop item — leave it active as-is.
--
-- Run this in the Supabase SQL editor. Safe to run more than once
-- (UPDATE ... WHERE active = true is idempotent).

UPDATE shop_items
SET active = false
WHERE id IN (
  25, -- 27" 4K Monitor -> superseded by Monitor Grant (Stackable)
  13, -- AI Credits ($10) -> superseded by AI Credits
  4,  -- Aseprite License -> superseded by Aseprite License
  24, -- Bambu Lab A1 Mini -> superseded by Bambu Lab A1 Mini
  11, -- ESP32 Starter Kit -> superseded by ESP32 Starter Kit
  16, -- Game Assets Grant ($10) -> superseded by Game Assets Grant
  5,  -- GameMaker Pro -> superseded by GameMaker Pro
  19, -- GitHub Pro (1 year) -> dropped from the new shop
  6,  -- Godot Plush -> superseded by Godot Plush (Limited Edition)
  7,  -- Hack Club Sticker Pack -> superseded by Hack Club Sticker Pack
  14, -- Indie Game of Your Choice -> superseded by Indie Game of Your Choice
  26, -- iPad (11th gen) -> superseded by iPad (11th gen)
  22, -- Mechanical Keyboard -> superseded by the specific keyboard SKUs
  15, -- Nintendo Switch Online (1 year) -> dropped from the new shop
  12, -- PICO-8 License -> superseded by PICO-8 License
  8,  -- Pixel Composer License -> superseded by Pixel Composer License
  10, -- PIXL Poster -> superseded by PIXL Poster
  17, -- Pixl Tamagotchi DIY Kit -> superseded by Pixl Tamagotchi DIY Kit
  20, -- Raspberry Pi 5 -> superseded by Raspberry Pi 5
  2,  -- Retro Handheld (RG35XX / Miyoo Mini+) -> superseded by Retro Handheld
  23, -- Sony WH-1000XM4 -> superseded by Sony WH-1000XM5
  21  -- Wacom Intuos (Small) -> superseded by Wacom Intuos (Small)
)
AND active = true;
