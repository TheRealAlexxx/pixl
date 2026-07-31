-- Village (lobby) invites. Any member currently inside a village can invite an
-- accepted friend into it. Invites persist so an offline friend can accept
-- later, as long as the village still exists. One row per invite; the sender's
-- village id/name is snapshotted so the invitee sees where they were called to
-- even before the lobby is re-resolved. Accepting is handled over the game
-- socket (it grants entry to the lobby); listing/declining go through the HTTP
-- village route. lobby_id has no FK because public quick-join lobbies aren't
-- always persisted — existence is validated against the live lobby set instead.
create table if not exists village_invites (
  id bigint generated always as identity primary key,
  lobby_id text not null,
  lobby_name text not null default '',
  from_user_id uuid not null references users(id) on delete cascade,
  to_user_id uuid not null references users(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours'
);

-- Fast lookup of a player's incoming invites.
create index if not exists idx_village_invites_to
  on village_invites(to_user_id, status);

-- At most one live invite per (village, invitee) so repeat clicks can't pile up.
create unique index if not exists uniq_village_invite_pending
  on village_invites(lobby_id, to_user_id)
  where status = 'pending';
