import { Router } from "express";
import { verifySessionToken } from "../auth/session.js";
import { supabase } from "../db/client.js";

const router = Router();

// Quest log: every active sidequest, flagged with whether this player has
// unlocked it (NPCs grant unlocks; that wiring lands later).
router.get("/api/sidequests", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const [{ data: quests, error }, { data: unlocks }] = await Promise.all([
    supabase
      .from("sidequests")
      .select("id, name, region, npc, description, reward")
      .eq("active", true)
      .order("position", { ascending: true })
      .order("id", { ascending: true }),
    supabase
      .from("sidequest_unlocks")
      .select("sidequest_id")
      .eq("user_id", session.userId),
  ]);
  if (error) return res.json({ ok: true, quests: [] });
  const unlocked = new Set((unlocks ?? []).map((u) => u.sidequest_id as number));
  res.json({
    ok: true,
    quests: (quests ?? []).map((q) => ({ ...q, unlocked: unlocked.has(q.id as number) })),
  });
});

// Pixo's first-Trial recommendation. Picks one active *starter* Trial whose
// difficulty best matches the player's coding experience — but always returns
// the full starter list too, so the Trial Board can offer "browse all" and
// never forces the pick. Requires drizzle/0050 (difficulty/starter columns).
const EXPERIENCE_DIFFICULTY: Record<string, number> = {
  beginner: 1,
  intermediate: 2,
  advanced: 3,
};

router.get("/api/sidequests/recommended", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const [{ data: user }, { data: starters, error }] = await Promise.all([
    supabase
      .from("users")
      .select("coding_experience")
      .eq("id", session.userId)
      .maybeSingle(),
    supabase
      .from("sidequests")
      .select("id, name, region, npc, description, reward, difficulty, tags")
      .eq("active", true)
      .eq("starter", true)
      .order("position", { ascending: true })
      .order("id", { ascending: true }),
  ]);
  if (error) return res.json({ ok: true, recommended: null, alternatives: [] });

  const list = starters ?? [];
  const want = EXPERIENCE_DIFFICULTY[String(user?.coding_experience ?? "")] ?? 1;
  // Nearest difficulty to `want`; ties already broken by the position/id order
  // above, so a stable reduce keeps the first (lowest-position) match.
  const recommended =
    list.length === 0
      ? null
      : list.reduce((best, q) => {
          const d = (x: { difficulty?: number | null }) =>
            Math.abs((Number(x.difficulty) || 2) - want);
          return d(q) < d(best) ? q : best;
        }, list[0]);

  res.json({ ok: true, recommended, alternatives: list });
});

export default router;
