-- Real price-varying customization for specific shop items (initially the
-- Framework 13/16 DIY laptops, which have dozens of components that each
-- change the real-world price). The existing `options` column (a flat
-- string-array of "GroupName: choiceA, choiceB", parsed by
-- apps/dashboard/lib/shopOptions.ts) never affected price — it's purely
-- descriptive, still used by every other item unchanged.
--
-- config_options is a SEPARATE, parallel mechanism only used by items that
-- opt in (config_options IS NOT NULL). Shape:
--   {
--     "base_price": 17843,                -- pixel price with nothing added
--     "groups": [
--       { "name": "CPU", "type": "single", "choices": [
--           { "label": "Ryzen AI 5 340 (...)", "price": 0 },
--           { "label": "Ryzen AI 7 350 (...)", "price": 3571 }
--       ] },
--       { "name": "Expansion Cards", "type": "multi", "choices": [
--           { "label": "USB-C", "price": 143 }
--       ] }
--     ]
--   }
-- "single" groups: buyer picks exactly one choice (defaults to choices[0] if
-- they never touch it). "multi" groups: buyer picks any number (0+), each
-- adds its own price. All "price" fields are PIXEL deltas already converted
-- from the real USD delta shown on the source configurator (rate: $3.50 =
-- 50px, same rate as every other shop item), computed once when the
-- migration was written — no runtime USD math anywhere.
--
-- `shop_orders.config` records exactly what the buyer picked (group name ->
-- chosen label, or group name -> array of chosen labels for multi groups) so
-- fulfillment knows precisely what to order. `option` (existing column)
-- keeps getting a human-readable summary for the ticket/dashboard display.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

ALTER TABLE shop_items ADD COLUMN IF NOT EXISTS config_options jsonb;
ALTER TABLE shop_orders ADD COLUMN IF NOT EXISTS config jsonb NOT NULL DEFAULT '{}'::jsonb;

-- Server-authoritative purchase, extended with an optional p_config. When the
-- item has config_options set, the price is recomputed here from base_price
-- + the buyer's picks (each validated against the item's own config_options
-- — nothing off-menu, no client-supplied price ever trusted) instead of the
-- flat shop_items.price. Items without config_options behave exactly as
-- before this migration.
create or replace function buy_shop_item(
  p_user_id uuid,
  p_item_id integer,
  p_option text,
  p_config jsonb default null
) returns json
language plpgsql
as $$
declare
  v_item shop_items%rowtype;
  v_balance bigint;
  v_order_id bigint;
  v_price integer;
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

  v_price := v_item.price;

  if v_item.config_options is not null then
    v_price := coalesce((v_item.config_options->>'base_price')::integer, v_item.price);
    for v_group in select * from jsonb_array_elements(v_item.config_options->'groups')
    loop
      v_key := v_group->>'name';
      if v_group->>'type' = 'multi' then
        for v_choice in select * from jsonb_array_elements(v_group->'choices')
        loop
          if p_config is not null and p_config->v_key is not null
             and (p_config->v_key) ? (v_choice->>'label') then
            v_price := v_price + coalesce((v_choice->>'price')::integer, 0);
          end if;
        end loop;
      else
        v_pick := p_config->>v_key;
        v_found := false;
        for v_choice in select * from jsonb_array_elements(v_group->'choices')
        loop
          if v_choice->>'label' = v_pick then
            v_price := v_price + coalesce((v_choice->>'price')::integer, 0);
            v_found := true;
          end if;
        end loop;
        -- no valid pick sent for a single-choice group: charge its default
        -- (first) choice rather than skip it, so price is never understated.
        if not v_found then
          v_choice := v_group->'choices'->0;
          v_price := v_price + coalesce((v_choice->>'price')::integer, 0);
        end if;
      end if;
    end loop;
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

  insert into shop_orders (user_id, item_id, item_name, option, config, price, status)
  values (p_user_id, v_item.id, v_item.name, coalesce(p_option, ''), coalesce(p_config, '{}'::jsonb), v_price, 'pending')
  returning id into v_order_id;

  return json_build_object('ok', true, 'balance', v_balance,
    'order_id', v_order_id, 'item_name', v_item.name, 'price', v_price);
end;
$$;

-- Framework 16 DIY (AMD Ryzen AI 300 Series) full configurator, USA pricing
-- from frame.work as of writing. base_price = $1,249 (cheapest CPU tier) →
-- 17843 px. Every other group's price is the exact "+$X" shown on the
-- configurator, converted at the same $3.50 = 50px rate as the rest of the
-- shop.
UPDATE shop_items
SET config_options = '{
  "base_price": 17843,
  "reference_url": "https://frame.work/products/laptop16-diy-amd-ai300/configuration/new",
  "groups": [
    { "name": "CPU", "type": "single", "choices": [
      { "label": "Ryzen AI 5 340 (6-core/12-thread, up to 4.8GHz)", "price": 0 },
      { "label": "Ryzen AI 7 350 (8-core/16-thread, up to 5.0GHz)", "price": 3571 },
      { "label": "Ryzen AI 9 HX 370 (12-core/24-thread, up to 5.1GHz)", "price": 7857 }
    ] },
    { "name": "Memory", "type": "single", "choices": [
      { "label": "DDR5-5600 - 8GB (1x8GB)", "price": 2286 },
      { "label": "DDR5-5600 - 16GB (1x16GB)", "price": 3571 },
      { "label": "DDR5-5600 - 16GB (2x8GB)", "price": 4571 },
      { "label": "DDR5-5600 - 32GB (1x32GB)", "price": 5786 },
      { "label": "DDR5-5600 - 32GB (2x16GB)", "price": 7143 },
      { "label": "DDR5-5600 - 48GB (1x48GB)", "price": 9414 },
      { "label": "DDR5-5600 - 64GB (2x32GB)", "price": 11571 },
      { "label": "DDR5-5600 - 96GB (2x48GB)", "price": 18829 }
    ] },
    { "name": "Storage", "type": "single", "choices": [
      { "label": "SanDisk SN7100 PCIe 4.0 M.2 2280 - 500GB", "price": 1929 },
      { "label": "SanDisk SN7100 PCIe 4.0 M.2 2280 - 1TB", "price": 3071 },
      { "label": "SanDisk SN7100 PCIe 4.0 M.2 2280 - 2TB", "price": 7214 },
      { "label": "SanDisk SN7100 PCIe 4.0 M.2 2280 - 4TB", "price": 12500 },
      { "label": "SanDisk 850X PCIe 4.0 M.2 2280 - 1TB", "price": 4271 },
      { "label": "SanDisk 850X PCIe 4.0 M.2 2280 - 2TB", "price": 8929 },
      { "label": "SanDisk 850X PCIe 4.0 M.2 2280 - 4TB", "price": 16986 },
      { "label": "SanDisk 850X PCIe 4.0 M.2 2280 - 8TB", "price": 32414 }
    ] },
    { "name": "Secondary Storage", "type": "single", "choices": [
      { "label": "None (bring your own)", "price": 0 },
      { "label": "WD_BLACK SN770M NVMe M.2 2230 - 500GB", "price": 1929 },
      { "label": "WD_BLACK SN770M NVMe M.2 2230 - 1TB", "price": 3643 },
      { "label": "WD_BLACK SN770M NVMe M.2 2230 - 2TB", "price": 7071 }
    ] },
    { "name": "Operating System", "type": "single", "choices": [
      { "label": "None (bring your own)", "price": 0 },
      { "label": "Windows 11 Home (Download)", "price": 1986 },
      { "label": "Windows 11 Pro (Download)", "price": 2843 }
    ] },
    { "name": "Power Adapter", "type": "single", "choices": [
      { "label": "None (bring your own)", "price": 0 },
      { "label": "Power Adapter - 240W - US/Canada", "price": 1557 }
    ] },
    { "name": "Bezel", "type": "single", "choices": [
      { "label": "Black", "price": 0 },
      { "label": "Orange", "price": 286 },
      { "label": "Lavender", "price": 286 }
    ] },
    { "name": "Touchpad", "type": "single", "choices": [
      { "label": "Three Piece Touchpad", "price": 0 },
      { "label": "One Piece Haptic Touchpad", "price": 0 }
    ] },
    { "name": "Input Modules", "type": "single", "choices": [
      { "label": "Default (2x Black Spacer)", "price": 0 },
      { "label": "Numpad (2nd Gen)", "price": 557 },
      { "label": "RGB Macropad (2nd Gen)", "price": 1129 },
      { "label": "LED Matrix", "price": 786 }
    ] },
    { "name": "Keyboard", "type": "single", "choices": [
      { "label": "US English", "price": 0 },
      { "label": "RGB US English (2nd Gen)", "price": 714 },
      { "label": "RGB Clear ANSI (2nd Gen)", "price": 714 },
      { "label": "Blank ISO (2nd Gen)", "price": 143 },
      { "label": "Blank ANSI (2nd Gen)", "price": 143 }
    ] },
    { "name": "Expansion Cards", "type": "multi", "choices": [
      { "label": "USB-C", "price": 143 },
      { "label": "USB-A (2nd Gen)", "price": 143 },
      { "label": "HDMI (3rd Gen)", "price": 314 },
      { "label": "DisplayPort (2nd Gen)", "price": 271 },
      { "label": "Ethernet", "price": 557 },
      { "label": "WisdPi 10G Ethernet", "price": 1414 },
      { "label": "SD", "price": 357 },
      { "label": "Audio", "price": 271 }
    ] },
    { "name": "Warranty", "type": "single", "choices": [
      { "label": "1 Year (included)", "price": 0 },
      { "label": "3 Year", "price": 2700 }
    ] }
  ]
}'::jsonb,
-- Keep the flat price column in sync with base_price — it's still read as a
-- fallback (e.g. if config_options fails to load) and by anything that
-- hasn't been updated to call basePrice()/computeConfigPrice().
price = 17843,
description = 'Fully custom-built Framework Laptop 16 (AMD Ryzen AI 300 Series) — pick your CPU, RAM, storage, ports, and more. Price adapts to what you choose. Check frame.work''s own configurator for the full spec sheet, then match your picks below.'
WHERE name = 'Framework 16 DIY' AND created_by = 'landing-sync';
