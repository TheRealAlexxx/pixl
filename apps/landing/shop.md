# PIXL Shop — Inventory

Conversion rate: **1 h of work = $3.5 = 50 pixels**. Shop price (px) = hours × 50.

Dollar values and fulfillment notes are internal reference only — the website shows pixel prices only, no dollar estimates.

The website list lives in `app/_components/Shop.tsx` (`generalItems`, rendered as a marquee carousel like the Sidequests section). This file is the recap: if you change an item, update **both places** (see note at the bottom).

## General Shop (buyable with pixels, sorted by price)

The "ID" column is a mnemonic label for humans only — `Shop.tsx` items are plain `{ name, description }` objects with no `id` field, matched to price/image purely by array position (see "Where to edit items" below).

| ID | Name | Hours | Price (px) | Internal cost / fulfillment notes | Image |
|---|---|---|---|---|---|
| `signed-photo` | Signed Org Photo | 2 h | 100 | ~$3 shipping + ~$1 photo; envelope near-free if we buy ~20 per member at once | `/shop/signed-photo.svg` (placeholder) |
| `assets-grant` | Game Assets Grant | 3 h | 150 | **$10** HCB grant, stackable. Fraudable like every grant but it's about pixels so ok | `/shop/assets-grant.png` |
| `hc-stickers` | Hack Club Sticker Pack | 3 h | 150 | Cheap if HQ stock; new custom stickers = big order (up to $500). Envelope ~$3 worldwide, ~$10 per pack total | `/shop/hc-stickers.png` |
| `api-credits` | AI Credits | 3 h | 150 | **$10** HCB grant, no shipping. Fraudable like every grant | `/shop/api.png` |
| `music-grant` | Music Grant | 3 h | 150 | **$10** stackable grant, instruments/plugins/samples/any music gear. Fraudable like every grant | `/shop/music-grant.png` (generated pixel-art icon: boombox) |
| `mystery-object` | Random Desk Object | 4 h | 200 | Object is free (random PCB, stickers — Gabin has a lot). Signed letter included ;) Shipping max ~$10. **Only a few in stock** | `/shop/mystery-box.svg` (placeholder) |
| `art-grant` | Art Supply Grant | 4 h | 200 | **$10** stackable grant, paints/pens/canvases/any art supplies. Fraudable like every grant | `/shop/art-grant.png` (generated pixel-art icon: palette + brush) |
| `pixel-composer` | Pixel Composer License | 5 h | 250 | $15, no shipping, easy to send as gift | `/shop/pixel-composer.png` |
| `pico8` | PICO-8 License | 5 h | 250 | $15, gift code, no fraud, in theme asf | `/shop/pico8.png` |
| `pixl-poster` | PIXL Poster | 6 h | 300 | **$20** print grant (general poster or print grant at a local shop). Design by Ricky or community bounty? **//not sure** | `/shop/poster.png` |
| `aseprite` | Aseprite License | 7 h | 350 | $22, no shipping, easy gift. High hacker value | `/shop/aseprite.png` |
| `tamagotchi-kit` | Pixl Tamagotchi DIY Kit | 8 h | 400 | Parts ~$30 (PCB + screen + components via JLC, cheaper in batch on LCSC/JLCPCB) + reshipping ~$10 ≈ $40. Huge in-house hacker value. **Waiting on mangoman for exact price/hours** | `/shop/tamagotchi.png` |
| `indie-game` | Indie Game of Your Choice | 8 h | 400 | Selection from the jame gam prize pool ($15–30 games), pay as if $25. Steam gift / Humble Bundle link, no shipping, no fraud | `/shop/indie-game.png` |
| `esp32-kit` | ESP32 Starter Kit | 10 h | 500 | ~$20 AliExpress / ~$30 Amazon US-EU, avg ~$25 + ~$8 shipping ≈ $33 | `/shop/esp32.png` |
| `furycube` | FURYCUBE 68% | 10 h | 500 | $35 Amazon US, cheap hot-swap keyboard | `/shop/furycube.png` (pending) |
| `godot-plush` | Godot Plush (Limited Edition) | 13 h | 650 | ~$30 + ~$10–15 small packet shipping ≈ $45 on Makeship, no reship needed | `/shop/godot-plush.png` |
| `pixl-hoodie` | PIXL Hoodie | 14 h | 700 | Print-on-demand (Printful type): they handle worldwide shipping and sizes, ~$35–45 shipped, global avg ~$50 | `/shop/hoodie.png` |
| `blahaj-plush` | Blahaj Plush | 14 h | 700 | $30 plush + $10 shipping = $40. HQ needs orders of at least 2 at a time, then reship. **This is the plush toy — distinct from the 3D-printed Blahaj, which is the trophy, not a shop item** | `/shop/blahaj.png` |
| `wacom-intuos` | Wacom Intuos (Small) | 15 h | 750 | ~$50–80, varies a lot by region (THE per-region problem item) + ~$10 shipping, global avg ~$50 | `/shop/wacom.png` |
| `retro-handheld` | Retro Handheld (Miyoo Mini+ / RG35XX) | 20 h | 1000 | ~$60–70 shipped from AliExpress, ships worldwide cheap (PK, IN, BR no problem) | `/shop/retro-handheld.png` |
| `keyboard-f75-pro` | Epomaker x Aula F75 Pro | 20 h | 1000 | $72 Amazon US. Hot-swap, has a little screen. Color chosen via order note. **Replaces both the old F75 and the TH80 V2 Pro (removed)** | `/shop/keyboard-f75-pro.png` (pending — new image replacing the old F75 photo) |
| `gamemaker` | GameMaker Pro | 29 h | 1450 | $99.99 one-time license, key, no shipping, no fraud | `/shop/gamemaker.png` |
| `monitor-grant` | Monitor Grant (Stackable) | 30 h | 1500 | **$100** stackable grant. Fraudable | `/shop/monitor-4k.png` |
| `raspberry-pi-5` | Raspberry Pi 5 | 40 h (4GB) / 63 h (8GB) | 2000 (4GB) / 3150 (8GB) | Board $130 (4GB) / $200 (8GB) + shipping ~$10–20. One card on the site, 8GB price mentioned in the description | `/shop/rpi.png` |
| `sony-ch720n` | Sony WH-CH720N | 43 h | 2150 | $150 Amazon US, cheap noise cancelling. **Not added to the shop before this batch** | `/shop/sony-ch720n.png` (pending) |
| `ender3-v3` | Creality Ender 3 V3 | 55 h | 2750 | $190 Amazon US, easily shippable, order in user's regional store | `/shop/ender3-v3.png` (pending) |
| `airpods-pro-3` | AirPods Pro 3 | 58 h | 2900 | $200 Amazon US, cool hacker value | `/shop/airpods-pro-3.png` (pending) |
| `a1-mini` | Bambu Lab A1 Mini | 67 h | 3350 | $235 Amazon US, sometimes $220 on Bambu Lab site. Order in user's regional store | `/shop/a1-mini.png` |
| `samsung-t7-ssd` | Samsung T7 External SSD (1TB) | 67 h | 3350 | $230 Amazon US, cool hacker value | `/shop/samsung-t7-ssd.png` (pending) |
| `sony-xm5` | Sony WH-1000XM5 | 72 h | 3600 | $250 Amazon US, easily shippable | `/shop/sony-headphones.png` |
| `sparkx-i7` | Creality Sparkx i7 | 75 h | 3750 | $260 Amazon US, easily shippable, order in user's regional store | `/shop/sparkx-i7.png` (pending) |
| `bambu-a1` | Bambu Lab A1 | 85 h | 4250 | $300 Amazon US, easily shippable, order in user's regional store | `/shop/bambu-a1.png` |
| `centauri-carbon` | Centauri Carbon | 100 h | 5000 | $360 Amazon US, easily shippable, order in user's regional store | `/shop/centauri-carbon.png` (pending) |
| `ipad` | iPad (11th gen) | 115 h | 5750 | $400 US but 509€ EU and more in expensive regions; priced on US $400 | `/shop/ipad.png` |
| `bambu-a1-combo` | Bambu Lab A1 Combo | 115 h | 5750 | $400 Amazon US (A1 + AMS Lite), easily shippable, order in user's regional store | `/shop/bambu-a1-combo.png` |
| `samsung-s24` | Samsung Galaxy S24 | 115 h | 5750 | $400 US, easily orderable, cool phone | `/shop/samsung-s24.png` (pending) |
| `airpods-max` | AirPods Max 2 | 129 h | 6450 | $450 Amazon US, easily shippable | `/shop/airpods-max.png` |
| `nothing-phone` | Nothing Phone (4a) Pro | 143 h | 7150 | $499.99 US, easily orderable, cool phone | `/shop/nothing-phone.png` (pending) |
| `macbook-neo` | MacBook Neo | 200 h (256GB) / 230 h (512GB) | 10000 (256GB) / 11500 (512GB) | Can't check Apple US pricing, ~$700 (256GB) / ~$800 (512GB) on Amazon. Easily shippable. One card on the site, 512GB price mentioned in the description, picked via order note | `/shop/macbook-neo.png` (pending) |
| `macbook-air-m5` | MacBook Air M5 | 343 h (16GB/512GB) / 485 h (24GB/1TB) | 17150 (16GB/512GB) / 24250 (24GB/1TB) | Can't check Apple US pricing, ~$1200 (16GB/512GB) / ~$1700 (24GB/1TB) on Amazon. Easily shippable. One card on the site, 24GB/1TB price mentioned in the description, picked via order note | `/shop/macbook-air.png` (pending) |
| `mac-mini` | Mac Mini (24GB/512GB) | 450 h | 22500 | $1570 Amazon US, easily shippable, order in user's regional store | `/shop/mac-mini.png` (pending) |

## Sidequest Rewards (not buyable — earned by completing sidequests)

Shown on the site in the Sidequests section (`Sidequests.tsx`, "min Xh of work" labels), not in the Shop carousel.

| ID | Name | Min hours | Internal cost | Image |
|---|---|---|---|---|
| `domain-stickers` | Domain + Sticker Pack | 7 h | Domain ~$15 as grant, stickers + envelope ~$10 ≈ $25 | `/shop/domain.png` |
| `apple-dev` | Apple Developer Account | 30 h | $99/year flat worldwide, redeemed with code/grant | `/shop/apple-dev.png` |
| `flipper-zero` | Flipper Zero | 55 h | $169 official + ~$15 shipping ≈ $185, ships to most countries | `/shop/flipper.png` |
| `graphics-tablet` | Graphics Tablet | 20 h | Small tablet ~$60–80 + ~$10 shipping ≈ $70 | `/shop/tablet.png` |
| `stickers-poster` | Sticker Pack + Poster | 8.5 h | Stickers ~$10 + poster print grant ~$20 ≈ $30 | `/shop/stickers.png` |
| `pcb-run` | Full PCB Manufacturing Run | — | They do a BOM, funded at the normal $3.5/h rate | `/shop/pcb.png` |
| `robux` | 2000 Robux | 7 h | ≈ $25 gift card, digital, no fraud possible | `/shop/robux.png` |

Below the Shop carousel, the site shows "...and even more coming!".

## Removed vs previous shop

- **Blahaj Plush** → new shop item (700 px / 14 h), a purchased plush toy. **Not the same as the 3D Printed Blahaj**, which is a separate object (the trophy, not in the shop)
- **Epomaker TH80 V2 Pro** → removed; **Epomaker x Aula F75** renamed to **Epomaker x Aula F75 Pro** (now has the little screen), consolidating what used to be two competing keyboard options into one
- **Nintendo Switch Online (1 year)** → dropped from the new list (image kept)
- **GitHub Pro (1 year)** → dropped from the new list (image kept)
- **Sony WH-1000XM4** → replaced by the XM5
- **27" 4K Monitor** → replaced by the stackable monitor grant
- **Arduino Starter Kit** → removed earlier (image `/shop/arduino.png` kept)

## Placeholder / pending images

- `signed-photo.svg`, `mystery-box.svg` are quick pixel-art SVG placeholders — swap them for real PNGs when available.
- `centauri-carbon.png`, `macbook-neo.png`, `macbook-air.png`, `airpods-pro-3.png`, `samsung-t7-ssd.png`, `samsung-s24.png`, `nothing-phone.png`, `furycube.png`, `keyboard-f75-pro.png`, `sony-ch720n.png`, `ender3-v3.png`, `sparkx-i7.png`, `mac-mini.png` are referenced in `Shop.tsx` but the files don't exist yet (Gabin is sourcing them) — the site will show a broken image for these until added to `public/shop/`.

## Where to edit items

The shop is now localized (en/fr/es/pt). Name and description live in each locale's dictionary; image and price are locale-independent and live in `Shop.tsx`.

1. **Text (name/description)**: `app/[lang]/dictionaries/{en,fr,es,pt}.json` → `shop.items`, a flat array. **Order matters** — item *i* in this array must line up with index *i* in `ITEM_IMAGES`/`ITEM_PRICES` below, so the same insertion position is needed in all 4 files.
2. **Image + price**: `app/_components/Shop.tsx` → `ITEM_IMAGES` and `ITEM_PRICES`, two parallel arrays indexed the same way as the dictionaries. `NICHE_INDICES` flags which indices get the red star badge (currently 0, 5, 11).
3. **This file**: `shop.md` — the tables above, for the human-readable recap with $ costs and fulfillment notes.

Nothing here is synced automatically: adding/reordering an item means touching all 4 dictionaries + both Shop.tsx arrays + this file, keeping every index aligned.
