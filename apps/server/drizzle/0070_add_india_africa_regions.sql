-- Add INDIA and AFRICA as shop regions, alongside the existing US, ASIA,
-- NORTH_AMERICA, SOUTH_AMERICA, EUROPE. Both start empty, same as the other
-- non-US regions when they were added (0063/0064) — stock them from the
-- dashboard's region tabs whenever ready.
--
-- Safe to run once. Re-running is a no-op.
-- Run this in the Supabase SQL editor.

ALTER TABLE shop_items DROP CONSTRAINT IF EXISTS shop_items_region_check;
ALTER TABLE shop_items ADD CONSTRAINT shop_items_region_check
  CHECK (region IN ('US', 'ASIA', 'NORTH_AMERICA', 'SOUTH_AMERICA', 'EUROPE', 'INDIA', 'AFRICA'));

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_region_check;
ALTER TABLE users ADD CONSTRAINT users_region_check
  CHECK (region IN ('US', 'ASIA', 'NORTH_AMERICA', 'SOUTH_AMERICA', 'EUROPE', 'INDIA', 'AFRICA'));
