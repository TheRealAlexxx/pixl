-- Village upgrades: cosmetic themes. A theme is a tint the whole village sees;
-- it composes with the day/night cycle rather than replacing it. Owners buy a
-- theme once (permanent unlock, a pixel sink) and can then apply/swap freely.
-- This is the first village upgrade — village_upgrades is intentionally generic
-- (upgrade_key) so later upgrades (capacity tiers, NPC slots) reuse the table.

-- Active theme on a village. '' means the default (no tint).
alter table lobbies add column if not exists theme text not null default '';

-- Permanent per-village unlocks. upgrade_key is the theme id for now.
create table if not exists village_upgrades (
  lobby_id text not null,
  upgrade_key text not null,
  unlocked_at timestamptz not null default now(),
  primary key (lobby_id, upgrade_key)
);

-- Server-authoritative theme purchase. Mirrors buy_shop_item: re-checks the
-- buyer owns the village and can afford it, deducts pixels, logs the movement,
-- and records the unlock — all under one row lock so a double-click can't
-- overspend or double-unlock. Returns the new balance or an error code.
create or replace function buy_village_theme(
  p_user_id uuid,
  p_lobby_id text,
  p_theme text,
  p_price integer
) returns json
language plpgsql
as $$
declare
  v_owner uuid;
  v_balance bigint;
begin
  if p_theme is null or p_theme = '' or p_price <= 0 then
    return json_build_object('ok', false, 'error', 'unavailable');
  end if;

  select owner_id into v_owner from lobbies where id = p_lobby_id;
  if not found or v_owner is distinct from p_user_id then
    return json_build_object('ok', false, 'error', 'not_owner');
  end if;

  if exists (
    select 1 from village_upgrades
    where lobby_id = p_lobby_id and upgrade_key = p_theme
  ) then
    return json_build_object('ok', false, 'error', 'owned');
  end if;

  select pixels into v_balance from users where id = p_user_id for update;
  if v_balance is null then
    return json_build_object('ok', false, 'error', 'unavailable');
  end if;
  if v_balance < p_price then
    return json_build_object('ok', false, 'error', 'insufficient',
      'balance', v_balance, 'price', p_price);
  end if;

  update users set pixels = pixels - p_price where id = p_user_id
    returning pixels into v_balance;

  insert into pixel_transactions (user_id, project_id, amount, hours, reason, created_by)
  values (p_user_id, null, -p_price, 0, 'village_upgrade', 'village');

  insert into village_upgrades (lobby_id, upgrade_key)
  values (p_lobby_id, p_theme);

  return json_build_object('ok', true, 'balance', v_balance);
end;
$$;
