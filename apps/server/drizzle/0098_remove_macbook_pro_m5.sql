-- Remove "MacBook Pro M5 (16GB/512GB)" — added in 0097, no longer wanted.
-- Removes it from every region it was added to (US, EUROPE, INDIA).
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

DELETE FROM shop_items WHERE name = 'MacBook Pro M5 (16GB/512GB)' AND created_by = 'landing-sync';
