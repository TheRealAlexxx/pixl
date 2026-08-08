import { app } from "../slack/app.js";
import { db } from "../db/client.js";
import { checkIsHelper, checkIsInTicketChannel } from "../tickets/service.js";

app.command("/pixl-addhelper", async ({ command, ack, respond, client }) => {
  await ack();
  const requesterId = command.user_id;
  const isAdmin = await checkIsHelper(requesterId);
  const isInTicketChannel = await checkIsInTicketChannel(requesterId, client);

  if (!isAdmin && !isInTicketChannel) {
    await respond({
      text: "Only support team members can add helpers. To bootstrap, add your Slack user ID to `SLACK_ADMIN_USER_IDS`.",
    });
    return;
  }

  const mention = command.text?.trim();
  const userId = mention?.match(/<@([A-Z0-9]+)(?:\|[^>]+)?>/)?.[1] || mention;

  if (!userId) {
    await respond({ text: "Usage: `/pixl-addhelper @username`" });
    return;
  }

  try {
    await db()
      .from("helpers")
      .upsert({ slack_user_id: userId }, { onConflict: "slack_user_id", ignoreDuplicates: true });
    await respond({ text: `<@${userId}> is now a helper.` });
  } catch (e) {
    await respond({ text: "Failed to add helper." });
  }
});

app.command("/pixl-removehelper", async ({ command, ack, respond, client }) => {
  await ack();
  const requesterId = command.user_id;
  const isInTicketChannel = await checkIsInTicketChannel(requesterId, client);
  const isHelper = await checkIsHelper(requesterId);

  if (!isHelper && !isInTicketChannel) {
    await respond({ text: "Only support team members can remove helpers." });
    return;
  }

  const mention = command.text?.trim();
  const userId = mention?.match(/<@([A-Z0-9]+)(?:\|[^>]+)?>/)?.[1] || mention;

  if (!userId) {
    await respond({ text: "Usage: `/pixl-removehelper @username`" });
    return;
  }

  await db().from("helpers").delete().eq("slack_user_id", userId);
  await respond({ text: `<@${userId}> is no longer a helper.` });
});

app.command("/pixl-helpers", async ({ ack, respond }) => {
  await ack();
  const { data: rows } = await db().from("helpers").select("slack_user_id");
  if (!rows?.length) {
    await respond({ text: "No helpers registered yet." });
    return;
  }
  await respond({
    text: `*Current helpers:*\n${rows.map((r) => `• <@${r.slack_user_id}>`).join("\n")}`,
  });
});

app.command("/pixl-helpstats", async ({ ack, respond }) => {
  await ack();
  const [{ count: total }, { count: open }, { count: closed }] = await Promise.all([
    db().from("tickets").select("*", { count: "exact", head: true }),
    db().from("tickets").select("*", { count: "exact", head: true }).eq("status", "open"),
    db().from("tickets").select("*", { count: "exact", head: true }).eq("status", "closed"),
  ]);
  await respond({
    text: `*Ticket Stats*\n• Total: ${total ?? 0}\n• Open: ${open ?? 0}\n• Resolved: ${closed ?? 0}`,
  });
});
