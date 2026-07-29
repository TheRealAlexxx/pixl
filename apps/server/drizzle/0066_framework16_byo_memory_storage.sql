-- Bug: Framework 16 DIY's config_options (0058) never gave Memory or
-- Storage a "None (bring your own)" free tier — unlike Framework 13 DIY
-- (0059), which correctly has one for both. That meant the cheapest possible
-- Memory (8GB, +2286px) and Storage (500GB, +1929px) were mandatory add-ons
-- on top of base_price, so "everything at minimum" actually priced out at
-- 17843 + 2286 + 1929 = 22058px — not the advertised "FROM 17843 px".
--
-- Fix: add a free "None (bring your own)" choice at the front of both
-- groups, matching Framework 13's pattern. Every other choice's price is
-- untouched (still the correct absolute delta from base_price). Now leaving
-- both groups on their default (index 0) genuinely prices at base_price.
--
-- Safe to run once. Re-running is a no-op (same config_options each time).
-- Run this in the Supabase SQL editor.

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
      { "label": "None (bring your own)", "price": 0 },
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
      { "label": "None (bring your own)", "price": 0 },
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
}'::jsonb
WHERE name = 'Framework 16 DIY' AND created_by = 'landing-sync';
