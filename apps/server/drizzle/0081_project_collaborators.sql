-- Project collaboration: invite other players onto your project, track each
-- person's own Hackatime hours, and split the per-hour pixel payout so every
-- accepted collaborator is credited independently at their own rate tier.
-- Collaborators are view/log-hours only (no co-edit/co-ship) — the projects
-- table's single user_id stays the sole owner/editor/shipper.
--
-- Run in the Supabase SQL editor. Safe to re-run.

create table if not exists project_collaborators (
  id bigint generated always as identity primary key,
  project_id bigint not null references projects(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  invited_by uuid not null references users(id),
  status text not null default 'pending',   -- pending | accepted | declined | removed
  hackatime_projects text[] not null default '{}', -- collaborator's own linked Hackatime projects
  hackatime_seconds integer,                -- refreshed at each ship, mirrors projects.hackatime_seconds
  approved_hours numeric(10, 2),            -- set per-collaborator at review time
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  unique (project_id, user_id)
);
create index if not exists project_collaborators_project_idx on project_collaborators(project_id);
create index if not exists project_collaborators_user_idx on project_collaborators(user_id);

-- credit_project_pixels / revoke_project_pixels (0023_pixel_economy.sql)
-- originally scoped their "already credited" lookup to project_id alone,
-- which was fine when a project only ever had one beneficiary. With
-- collaborators, crediting person B on a project must not see person A's
-- payout as "already credited" — scope both by (project_id, user_id). This
-- is a no-op for every existing solo project (their history only ever had
-- one user_id per project_id anyway).
create or replace function credit_project_pixels(
  p_user_id uuid,
  p_project_id bigint,
  p_amount numeric,
  p_hours numeric,
  p_created_by text
) returns numeric
language plpgsql
as $$
declare
  already bigint;
  delta bigint;
  new_balance bigint;
begin
  select coalesce(sum(amount), 0) into already
  from pixel_transactions
  where project_id = p_project_id
    and user_id = p_user_id
    and reason in ('project_approved', 'review_reverted');

  delta := round(p_amount) - already;

  if delta <> 0 then
    insert into pixel_transactions (user_id, project_id, amount, hours, reason, created_by)
    values (p_user_id, p_project_id, delta, p_hours, 'project_approved', p_created_by);

    update users set pixels = pixels + delta
    where id = p_user_id
    returning pixels into new_balance;
  else
    select pixels into new_balance from users where id = p_user_id;
  end if;

  return coalesce(new_balance, 0);
end;
$$;

create or replace function revoke_project_pixels(
  p_user_id uuid,
  p_project_id bigint,
  p_created_by text
) returns numeric
language plpgsql
as $$
declare
  net bigint;
begin
  select coalesce(sum(amount), 0) into net
  from pixel_transactions
  where project_id = p_project_id
    and user_id = p_user_id
    and reason in ('project_approved', 'review_reverted');

  if net <> 0 then
    insert into pixel_transactions (user_id, project_id, amount, hours, reason, created_by)
    values (p_user_id, p_project_id, -net, 0, 'review_reverted', p_created_by);

    update users set pixels = pixels - net where id = p_user_id;
  end if;

  return coalesce(net, 0);
end;
$$;
