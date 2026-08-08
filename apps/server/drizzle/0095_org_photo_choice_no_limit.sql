-- Follow-up to 0093/0094: Signed Org Photo should let the buyer pick who it's
-- from (Ridit / Ricky / Gabin) same as Random Desk Object, but with no stock
-- limit — just an unlimited option group, no shop_option_stock rows.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

UPDATE shop_items
SET options = '["Signed by: Ridit, Ricky, Gabin"]'::jsonb
WHERE name = 'Signed Org Photo' AND created_by = 'landing-sync';
