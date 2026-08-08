-- Three shop features in one migration:
--   1. A buyer-submitted "note to fulfiller" on every order (separate from
--      the existing `note` column, which is the admin/cancellation-reason
--      note shown when an order is cancelled — this is the buyer's own).
--   2. Per-choice stock pools: Signed Org Photo and Random Desk Object now
--      let the buyer pick who it's from (Ridit / Ricky / Gabin), capped at
--      15 available per person, tracked live and decremented atomically
--      under a row lock so two buyers can't both grab the last unit.
--   3. Indie Game of Your Choice gets its full picklist.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

-- 1. Buyer note.
ALTER TABLE shop_orders ADD COLUMN IF NOT EXISTS buyer_note text NOT NULL DEFAULT '';

-- 2a. Which stock-limited choice (if any) this order consumed, so a
--     cancellation/refund can hand the unit back.
ALTER TABLE shop_orders ADD COLUMN IF NOT EXISTS stock_choice text NOT NULL DEFAULT '';

-- 2b. Per-item, per-choice stock pools.
CREATE TABLE IF NOT EXISTS shop_option_stock (
  id bigint generated always as identity primary key,
  item_id integer NOT NULL REFERENCES shop_items(id) ON DELETE CASCADE,
  choice text NOT NULL,
  total integer NOT NULL,
  remaining integer NOT NULL,
  UNIQUE (item_id, choice)
);

-- buy_shop_item: now also takes an optional note and stock choice. If the
-- item has a stock pool for the chosen option, the purchase is rejected
-- (before any pixels move) once that pool can't cover the requested quantity.
create or replace function buy_shop_item(
  p_user_id uuid,
  p_item_id integer,
  p_option text,
  p_config jsonb default null,
  p_quantity integer default 1,
  p_note text default '',
  p_stock_choice text default ''
) returns json
language plpgsql
as $$
declare
  v_item shop_items%rowtype;
  v_balance bigint;
  v_order_id bigint;
  v_unit_price integer;
  v_price integer;
  v_qty integer;
  v_group jsonb;
  v_choice jsonb;
  v_pick text;
  v_found boolean;
  v_key text;
  v_stock_remaining integer;
begin
  select * into v_item from shop_items where id = p_item_id;
  if not found or not v_item.active then
    return json_build_object('ok', false, 'error', 'unavailable');
  end if;
  if coalesce(v_item.unlock_xp, 0) > 0 or v_item.price <= 0 then
    return json_build_object('ok', false, 'error', 'not_for_sale');
  end if;

  v_qty := greatest(1, least(999, coalesce(p_quantity, 1)));
  v_unit_price := v_item.price;

  if v_item.config_options is not null then
    v_unit_price := coalesce((v_item.config_options->>'base_price')::integer, v_item.price);
    for v_group in select * from jsonb_array_elements(v_item.config_options->'groups')
    loop
      v_key := v_group->>'name';
      if v_group->>'type' = 'multi' then
        for v_choice in select * from jsonb_array_elements(v_group->'choices')
        loop
          if p_config is not null and p_config->v_key is not null
             and (p_config->v_key) ? (v_choice->>'label') then
            v_unit_price := v_unit_price + coalesce((v_choice->>'price')::integer, 0);
          end if;
        end loop;
      else
        v_pick := p_config->>v_key;
        v_found := false;
        for v_choice in select * from jsonb_array_elements(v_group->'choices')
        loop
          if v_choice->>'label' = v_pick then
            v_unit_price := v_unit_price + coalesce((v_choice->>'price')::integer, 0);
            v_found := true;
          end if;
        end loop;
        -- no valid pick sent for a single-choice group: charge its default
        -- (first) choice rather than skip it, so price is never understated.
        if not v_found then
          v_choice := v_group->'choices'->0;
          v_unit_price := v_unit_price + coalesce((v_choice->>'price')::integer, 0);
        end if;
      end if;
    end loop;
  end if;

  v_price := v_unit_price * v_qty;

  -- Stock-limited choice check (e.g. "Ridit" for the Signed Org Photo) —
  -- locked so two simultaneous buyers can't both grab the last unit. Only
  -- enforced for items that actually have a stock pool; a stray/bogus
  -- p_stock_choice sent for any other item is just ignored, not rejected.
  if coalesce(p_stock_choice, '') <> '' and exists (
    select 1 from shop_option_stock where item_id = p_item_id
  ) then
    select remaining into v_stock_remaining
      from shop_option_stock
      where item_id = p_item_id and choice = p_stock_choice
      for update;
    if v_stock_remaining is null or v_stock_remaining < v_qty then
      return json_build_object('ok', false, 'error', 'sold_out',
        'remaining', coalesce(v_stock_remaining, 0));
    end if;
  else
    p_stock_choice := '';
  end if;

  select pixels into v_balance from users where id = p_user_id for update;
  if v_balance is null then
    return json_build_object('ok', false, 'error', 'unavailable');
  end if;
  if v_balance < v_price then
    return json_build_object('ok', false, 'error', 'insufficient',
      'balance', v_balance, 'price', v_price);
  end if;

  update users set pixels = pixels - v_price where id = p_user_id
    returning pixels into v_balance;

  insert into pixel_transactions (user_id, project_id, amount, hours, reason, created_by)
  values (p_user_id, null, -v_price, 0, 'shop_purchase', 'shop');

  if coalesce(p_stock_choice, '') <> '' then
    update shop_option_stock set remaining = remaining - v_qty
      where item_id = p_item_id and choice = p_stock_choice;
  end if;

  insert into shop_orders (user_id, item_id, item_name, option, config, price, quantity, status, buyer_note, stock_choice)
  values (p_user_id, v_item.id, v_item.name, coalesce(p_option, ''), coalesce(p_config, '{}'::jsonb), v_price, v_qty, 'pending',
          left(coalesce(p_note, ''), 300), coalesce(p_stock_choice, ''))
  returning id into v_order_id;

  return json_build_object('ok', true, 'balance', v_balance,
    'order_id', v_order_id, 'item_name', v_item.name, 'price', v_price, 'quantity', v_qty);
end;
$$;

-- cancel_shop_order: also hand back a consumed stock unit.
create or replace function cancel_shop_order(
  p_order_id bigint,
  p_by text
) returns integer
language plpgsql
as $$
declare
  v_order shop_orders%rowtype;
begin
  select * into v_order from shop_orders where id = p_order_id for update;
  if not found or v_order.status <> 'pending' then
    return 0;
  end if;

  update shop_orders
    set status = 'cancelled', fulfilled_at = now(), fulfilled_by = p_by
    where id = p_order_id;

  update users set pixels = pixels + v_order.price where id = v_order.user_id;

  insert into pixel_transactions (user_id, project_id, amount, hours, reason, created_by)
  values (v_order.user_id, null, v_order.price, 0, 'shop_refund', p_by);

  if coalesce(v_order.stock_choice, '') <> '' then
    update shop_option_stock set remaining = remaining + v_order.quantity
      where item_id = v_order.item_id and choice = v_order.stock_choice;
  end if;

  return v_order.price;
end;
$$;

-- 3. Seed the 15-per-person pools for the two items that need them.
INSERT INTO shop_option_stock (item_id, choice, total, remaining)
SELECT id, choice, 15, 15
FROM shop_items, unnest(ARRAY['Ridit', 'Ricky', 'Gabin']) AS choice
WHERE name IN ('Signed Org Photo', 'Random Desk Object') AND created_by = 'landing-sync'
ON CONFLICT (item_id, choice) DO NOTHING;

-- 4. Give those two items their person-choice option group. The group name
--    ("Signed by" / "Desk of") must exactly match what the client looks for
--    to pair chips up with live stock counts.
UPDATE shop_items
SET options = '["Signed by: Ridit, Ricky, Gabin"]'::jsonb,
    description = 'A signed photo of one of the org members, shipped to your door. Only 15 available per person.'
WHERE name = 'Signed Org Photo' AND created_by = 'landing-sync';

UPDATE shop_items
SET options = '["Desk of: Ridit, Ricky, Gabin"]'::jsonb,
    description = 'A random object from that person''s desk: a PCB, a sticker stash, anything. Comes with a signed letter. Only 15 available per person.'
WHERE name = 'Random Desk Object' AND created_by = 'landing-sync';

-- 5. Indie Game of Your Choice picklist. "Papers Please" drops its comma —
--    the options encoding is comma-delimited, so a literal comma inside a
--    choice would get split into two.
UPDATE shop_items
SET options = '["Game: Hollow Knight, Hollow Knight: Silksong, Baba Is You, Celeste, Terraria, Balatro, Stardew Valley, Undertale, DELTARUNE, Vampire Survivors, Megabonk, Outer Wilds, Papers Please, Pizza Tower, OMORI, Lethal Company, A Short Hike, Downwell, OneShot, Inscryption, ANIMAL WELL, Return of the Obra Dinn, Thomas Was Alone, Super Hexagon, Hotline Miami, Super Meat Boy, Cruelty Squad"]'::jsonb
WHERE name = 'Indie Game of Your Choice' AND created_by = 'landing-sync';
