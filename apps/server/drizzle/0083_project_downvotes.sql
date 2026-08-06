-- Project downvotes: same shape as project_upvotes (0060), a permanent,
-- one-per-voter signal. Downvotes do NOT feed a currency and don't affect
-- the upvote balance/collectibles economy — pure community signal.
--
-- A voter can only cast one direction per project: the API blocks a
-- downvote if they've already upvoted (and vice versa).
--
-- Run in the Supabase SQL editor. Safe to re-run.

create table if not exists project_downvotes (
  id bigint generated always as identity primary key,
  project_id bigint not null references projects(id) on delete cascade,
  voter_id  uuid   not null references users(id)    on delete cascade,
  created_at timestamptz not null default now(),
  unique (project_id, voter_id)              -- one permanent downvote per voter
);
create index if not exists project_downvotes_project_idx on project_downvotes(project_id);
create index if not exists project_downvotes_voter_idx   on project_downvotes(voter_id);
