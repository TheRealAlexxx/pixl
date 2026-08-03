const express = require("express");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 4100;
const API_KEY = process.env.EXTERNAL_API_KEY;
const SLACK_BOT_TOKEN = process.env.SLACK_BOT_TOKEN;

app.get("/", (_req, res) => res.json({ ok: true, service: "pixo-dm" }));

app.post("/api/external/dm", async (req, res) => {
  if (!API_KEY) return res.status(503).json({ error: "API key not configured" });
  if (req.headers["x-api-key"] !== API_KEY)
    return res.status(401).json({ error: "Invalid API key" });

  const { userId, message } = req.body || {};
  if (!userId?.trim() || !message?.trim())
    return res.status(400).json({ error: "Missing userId or message" });

  try {
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
