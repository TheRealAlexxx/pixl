// pixo-dm , a tiny standalone DM relay for Pixl.
//
// The internal dashboard POSTs player-facing DMs here (warns, bans, project
// verdicts, shipping tracking) and we deliver them as the Pixl Slack bot, so
// they arrive from Pixo. It's kept deliberately separate from the pixorpheus bot
// process: same bot token, its own service, nothing shared but Slack.
//
// Auth: an x-api-key header that must equal EXTERNAL_API_KEY (the same secret the
// dashboard sends). Env: SLACK_BOT_TOKEN (the Pixo bot), EXTERNAL_API_KEY, PORT.
const express = require("express");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 4100;
const API_KEY = process.env.EXTERNAL_API_KEY;
const SLACK_BOT_TOKEN = process.env.SLACK_BOT_TOKEN;

// Health check , Railway pings this and it's handy to confirm the service is up.
app.get("/", (_req, res) => res.json({ ok: true, service: "pixo-dm" }));

app.post("/api/external/dm", async (req, res) => {
  if (!API_KEY) return res.status(503).json({ error: "API key not configured" });
  if (req.headers["x-api-key"] !== API_KEY)
    return res.status(401).json({ error: "Invalid API key" });

  const { userId, message } = req.body || {};
  if (!userId?.trim() || !message?.trim())
    return res.status(400).json({ error: "Missing userId or message" });

  try {
    // channel = a Slack user id opens (or reuses) the IM with that user.
    const r = await fetch("https://slack.com/api/chat.postMessage", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${SLACK_BOT_TOKEN}`,
        "Content-Type": "application/json; charset=utf-8",
      },
      body: JSON.stringify({ channel: userId.trim(), text: message.trim() }),
    });
    const json = await r.json();
    if (!json.ok) return res.status(502).json({ error: json.error || "slack_error" });
    res.json({ ok: true });
  } catch (e) {
    console.error("[pixo-dm]", e.message);
    res.status(502).json({ error: e.message });
  }
});

app.listen(PORT, () => console.log(`pixo-dm listening on ${PORT}`));
