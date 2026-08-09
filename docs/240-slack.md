---
title: Slack app guide
group: Guides
description: Since #pixl lives on Slack, a Slack bot or app is a genuinely good trial idea, and a lot of NPCs might ask for exactly this kind of thing.
---

# Slack app guide

Since #pixl lives on Slack, a Slack bot or app is a genuinely good trial idea, and a lot of NPCs might ask for exactly this kind of thing.

## Setting up your app

Head to [api.slack.com/apps](https://api.slack.com/apps) and create a new app. Slack will ask if you want to start from scratch or from a manifest, from scratch is fine for your first one. Pick the workspace you want to test in (your own test workspace, not the Hack Club Slack, while you're building).

## Bot tokens and scopes

Under OAuth & Permissions, add some scopes depending on what your bot needs to do. A few common ones:

- `chat:write` lets your bot post messages
- `channels:history` lets it read messages in channels it's in
- `commands` if you want slash commands
- `app_mentions:read` if you want it to respond when someone @s it

Install the app to your workspace and grab your Bot User OAuth Token, it starts with `xoxb-`. Keep this secret, don't commit it to GitHub.

## Actually running the bot

You'll want a small backend, Node with the `@slack/bolt` package is probably the easiest way in:

```javascript
const { App } = require('@slack/bolt');

const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
  socketMode: true,
  appToken: process.env.SLACK_APP_TOKEN
});

app.message('hello', async ({ message, say }) => {
  await say(`hey <@${message.user}>`);
});

app.start();
```

Socket mode is nice while you're building because you don't need a public URL yet, you can just run it on your own laptop.

## Where to host it

Once it works, throw it on Nest, the free Linux hosting Hack Club gives you. That way your bot stays online even when your laptop's closed.

## Trial ideas

A bot that tracks Hackatime stats and posts leaderboards, a bot that reminds people about chapter deadlines, a slash command that pulls a random trial, all of these are solid, real, shippable projects.
