// Shared #pixl-logs event logging, used by both the bot (index.js) and the dashboard.
// Resolves the channel once, then posts. Never throws — logging must not break
// the feature that triggered it.
//
// In a huge workspace (Hack Club), paginating conversations.list to find the
// channel is hopeless: Slack rate-limits non-Marketplace apps hard on that API,
// and each retry blocks the shared client queue for 30s+, starving every other
// Slack call the bot makes. So the scan is capped to a few pages and backs off
// for a while on failure. Set PIXL_LOGS_CHANNEL_ID to skip the scan entirely.
const LOG_CHANNEL_NAME = 'pixl-logs';
const MAX_PAGES = 3;
const FAIL_COOLDOWN_MS = 15 * 60 * 1000;

let channelId = process.env.PIXL_LOGS_CHANNEL_ID || null;
let resolving = null;
let lastFailedAt = 0;
let warned = false;

async function resolveChannel(slack) {
  if (channelId) return channelId;
  if (Date.now() - lastFailedAt < FAIL_COOLDOWN_MS) return null;
  if (resolving) return resolving;

  resolving = (async () => {
    let found = null, cursor, pages = 0;
    do {
      const page = await slack.conversations.list({ limit: 200, cursor, types: 'public_channel', exclude_archived: true });
      pages++;
      found = page.channels?.find(c => c.name === LOG_CHANNEL_NAME);
      cursor = found ? null : page.response_metadata?.next_cursor;
    } while (!found && cursor && pages < MAX_PAGES);

    if (!found) {
      lastFailedAt = Date.now();
      if (!warned) {
        warned = true;
        console.warn(`[pixl-logs] #${LOG_CHANNEL_NAME} not found within ${MAX_PAGES} pages of conversations.list — set the PIXL_LOGS_CHANNEL_ID env var to the channel ID to enable logging without scanning`);
      }
      return null;
    }

    channelId = found.id;
    if (!found.is_member) {
      try { await slack.conversations.join({ channel: channelId }); } catch (_) {}
    }
    return channelId;
  })();

  try {
    return await resolving;
  } catch (e) {
    lastFailedAt = Date.now();
    throw e;
  } finally {
    resolving = null;
  }
}

async function logEvent(slack, text) {
  try {
    const channel = await resolveChannel(slack);
    if (!channel) return;
    await slack.chat.postMessage({ channel, text, unfurl_links: false });
  } catch (e) {
    const scope = e.data?.needed ? ` (missing scope: ${e.data.needed})` : '';
    console.error(`[pixl-logs] failed to log: ${e.data?.error || e.message}${scope}`);
  }
}

module.exports = { logEvent };
