import { Router } from "express";
import { verifySessionToken } from "../auth/session.js";
import { supabase } from "../db/client.js";
import { activeEvents } from "../events.js";
import { approvedHoursFor } from "../xp.js";
import { addNotification } from "./notifications.js";

const router = Router();

const SHOP_REGIONS = ["US", "ASIA", "NORTH_AMERICA", "SOUTH_AMERICA", "EUROPE"];

async function regionFor(userId: string): Promise<string> {
  const { data } = await supabase.from("users").select("region").eq("id", userId).maybeSingle();
  const region = (data as { region?: string } | null)?.region;
  return region && SHOP_REGIONS.includes(region) ? region : "US";
}

// Base columns plus unlock_xp (trophies) and region. unlock_xp/config_options
// arrived with migration 0032/0058, region with 0063 — fall back gracefully
// before each is applied so the catalog keeps loading.
const ITEM_COLUMNS =
  "id, name, description, price, image_url, options, unlock_xp, config_options, region";
const ITEM_COLUMNS_FALLBACK = "id, name, description, price, image_url, options";

// Items are scoped to the player's own region (fulfillment/shipping differ a
// lot by where they live) — pass `region` to filter, or omit it to get every
// region (not currently used, but keeps this function generally useful).
async function fetchItems(filterIds?: number[], region?: string) {
  const build = (cols: string, withRegion: boolean) => {
    let q = supabase.from("shop_items").select(cols);
    if (filterIds) q = q.in("id", filterIds);
    else q = q.eq("active", true);
    if (withRegion && region) q = q.eq("region", region);
    return q.order("position", { ascending: true }).order("id", { ascending: true });
  };
  const first = await build(ITEM_COLUMNS, true);
  if (first.error) {
    const second = await build(ITEM_COLUMNS_FALLBACK, false);
    return {
      error: second.error,
      data: ((second.data ?? []) as unknown as Record<string, unknown>[]).map((i) => ({
        ...i,
        unlock_xp: 0,
        config_options: null,
        region: "US",
      })),
    };
  }
  return { error: null, data: (first.data ?? []) as unknown as Record<string, unknown>[] };
}

// Active catalog, plus mystery-merchant items while their event runs — those
// stay inactive in the dashboard so they vanish the moment the event ends.
// Trophy items (unlock_xp > 0) come back flagged with the player's own progress.
router.get("/api/shop/items", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const region = await regionFor(session.userId);
  const { data, error } = await fetchItems(undefined, region);
  if (error) {
    console.error("[shop] items failed", error);
    return res.status(500).json({ ok: false });
  }
  const items: Record<string, unknown>[] = data.map((i) => ({ ...i, limited: false }));

  const merchants = await activeEvents(["mystery_merchant"]);
  const limitedIds = [
    ...new Set(
      merchants.flatMap((ev) =>
        Array.isArray(ev.config.itemIds) ? ev.config.itemIds.map(Number) : [],
      ),
    ),
  ].filter((id) => Number.isFinite(id) && !items.some((i) => i.id === id));
  if (limitedIds.length > 0) {
    const { data: limited } = await fetchItems(limitedIds, region);
    const endsAt = merchants.map((m) => m.ends_at).sort()[0];
    for (const i of limited ?? []) items.unshift({ ...i, limited: true, limited_until: endsAt });
  }

  // The player's own trophy progress: current XP and which trophies they've claimed.
  const hasTrophies = items.some((i) => Number(i.unlock_xp) > 0);
  let xp = 0;
  let claimed: number[] = [];
  if (hasTrophies) {
    const [hours, { data: claims }] = await Promise.all([
      approvedHoursFor(session.userId),
      supabase.from("shop_claims").select("item_id").eq("user_id", session.userId),
    ]);
    xp = hours;
    claimed = ((claims ?? []) as { item_id: number }[]).map((c) => c.item_id);
  }

  res.json({ ok: true, items, xp, claimed, region });
});

// Switch which regional catalog the player shops from.
router.post("/api/shop/region", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const region = typeof req.body?.region === "string" ? req.body.region : "";
  if (!SHOP_REGIONS.includes(region))
    return res.status(400).json({ ok: false, error: "invalid_region" });

  const { error } = await supabase.from("users").update({ region }).eq("id", session.userId);
  if (error) {
    console.error("[shop] region update failed", error);
    return res.status(500).json({ ok: false });
  }
  res.json({ ok: true, region });
});

// Claim a trophy the player has earned. Server-authoritative: it re-checks the
// XP requirement, so a client can't claim early. Idempotent via the unique
// (user_id, item_id) constraint.
router.post("/api/shop/claim/:id", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ ok: false });

  const { data: item } = await supabase
    .from("shop_items")
    .select("id, name, unlock_xp, active")
    .eq("id", id)
    .maybeSingle();
  const unlockXp = Number((item as { unlock_xp?: number } | null)?.unlock_xp ?? 0);
  if (!item || !item.active || unlockXp <= 0)
    return res.status(404).json({ ok: false, error: "not_a_trophy" });

  const xp = await approvedHoursFor(session.userId);
  if (xp < unlockXp)
    return res.status(400).json({ ok: false, error: "not_eligible", xp, need: unlockXp });

  const { error } = await supabase
    .from("shop_claims")
    .upsert(
      { user_id: session.userId, item_id: id },
      { onConflict: "user_id,item_id", ignoreDuplicates: true },
    );
  if (error) {
    console.error("[shop] claim failed", error);
    return res.status(500).json({ ok: false });
  }
  void addNotification(
    session.userId,
    "Trophy claimed! 🏆",
    `You claimed "${item.name}". The team will reach out about getting it to you.`,
  );
  res.json({ ok: true, claimed: true });
});

// The player's own orders, newest first, for the Orders tab in the dash. Reads
// the fulfillment-pipeline columns (status/tracking/stage stamps) but falls back
// to the base columns so it keeps working before migration 0052 is applied.
const ORDER_COLUMNS =
  "id, item_name, option, price, quantity, status, note, created_at, ordered_at, credited_at, shipped_at, done_at, tracking";
const ORDER_COLUMNS_FALLBACK =
  "id, item_name, option, price, status, note, created_at, fulfilled_at";

router.get("/api/shop/orders", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const build = (cols: string) =>
    supabase
      .from("shop_orders")
      .select(cols)
      .eq("user_id", session.userId)
      .order("created_at", { ascending: false })
      .limit(100);

  let { data, error } = await build(ORDER_COLUMNS);
  if (error) ({ data, error } = await build(ORDER_COLUMNS_FALLBACK));
  if (error) {
    console.error("[shop] orders failed", error);
    return res.status(500).json({ ok: false });
  }
  res.json({ ok: true, orders: data ?? [] });
});

// Buy a priced item with pixels. All the real checks (item on sale, affordable,
// pixels deducted) happen inside buy_shop_item under a row lock, so a
// double-click can't overspend. On success we open a pending order the team
// fulfils from the dashboard and tell the player to expect us.
router.post("/api/shop/buy/:id", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ ok: false });
  const option = typeof req.body?.option === "string" ? req.body.option.slice(0, 80) : "";
  // Structured picks for items with a real price-varying configurator
  // (config_options). Ignored by buy_shop_item for every other item.
  const config =
    req.body?.config && typeof req.body.config === "object" ? req.body.config : null;
  // How many of this item to buy in one order. Clamped again server-side
  // inside buy_shop_item — this is just so a garbage value doesn't even reach it.
  const rawQty = Number(req.body?.quantity);
  const quantity = Number.isFinite(rawQty) ? Math.max(1, Math.min(999, Math.round(rawQty))) : 1;

  const { data, error } = await supabase.rpc("buy_shop_item", {
    p_user_id: session.userId,
    p_item_id: id,
    p_option: option,
    p_config: config,
    p_quantity: quantity,
  });
  if (error) {
    console.error("[shop] buy failed", error);
    return res.status(500).json({ ok: false });
  }
  const result = (data ?? {}) as {
    ok?: boolean;
    error?: string;
    balance?: number;
    price?: number;
    item_name?: string;
    quantity?: number;
  };
  if (!result.ok) {
    return res.status(result.error === "insufficient" ? 400 : 409).json(result);
  }

  const qtyPrefix = (result.quantity ?? 1) > 1 ? `${result.quantity}x ` : "";
  void addNotification(
    session.userId,
    "Order placed! 🛍️",
    `You bought ${qtyPrefix}"${result.item_name}"${option ? ` (${option})` : ""}. The team will reach out about getting it to you.`,
  );
  res.json({ ok: true, balance: result.balance });
});

export default router;
