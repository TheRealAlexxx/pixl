-- Follow-up to 0093:
--   1. The per-person choice + 15-unit stock pool was meant for Random Desk
--      Object only, not Signed Org Photo — revert the photo back to a plain
--      item with no options and no stock pool.
--   2. Reword Random Desk Object's description: the 15-per-person cap is how
--      many that ORG MEMBER has to give away in total (Ridit has 15, Gabin
--      has 15, Ricky has 15) — not how many a single buyer can purchase.
--      "Only 15 available per person" read as the latter.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

DELETE FROM shop_option_stock
WHERE item_id = (SELECT id FROM shop_items WHERE name = 'Signed Org Photo' AND created_by = 'landing-sync');

UPDATE shop_items
SET options = '[]'::jsonb,
    description = 'A signed photo of one of the org members, shipped to your door.'
WHERE name = 'Signed Org Photo' AND created_by = 'landing-sync';

UPDATE shop_items
SET description = 'A random object from that person''s desk: a PCB, a sticker stash, anything. Comes with a signed letter. Ridit, Ricky and Gabin each only have 15 to give away — once one of them runs out, pick another.'
WHERE name = 'Random Desk Object' AND created_by = 'landing-sync';
