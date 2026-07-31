-- Follow-up to 0049 (which only deactivated these 22 pre-landing-sync
-- duplicate rows). Confirmed obsolete since — each is superseded by an
-- equivalent (renamed/re-priced) row synced from the landing page. Hard
-- delete now so they stop cluttering the dashboard's shop list, which shows
-- inactive rows too (greyed out with a "hidden" badge), not just what's live
-- in the game.
--
-- id=9 "3D Printed Blahaj" is intentionally excluded — it's the XP trophy,
-- still active, not a duplicate. Same list as 0049, just DELETE instead of
-- UPDATE this time.
--
-- Run this in the Supabase SQL editor. Safe to run more than once (DELETE ...
-- WHERE id IN (...) is a no-op the second time since the rows will be gone).
-- If any of these ids are referenced by a real shop_orders row (unlikely ,
-- the game hasn't launched and these were all superseded before purchases
-- were live), this will fail with a foreign-key error instead of silently
-- corrupting anything — if that happens, tell me which id and I'll adjust.

DELETE FROM shop_items
WHERE id IN (25, 13, 4, 24, 11, 16, 5, 19, 6, 7, 14, 26, 22, 15, 12, 8, 10, 17, 20, 2, 23, 21)
AND active = false;
