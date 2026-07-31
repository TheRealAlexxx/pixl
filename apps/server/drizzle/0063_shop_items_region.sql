-- Shop items get split per-region so fulfillment/shipping can differ by
-- where the buyer lives. Everything that already exists in the shop
-- (created before this migration) is the "US" catalog; the other four
-- regions start out empty and get stocked separately from the dashboard.
--
-- Safe to run once. Re-running is a no-op (column/constraint/index already
-- exist, existing rows already default to 'US').
-- Run this in the Supabase SQL editor.

ALTER TABLE shop_items ADD COLUMN IF NOT EXISTS region text NOT NULL DEFAULT 'US';

ALTER TABLE shop_items DROP CONSTRAINT IF EXISTS shop_items_region_check;
ALTER TABLE shop_items ADD CONSTRAINT shop_items_region_check
  CHECK (region IN ('US', 'ASIA', 'NORTH_AMERICA', 'SOUTH_AMERICA', 'EUROPE'));

CREATE INDEX IF NOT EXISTS shop_items_region_idx ON shop_items(region);
