-- New niche item: a 5-pack of random community-made memes, printed on real
-- photo paper and shipped in an envelope. Same fulfillment shape as the
-- Signed Org Photo (cheap prints + a near-nothing envelope), so priced the
-- same: ~$5 real cost (5 prints + envelope), bumped to 100px/2h to match
-- the Signed Org Photo's value-add price rather than the raw $5/3.5≈1.5h
-- formula price — it's a fun collectible, not a formula-priced grant.
--
-- US region only for now (the only stocked catalog). Position continues at
-- 60 (after 0062's Nintendo Switch 2 at 59).
--
-- Safe to run once. Re-running duplicates the row (no unique constraint on
-- name) — check first with:
--   SELECT id FROM shop_items WHERE name = 'Community Meme Pack (5-Pack)';
-- Run this in the Supabase SQL editor.

INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp, region)
VALUES (
  'Community Meme Pack (5-Pack)',
  '5 random memes made by the community team, printed on real photo paper and shipped to your door.',
  100,
  'https://pixl.rsvp/shop/meme-pack.png',
  '[]'::jsonb,
  true,
  60,
  'landing-sync',
  0,
  'US'
);
