-- Fulfillers manage shop-order fulfillment (claim/credit/ship), mirroring the
-- `helpers` table's role for tickets. Owners always qualify; anyone else needs
-- to be listed here to claim/credit/ship orders. The final close (mark done),
-- reassign, and cancel/refund stay owner-only (see actions.ts).
create table fulfillers (
  slack_user_id text primary key,
  created_at timestamptz not null default now()
);
