-- Drops the four intermediate trophies added by 0079 (25/75/175/350 hours),
-- leaving the trophy track as just the two Blahaj items again: "3D Printed
-- Blahaj" and "Blahaj Plush", both at the 500 top tier.
--
-- None of the four ever got real art from Ricky (0079 inserted them pointing
-- at https://pixl.rsvp/shop/<slug>.png placeholders that don't exist), so
-- nothing is lost visually. The restoration-energy RATE_TIERS in src/xp.ts are
-- untouched — this only removes their shop rows, not the rate tiers.
--
-- Foreign keys, so you know what travels with the delete:
--   shop_orders.item_id  ON DELETE SET NULL  -> orders survive, keep item_name
--   shop_claims.item_id  ON DELETE CASCADE   -> any claim on these is dropped
-- Dropping the claims is the point (the trophy stops existing), but if you'd
-- rather know the damage first, run the pre-check below before the DELETE.
--
-- Run this in the Supabase SQL editor. Safe to run more than once (the second
-- run matches no rows).

-- Pre-check , how many claims are about to disappear:
-- select i.id, i.name, count(c.id) as claims
-- from shop_items i
-- left join shop_claims c on c.item_id = i.id
-- where i.name in (
--   'Pixl Holographic Pin',
--   'Pixl Varsity Patch',
--   'Pixl Embroidered Cap',
--   'Pixl Bomber Jacket'
-- )
-- group by i.id, i.name
-- order by i.name;

delete from shop_items
where name in (
  'Pixl Holographic Pin',
  'Pixl Varsity Patch',
  'Pixl Embroidered Cap',
  'Pixl Bomber Jacket'
);
