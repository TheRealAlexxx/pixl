-- Multi-stage fulfillment pipeline for shop orders.
--
-- Until now an order was just pending -> fulfilled | cancelled: one team member
-- flipped it "done" and dropped a note. Real fulfilment has distinct stages a
-- physical order actually moves through, and each order is owned by one fulfiller
-- so it lands in their queue and nobody else steps on it:
--
--   pending  -> a buyer spent pixels; nobody has picked it up yet
--   ordered  -> a fulfiller placed the real order (e.g. on Amazon) and claimed
--               it. HCB hasn't pulled the money from the card yet.
--   credited -> HCB credited the card and the fulfiller uploaded the receipt.
--               Paid, not shipped.
--   shipped  -> the order shipped; tracking is recorded and DM'd to the buyer.
--   cancelled-> refunded (e.g. a blocked Amazon account killed the order).
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

-- ── new pipeline columns ────────────────────────────────────────────────────
-- claimed_by / claimed_by_slack identify the one fulfiller who owns the order
-- once it's picked up; the slack id is what "my queue" filters on. Each stage
-- stamps its own timestamp so the card can show what happened when, and tracking
-- holds the shipment number we DM to the buyer.
ALTER TABLE shop_orders
  ADD COLUMN IF NOT EXISTS claimed_by       text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS claimed_by_slack text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS claimed_at       timestamptz,
  ADD COLUMN IF NOT EXISTS ordered_at       timestamptz,
  ADD COLUMN IF NOT EXISTS credited_at      timestamptz,
  ADD COLUMN IF NOT EXISTS shipped_at       timestamptz,
  ADD COLUMN IF NOT EXISTS tracking         text NOT NULL DEFAULT '';

-- Fold the old terminal 'fulfilled' status into the new terminal 'shipped'. The
-- old fulfilled_by/fulfilled_at already record who finished it and when, so reuse
-- those as the claimer + shipped time for history.
UPDATE shop_orders
  SET status      = 'shipped',
      shipped_at  = COALESCE(shipped_at, fulfilled_at, now()),
      claimed_at  = COALESCE(claimed_at, fulfilled_at),
      ordered_at  = COALESCE(ordered_at, fulfilled_at),
      credited_at = COALESCE(credited_at, fulfilled_at),
      claimed_by  = CASE WHEN claimed_by = '' THEN fulfilled_by ELSE claimed_by END
  WHERE status = 'fulfilled';

-- "My queue" lookups filter by the owning fulfiller.
CREATE INDEX IF NOT EXISTS idx_shop_orders_claimed ON shop_orders(claimed_by_slack, status);

-- ── cancel from any live stage, not just pending ────────────────────────────
-- An order can die at any point before it ships (a blocked Amazon account, a
-- refund request, wrong item). Broaden the refund so pending / ordered / credited
-- all hand the pixels back; shipped and cancelled are terminal and no-op. Still
-- idempotent under a row lock so a double-click can't refund twice.
CREATE OR REPLACE FUNCTION cancel_shop_order(
  p_order_id bigint,
  p_by text
) returns integer
language plpgsql
as $$
declare
  v_order shop_orders%rowtype;
begin
  select * into v_order from shop_orders where id = p_order_id for update;
  if not found or v_order.status in ('shipped', 'cancelled') then
    return 0;
  end if;

  update shop_orders
    set status = 'cancelled', fulfilled_at = now(), fulfilled_by = p_by
    where id = p_order_id;

  update users set pixels = pixels + v_order.price where id = v_order.user_id;

  insert into pixel_transactions (user_id, project_id, amount, hours, reason, created_by)
  values (v_order.user_id, null, v_order.price, 0, 'shop_refund', p_by);

  return v_order.price;
end;
$$;
