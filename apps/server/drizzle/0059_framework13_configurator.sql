-- Framework 13 Pro DIY (Intel Core Ultra Series 3) full configurator, USA
-- pricing from frame.work as of writing. Same mechanism as 0058 (Framework
-- 16 DIY): config_options set -> buy_shop_item recomputes price server-side
-- from validated picks instead of trusting shop_items.price.
--
-- base_price = $1,199 (cheapest CPU tier) -> 17129 px. Every other group's
-- price is the exact "+$X" shown on the configurator, converted at the same
-- $3.50 = 50px rate as the rest of the shop.
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

UPDATE shop_items
SET config_options = '{
  "base_price": 17129,
  "reference_url": "https://frame.work/products/laptop13pro-diy-intel-ultra-3/configuration/new",
  "groups": [
    { "name": "CPU", "type": "single", "choices": [
      { "label": "Intel Core Ultra 5 325 (4+4 core, up to 4.5GHz)", "price": 0 },
      { "label": "Intel Core Ultra X7 358H (4+8+4 core, up to 4.8GHz)", "price": 7143 }
    ] },
    { "name": "Memory", "type": "single", "choices": [
      { "label": "None (bring your own)", "price": 0 },
      { "label": "LPCAMM2 LPDDR5X - 16GB", "price": 3414 },
      { "label": "LPCAMM2 LPDDR5X - 32GB", "price": 11429 },
      { "label": "LPCAMM2 LPDDR5X - 64GB", "price": 22857 }
    ] },
    { "name": "Storage", "type": "single", "choices": [
      { "label": "None (bring your own)", "price": 0 },
      { "label": "SanDisk SN7100 PCIe 4.0 M.2 2280 - 500GB", "price": 1929 },
      { "label": "SanDisk SN7100 PCIe 4.0 M.2 2280 - 1TB", "price": 3071 },
      { "label": "SanDisk SN7100 PCIe 4.0 M.2 2280 - 2TB", "price": 7214 },
      { "label": "SanDisk SN7100 PCIe 4.0 M.2 2280 - 4TB", "price": 12500 },
      { "label": "SanDisk 850X PCIe 4.0 M.2 2280 - 1TB", "price": 4271 },
      { "label": "SanDisk 850X PCIe 4.0 M.2 2280 - 2TB", "price": 8929 },
      { "label": "SanDisk 850X PCIe 4.0 M.2 2280 - 4TB", "price": 16986 },
      { "label": "SanDisk 850X PCIe 4.0 M.2 2280 - 8TB", "price": 32414 },
      { "label": "ADATA MARS 970 PLUS PCIe 5.0 M.2 2280 - 1TB", "price": 4271 },
      { "label": "ADATA MARS 970 PLUS PCIe 5.0 M.2 2280 - 2TB", "price": 9414 }
    ] },
    { "name": "Operating System", "type": "single", "choices": [
      { "label": "None (bring your own)", "price": 0 },
      { "label": "Windows 11 Home (Download)", "price": 1986 },
      { "label": "Windows 11 Pro (Download)", "price": 2843 }
    ] },
    { "name": "Bezel", "type": "single", "choices": [
      { "label": "Black", "price": 0 },
      { "label": "Green", "price": 0 },
      { "label": "Red", "price": 0 },
      { "label": "Translucent", "price": 0 },
      { "label": "Orange", "price": 143 },
      { "label": "Lavender", "price": 143 },
      { "label": "Gray", "price": 143 },
      { "label": "Translucent Orange", "price": 143 },
      { "label": "Translucent Purple", "price": 143 },
      { "label": "Translucent Green", "price": 143 },
      { "label": "Translucent Black", "price": 143 }
    ] },
    { "name": "Keyboard", "type": "single", "choices": [
      { "label": "US English - Graphite", "price": 0 },
      { "label": "US English - Graphite - Gray/Black", "price": 143 },
      { "label": "US English - Graphite - Lavender/Black", "price": 143 },
      { "label": "Blank ISO - Graphite", "price": 143 },
      { "label": "Clear ISO - Graphite", "price": 143 },
      { "label": "Blank ANSI - Graphite", "price": 143 },
      { "label": "Clear ANSI - Graphite", "price": 143 }
    ] },
    { "name": "Power Adapter", "type": "single", "choices": [
      { "label": "None (bring your own)", "price": 0 },
      { "label": "Power Adapter - 100W - US/Canada", "price": 843 }
    ] },
    { "name": "Expansion Cards", "type": "multi", "choices": [
      { "label": "USB-C", "price": 143 },
      { "label": "USB-A (2nd Gen)", "price": 143 },
      { "label": "HDMI (3rd Gen)", "price": 314 },
      { "label": "Ethernet", "price": 557 },
      { "label": "WisdPi 10G Ethernet", "price": 1414 },
      { "label": "DisplayPort (2nd Gen)", "price": 271 },
      { "label": "MicroSD (2nd Gen)", "price": 271 },
      { "label": "SD", "price": 357 }
    ] },
    { "name": "Laptop Sleeve", "type": "multi", "choices": [
      { "label": "Smoke Black", "price": 557 },
      { "label": "Space Silver", "price": 557 }
    ] },
    { "name": "Warranty", "type": "single", "choices": [
      { "label": "1 Year (included)", "price": 0 },
      { "label": "3 Year", "price": 2557 }
    ] }
  ]
}'::jsonb,
price = 17129,
description = 'Fully custom-built Framework Laptop 13 Pro (Intel Core Ultra Series 3) — pick your CPU, RAM, storage, ports, and more. Price adapts to what you choose. Check frame.work''s own configurator for the full spec sheet, then match your picks below.'
WHERE name = 'Framework 13 DIY' AND created_by = 'landing-sync';
