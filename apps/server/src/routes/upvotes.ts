import { Router } from "express";
import { verifySessionToken } from "../auth/session.js";
import { supabase } from "../db/client.js";

const router = Router();

// A user's upvote balance = (upvotes received across their projects) - (upvotes
// already spent on collectibles). Kept as a derived value so upvotes stay a
// simple permanent ledger rather than a mutable counter.
async function upvoteBalance(userId: string): Promise<number> {
  const { data: mine } = await supabase
    .from("projects")
    .select("id")
    .eq("user_id", userId);
  const ids = (mine ?? []).map((p) => p.id as number);
  let received = 0;
  if (ids.length > 0) {
    const { count } = await supabase
      .from("project_upvotes")
      .select("id", { count: "exact", head: true })
      .in("project_id", ids);
    received = count ?? 0;
  }
  const { data: spends } = await supabase
    .from("collectible_purchases")
    .select("cost")
    .eq("user_id", userId);
  const spent = (spends ?? []).reduce((s, r) => s + Number(r.cost), 0);
  return Math.max(0, received - spent);
}

// Permanent upvote on an approved project. One per voter, never taken back, and
// you can't upvote your own work. Idempotent — re-hitting it is a no-op.
router.post("/api/projects/:id/upvote", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ ok: false, error: "bad_id" });

  const { data: project } = await supabase
    .from("projects")
    .select("id, user_id, status")
    .eq("id", id)
    .is("archived_at", null)
    .is("banned_at", null)
    .maybeSingle();
  if (!project || project.status !== "approved")
    return res.status(404).json({ ok: false, error: "not_found" });
  if (project.user_id === session.userId)
    return res.status(400).json({ ok: false, error: "own_project" });

  const { data: existingDownvote } = await supabase
    .from("project_downvotes")
    .select("id")
    .eq("project_id", id)
    .eq("voter_id", session.userId)
    .maybeSingle();
  if (existingDownvote) return res.status(400).json({ ok: false, error: "already_downvoted" });

  // Permanent + unique(project_id, voter_id): ignore a duplicate rather than 500.
  const { error } = await supabase
    .from("project_upvotes")
    .insert({ project_id: id, voter_id: session.userId });
  if (error && !String(error.code).startsWith("23")) {
    console.error("[upvotes] insert failed", error);
    return res.status(500).json({ ok: false });
  }

  const { count } = await supabase
    .from("project_upvotes")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id);
  res.json({ ok: true, upvotes: count ?? 0, has_upvoted: true });
});

// Permanent downvote on an approved project. Same rules as upvote (one per
// voter, never taken back, can't vote your own project), plus: a voter can't
// downvote a project they've already upvoted, or upvote one they've already
// downvoted — only one direction per voter per project. Doesn't touch the
// upvote currency/balance; it's a signal, not a spend.
router.post("/api/projects/:id/downvote", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ ok: false, error: "bad_id" });

  const { data: project } = await supabase
    .from("projects")
    .select("id, user_id, status")
    .eq("id", id)
    .is("archived_at", null)
    .is("banned_at", null)
    .maybeSingle();
  if (!project || project.status !== "approved")
    return res.status(404).json({ ok: false, error: "not_found" });
  if (project.user_id === session.userId)
    return res.status(400).json({ ok: false, error: "own_project" });

  const { data: existingUpvote } = await supabase
    .from("project_upvotes")
    .select("id")
    .eq("project_id", id)
    .eq("voter_id", session.userId)
    .maybeSingle();
  if (existingUpvote) return res.status(400).json({ ok: false, error: "already_upvoted" });

  // Permanent + unique(project_id, voter_id): ignore a duplicate rather than 500.
  const { error } = await supabase
    .from("project_downvotes")
    .insert({ project_id: id, voter_id: session.userId });
  if (error && !String(error.code).startsWith("23")) {
    console.error("[downvotes] insert failed", error);
    return res.status(500).json({ ok: false });
  }

  const { count } = await supabase
    .from("project_downvotes")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id);
  res.json({ ok: true, downvotes: count ?? 0, has_downvoted: true });
});

// The signed-in player's spendable upvote balance ("upvote account").
router.get("/api/upvotes/balance", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });
  res.json({ ok: true, balance: await upvoteBalance(session.userId) });
});

// Collectibles catalog + what the player already owns + their balance.
router.get("/api/collectibles", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const [{ data: items }, { data: owned }, balance] = await Promise.all([
    supabase
      .from("collectibles")
      .select("id, name, description, image_url, cost")
      .eq("active", true)
      .order("position", { ascending: true })
      .order("id", { ascending: true }),
    supabase
      .from("collectible_purchases")
      .select("collectible_id")
      .eq("user_id", session.userId),
    upvoteBalance(session.userId),
  ]);
  const ownedSet = new Set((owned ?? []).map((r) => r.collectible_id as number));
  res.json({
    ok: true,
    balance,
    collectibles: (items ?? []).map((c) => ({ ...c, owned: ownedSet.has(c.id as number) })),
  });
});

// Buy a collectible with upvotes. Guards: exists/active, not already owned,
// enough balance. The unique(user_id, collectible_id) constraint is the final
// backstop against a double-spend race.
router.post("/api/collectibles/:id/buy", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ ok: false, error: "bad_id" });

  const { data: item } = await supabase
    .from("collectibles")
    .select("id, cost, active")
    .eq("id", id)
    .maybeSingle();
  if (!item || !item.active) return res.status(404).json({ ok: false, error: "not_found" });

  const { data: already } = await supabase
    .from("collectible_purchases")
    .select("id")
    .eq("user_id", session.userId)
    .eq("collectible_id", id)
    .maybeSingle();
  if (already) return res.status(400).json({ ok: false, error: "already_owned" });

  const balance = await upvoteBalance(session.userId);
  const cost = Number(item.cost);
  if (balance < cost)
    return res.status(400).json({ ok: false, error: "insufficient_upvotes", balance, cost });

  const { error } = await supabase
    .from("collectible_purchases")
    .insert({ user_id: session.userId, collectible_id: id, cost });
  if (error) {
    if (String(error.code).startsWith("23"))
      return res.status(400).json({ ok: false, error: "already_owned" });
    console.error("[collectibles] buy failed", error);
    return res.status(500).json({ ok: false });
  }
  res.json({ ok: true, balance: balance - cost });
});

export default router;
