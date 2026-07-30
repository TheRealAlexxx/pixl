-- Move the Community Meme Pack from last (position 60) to right after the
-- Signed Org Photo (position 0) in the "featured" sort — it's just as niche
-- and belongs with the other cheap/fun items up front, not buried at the
-- end of the catalog.
--
-- Shifts every other item at position >= 1 up by one slot, then drops the
-- meme pack into the freed-up position 1.
--
-- NOT idempotent — running this twice will shift everything an extra slot.
-- Run this once in the Supabase SQL editor.

UPDATE shop_items
SET position = position + 1
WHERE position >= 1 AND name != 'Community Meme Pack (5-Pack)';

UPDATE shop_items
SET position = 1
WHERE name = 'Community Meme Pack (5-Pack)';
