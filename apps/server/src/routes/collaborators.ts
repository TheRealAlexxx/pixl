import { Router } from "express";
import { verifySessionToken } from "../auth/session.js";
import { supabase } from "../db/client.js";
import { addNotification } from "./notifications.js";

const router = Router();

interface CollaboratorRow {
  id: number;
  project_id: number;
  user_id: string;
  invited_by: string;
  status: string;
  hackatime_projects: string[];
  hackatime_seconds: number | null;
  approved_hours: number | null;
  created_at: string;
  responded_at: string | null;
}

async function projectOwner(projectId: number): Promise<{ id: number; name: string; user_id: string } | null> {
  const { data } = await supabase
    .from("projects")
    .select("id, name, user_id")
    .eq("id", projectId)
    .maybeSingle();
  return data as { id: number; name: string; user_id: string } | null;
}

// Owner invites another player onto their project. Re-invites a
// previously declined/removed collaborator instead of stacking a duplicate
// row, mirroring friends.ts's handling of a stale request row.
router.post("/api/projects/:id/collaborators/invite", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const projectId = Number(req.params.id);
  if (!Number.isFinite(projectId)) return res.status(400).json({ ok: false });

  const project = await projectOwner(projectId);
  if (!project || project.user_id !== session.userId)
    return res.status(404).json({ ok: false });

  const targetId = typeof req.body?.userId === "string" ? req.body.userId : "";
  if (!targetId || targetId === session.userId)
    return res.status(400).json({ ok: false, reason: "Invalid target." });

  const { data: target } = await supabase
    .from("users")
    .select("id, display_name")
    .eq("id", targetId)
    .single();
  if (!target) return res.status(404).json({ ok: false, reason: "No such player." });

  const { data: existing } = await supabase
    .from("project_collaborators")
    .select("id, status")
    .eq("project_id", projectId)
    .eq("user_id", targetId)
    .maybeSingle();

  if (existing) {
    if (existing.status === "accepted" || existing.status === "pending")
      return res.json({ ok: true, status: existing.status });
    const { error } = await supabase
      .from("project_collaborators")
      .update({ status: "pending", invited_by: session.userId, responded_at: null })
      .eq("id", existing.id);
    if (error) {
      console.error("[collaborators] re-invite failed", error);
      return res.status(500).json({ ok: false });
    }
  } else {
    const { error } = await supabase.from("project_collaborators").insert({
      project_id: projectId,
      user_id: targetId,
      invited_by: session.userId,
      status: "pending",
    });
    if (error) {
      console.error("[collaborators] invite insert failed", error);
      return res.status(500).json({ ok: false });
    }
  }

  void addNotification(
    targetId,
    "Project collaboration invite",
    `${session.displayName} invited you to collaborate on "${project.name}". Open Projects to accept.`,
  );
  res.json({ ok: true, status: "pending" });
});

// Visible to the owner and to anyone (pending or accepted) invited onto it.
router.get("/api/projects/:id/collaborators", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const projectId = Number(req.params.id);
  if (!Number.isFinite(projectId)) return res.status(400).json({ ok: false });

  const project = await projectOwner(projectId);
  if (!project) return res.status(404).json({ ok: false });

  const { data: rows, error } = await supabase
    .from("project_collaborators")
    .select("*")
    .eq("project_id", projectId)
    .neq("status", "removed")
    .order("created_at", { ascending: true });
  if (error) {
    console.error("[collaborators] list failed", error);
    return res.status(500).json({ ok: false });
  }
  const collaborators = (rows ?? []) as CollaboratorRow[];
  const isOwner = project.user_id === session.userId;
  const isMember = collaborators.some((c) => c.user_id === session.userId);
  if (!isOwner && !isMember) return res.status(404).json({ ok: false });

  const ids = collaborators.map((c) => c.user_id);
  const names = new Map<string, string>();
  if (ids.length > 0) {
    const { data: users } = await supabase
      .from("users")
      .select("id, display_name")
      .in("id", ids);
    for (const u of users ?? []) names.set(u.id as string, u.display_name as string);
  }

  res.json({
    ok: true,
    isOwner,
    collaborators: collaborators.map((c) => ({
      id: c.id,
      userId: c.user_id,
      name: names.get(c.user_id) ?? "Unknown",
      status: c.status,
      hackatimeProjects: c.hackatime_projects ?? [],
      hackatimeSeconds: c.hackatime_seconds ?? 0,
      isSelf: c.user_id === session.userId,
    })),
  });
});

// The caller's own incoming invites across every project, for a "pending
// invites" list on the Projects page.
router.get("/api/collaborations/pending", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const { data: rows, error } = await supabase
    .from("project_collaborators")
    .select("id, project_id, invited_by, created_at, projects(name)")
    .eq("user_id", session.userId)
    .eq("status", "pending")
    .order("created_at", { ascending: false });
  if (error) {
    console.error("[collaborators] pending list failed", error);
    return res.status(500).json({ ok: false });
  }
  const inviterIds = [...new Set((rows ?? []).map((r) => r.invited_by as string))];
  const names = new Map<string, string>();
  if (inviterIds.length > 0) {
    const { data: users } = await supabase
      .from("users")
      .select("id, display_name")
      .in("id", inviterIds);
    for (const u of users ?? []) names.set(u.id as string, u.display_name as string);
  }
  res.json({
    ok: true,
    invites: (rows ?? []).map((r) => ({
      id: r.id,
      projectId: r.project_id,
      projectName: (r as unknown as { projects?: { name?: string } }).projects?.name ?? "",
      invitedBy: names.get(r.invited_by as string) ?? "Someone",
      createdAt: r.created_at,
    })),
  });
});

router.post("/api/collaborators/:id/accept", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ ok: false });

  const { data, error } = await supabase
    .from("project_collaborators")
    .update({ status: "accepted", responded_at: new Date().toISOString() })
    .eq("id", id)
    .eq("user_id", session.userId)
    .eq("status", "pending")
    .select("project_id, invited_by")
    .maybeSingle();
  if (error) {
    console.error("[collaborators] accept failed", error);
    return res.status(500).json({ ok: false });
  }
  if (!data) return res.status(404).json({ ok: false, reason: "No pending invite." });

  const project = await projectOwner(data.project_id as number);
  if (project) {
    void addNotification(
      project.user_id,
      "Collaboration accepted",
      `${session.displayName} accepted your invite to collaborate on "${project.name}".`,
    );
  }
  res.json({ ok: true });
});

router.post("/api/collaborators/:id/decline", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ ok: false });

  const { data, error } = await supabase
    .from("project_collaborators")
    .update({ status: "declined", responded_at: new Date().toISOString() })
    .eq("id", id)
    .eq("user_id", session.userId)
    .eq("status", "pending")
    .select("id")
    .maybeSingle();
  if (error) {
    console.error("[collaborators] decline failed", error);
    return res.status(500).json({ ok: false });
  }
  if (!data) return res.status(404).json({ ok: false, reason: "No pending invite." });
  res.json({ ok: true });
});

// Owner removes an accepted collaborator, or a collaborator leaves on their
// own — either way the row is marked 'removed' (not deleted) to keep past
// payout history intact.
router.post("/api/collaborators/:id/remove", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ ok: false });

  const { data: row } = await supabase
    .from("project_collaborators")
    .select("id, project_id, user_id, status")
    .eq("id", id)
    .maybeSingle();
  if (!row) return res.status(404).json({ ok: false });

  const project = await projectOwner(row.project_id as number);
  const isOwner = !!project && project.user_id === session.userId;
  const isSelf = row.user_id === session.userId;
  if (!isOwner && !isSelf) return res.status(404).json({ ok: false });

  const { error } = await supabase
    .from("project_collaborators")
    .update({ status: "removed", responded_at: new Date().toISOString() })
    .eq("id", id);
  if (error) {
    console.error("[collaborators] remove failed", error);
    return res.status(500).json({ ok: false });
  }
  res.json({ ok: true });
});

// An accepted collaborator links their own Hackatime projects (their own
// account, tracked separately from the owner's — see parseProjectBody's
// hackatime_projects handling in projects.ts for the same shape).
router.put("/api/collaborators/:id/hackatime", async (req, res) => {
  const token = typeof req.query.token === "string" ? req.query.token : "";
  const session = token ? verifySessionToken(token) : null;
  if (!session) return res.status(401).json({ ok: false });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ ok: false });

  const hackatimeProjects = Array.isArray(req.body?.hackatimeProjects)
    ? req.body.hackatimeProjects.map((p: unknown) => String(p)).slice(0, 50)
    : [];

  const { data, error } = await supabase
    .from("project_collaborators")
    .update({ hackatime_projects: hackatimeProjects })
    .eq("id", id)
    .eq("user_id", session.userId)
    .eq("status", "accepted")
    .select("id")
    .maybeSingle();
  if (error) {
    console.error("[collaborators] hackatime link failed", error);
    return res.status(500).json({ ok: false });
  }
  if (!data) return res.status(404).json({ ok: false });
  res.json({ ok: true });
});

export default router;
