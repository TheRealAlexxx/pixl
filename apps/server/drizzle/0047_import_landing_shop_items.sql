-- Import the 44 shop items designed on the landing page (pixl.rsvp) into the
-- real, purchasable in-game shop_items table (the shop players reach in-game at
-- pixl.rsvp/shop -> play.pixl.rsvp/shop/). Pure data insert — no application code
-- touched. Images already live on the landing site's public folder and are
-- reachable at https://pixl.rsvp/shop/<file> (this path is NOT caught by the
-- landing's /shop page rewrite in vercel.json, which only matches the exact
-- "/shop" and "/shop/" routes, not sub-paths like /shop/<file>.png).
--
-- Safe to run once. If you run it twice you'll get duplicate rows (no unique
-- constraint on name) — check first with:
--   SELECT name FROM shop_items WHERE created_by = 'landing-sync';
-- and delete before re-running if needed:
--   DELETE FROM shop_items WHERE created_by = 'landing-sync';

INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Signed Org Photo', 'A signed photo of one of the org members, shipped to your door.', 100, 'https://pixl.rsvp/shop/signed-photo.png', '[]'::jsonb, true, 0, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Game Assets Grant', 'A stackable $10 grant to buy tilesets, sprites, music and sounds for your game.', 150, 'https://pixl.rsvp/shop/assets-grant.png', '[]'::jsonb, true, 1, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Hack Club Sticker Pack', 'An envelope of Hack Club and Pixl stickers.', 150, 'https://pixl.rsvp/shop/hc-stickers.png', '[]'::jsonb, true, 2, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('AI Credits', 'A $10 grant for AI credits for the provider of your choice.', 150, 'https://pixl.rsvp/shop/api.png', '[]'::jsonb, true, 3, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Music Grant', 'A stackable $10 grant to spend on instruments, plugins, samples or any music gear you want. Don''t use it for subscription to spotify/apple music etc', 150, 'https://pixl.rsvp/shop/music-grant.png', '[]'::jsonb, true, 4, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Random Desk Object', 'A random object from our desks: a PCB, a sticker stash, anything. Comes with a signed letter. Only a few in stock!', 200, 'https://pixl.rsvp/shop/mystery-box.png', '[]'::jsonb, true, 5, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Art Supply Grant', 'A stackable $10 grant to spend on paints, pens, canvases or any art supplies you want.', 200, 'https://pixl.rsvp/shop/art-grant.png', '[]'::jsonb, true, 6, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('PIXL Cookie Cutter', 'Big pixelated PIXL letter cookie cutters, designed by Ricky. Bake a batch for Barnav, our resident cookie muncher.', 200, 'https://pixl.rsvp/shop/cookie-cutter.png', '[]'::jsonb, true, 7, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Pixel Composer License', 'VFX compositor for pixel art. Effects and animations for your sprites.', 250, 'https://pixl.rsvp/shop/pixel-composer.png', '[]'::jsonb, true, 8, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('PICO-8 License', 'The fantasy console. Code, draw and compose tiny games in one tool.', 250, 'https://pixl.rsvp/shop/pico8.png', '[]'::jsonb, true, 9, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('PIXL Poster', 'A $20 print grant for the PIXL poster or any poster you want. Everyone loves posters.', 300, 'https://pixl.rsvp/shop/poster.png', '[]'::jsonb, true, 10, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Aseprite License', 'The pixel art editor. Animated sprites, tilesets and more.', 350, 'https://pixl.rsvp/shop/aseprite.png', '[]'::jsonb, true, 11, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Pixl Tamagotchi DIY Kit', 'Solder and code your own pocket pet, designed by mangoman.', 400, 'https://pixl.rsvp/shop/tamagotchi.png', '[]'::jsonb, true, 12, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Indie Game of Your Choice', 'Pick from our selection of cool indie games. Sent as a gift link on Steam or Humble Bundle.', 400, 'https://pixl.rsvp/shop/indie-game.png', '[]'::jsonb, true, 13, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('ESP32 Starter Kit', 'ESP32 dev board with a breadboard and components to start hacking.', 500, 'https://pixl.rsvp/shop/esp32.png', '[]'::jsonb, true, 14, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('FURYCUBE 68%', 'A cheap hot-swap mechanical keyboard for late night game jams.', 500, 'https://pixl.rsvp/shop/furycube.png', '[]'::jsonb, true, 15, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Godot Plush (Limited Edition)', 'The official Godot robot plushie. Emotional support for game jams.', 650, 'https://pixl.rsvp/shop/godot-plush.png', '[]'::jsonb, true, 16, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('PIXL Hoodie', 'Limited PIXL hoodie with the logo on the chest.', 700, 'https://pixl.rsvp/shop/hoodie.png', '[]'::jsonb, true, 17, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Blahaj Plush', 'A plush Blahaj shark shipped to your door.', 700, 'https://pixl.rsvp/shop/blahaj.png', '[]'::jsonb, true, 18, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Wacom Intuos (Small)', 'A Wacom drawing tablet, the classic for digital art.', 750, 'https://pixl.rsvp/shop/wacom.png', '[]'::jsonb, true, 19, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Retro Handheld (Miyoo Mini+ / RG35XX)', 'A retro handheld to play your builds and the classics on the go.', 1000, 'https://pixl.rsvp/shop/retro-handheld.png', '[]'::jsonb, true, 20, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Epomaker x Aula S75 Pro', 'Hot-swap mechanical keyboard with a little screen. Add a note to pick your color.', 1000, 'https://pixl.rsvp/shop/keyboard-s75-pro.png', '[]'::jsonb, true, 21, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('GameMaker Pro', 'GameMaker Professional license to export your games everywhere.', 1450, 'https://pixl.rsvp/shop/gamemaker.png', '[]'::jsonb, true, 22, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Monitor Grant (Stackable)', 'A stackable $100 grant towards the monitor of your choice. Your pixels deserve more pixels.', 1500, 'https://pixl.rsvp/shop/monitor-4k.png', '[]'::jsonb, true, 23, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Raspberry Pi 5', 'A Raspberry Pi 5 (4GB) to run your servers, emulators and experiments. 8GB version for 3150 px.', 2000, 'https://pixl.rsvp/shop/rpi.png', '[]'::jsonb, true, 24, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Sony WH-CH720N', 'Lightweight noise cancelling headphones, easy on the budget.', 2150, 'https://pixl.rsvp/shop/sony-ch720n.png', '[]'::jsonb, true, 25, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Creality Ender 3 V3', 'A dependable entry-level 3D printer for props and prototypes.', 2750, 'https://pixl.rsvp/shop/ender3-v3.png', '[]'::jsonb, true, 26, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('AirPods Pro 3', 'Apple''s noise cancelling earbuds, compact and easy to bring everywhere.', 2900, 'https://pixl.rsvp/shop/airpods-pro-3.png', '[]'::jsonb, true, 27, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Bambu Lab A1 Mini', 'A fast, quiet 3D printer. Print your own game props and cases.', 3350, 'https://pixl.rsvp/shop/a1-mini.png', '[]'::jsonb, true, 28, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Samsung T7 External SSD (1TB)', 'A fast portable SSD for backups, builds and moving big files around.', 3350, 'https://pixl.rsvp/shop/samsung-t7-ssd.png', '[]'::jsonb, true, 29, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Sony WH-1000XM5', 'Noise cancelling headphones to get in the zone.', 3600, 'https://pixl.rsvp/shop/sony-headphones.png', '[]'::jsonb, true, 30, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Creality Sparkx i7', 'A fast, capable 3D printer for bigger builds.', 3750, 'https://pixl.rsvp/shop/sparkx-i7.png', '[]'::jsonb, true, 31, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Bambu Lab A1', 'A reliable, well-rounded 3D printer for props, cases and prototypes.', 4250, 'https://pixl.rsvp/shop/bambu-a1.png', '[]'::jsonb, true, 32, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Centauri Carbon', 'A fast, enclosed 3D printer built for tougher, higher-temp filaments.', 5000, 'https://pixl.rsvp/shop/centauri-carbon.png', '[]'::jsonb, true, 33, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('iPad (11th gen)', 'An iPad with pencil support for drawing and playtesting.', 5750, 'https://pixl.rsvp/shop/ipad.png', '[]'::jsonb, true, 34, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Bambu Lab A1 Combo', 'The A1 bundled with the AMS Lite for multi-color prints out of the box.', 5750, 'https://pixl.rsvp/shop/bambu-a1-combo.png', '[]'::jsonb, true, 35, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Samsung Galaxy S24', 'A solid Android flagship for everyday use and testing your apps.', 5750, 'https://pixl.rsvp/shop/samsung-s24.png', '[]'::jsonb, true, 36, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('AirPods Max 2', 'Apple''s over-ear noise cancelling headphones. The endgame flex.', 6450, 'https://pixl.rsvp/shop/airpods-max.png', '[]'::jsonb, true, 37, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Nothing Phone (4a) Pro', 'A sleek Android phone with Nothing''s signature transparent design.', 7150, 'https://pixl.rsvp/shop/nothing-phone.png', '[]'::jsonb, true, 38, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('MacBook Neo', 'A light, portable MacBook for code, art and everything in between. 256GB shown, add a note to pick 512GB for 11500 px.', 10000, 'https://pixl.rsvp/shop/macbook-neo.png', '[]'::jsonb, true, 39, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('MacBook Air M5', 'Apple''s air laptop, 16GB/512GB shown, add a note to pick 24GB/1TB for 24250 px.', 17150, 'https://pixl.rsvp/shop/macbook-air.png', '[]'::jsonb, true, 40, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Framework 13 DIY', 'A modular, repairable 13-inch laptop you build yourself.', 17150, 'https://pixl.rsvp/shop/framework-13.png', '[]'::jsonb, true, 41, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Framework 16 DIY', 'The bigger 16-inch Framework laptop, build it yourself.', 17900, 'https://pixl.rsvp/shop/framework-16.png', '[]'::jsonb, true, 42, 'landing-sync', 0);
INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Mac Mini (24GB/512GB)', 'A compact desktop Mac for coding, streaming and everyday builds.', 22500, 'https://pixl.rsvp/shop/mac-mini.png', '[]'::jsonb, true, 43, 'landing-sync', 0);
