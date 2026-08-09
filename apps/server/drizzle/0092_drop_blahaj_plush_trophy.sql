-- Follow-up to 0091: drop "Blahaj Plush" too, leaving "3D Printed Blahaj" as
-- the only trophy on the track.
--
-- Worth knowing what this row actually is: 0047 imported Blahaj Plush as a
-- normal purchasable item (price 700, later repriced to 575 by 0062), and then
-- 0077's `update ... where name ilike '%blahaj%'` swept it into a trophy by
-- setting unlock_xp = 500. So it still carries a price it never uses — the
-- shop partitions on unlock_xp > 0 (isTrophy() in web/shop/index.html), and
-- the trophy grid and the buyable list are mutually exclusive, so this row only
-- ever rendered as a trophy card. Deleting it removes it from the trophy grid
-- and from nowhere else.
--
-- Verified before writing this: no shop_claims and no shop_orders reference it,
-- so nothing cascades. (shop_claims.item_id is ON DELETE CASCADE,
-- shop_orders.item_id is ON DELETE SET NULL.)
--
-- Matched on exact name + unlock_xp > 0, so if a purchasable Blahaj Plush is
-- ever re-imported by 0047 this can't touch it.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

delete from shop_items
where name = 'Blahaj Plush'
  and unlock_xp > 0;
