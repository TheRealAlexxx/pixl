// Behaviour for the generated doc pages. No routing here: every page is a real
// document now, so this is only the sidebar groups, the on-this-page rail,
// theme, and code copy buttons.
(() => {
  const GAME = location.hostname.startsWith("play.") ? "/" : "/play";
  const brand = document.getElementById("docs-brand");
  if (brand) brand.href = GAME;

  const back = document.getElementById("docs-back");
  if (back) {
    const ref = (() => {
      try {
        const r = document.referrer;
        if (r && new URL(r).origin === location.origin && !/\/docs(\/|$)/.test(new URL(r).pathname)) {
          return r;
        }
      } catch (e) {}
      return "/home/";
    })();
    back.addEventListener("click", () => {
      location.href = ref;
    });
  }

  document.querySelectorAll(".docs-group-head").forEach((head) => {
    head.addEventListener("click", () => head.parentElement.classList.toggle("collapsed"));
  });

  const SUN = '<svg viewBox="0 0 16 16" fill="currentColor"><rect x="6" y="6" width="4" height="4"/><rect x="7" y="1" width="2" height="2"/><rect x="7" y="13" width="2" height="2"/><rect x="1" y="7" width="2" height="2"/><rect x="13" y="7" width="2" height="2"/><rect x="3" y="3" width="2" height="2"/><rect x="11" y="3" width="2" height="2"/><rect x="3" y="11" width="2" height="2"/><rect x="11" y="11" width="2" height="2"/></svg>';
  const MOON = '<svg viewBox="0 0 16 16" fill="currentColor"><rect x="5" y="2" width="2" height="1"/><rect x="4" y="3" width="3" height="1"/><rect x="3" y="4" width="3" height="1"/><rect x="2" y="5" width="4" height="1"/><rect x="2" y="6" width="5" height="1"/><rect x="2" y="7" width="5" height="1"/><rect x="2" y="8" width="5" height="1"/><rect x="2" y="9" width="6" height="1"/><rect x="2" y="10" width="8" height="1"/><rect x="3" y="11" width="10" height="1"/><rect x="4" y="12" width="8" height="1"/><rect x="5" y="13" width="6" height="1"/></svg>';
  const themeBtn = document.getElementById("docs-theme-btn");
  function syncTheme() {
    if (!themeBtn) return;
    const light = document.documentElement.dataset.theme === "light";
    themeBtn.innerHTML = light ? MOON : SUN;
    themeBtn.setAttribute("aria-label", light ? "Switch to dark theme" : "Switch to light theme");
  }
  if (themeBtn) {
    themeBtn.addEventListener("click", () => {
      const next = document.documentElement.dataset.theme === "light" ? "dark" : "light";
      document.documentElement.dataset.theme = next;
      try {
        localStorage.setItem("pixl_theme", next);
      } catch (e) {}
      syncTheme();
    });
    syncTheme();
  }

  const tocLinks = [...document.querySelectorAll(".docs-toc a")];
  tocLinks.forEach((a) =>
    a.addEventListener("click", (e) => {
      e.preventDefault();
      document.getElementById(a.dataset.h)?.scrollIntoView({ behavior: "smooth", block: "start" });
    }),
  );
  function markToc() {
    if (!tocLinks.length) return;
    let current = tocLinks[0].dataset.h;
    const atBottom =
      window.scrollY + window.innerHeight >= document.documentElement.scrollHeight - 4;
    if (atBottom) {
      current = tocLinks[tocLinks.length - 1].dataset.h;
    } else {
      for (const a of tocLinks) {
        const el = document.getElementById(a.dataset.h);
        if (el && el.getBoundingClientRect().top <= 96) current = a.dataset.h;
      }
    }
    tocLinks.forEach((a) => a.classList.toggle("active", a.dataset.h === current));
  }
  window.addEventListener("scroll", markToc, { passive: true });
  markToc();

  if (window.hljs) hljs.highlightAll();
  document.querySelectorAll("pre").forEach((pre) => {
    const btn = document.createElement("button");
    btn.className = "copy-btn";
    btn.type = "button";
    btn.textContent = "Copy";
    btn.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(pre.querySelector("code").textContent);
        btn.textContent = "Copied";
        btn.classList.add("copied");
        setTimeout(() => {
          btn.textContent = "Copy";
          btn.classList.remove("copied");
        }, 1600);
      } catch (e) {}
    });
    pre.appendChild(btn);
  });
})();
