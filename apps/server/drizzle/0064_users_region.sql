-- Players get a region so the shop can show the catalog meant for where they
-- actually live (fulfillment/shipping differ a lot by region — see
-- 0063_shop_items_region.sql). Everyone defaults to 'US' until they pick a
-- different region from the shop's region selector.
--
-- Safe to run once. Re-running is a no-op.
-- Run this in the Supabase SQL editor.

ALTER TABLE users ADD COLUMN IF NOT EXISTS region text NOT NULL DEFAULT 'US';

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_region_check;
ALTER TABLE users ADD CONSTRAINT users_region_check
  CHECK (region IN ('US', 'ASIA', 'NORTH_AMERICA', 'SOUTH_AMERICA', 'EUROPE'));
