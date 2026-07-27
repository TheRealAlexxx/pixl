-- Project upvotes + the "upvote account" currency and the collectibles it buys.
--
-- Upvotes are PERMANENT: a player can upvote an approved project once, and it
-- never gets taken back. The count lives with the project. Every upvote a
-- project RECEIVES credits its owner's upvote balance, which is a separate
-- currency (distinct from Pixels / Restoration Energy) spent on in-game
-- collectibles.
--
-- Run in the Supabase SQL editor. Safe to re-run.

create table if not exists project_upvotes (
  id bigint generated always as identity primary key,
  project_id bigint not null references projects(id) on delete cascade,
  voter_id  uuid   not null references users(id)    on delete cascade,
  created_at timestamptz not null default now(),
  unique (project_id, voter_id)              -- one permanent upvote per voter
);
create index if not exists project_upvotes_project_idx on project_upvotes(project_id);
create index if not exists project_upvotes_voter_idx   on project_upvotes(voter_id);

-- Catalog of in-game collectibles bought with the upvote currency. `cost` is in
-- upvotes. Content is authored here / in the dashboard later.
create table if not exists collectibles (
  id bigint generated always as identity primary key,
  name text not null,
  description text not null default '',
  image_url text not null default '',
  cost integer not null default 0,           -- price in upvotes
  active boolean not null default true,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

-- Spend ledger. A user's upvote balance =
--   (upvotes received across their projects) - (sum of these costs).
create table if not exists collectible_purchases (
  id bigint generated always as identity primary key,
  user_id uuid not null references users(id) on delete cascade,
  collectible_id bigint not null references collectibles(id) on delete cascade,
  cost integer not null,
  created_at timestamptz not null default now(),
  unique (user_id, collectible_id)           -- own each collectible once
);
create index if not exists collectible_purchases_user_idx on collectible_purchases(user_id);

-- Placeholder collectibles so the store isn't empty — replace with real content.
insert into collectibles (name, description, image_url, cost, position)
select v.name, v.description, '', v.cost, v.position
from (values
  ('Bronze Builder Badge', 'A little bronze badge for your profile — proof people liked what you shipped.', 5, 1),
  ('Silver Builder Badge', 'A polished silver badge. You are clearly onto something.', 15, 2),
  ('Golden Builder Badge', 'The gold one. Reserved for the community favourites.', 40, 3)
) as v(name, description, cost, position)
where not exists (select 1 from collectibles c where c.name = v.name);
