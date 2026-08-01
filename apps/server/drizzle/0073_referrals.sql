-- Referral system.
--
-- A player gets a short referral_code (generated lazily on first request via
-- GET /api/referral/me). A new player applies someone's code once via
-- POST /api/referral/apply, creating a `referrals` row (one per referred_id ,
-- a player can only ever be referred once, and only by someone else). The
-- applying account must also be within its first 2 days on Pixl (enforced in
-- referral.ts, not the schema) , otherwise two existing players could just
-- "refer" each other after the fact for free money with zero real user
-- acquisition behind it.
--
-- Two payouts hang off that row:
--   - The REFERRER gets a one-time reward when the referred player's first
--     *qualifying* newly-approved project clears an hour tier (2h/5h/10h , see
--     apps/dashboard/app/actions.ts reviewProject). A project under 2h doesn't
--     close the referral, it just waits for a bigger one; the first project
--     that DOES clear a tier pays out and sets rewarded_at, closing the
--     contract for good, no matter how big future ships get.
--   - The REFERRED player gets a flat +14px/hr (~$1/hr) boost on top of their
--     normal level-based rate, for their first newly-approved ship only,
--     tracked by boosted_ships (capped at 1 in application code).
--
-- Every 10th referral a referrer gets rewarded on (10, 20, 30…) also pays a
-- milestone bonus, checked in the same code path.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

alter table users add column if not exists referral_code text unique;

create table if not exists referrals (
  id bigint generated always as identity primary key,
  referrer_id uuid not null references users(id) on delete cascade,
  referred_id uuid not null references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  rewarded_at timestamptz,
  reward_tier text,
  reward_pixels integer,
  boosted_ships integer not null default 0,
  unique (referred_id),
  constraint referrals_no_self_referral check (referrer_id <> referred_id)
);

create index if not exists idx_referrals_referrer on referrals(referrer_id);
create index if not exists idx_referrals_referrer_rewarded
  on referrals(referrer_id) where rewarded_at is not null;
