import { app } from "../slack/app.js";
import { RIDIT_ID, PIXL_MAIN_CHANNEL, RIDIT_CHANNEL } from "../constants.js";
import { botIdentity } from "../slack/identity.js";
import { welcomeThreads } from "./thread.js";
import { hasLaunched } from "../config.generated.js";

// Two sets, picked at send time by the launch date in packages/config — no
// code change needed on launch day. PIXL_WELCOME_MSGS_LAUNCHED used to be dead
// code nobody remembered to swap in.
export const PIXL_WELCOME_MSGS_LAUNCHED = [
  "yo welcome to <#C0B5P4N0WHH> !! go ship something and earn your first pixels :pixel_heart:",
  "welcome !! pixl is a retro 2D world where you level up by building real stuff - go crazy :yay:",
  "heyy welcome :hyper-dino-wave: start shipping projects and you'll earn pixels to unlock prizes and funding fr",
  "welcome to pixl !! it's basically a game where you build real things and get rewarded for it — idk it slaps :sm_slap:",
  "oh a new one :eyes_shaking: welcome !! go check out the sidequests and start shipping, that's literally how this works",
];

export const PIXL_WELCOME_MSGS = [
  "yo welcome to <#C0B5P4N0WHH> !! we haven't launched yet but it's coming SOON, you're early :pixel_heart:",
  "welcome !! pixl is a retro 2D world where you level up by building real stuff — not launched yet but launching soon, stay tuned :yay:",
  "heyy welcome :hyper-dino-wave: pixl hasn't launched yet but it drops soon — you're getting in before everyone fr",
  "welcome to pixl !! it's a game where you build real things and get rewarded for it — launching soon, you picked the perfect time to show up :sm_slap:",
  "oh a new one :eyes_shaking: welcome !! pixl isn't out yet but launch is coming soon — hang around, you'll be first in line",
];

export const RIDIT_CHANNEL_MSGS = [
  ":sho: welcome to <#C0BHLGJ7YBA> !! we all yap here :neocat_hug:",
  "yoooooo we got another yapper!! :yay:",
  "another certified professional yapper has arrived :yay:",
  "grab a seat and start yapping :3",
  "welcome!! we hope you like pings :sob:",
  "the chat just got 0.1% funnier :catjam:",
  "welcome!! the floor is yours :microphone:",
];

app.event("member_joined_channel", async ({ event, client }) => {
  if (event.channel !== PIXL_MAIN_CHANNEL && event.channel !== RIDIT_CHANNEL) return;
  if (event.user === botIdentity.userId) return;

  try {
    const pixlMsgs = hasLaunched() ? PIXL_WELCOME_MSGS_LAUNCHED : PIXL_WELCOME_MSGS;
    const messages = event.channel === RIDIT_CHANNEL ? RIDIT_CHANNEL_MSGS : pixlMsgs;

    const msg = messages[Math.floor(Math.random() * messages.length)];

    const posted = await client.chat.postMessage({
      channel: event.channel,
      text: `<@${event.user}> ${msg}`,
    });

    welcomeThreads.add(posted.ts!);

    const ccText = event.channel === PIXL_MAIN_CHANNEL ? `cc <!subteam^S0BFM30573R>` : `cc <@${RIDIT_ID}>`;

    await client.chat.postMessage({
      channel: event.channel,
      thread_ts: posted.ts,
      text: ccText,
    });
  } catch (e: any) {
    console.error("welcome error:", e.message);
  }
});
