import type { ArchiveShip } from "./archive.js";
import { normalizeProjectUrl } from "./archive.js";

export function nameFromShip(codeUrl: string, demoUrl: string, ysws: string): string {
  for (const url of [codeUrl, demoUrl]) {
    if (!url) continue;
    try {
      const last = new URL(url).pathname.split("/").filter(Boolean).pop() ?? "";
      const cleaned = last.replace(/\.git$/, "").replace(/[-_]+/g, " ").trim();
      if (cleaned !== "") {
        return cleaned.replace(/\b\w/g, (c) => c.toUpperCase()).slice(0, 120);
      }
    } catch {
      continue;
    }
  }
  return `Project from ${ysws}`.slice(0, 120);
}

export interface TakenProjectUrls {
  ids: Set<string>;
  urls: Set<string>;
}

export function collectTaken(
  rows: {
    imported_ysws_entry_id?: string | null;
    repo_url?: string | null;
    demo_url?: string | null;
  }[],
): TakenProjectUrls {
  const ids = new Set<string>();
  const urls = new Set<string>();
  for (const p of rows) {
    if (p.imported_ysws_entry_id) ids.add(p.imported_ysws_entry_id);
    for (const u of [p.repo_url, p.demo_url]) {
      const n = normalizeProjectUrl(String(u ?? ""));
      if (n !== "") urls.add(n);
    }
  }
  return { ids, urls };
}

export function availableShips(ships: ArchiveShip[], taken: TakenProjectUrls): ArchiveShip[] {
  return ships.filter((s) => {
    if (taken.ids.has(s.id)) return false;
    const repo = normalizeProjectUrl(s.codeUrl);
    const demo = normalizeProjectUrl(s.demoUrl);
    return !(repo !== "" && taken.urls.has(repo)) && !(demo !== "" && taken.urls.has(demo));
  });
}