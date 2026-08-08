// Slack profile photos via users.info. Needs SLACK_BOT_TOKEN (users:read);
// silently does nothing without it so login never breaks.
export async function fetchSlackAvatar(slackId: string): Promise<string | null> {
  const token = process.env.SLACK_BOT_TOKEN;
  if (!token || !slackId) return null;
  try {
    const r = await fetch(
      `https://slack.com/api/users.info?user=${encodeURIComponent(slackId)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (!r.ok) return null;
    const json = (await r.json()) as {
      ok?: boolean;
      user?: { profile?: { image_512?: string; image_192?: string } };
    };
    if (!json.ok) return null;
    return json.user?.profile?.image_512 || json.user?.profile?.image_192 || null;
  } catch {
    return null;
  }
}

// A player's real name via Slack's own directory , used as a fallback when
// Hack Club Auth doesn't have a name on file for them (younger/incomplete
// accounts). Every player is a real Slack workspace member, so this is a
// better fallback than a generated "user_xxxx" placeholder.
export async function fetchSlackDisplayName(slackId: string): Promise<string | null> {
  const token = process.env.SLACK_BOT_TOKEN;
  if (!token || !slackId) return null;
  try {
    const r = await fetch(
      `https://slack.com/api/users.info?user=${encodeURIComponent(slackId)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (!r.ok) return null;
    const json = (await r.json()) as {
      ok?: boolean;
      user?: { real_name?: string; name?: string; profile?: { display_name?: string; real_name?: string } };
    };
    if (!json.ok) return null;
    const u = json.user;
    return u?.profile?.display_name || u?.profile?.real_name || u?.real_name || u?.name || null;
  } catch {
    return null;
  }
}
