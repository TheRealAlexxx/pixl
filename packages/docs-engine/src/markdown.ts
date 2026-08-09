// Markdown for the docs, plus the two block types the pages actually use that
// plain markdown has no syntax for: callouts and the three-column fact grid.
export interface Frontmatter {
  title: string;
  group: string;
  description: string;
  slug?: string;
}

export interface Doc {
  slug: string;
  meta: Frontmatter;
  body: string;
  headings: { id: string; text: string }[];
}

const esc = (s: string) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

export function slugify(s: string): string {
  return s
    .toLowerCase()
    .replace(/[^\w]+/g, "-")
    .replace(/^-|-$/g, "");
}

function inline(raw: string): string {
  return esc(raw)
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>")
    .replace(/(^|[^*])\*([^*\s][^*]*?)\*/g, "$1<i>$2</i>")
    .replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, '<a href="$2">$1</a>');
}

function parseFrontmatter(src: string): { meta: Frontmatter; rest: string } {
  const match = src.match(/^---\n([\s\S]*?)\n---\n?/);
  if (!match) throw new Error("missing frontmatter");
  const meta: Record<string, string> = {};
  for (const line of match[1]!.split("\n")) {
    const at = line.indexOf(":");
    if (at === -1) continue;
    meta[line.slice(0, at).trim()] = line
      .slice(at + 1)
      .trim()
      .replace(/^["']|["']$/g, "");
  }
  for (const key of ["title", "group", "description"]) {
    if (!meta[key]) throw new Error(`frontmatter is missing "${key}"`);
  }
  return { meta: meta as unknown as Frontmatter, rest: src.slice(match[0].length) };
}

// A markdown table becomes the .fact-grid used for the tier and level tables.
function factGrid(rows: string[][]): string {
  const cells = rows
    .flatMap((cols) => cols.map((c) => `<div>${inline(c)}</div>`))
    .join("\n          ");
  return `<div class="fact-grid">\n          ${cells}\n        </div>`;
}

export function render(src: string, tokens: Record<string, string>): Doc {
  const { meta, rest } = parseFrontmatter(src);
  const withTokens = rest.replace(/\{\{\s*([\w.]+)\s*\}\}/g, (_match, key: string) => {
    if (!(key in tokens)) throw new Error(`unknown token {{${key}}}`);
    return tokens[key]!;
  });

  const lines = withTokens.split("\n");
  const headings: { id: string; text: string }[] = [];
  let html = "";
  let list: string | null = null;
  const closeList = () => {
    if (list) {
      html += `</${list}>\n`;
      list = null;
    }
  };

  for (let i = 0; i < lines.length; ) {
    const line = lines[i]!;

    if (/^```/.test(line)) {
      closeList();
      const lang = line.slice(3).trim();
      const buf: string[] = [];
      i++;
      while (i < lines.length && !/^```/.test(lines[i]!)) buf.push(lines[i++]!);
      i++;
      const cls = lang ? ` class="language-${lang}"` : "";
      html += `<pre><code${cls}>${esc(buf.join("\n"))}</code></pre>\n`;
      continue;
    }

    // ::: note Title  /  ::: warn Title
    const callout = line.match(/^:::\s*(note|warn)\s*(.*)$/);
    if (callout) {
      closeList();
      const buf: string[] = [];
      i++;
      while (i < lines.length && !/^:::\s*$/.test(lines[i]!)) buf.push(lines[i++]!);
      i++;
      const kind = callout[1] === "warn" ? "callout warn" : "callout";
      html += `<div class="${kind}">\n          <span class="k">${inline(callout[2] || "")}</span>\n          <p>${inline(buf.join(" ").trim())}</p>\n        </div>\n`;
      continue;
    }

    if (/^\|/.test(line)) {
      closeList();
      const rows: string[][] = [];
      while (i < lines.length && /^\|/.test(lines[i]!)) {
        const raw = lines[i++]!.trim();
        if (/^\|[\s:|-]+\|$/.test(raw)) continue;
        rows.push(
          raw
            .slice(1, -1)
            .split("|")
            .map((c) => c.trim()),
        );
      }
      html += factGrid(rows) + "\n";
      continue;
    }

    const heading = line.match(/^(#{1,3})\s+(.*)$/);
    if (heading) {
      closeList();
      const level = heading[1]!.length;
      const text = heading[2]!.trim();
      if (level === 1) {
        html += `<h1>${inline(text)}</h1>\n`;
      } else if (level === 2) {
        const id = `h-${slugify(text)}`;
        // The rail shows plain text, so strip the inline markers rather than
        // printing the backticks a heading like "The page - `index.html`" has.
        headings.push({ id, text: text.replace(/[`*]/g, "") });
        html += `<h2 id="${id}">${inline(text)}</h2>\n`;
      } else {
        html += `<h3>${inline(text)}</h3>\n`;
      }
      i++;
      continue;
    }

    if (/^\s*[-*]\s+/.test(line)) {
      if (list !== "ul") {
        closeList();
        html += "<ul>\n";
        list = "ul";
      }
      html += `<li>${inline(line.replace(/^\s*[-*]\s+/, ""))}</li>\n`;
      i++;
      continue;
    }

    if (/^\s*$/.test(line)) {
      closeList();
      i++;
      continue;
    }

    closeList();
    const para = [line];
    i++;
    while (i < lines.length && !/^\s*$/.test(lines[i]!) && !/^(#{1,3}\s|```|:::|\||\s*[-*]\s)/.test(lines[i]!)) {
      para.push(lines[i++]!);
    }
    const lead = para[0]!.startsWith("^ ") ? ' class="lead"' : "";
    html += `<p${lead}>${inline(para.join(" ").replace(/^\^ /, ""))}</p>\n`;
  }
  closeList();

  return { slug: meta.slug ?? "", meta, body: html.trim(), headings };
}
