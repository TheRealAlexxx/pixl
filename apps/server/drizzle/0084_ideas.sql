-- Idea playground: post an idea, browse others', up/downvote them. No review
-- queue (unlike projects) — posting is instant, since these are just prompts
-- for inspiration, not shipped work. Vote tables mirror project_upvotes/
-- project_downvotes (0060, 0083): permanent, one-per-voter, no self-votes,
-- one direction per voter per idea.
--
-- Run in the Supabase SQL editor. Safe to re-run.

create table if not exists ideas (
  id bigint generated always as identity primary key,
  user_id uuid not null references users(id) on delete cascade,
  title text not null,
  body text not null default '',
  created_at timestamptz not null default now(),
  banned_at timestamptz              -- admin moderation hook; null = live
);
create index if not exists ideas_user_idx on ideas(user_id);
create index if not exists ideas_created_idx on ideas(created_at desc);

create table if not exists idea_upvotes (
  id bigint generated always as identity primary key,
  idea_id bigint not null references ideas(id) on delete cascade,
  voter_id uuid   not null references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (idea_id, voter_id)
);
create index if not exists idea_upvotes_idea_idx on idea_upvotes(idea_id);
create index if not exists idea_upvotes_voter_idx on idea_upvotes(voter_id);

create table if not exists idea_downvotes (
  id bigint generated always as identity primary key,
  idea_id bigint not null references ideas(id) on delete cascade,
  voter_id uuid   not null references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (idea_id, voter_id)
);
create index if not exists idea_downvotes_idea_idx on idea_downvotes(idea_id);
create index if not exists idea_downvotes_voter_idx on idea_downvotes(voter_id);
