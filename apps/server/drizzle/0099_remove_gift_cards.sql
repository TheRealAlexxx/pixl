-- Remove "Steam Gift Card ($100)" and "Google Play Gift Card ($25)" — added
-- in 0097, no longer wanted. Removes them from every region they were added
-- to (US, EUROPE, INDIA). The existing "Steam License" / "Google Play
-- Developer License" grant items are untouched.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

DELETE FROM shop_items WHERE name = 'Steam Gift Card ($100)' AND created_by = 'landing-sync';
DELETE FROM shop_items WHERE name = 'Google Play Gift Card ($25)' AND created_by = 'landing-sync';
