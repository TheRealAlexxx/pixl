import axios from "axios";
import { aiClassify } from "./client.js";
import { resolveUserMentions } from "../memory/users.js";
import { botIdentity } from "../slack/identity.js";

export async function braveSearch(query: string): Promise<string | null> {
  try {
    const res = await axios.get("https://api.search.brave.com/res/v1/web/search", {
      params: { q: query, count: 5 },
      headers: {
        "X-Subscription-Token": process.env.BRAVE_SEARCH_KEY,
        Accept: "application/json",
      },
    });
    const results = res.data.web?.results || [];
    return results
      .slice(0, 4)
      .map((r: { title: string; description: string }) => `${r.title}: ${r.description}`)
      .join("\n");
  } catch (e) {
    return null;
  }
}

export async function extractSearchQuery(messages: string[]): Promise<string | null> {
  if (!process.env.BRAVE_SEARCH_KEY) return null;
  const combined = messages.join("\n");
  try {
    const res = await aiClassify({
      messages: [
        {
          role: "system",
          content:
            "If this message needs up-to-date info from the web (current events, news, prices, recent releases, live data, things that change over time), output ONLY the ideal search query in English. If no web search is needed, output SKIP.",
        },
        { role: "user", content: combined },
      ],
      max_tokens: 20,
    });
    const out = res.data.choices?.[0]?.message?.content?.trim();
    if (!out || out.toUpperCase().startsWith("SKIP")) return null;
    return out;
  } catch (e) {
    return null;
  }
}

export type ChimeVerdict = "direct" | "chime" | "skip";

export async function shouldChimeIn(messages: string[]): Promise<ChimeVerdict> {
  const combined = messages.map(resolveUserMentions).join("\n");
  const botIdHint = botIdentity.userId
    ? `The bot's Slack mention is @pixorpheus (ID <@${botIdentity.userId}>). `
    : "";
  try {
    const res = await aiClassify({
      messages: [
        {
          role: "system",
          content: `${botIdHint}You are deciding whether Pixorpheus (a sarcastic Slack bot) should respond. Reply with exactly one word — nothing else.

DIRECT — someone is clearly talking TO the bot. Signs: mentions "pixorpheus", "pix", "pixo", "bot", asks a question in a way that expects the bot to answer, replies directly to something the bot said, or the message is clearly addressed to no one else in the conversation.
CHIME — people are talking among themselves BUT there's a genuinely perfect, funny, or obvious 1-line opening for the bot (rare — only if it's really there)
SKIP — just people chatting between themselves, bot has no business here

When in doubt between DIRECT and CHIME, pick DIRECT. When in doubt between CHIME and SKIP, pick SKIP.`,
        },
        { role: "user", content: combined },
      ],
      max_tokens: 5,
    });
    const word = res.data.choices?.[0]?.message?.content?.trim().toUpperCase().split(/\s/)[0];
    if (word === "DIRECT") return "direct";
    if (word === "CHIME") return "chime";
    return "skip";
  } catch (e) {
    return "skip";
  }
}
