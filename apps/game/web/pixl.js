const Pixl = (() => {
  const API = "https://server.pixl.rsvp";
  // On the standalone play.* host the game is at the root; when the same build
  // is served under pixl.rsvp (via rewrites) it lives at /play. Keep the
  // "back to game" link pointing at the right place without a redirect.
  const GAME = location.hostname.startsWith("play.") ? "/" : "/play";

  const params = new URLSearchParams(location.search);
  let token = params.get("token") || "";
  if (token) {
    try { localStorage.setItem("pixl_token", token); } catch {}
    params.delete("token");
    params.delete("name");
    params.delete("embed");
    const qs = params.toString();
    history.replaceState({}, "", location.pathname + (qs ? "?" + qs : "") + location.hash);
  } else {
    try { token = localStorage.getItem("pixl_token") || ""; } catch {}
  }

  function phase() {
    const h = new Date().getHours() + new Date().getMinutes() / 60;
    if (h < 5 || h >= 21) return "night";
    if (h < 7) return "dawn";
    if (h < 17) return "day";
    return "dusk";
  }
  document.documentElement.dataset.phase = phase();

  function esc(s) {
    return String(s ?? "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    })[c]);
  }

  function gate() {
    document.body.insertAdjacentHTML("beforeend", `
      <div class="gate">
        <div class="gate-card panel">
          <div style="font-size:44px;margin-bottom:12px"></div>
          <h1>PIXL</h1>
          <p>This page is part of the Pixl world — hop into the game and walk up to the shop, an NPC or press the shortcut key to open it with your account.</p>
          <a class="btn" href="${GAME}">ENTER THE GAME</a>
        </div>
      </div>`);
  }

  async function api(path) {
    const url = API + path + (path.includes("?") ? "&" : "?") + "token=" + encodeURIComponent(token);
    const res = await fetch(url);
    if (res.status === 401) {
      try { localStorage.removeItem("pixl_token"); } catch {}
      if (!document.querySelector(".gate")) gate();
      throw new Error("unauthorized");
    }
    if (!res.ok) throw new Error("http_" + res.status);
    return res.json();
  }

  function apiUrl(path) {
    return API + path + (path.includes("?") ? "&" : "?") + "token=" + encodeURIComponent(token);
  }

  let toastSlot = null;
  function toast(text, bad = false) {
    if (!toastSlot) {
      toastSlot = document.createElement("div");
      toastSlot.className = "toast-slot";
      document.body.appendChild(toastSlot);
    }
    const t = document.createElement("div");
    t.className = "toast" + (bad ? " bad" : "");
    t.textContent = text;
    toastSlot.appendChild(t);
    setTimeout(() => t.remove(), 3200);
  }

  async function send(method, path, body) {
    const res = await fetch(apiUrl(path), {
      method,
      headers: { "Content-Type": "application/json" },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    let json = null;
    try { json = await res.json(); } catch {}
    return { status: res.status, ...(json || {}) };
  }

  async function upload(file) {
    const res = await fetch(apiUrl("/api/uploads"), {
      method: "POST",
      headers: { "Content-Type": file.type || "image/png" },
      body: file,
    });
    const json = await res.json().catch(() => null);
    if (!json || !json.ok || !json.url) {
      if (json && json.error === "image_rejected")
        throw new Error("That image was rejected: " + (json.reason || "inappropriate for Pixl") + ".");
      throw new Error((json && json.error) || "upload_failed");
    }
    return json.url;
  }

  const PAGES = [
    ["shop", "SHOP"],
    // VAULT and QUESTS are hidden from the dash for now — not ready for players.
    // Re-enable when they are.
    // ["vault", "VAULT"],
    ["explore", "EXPLORE"],
    // ["quests", "QUESTS"],
    // STORY (The Chronicle) is disabled in the dash for now — the storyline is
    // surfaced through community goals instead. Re-enable when it's ready.
    // ["timeline", "STORY"],
    ["projects", "PROJECTS"],
    ["report", "REPORT"],
  ];

  function mountTopbar(active) {
    const nav = PAGES.map(([slug, label]) =>
      `<a href="/${slug}/" class="${slug === active ? "active" : ""}">${label}</a>`,
    ).join("");
    document.body.insertAdjacentHTML("afterbegin", `
      <header class="topbar">
        <a class="logo" href="${GAME}" title="Back to the game"><img src="/index.icon.png" alt="">PIXL</a>
        <nav class="nav">${nav}</nav>
        <div class="topbar-right">
          <div class="wallet-chip" id="pixl-wallet" title="Your pixels">
            <img src="/img/pixel.png" alt="px">
            <span class="px">—</span>
            <span class="lv"></span>
          </div>
          <a class="btn dark" href="${GAME}">BACK TO GAME</a>
        </div>
      </header>`);
  }

  async function loadWallet() {
    const el = document.getElementById("pixl-wallet");
    if (!el) return null;
    try {
      const w = await api("/api/profile/wallet");
      if (!w.ok) return null;
      el.querySelector(".px").textContent = Math.round(w.pixels).toLocaleString();
      el.querySelector(".lv").textContent = `LVL ${w.level} · ${w.pxPerHour} px/h`;
      return w;
    } catch {
      return null;
    }
  }

  // Godot RichTextLabel BBCode subset → HTML.
  // https://docs.godotengine.org/en/latest/tutorials/ui/bbcode_in_richtextlabel.html
  function bbSafeColor(v) {
    return /^(#[0-9a-fA-F]{3,8}|[a-zA-Z]{2,24})$/.test(v) ? v : "";
  }

  function bbSafeUrl(v) {
    return /^https?:\/\/[^"'\s]+$/i.test(v) ? v : "";
  }

  function bbChars(cls, inner) {
    if (inner.includes("<")) return `<span class="${cls}">${inner}</span>`;
    const chars = inner.match(/&[^;\s]{1,10};|[\s\S]/g) || [];
    return `<span class="${cls}">${chars.map((c, i) =>
      `<span class="bb-char" style="animation-delay:-${(i * 0.09).toFixed(2)}s">${c}</span>`,
    ).join("")}</span>`;
  }

  const BB_RULES = [
    [/\[b\]([\s\S]*?)\[\/b\]/g, "<b>$1</b>"],
    [/\[i\]([\s\S]*?)\[\/i\]/g, "<i>$1</i>"],
    [/\[u\]([\s\S]*?)\[\/u\]/g, "<u>$1</u>"],
    [/\[s\]([\s\S]*?)\[\/s\]/g, "<s>$1</s>"],
    [/\[code\]([\s\S]*?)\[\/code\]/g, '<span class="bb-code">$1</span>'],
    [/\[center\]([\s\S]*?)\[\/center\]/g, '<span style="display:block;text-align:center">$1</span>'],
    [/\[right\]([\s\S]*?)\[\/right\]/g, '<span style="display:block;text-align:right">$1</span>'],
    [/\[left\]([\s\S]*?)\[\/left\]/g, '<span style="display:block;text-align:left">$1</span>'],
    [/\[color=([^\]]+)\]([\s\S]*?)\[\/color\]/g,
      (_m, c, inner) => bbSafeColor(c) ? `<span style="color:${bbSafeColor(c)}">${inner}</span>` : inner],
    [/\[bgcolor=([^\]]+)\]([\s\S]*?)\[\/bgcolor\]/g,
      (_m, c, inner) => bbSafeColor(c) ? `<span style="background:${bbSafeColor(c)}">${inner}</span>` : inner],
    [/\[font_size=(\d{1,3})\]([\s\S]*?)\[\/font_size\]/g,
      (_m, n, inner) => `<span style="font-size:${Math.min(Math.max(Number(n), 8), 64)}px">${inner}</span>`],
    [/\[url\](https?:\/\/[^\[\s]+)\[\/url\]/g,
      (_m, u) => bbSafeUrl(u) ? `<a href="${u}" target="_blank" rel="noopener">${u}</a>` : u],
    [/\[url=([^\]]+)\]([\s\S]*?)\[\/url\]/g,
      (_m, u, inner) => bbSafeUrl(u) ? `<a href="${bbSafeUrl(u)}" target="_blank" rel="noopener">${inner}</a>` : inner],
    [/\[img(?:[^\]]*)\](https?:\/\/[^\[\s]+)\[\/img\]/g,
      (_m, u) => bbSafeUrl(u) ? `<img class="bb-img" src="${u}" alt="" loading="lazy" onerror="this.remove()">` : ""],
    [/\[wave(?:[^\]]*)\]([\s\S]*?)\[\/wave\]/g, (_m, inner) => bbChars("bb-wave", inner)],
    [/\[shake(?:[^\]]*)\]([\s\S]*?)\[\/shake\]/g, (_m, inner) => bbChars("bb-shake", inner)],
    [/\[rainbow(?:[^\]]*)\]([\s\S]*?)\[\/rainbow\]/g, (_m, inner) => bbChars("bb-rainbow", inner)],
    [/\[tornado(?:[^\]]*)\]([\s\S]*?)\[\/tornado\]/g, (_m, inner) => bbChars("bb-wave", inner)],
    [/\[pulse(?:[^\]]*)\]([\s\S]*?)\[\/pulse\]/g, '<span class="bb-pulse">$1</span>'],
    [/\[fade(?:[^\]]*)\]([\s\S]*?)\[\/fade\]/g, '<span style="opacity:.55">$1</span>'],
  ];

  function bbcode(src) {
    let s = esc(src);
    for (let pass = 0; pass < 4; pass++) {
      const before = s;
      for (const [re, rep] of BB_RULES) s = s.replace(re, rep);
      if (s === before) break;
    }
    return s.replace(/\[lb\]/g, "&#91;").replace(/\[rb\]/g, "&#93;");
  }

  function bbstrip(src) {
    return String(src ?? "")
      .replace(/\[\/?(?!lb\]|rb\])[a-zA-Z][^\]]*\]/g, "")
      .replace(/\[lb\]/g, "[")
      .replace(/\[rb\]/g, "]");
  }

  // Safe Markdown subset for journals — escapes first, then renders headings,
  // bold/italic/strike, inline code + fenced blocks, links, images, lists,
  // blockquotes and rules. URLs are restricted to http(s).
  function mdInline(raw) {
    return esc(raw)
      .replace(/`([^`]+)`/g, "<code>$1</code>")
      .replace(/!\[([^\]]*)\]\((https?:\/\/[^)\s]+)\)/g,
        (_m, a, u) => (bbSafeUrl(u) ? `<img class="md-img" src="${u}" alt="${a}" loading="lazy" onerror="this.remove()">` : ""))
      .replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g,
        (_m, t, u) => (bbSafeUrl(u) ? `<a href="${u}" target="_blank" rel="noopener">${t}</a>` : t))
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/__([^_]+)__/g, "<strong>$1</strong>")
      .replace(/(^|[^*])\*([^*\s][^*]*?)\*/g, "$1<em>$2</em>")
      .replace(/~~([^~]+)~~/g, "<s>$1</s>");
  }

  function markdown(src) {
    const lines = String(src ?? "").split(/\r?\n/);
    let html = "";
    let list = null;
    const closeList = () => { if (list) { html += `</${list}>`; list = null; } };
    for (let i = 0; i < lines.length; ) {
      const line = lines[i];
      if (/^```/.test(line)) {
        closeList();
        const buf = [];
        i++;
        while (i < lines.length && !/^```/.test(lines[i])) buf.push(lines[i++]);
        i++;
        html += `<pre class="md-pre"><code>${esc(buf.join("\n"))}</code></pre>`;
        continue;
      }
      const h = line.match(/^(#{1,6})\s+(.*)$/);
      if (h) { closeList(); html += `<h${h[1].length} class="md-h">${mdInline(h[2])}</h${h[1].length}>`; i++; continue; }
      if (/^\s*([-*_])\1\1+\s*$/.test(line)) { closeList(); html += `<hr class="md-hr">`; i++; continue; }
      if (/^>\s?/.test(line)) {
        closeList();
        const q = [];
        while (i < lines.length && /^>\s?/.test(lines[i])) q.push(lines[i++].replace(/^>\s?/, ""));
        html += `<blockquote class="md-quote">${mdInline(q.join(" "))}</blockquote>`;
        continue;
      }
      if (/^\s*[-*+]\s+/.test(line)) {
        if (list !== "ul") { closeList(); html += `<ul class="md-list">`; list = "ul"; }
        html += `<li>${mdInline(line.replace(/^\s*[-*+]\s+/, ""))}</li>`; i++; continue;
      }
      if (/^\s*\d+\.\s+/.test(line)) {
        if (list !== "ol") { closeList(); html += `<ol class="md-list">`; list = "ol"; }
        html += `<li>${mdInline(line.replace(/^\s*\d+\.\s+/, ""))}</li>`; i++; continue;
      }
      if (/^\s*$/.test(line)) { closeList(); i++; continue; }
      closeList();
      const para = [line];
      i++;
      while (i < lines.length && !/^\s*$/.test(lines[i]) &&
        !/^(#{1,6}\s|```|>\s?|\s*[-*+]\s+|\s*\d+\.\s+)/.test(lines[i]) &&
        !/^\s*([-*_])\1\1+\s*$/.test(lines[i])) para.push(lines[i++]);
      html += `<p class="md-p">${para.map(mdInline).join("<br>")}</p>`;
    }
    closeList();
    return html;
  }

  function timeAgo(iso) {
    const s = (Date.now() - new Date(iso).getTime()) / 1000;
    if (!isFinite(s)) return "";
    if (s < 90) return "just now";
    if (s < 3600) return `${Math.floor(s / 60)}m ago`;
    if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
    if (s < 86400 * 30) return `${Math.floor(s / 86400)}d ago`;
    return new Date(iso).toLocaleDateString();
  }

  function countdown(iso) {
    const ms = new Date(iso).getTime() - Date.now();
    if (!isFinite(ms) || ms <= 0) return "gone!";
    const h = Math.floor(ms / 3600000);
    const m = Math.floor((ms % 3600000) / 60000);
    const s = Math.floor((ms % 60000) / 1000);
    if (h > 48) return `${Math.floor(h / 24)}d ${h % 24}h left`;
    if (h > 0) return `${h}h ${m}m left`;
    return `${m}m ${s}s left`;
  }

  function hours(seconds) {
    return (seconds / 3600).toFixed(1) + "h";
  }

  /* ─────────────────────────── onboarding tour ───────────────────────────
   * A first-visit interactive walkthrough for people who've never heard of
   * Hack Club or Pixl. Each step is either a centered card (great for intro
   * copy + a short video/GIF) or a spotlight that highlights a real element on
   * the page and points a tooltip at it. Runs once, then remembers via
   * localStorage. EDIT ONBOARDING_STEPS to change the copy / media / targets.
   *
   * Step shape:
   *   { title, body, target?, video?, img? }
   *     target  CSS selector to spotlight (omit for a centered card)
   *     video   URL of a short .mp4/.webm to autoplay muted+looped in the card
   *     img     URL of a .gif/.png to show in the card instead of a video
   * A step whose target isn't on the current page falls back to a centered card.
   */
  const ONBOARDING_STEPS = [
    {
      title: "Welcome to Pixl 👋",
      body: "New here? Take 30 seconds and we'll show you the ropes. You can skip anytime.",
      // video: "/img/onboarding/welcome.mp4",
    },
    {
      title: "What's Hack Club?",
      body: "Hack Club is a worldwide community of teenage hackers, makers and builders. You learn by shipping real things , and they send real prizes and grants for what you make.",
      // video: "/img/onboarding/hackclub.mp4",
    },
    {
      title: "So what's Pixl?",
      body: "Pixl is a pixel-art world you actually build. Ship real projects for the characters inside it, repair the world, and earn <b>pixels</b> , the in-game currency , plus real-world rewards.",
    },
    {
      target: ".nav",
      title: "Getting around",
      body: "Jump between the shop, explore, your projects and more from up here.",
    },
    {
      target: "#pixl-wallet",
      title: "Your pixels",
      body: "This is your wallet. Earn pixels by shipping projects, then spend them in the shop on real rewards.",
    },
    {
      target: "#new-btn",
      title: "Start a project",
      body: "Tap here to create your first project. Give it a name, link a GitHub repo and a demo, and log your time with Hackatime.",
    },
    {
      target: "#s-ship",
      title: "Ship it for review",
      body: "When your project is ready, ship it. A reviewer checks it out and credits you pixels + a prize for the work.",
    },
    {
      title: "That's it , go build 🚀",
      body: "Pick a sidequest or make your own thing. Stuck? Ask in <b>#pixl-help</b> on the Hack Club Slack.",
    },
  ];

  function injectTourCSS() {
    if (document.getElementById("pixl-tour-css")) return;
    const s = document.createElement("style");
    s.id = "pixl-tour-css";
    s.textContent = `
      #pixl-tour{position:fixed;inset:0;z-index:99999;font-family:var(--sans,sans-serif)}
      #pixl-tour .pt-veil{position:absolute;inset:0;background:rgba(10,10,14,.72)}
      #pixl-tour .pt-hole{position:absolute;border-radius:10px;box-shadow:0 0 0 9999px rgba(10,10,14,.72);transition:all .25s ease;pointer-events:none;border:2px solid var(--gold,#f4b942)}
      #pixl-tour .pt-card{position:absolute;max-width:340px;width:calc(100% - 32px);background:var(--panel,#1b1b24);color:var(--ink,#f4f4f5);border:2px solid var(--stroke,#2a2a35);border-radius:14px;padding:18px;box-shadow:0 14px 40px rgba(0,0,0,.5);transition:top .2s ease,left .2s ease}
      #pixl-tour .pt-card.center{top:50%;left:50%;transform:translate(-50%,-50%)}
      #pixl-tour .pt-media{width:100%;border-radius:10px;margin-bottom:12px;display:block;background:#000;aspect-ratio:16/9;object-fit:cover}
      #pixl-tour .pt-title{font-family:var(--pixel,var(--sans));font-size:18px;letter-spacing:.5px;color:var(--gold,#f4b942);margin-bottom:8px}
      #pixl-tour .pt-body{font-size:14px;line-height:1.55;color:var(--dim,#cfcfd6)}
      #pixl-tour .pt-body b{color:var(--ink,#f4f4f5)}
      #pixl-tour .pt-foot{display:flex;align-items:center;gap:10px;margin-top:16px}
      #pixl-tour .pt-dots{display:flex;gap:5px;margin-right:auto}
      #pixl-tour .pt-dot{width:7px;height:7px;border-radius:50%;background:var(--muted,#4a4a52)}
      #pixl-tour .pt-dot.on{background:var(--gold,#f4b942)}
      #pixl-tour .pt-skip{background:none;border:0;color:var(--faint,#8a8a93);cursor:pointer;font-size:12px;padding:6px}
      #pixl-tour .pt-btn{background:var(--gold,#f4b942);color:var(--btn-ink,#241710);border:0;border-radius:8px;padding:8px 16px;font-weight:700;cursor:pointer;font-size:14px}
      #pixl-tour .pt-back{background:none;border:1px solid var(--stroke,#2a2a35);color:var(--dim,#cfcfd6);border-radius:8px;padding:8px 12px;cursor:pointer;font-size:13px}
    `;
    document.head.appendChild(s);
  }

  function markOnboarded() {
    try { localStorage.setItem("pixl_onboarded", "1"); } catch {}
  }

  function runTour(steps = ONBOARDING_STEPS, startAt = 0) {
    injectTourCSS();
    document.getElementById("pixl-tour")?.remove();
    const root = document.createElement("div");
    root.id = "pixl-tour";
    root.innerHTML = `<div class="pt-veil"></div><div class="pt-hole" style="display:none"></div><div class="pt-card"></div>`;
    document.body.appendChild(root);
    const veil = root.querySelector(".pt-veil");
    const hole = root.querySelector(".pt-hole");
    const card = root.querySelector(".pt-card");
    let i = Math.max(0, Math.min(startAt, steps.length - 1));

    function close() { root.remove(); markOnboarded(); }

    function media(step) {
      if (step.video) return `<video class="pt-media" src="${esc(step.video)}" autoplay muted loop playsinline></video>`;
      if (step.img) return `<img class="pt-media" src="${esc(step.img)}" alt="">`;
      return "";
    }

    function render() {
      const step = steps[i];
      const el = step.target ? document.querySelector(step.target) : null;
      const dots = steps.map((_, n) => `<span class="pt-dot ${n === i ? "on" : ""}"></span>`).join("");
      card.innerHTML = `
        ${media(step)}
        <div class="pt-title">${esc(step.title)}</div>
        <div class="pt-body">${step.body}</div>
        <div class="pt-foot">
          <div class="pt-dots">${dots}</div>
          ${i > 0 ? `<button class="pt-back">Back</button>` : `<button class="pt-skip">Skip</button>`}
          <button class="pt-btn">${i === steps.length - 1 ? "Done" : "Next"}</button>
        </div>`;
      card.querySelector(".pt-btn").onclick = () => (i === steps.length - 1 ? close() : (i++, render()));
      const back = card.querySelector(".pt-back");
      if (back) back.onclick = () => { i--; render(); };
      const skip = card.querySelector(".pt-skip");
      if (skip) skip.onclick = close;

      if (el && el.getClientRects().length) {
        el.scrollIntoView({ block: "center", behavior: "smooth" });
        // wait a tick for the smooth scroll before measuring
        setTimeout(() => {
          const r = el.getBoundingClientRect();
          const pad = 6;
          hole.style.display = "block";
          hole.style.top = `${r.top - pad}px`;
          hole.style.left = `${r.left - pad}px`;
          hole.style.width = `${r.width + pad * 2}px`;
          hole.style.height = `${r.height + pad * 2}px`;
          card.classList.remove("center");
          const below = r.bottom + 14;
          const room = window.innerHeight - r.bottom;
          const cw = card.offsetWidth || 340;
          const ch = card.offsetHeight || 200;
          card.style.top = `${room > ch + 20 ? below : Math.max(14, r.top - ch - 14)}px`;
          card.style.left = `${Math.min(Math.max(14, r.left + r.width / 2 - cw / 2), window.innerWidth - cw - 14)}px`;
        }, 260);
      } else {
        hole.style.display = "none";
        card.classList.add("center");
        card.style.top = "";
        card.style.left = "";
      }
    }
    veil.onclick = close;
    render();
  }

  // Run the tour once, the first time a signed-in newcomer opens the dash.
  function maybeOnboard(steps = ONBOARDING_STEPS) {
    let done = true;
    try { done = localStorage.getItem("pixl_onboarded") === "1"; } catch {}
    if (done || !token) return;
    setTimeout(() => runTour(steps), 700);
  }

  if (!token) {
    document.addEventListener("DOMContentLoaded", gate);
  }

  return { API, token, api, apiUrl, send, upload, esc, bbcode, bbstrip, markdown, toast, mountTopbar, loadWallet, timeAgo, countdown, hours, hasToken: !!token, runTour, maybeOnboard, ONBOARDING_STEPS };
})();
