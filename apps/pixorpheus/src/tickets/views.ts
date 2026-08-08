import { app } from "../slack/app.js";
import { deleteTitlePrompt, createTicket } from "./service.js";
import { pendingTickets } from "./state.js";

function parseTitleModalMeta(raw: string): { msgTs: string; promptTs: string | null } {
  try {
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === "object") return { msgTs: parsed.msgTs, promptTs: parsed.promptTs || null };
  } catch (e) {}
  // Backwards compat: metadata used to be the bare msg_ts string
  return { msgTs: raw, promptTs: null };
}

app.view("title_modal", async ({ ack, body, view, client }) => {
  await ack();
  const { msgTs, promptTs } = parseTitleModalMeta(view.private_metadata);
  const title = view.state.values?.title_block?.title_input?.value?.trim() || null;
  await deleteTitlePrompt(msgTs, client, promptTs);
  const pending = pendingTickets.get(msgTs);
  if (!pending) return;
  await createTicket(pending.event, title, client);
});

app.view({ callback_id: "title_modal", type: "view_closed" }, async ({ ack, view }) => {
  await ack();
  const { msgTs, promptTs } = parseTitleModalMeta(view.private_metadata);
  await deleteTitlePrompt(msgTs, app.client, promptTs);
  const pending = pendingTickets.get(msgTs);
  if (!pending) return;
  await createTicket(pending.event, null, app.client);
});
