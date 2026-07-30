-- Ship-for-a-Trial reward flow: a per-Trial minimum hour requirement, an
-- optional catalog item to auto-grant as the Trial's prize, and the
-- project-side record of that grant (so it only happens once per project).
--
-- min_hours stays nullable = "no gate" (every Trial that doesn't set one
-- behaves exactly as before). prize_shop_item_id is optional too: when unset,
-- the reviewer flow (apps/dashboard/app/actions.ts) opens a $0 shop_order
-- with the sidequest's free-text `reward` as the item name instead of a real
-- catalog item, same as any custom order ops fulfils by hand.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

ALTER TABLE sidequests
  ADD COLUMN IF NOT EXISTS min_hours numeric,
  ADD COLUMN IF NOT EXISTS prize_shop_item_id bigint REFERENCES shop_items(id);

ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS trial_prize_order_id bigint REFERENCES shop_orders(id);

-- The one Trial live today that already has a documented minimum (see
-- 0061_project_trial_link.sql's description text).
UPDATE sidequests SET min_hours = 7
WHERE name = 'The Wall at the Sixteen Colors' AND min_hours IS NULL;
