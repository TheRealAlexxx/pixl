-- Fourth batch: 1 more shop item designed on the landing page (pixl.rsvp),
-- added alongside 0047/0048/0051's items. Pure data insert.
--
-- Position continues at 58 (after 0051's 55..57).
--
-- Safe to run once. Check first / undo with:
--   SELECT name FROM shop_items WHERE created_by = 'landing-sync';
--   DELETE FROM shop_items WHERE created_by = 'landing-sync' AND position >= 58;

INSERT INTO shop_items (name, description, price, image_url, options, active, position, created_by, unlock_xp)
VALUES ('Food Grant', 'A stackable $10 grant for food and snacks while you build.', 200, 'https://pixl.rsvp/shop/food-grant.png', '[]'::jsonb, true, 58, 'landing-sync', 0);
