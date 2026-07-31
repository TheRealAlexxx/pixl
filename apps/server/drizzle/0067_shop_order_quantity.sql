-- Let a buyer purchase more than one of a shop item in a single order. Until
-- now `buy_shop_item` always charged one unit; this adds a `quantity` on
-- shop_orders (default 1, so every existing row reads as "one of these") and
-- a p_quantity arg on the RPC that multiplies the unit price (config-priced
-- items included) by the quantity, clamped to 1-999 server-side so a bad
-- client value can't over/undercharge or spam fulfillment with a negative
-- or absurdly large order.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

ALTER TABLE shop_orders ADD COLUMN IF NOT EXISTS quantity integer NOT NULL DEFAULT 1;

create or replace function buy_shop_item(
  p_user_id uuid,
  p_item_id integer,
  p_option text,
  p_config jsonb default null,
  p_quantity integer default 1
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

  insert into shop_orders (user_id, item_id, item_name, option, config, price, quantity, status)
  values (p_user_id, v_item.id, v_item.name, coalesce(p_option, ''), coalesce(p_config, '{}'::jsonb), v_price, v_qty, 'pending')
  returning id into v_order_id;

  return json_build_object('ok', true, 'balance', v_balance,
    'order_id', v_order_id, 'item_name', v_item.name, 'price', v_price, 'quantity', v_qty);
end;
$$;
