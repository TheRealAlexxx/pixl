-- Referral reward/boost clawback tracking.
--
-- creditBeneficiary (apps/dashboard/app/actions.ts) grants the referred
-- player's one-time +14px/hr boost and the referrer's one-time tier reward
-- the first time ANY of the referred player's projects earns pixels. Nothing
-- recorded which project actually triggered them, so reReviewProject's pixel
-- clawback (voiding a bad verdict) never reversed the referral side effects ,
-- a fraudulent low-effort ship could get caught and reverted while the
-- referrer kept the real money it paid out.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

alter table referrals add column if not exists boost_project_id bigint references projects(id) on delete set null;
alter table referrals add column if not exists reward_project_id bigint references projects(id) on delete set null;
