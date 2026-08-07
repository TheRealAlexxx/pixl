const ARCHIVE_URL = "https://ships.hackclub.com/api/v1/ysws_entries";
const CACHE_MS = 10 * 60_000;

export interface ArchiveEntry {
  ysws: string;
  hours: number;
  approvedAt: number | null;
}

export interface ArchiveShip extends ArchiveEntry {
  id: string;
  slackId: string;
  codeUrl: string;
  demoUrl: string;
  description: string;
  screenshotUrl: string;
}

export interface ArchiveMatch extends ArchiveEntry {
  url: string;
}

interface LoadedArchive {
  byUrl: Map<string, ArchiveEntry>;
  ships: ArchiveShip[];
}

let cache: { at: number; data: LoadedArchive } | null = null;

export function normalizeProjectUrl(raw: string): string {
  let s = String(raw ?? "").trim().toLowerCase();
  if (s === "" || s === "null" || s === "undefined") return "";
  s = s.replace(/^https?:\/\//, "").replace(/^www\./, "");
  s = s.replace(/\.git$/, "");
  s = s.replace(/\/+$/, "");
  return s;
}

function cleanField(raw: unknown): string {
  const s = String(raw ?? "").trim();
  return s === "" || s === "null" || s === "undefined" ? "" : s;
}

function safeUrl(raw: unknown): string {
  const s = cleanField(raw);
  if (s === "") return "";
  try {
    const proto = new URL(s).protocol;
    return proto === "http:" || proto === "https:" ? s : "";
  } catch {
    return "";
  }
}

function toEntry(entry: Record<string, unknown>): ArchiveEntry {
  return {
    ysws: String(entry.ysws ?? "another YSWS"),
    hours: Number(entry.hours) || 0,
    approvedAt: Number(entry.approved_at) > 0 ? Number(entry.approved_at) : null,
  };
}

async function loadArchive(): Promise<LoadedArchive | null> {
  if (cache && Date.now() - cache.at < CACHE_MS) return cache.data;
  try {
    const r = await fetch(ARCHIVE_URL, { signal: AbortSignal.timeout(15000) });
    if (!r.ok) throw new Error(`status ${r.status}`);
    const json = (await r.json()) as any;
    const raw: unknown[] = Array.isArray(json)
      ? json
      : Array.isArray(json?.entries)
        ? json.entries
        : Array.isArray(json?.data)
          ? json.data
          : [];

    const byUrl = new Map<string, ArchiveEntry>();
    const ships: ArchiveShip[] = [];
    for (const rawEntry of raw) {
      const entry = rawEntry as Record<string, unknown>;
      const info = toEntry(entry);
      for (const key of ["code_url", "demo_url"]) {
        const u = normalizeProjectUrl(String(entry[key] ?? ""));
        if (u !== "" && !byUrl.has(u)) byUrl.set(u, info);
      }
      const id = cleanField(entry.id);
      const slackId = cleanField(entry.slack_id);
      if (id === "" || slackId === "") continue;
      ships.push({
        ...info,
        id,
        slackId,
        codeUrl: safeUrl(entry.code_url),
        demoUrl: safeUrl(entry.demo_url),
        description: cleanField(entry.description).slice(0, 2000),
        screenshotUrl: safeUrl(entry.screenshot_url),
      });
    }
    cache = { at: Date.now(), data: { byUrl, ships } };
    return cache.data;
  } catch (e) {
    console.error("[ysws-archive] fetch failed", e);
    return cache ? cache.data : null;
  }
}

export async function findInYswsArchive(
  repoUrl: string,
  demoUrl: string,
): Promise<ArchiveMatch | null> {
  const loaded = await loadArchive();
  if (!loaded) return null;
  const { byUrl } = loaded;
  const repo = normalizeProjectUrl(repoUrl);
  if (repo !== "" && byUrl.has(repo)) return { url: repoUrl, ...byUrl.get(repo)! };
  const demo = normalizeProjectUrl(demoUrl);
  if (demo !== "" && byUrl.has(demo)) return { url: demoUrl, ...byUrl.get(demo)! };
  return null;
}

export async function yswsShipsForSlackId(slackId: string): Promise<ArchiveShip[]> {
  const id = cleanField(slackId);
  if (id === "") return [];
  const loaded = await loadArchive();
  if (!loaded) return [];
  return loaded.ships
    .filter((s) => s.slackId === id)
    .sort((a, b) => (b.approvedAt ?? 0) - (a.approvedAt ?? 0));
}

export async function yswsShipForSlackId(
  slackId: string,
  entryId: string,
): Promise<ArchiveShip | null> {
  const ships = await yswsShipsForSlackId(slackId);
  return ships.find((s) => s.id === entryId) ?? null;
}