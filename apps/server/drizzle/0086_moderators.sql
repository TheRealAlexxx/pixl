-- Moderators: a lighter-weight role than sub-admins. Being listed here grants
-- report access (folded into report_viewers checks on the dashboard) and the
-- ability to warn players directly, but NOT to ban outright -- they can only
-- propose one, which an admin/owner with the "ban" permission must confirm.
-- Same allow-list shape as report_viewers/helpers/fulfillers.
create table if not exists moderators (
  slack_id text primary key,
  name text not null default '',
  added_by text not null default '',
  created_at timestamptz not null default now()
);

-- A moderator's proposed ban, pending admin confirmation. Confirming inserts
-- a real row into `bans` and links it back here; rejecting just closes it out.
create table if not exists ban_proposals (
  id bigint generated always as identity primary key,
  user_id uuid not null references users(id) on delete cascade,
  reason text not null default '',
  hours integer not null default 0, -- 0 = permanent, matches bans/BanForm semantics
  proposed_by text not null default '',
  status text not null default 'pending', -- pending | confirmed | rejected
  decided_by text,
  decided_at timestamptz,
  ban_id bigint references bans(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists ban_proposals_status_idx on ban_proposals (status);
create index if not exists ban_proposals_user_idx on ban_proposals (user_id);
