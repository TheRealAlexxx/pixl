-- Trophy items for the restoration-energy rate tiers that don't already have
-- one (25/75/175/350 lifetime approved hours from src/xp.ts's RATE_TIERS -
-- the 500h top tier already has the Blahaj trophies). Same pattern as
-- 0032_shop_trophies.sql: unlock_xp > 0, price = 0, claimed via the existing
-- generic /api/shop/claim flow - no new server code needed.
--
-- image_url follows the existing https://pixl.rsvp/shop/<slug>.png
-- convention but the actual art doesn't exist yet - these need real assets
-- from Ricky before going live. Inserted active so they show up in the shop
-- (broken image icon until the asset lands), same as everything else in this
-- table; flip `active` false first if that's not wanted.
--
-- shop_items has no unique constraint on name, so this guards re-runs with
-- NOT EXISTS instead of ON CONFLICT (which would silently no-op forever
-- without a real conflict target to key off).
insert into shop_items (name, description, price, image_url, unlock_xp, region, active, position)
select v.name, v.description, 0, v.image_url, v.unlock_xp, 'US', true, v.position
from (values
  ('Pixl Holographic Pin', 'A holographic enamel pin for hitting 25 hours of shipped work. The first trophy on the road to the Blahaj.', 'https://pixl.rsvp/shop/holo-pin.png', 25, 500),
  ('Pixl Varsity Patch', 'An iron-on patch for your jacket or backpack, earned at 75 hours.', 'https://pixl.rsvp/shop/varsity-patch.png', 75, 501),
  ('Pixl Embroidered Cap', 'A snapback cap with the Pixl logo embroidered on front, earned at 175 hours.', 'https://pixl.rsvp/shop/embroidered-cap.png', 175, 502),
  ('Pixl Bomber Jacket', 'A full embroidered bomber jacket - the last stop before the Blahaj at 350 hours.', 'https://pixl.rsvp/shop/bomber-jacket.png', 350, 503)
) as v(name, description, image_url, unlock_xp, position)
where not exists (select 1 from shop_items existing where existing.name = v.name);
