import { Router } from "express";
import { issueSessionToken, verifySessionToken } from "../auth/session.js";
import { containsBlocked, logViolation } from "../moderation.js";
import { supabase } from "../db/client.js";
import { approvedHoursFor, levelFor, pxPerHourFor } from "../xp.js";
import { decryptPII, encryptPII } from "../crypto.js";

const router = Router();

// Returns a human-readable rejection reason, or null when the name is fine.
export function nameProblem(raw: string): string | null {
  const name = raw.trim();
  if (name.length < 2) return "That name is too short — use at least 2 characters.";
  if (name.length > 24) return "That name is too long — keep it under 24 characters.";
  if (!/^[\p{L}\p{N} ._'-]+$/u.test(name))
    return "Only letters, numbers, spaces and . _ ' - are allowed.";
  if (containsBlocked(name))
    return "That name isn't okay here. Pick something friendly — this is a warning.";
  return null;
}

router.post("/api/profile/name", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false, reason: "Not signed in." });

  const raw = typeof req.body?.name === "string" ? req.body.name : "";
  const name = raw.trim().replace(/\s+/g, " ");
  const problem = nameProblem(name);
  if (problem) {
    if (containsBlocked(name)) logViolation(session.userId, "name", name);
    return res.json({ ok: false, reason: problem });
  }

  const { error } = await supabase
    .from("users")
    .update({ display_name: name })
    .eq("id", session.userId);
  if (error) {
    console.error("Failed to update display_name", error);
    return res.status(500).json({ ok: false, reason: "Database error." });
  }

  // Re-issue the session token so the embedded displayName matches the new one.
  const fresh = issueSessionToken({ userId: session.userId, displayName: name });
  res.json({ ok: true, name, token: fresh });
});

// Read-only wallet: current pixel balance and lifetime approved hours. Pixels
// are only ever changed server-side (by the dashboard on final approval), so
// the game just displays whatever this returns.
router.get("/api/profile/wallet", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const [{ data: user }, approvedHours] = await Promise.all([
    supabase.from("users").select("pixels").eq("id", session.userId).single(),
    approvedHoursFor(session.userId),
  ]);
  const pixels = Math.round(Number(user?.pixels) || 0);
  res.json({
    ok: true,
    pixels,
    approvedHours,
    level: levelFor(approvedHours),
    pxPerHour: pxPerHourFor(approvedHours),
  });
});

// Coding-experience answer Pixo asks for during arrival. Drives the starter-
// Trial recommendation (sidequests.ts) and how much the web first-project
// walkthrough explains. null = never asked. See drizzle/0050.
const EXPERIENCE_VALUES = ["beginner", "intermediate", "advanced"] as const;
type Experience = (typeof EXPERIENCE_VALUES)[number];

router.get("/api/profile/experience", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const { data, error } = await supabase
    .from("users")
    .select("coding_experience")
    .eq("id", session.userId)
    .maybeSingle();
  // Before 0050 the column doesn't exist — treat as "not asked yet".
  const raw = error ? null : (data?.coding_experience ?? null);
  const experience = EXPERIENCE_VALUES.includes(raw as Experience)
    ? (raw as Experience)
    : null;
  res.json({ ok: true, experience });
});

router.post("/api/profile/experience", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const value = typeof req.body?.experience === "string" ? req.body.experience : "";
  if (!EXPERIENCE_VALUES.includes(value as Experience))
    return res.status(400).json({ ok: false, error: "bad_experience" });

  const { error } = await supabase
    .from("users")
    .update({ coding_experience: value })
    .eq("id", session.userId);
  if (error) {
    console.error("[profile] experience update failed", error.message);
    return res.status(500).json({ ok: false });
  }
  res.json({ ok: true, experience: value });
});

// The player's own pixel ledger, newest first, with project names attached.
router.get("/api/profile/transactions", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const { data, error } = await supabase
    .from("pixel_transactions")
    .select("id, project_id, amount, hours, reason, created_at")
    .eq("user_id", session.userId)
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) {
    console.error("[profile] transactions failed", error);
    return res.status(500).json({ ok: false });
  }
  const rows = data ?? [];
  const projectIds = [
    ...new Set(rows.map((t) => t.project_id).filter((x): x is number => x != null)),
  ];
  const names = new Map<number, string>();
  if (projectIds.length > 0) {
    const { data: projects } = await supabase
      .from("projects")
      .select("id, name")
      .in("id", projectIds);
    for (const p of projects ?? []) names.set(p.id as number, p.name as string);
  }
  res.json({
    ok: true,
    transactions: rows.map((t) => ({
      id: t.id,
      amount: Math.round(Number(t.amount) || 0),
      reason: t.reason,
      project: t.project_id != null ? (names.get(t.project_id as number) ?? "") : "",
      created_at: t.created_at,
    })),
  });
});

// Player-card photo settings. The photo itself goes through /api/uploads
// (or comes from Slack at sign-up); these just point the card at it.
router.get("/api/profile/card", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  let { data: user, error } = await supabase
    .from("users")
    .select("avatar_url, card_pixelate")
    .eq("id", session.userId)
    .maybeSingle();
  if (error)
    ({ data: user } = (await supabase
      .from("users")
      .select("avatar_url")
      .eq("id", session.userId)
      .maybeSingle()) as { data: typeof user });
  res.json({
    ok: true,
    avatar_url: user?.avatar_url ?? "",
    pixelate: user?.card_pixelate ?? true,
  });
});

router.post("/api/profile/card-image", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const url = typeof req.body?.url === "string" ? req.body.url.trim() : "";
  if (!url.startsWith("https://") || url.length > 500)
    return res.status(400).json({ ok: false, error: "bad_url" });
  const { error } = await supabase
    .from("users")
    .update({ avatar_url: url })
    .eq("id", session.userId);
  if (error) {
    console.error("[profile] card image update failed", error.message);
    return res.status(500).json({ ok: false });
  }
  res.json({ ok: true });
});

// Cross-app onboarding progress — a single forward-only counter shared by the
// in-game first-run guide (apps/game/scripts/guide_hud.gd) and the web dashboard
// tour (apps/game/web/pixl.js) so they hand off to each other rather than
// running as two separate walkthroughs. 0 = new, 1 = game intro done (dashboard
// tour pending), 2 = fully onboarded.
const ONBOARDING_DONE = 2;

// Rollout gate: while the redesigned arrival flow is being tested, only these
// Slack IDs get it. Everyone else reads as fully onboarded so neither the game
// nor the dashboard runs it. Empty set = allow everyone. Both apps gate on this
// one endpoint, so this keeps the game and the dashboard in sync automatically.
const ONBOARDING_ALLOWLIST = new Set<string>(["U0ARC79GEAV"]);

router.get("/api/profile/onboarding", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const { data, error } = await supabase
    .from("users")
    .select("onboarding_step, slack_id")
    .eq("id", session.userId)
    .maybeSingle();

  // Not on the allowlist → report fully onboarded so onboarding never triggers.
  if (
    ONBOARDING_ALLOWLIST.size > 0 &&
    !ONBOARDING_ALLOWLIST.has(String(data?.slack_id ?? ""))
  ) {
    return res.json({ ok: true, step: ONBOARDING_DONE, done: true });
  }

  // Before the 0046 migration is applied the column doesn't exist — treat that
  // as "brand new" rather than failing the request.
  const step = error ? 0 : Math.max(0, Number(data?.onboarding_step) || 0);
  res.json({ ok: true, step, done: step >= ONBOARDING_DONE });
});

router.post("/api/profile/onboarding", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const raw = Number(req.body?.step);
  if (!Number.isFinite(raw)) return res.status(400).json({ ok: false, error: "bad_step" });
  const want = Math.max(0, Math.min(ONBOARDING_DONE, Math.round(raw)));

  // Forward-only: a stale client (older tab, a replay) must never rewind a
  // player who's already further along.
  const { data: cur } = await supabase
    .from("users")
    .select("onboarding_step")
    .eq("id", session.userId)
    .maybeSingle();
  const step = Math.max(Math.max(0, Number(cur?.onboarding_step) || 0), want);

  const { error } = await supabase
    .from("users")
    .update({ onboarding_step: step })
    .eq("id", session.userId);
  if (error) {
    console.error("[profile] onboarding update failed", error.message);
    return res.status(500).json({ ok: false });
  }
  res.json({ ok: true, step, done: step >= ONBOARDING_DONE });
});

router.post("/api/profile/card-pixelate", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const pixelate = req.body?.pixelate === true;
  const { error } = await supabase
    .from("users")
    .update({ card_pixelate: pixelate })
    .eq("id", session.userId);
  if (error) {
    console.error("[profile] card pixelate update failed", error.message);
    return res.status(500).json({ ok: false });
  }
  res.json({ ok: true });
});

// Birthday + mailing address, collected once for Hack Club's YSWS Unified
// Database submission requirements (not entered per-ship — see /account in
// apps/game/web and the address-confirm step before shop checkout).
const ADDRESS_FIELDS = [
  "address_line1",
  "address_line2",
  "address_city",
  "address_state",
  "address_country",
  "address_postal",
] as const;

function hasAddress(row: Record<string, unknown>): boolean {
  return (
    String(row.address_line1 ?? "").trim() !== "" &&
    String(row.address_city ?? "").trim() !== "" &&
    String(row.address_country ?? "").trim() !== "" &&
    String(row.address_postal ?? "").trim() !== ""
  );
}

router.get("/api/profile/eligibility", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const { data, error } = await supabase
    .from("users")
    .select(["birthday", ...ADDRESS_FIELDS].join(", "))
    .eq("id", session.userId)
    .maybeSingle();
  if (error) {
    console.error("[profile] eligibility fetch failed", error.message);
    return res.status(500).json({ ok: false });
  }
  const row = (data ?? {}) as Record<string, unknown>;
  const birthday = decryptPII(row.birthday as string | null);
  res.json({
    ok: true,
    birthday: birthday || null,
    addressLine1: decryptPII(row.address_line1 as string | null),
    addressLine2: decryptPII(row.address_line2 as string | null),
    addressCity: decryptPII(row.address_city as string | null),
    addressState: decryptPII(row.address_state as string | null),
    addressCountry: decryptPII(row.address_country as string | null),
    addressPostal: decryptPII(row.address_postal as string | null),
    hasAddress: hasAddress(row),
  });
});

router.post("/api/profile/eligibility", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  // encryptPII throws if PII_ENCRYPTION_KEY is missing/malformed — without
  // this, that throw was unhandled inside an async handler and just hung the
  // request instead of returning an error (looked like "save does nothing").
  try {
    const patch: Record<string, string | null> = {};

    if (req.body?.birthday !== undefined) {
      const raw = String(req.body.birthday ?? "").trim();
      if (raw) {
        const date = new Date(raw);
        const now = new Date();
        if (Number.isNaN(date.getTime()) || date > now || date.getFullYear() < 1900) {
          return res.json({ ok: false, reason: "That birthday doesn't look right." });
        }
        patch.birthday = encryptPII(raw.slice(0, 10));
      } else {
        patch.birthday = null;
      }
    }

    const wantsAddress = ADDRESS_FIELDS.some((f) => req.body?.[toCamel(f)] !== undefined);
    if (wantsAddress) {
      const line1 = String(req.body?.addressLine1 ?? "").trim().slice(0, 200);
      const line2 = String(req.body?.addressLine2 ?? "").trim().slice(0, 200);
      const city = String(req.body?.addressCity ?? "").trim().slice(0, 100);
      const state = String(req.body?.addressState ?? "").trim().slice(0, 100);
      const country = String(req.body?.addressCountry ?? "").trim().slice(0, 100);
      const postal = String(req.body?.addressPostal ?? "").trim().slice(0, 20);
      if (!line1 || !city || !country || !postal) {
        return res.json({
          ok: false,
          reason: "Address line 1, city, country and postal code are required.",
        });
      }
      patch.address_line1 = encryptPII(line1);
      patch.address_line2 = encryptPII(line2);
      patch.address_city = encryptPII(city);
      patch.address_state = encryptPII(state);
      patch.address_country = encryptPII(country);
      patch.address_postal = encryptPII(postal);
    }

    if (Object.keys(patch).length === 0) return res.json({ ok: true });

    const { error } = await supabase.from("users").update(patch).eq("id", session.userId);
    if (error) {
      console.error("[profile] eligibility update failed", error.message);
      return res.status(500).json({ ok: false, reason: "Database error." });
    }
    res.json({ ok: true });
  } catch (err) {
    console.error("[profile] eligibility update crashed", (err as Error).message);
    return res.status(500).json({ ok: false, reason: "Server error — try again in a moment." });
  }
});

function toCamel(snake: string): string {
  return snake.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
}

export default router;
