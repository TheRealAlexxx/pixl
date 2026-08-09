# Pixorpheus

Slack bot for the [Pixl](https://hackclub.slack.com/archives/C0B5P4N0WHH) YSWS program. Built by Gabin and Alexxx. Handles tickets, talks in threads, remembers stuff about people, roasts on command. Basically acts like a teenager with admin access.

---

## Contents

- [Architecture](#architecture)
- [Slash Commands](#slash-commands)
- [Inline Commands (pixo:)](#inline-commands-pixo)
- [Thread Controls](#thread-controls)
- [AI System](#ai-system)
- [Smart FAQ](#smart-faq)
- [Auto-Close](#auto-close)
- [Ticket System](#ticket-system)
- [Style Listening](#style-listening)
- [Training Mode](#training-mode)
- [Dashboard](#dashboard)
- [Database](#database)
- [Env Vars](#env-vars)
- [Deployment](#deployment)

---

## Architecture

- `index.js`: the bot itself. Commands, events, AI, tickets, all of it.
- `dashboard.js`: separate Express server for the helper dashboard, has Slack OAuth login.
- `public/`: dashboard frontend, plain HTML/CSS/JS.
- `models.json`: OpenRouter model list.

Two separate processes, one shared Postgres DB. Bot runs on Bolt v4, dashboard runs on Express. Both need to be up for everything to work.

---

## Slash Commands

### Fun / utility

- `/pixl-ping`: latency check
- `/pixl-help`: command list
- `/pixl-joke`: random joke (JokeAPI)
- `/pixl-coinflip`
- `/pixl-fact`: random AI-generated fact
- `/pixl-urban [word]`: Urban Dictionary, AI-filtered so it doesn't post the truly awful ones
- `/pixl-ask [question]`: ask Pixorpheus something, publicly
- `/pixl-roast [@user]`: roast someone (or yourself), pulls from memory so it's personal
- `/pixl-remind [time] [message]`: reminder, supports `s`/`min`/`h`, max 24h
- `/pixl-countdown [time] [label]`: countdown that posts when it hits zero
- `/pixl-poll Question; Option1, Option2 [, 10min]`: emoji-reaction poll, optional auto-close time
- `/pixl-ship [description]`: announce something you shipped
- `/pixl-stats`: bot stats since last restart (pixelizations, replies, roasts, reminders)

### Pixl program

- `/pixl [@user] [size]`: pixelate a profile pic, only in Pixl channels, size 2-64 (default 8), react `:pixl-delete:` to remove it
- `/pixl-lastship [github_username]`: last approved Hack Club Ship for that GitHub user
- `/pixl-leaderboard`: who Pixorpheus knows the most about (most engaged people)

### Memory / knowledge

- `/pixl-mymemory [@user]`: see what's remembered about you (ephemeral), or mention someone to show it publicly
- `/pixl-helpstats`: ticket totals, open/resolved/etc

### Support team only

Needs to be a helper, an admin (`SLACK_ADMIN_USER_IDS`), or in the ticket channel.

- `/pixl-addhelper @user`
- `/pixl-removehelper @user`
- `/pixl-helpers`: list current helpers
- `/pixl-remember [fact]`: teach it a fact about the program, gets injected into every reply (Gabin can use this too)
- `/pixl-forget [number]`: delete a stored memory by number
- `/pixl-memories`: list stored server memories

---

## Inline commands (pixo:)

Typed inline, not slash commands. Only work where Pixorpheus is actually present (private channels or ones it's added to).

- `pixo:kawaii`: start listening mode, it starts collecting messages to learn how people write
- `pixo:notkawaii`: stop listening, processes what it collected and saves the style
- `pixo:kawaii?`: check if it's currently listening, shows channel + message count (ephemeral)
- `pixo:recap`: summarize the last 6 hours in the channel, ephemeral. `pixo:recap today` for since midnight, `pixo:recap 2h` for custom (min/h/d). In a thread, it recaps the thread instead.

Only one listening session at a time, starting a new one kills the old one.

Also: react `:pixl-delete:` to any Pixorpheus message and it deletes itself.

---

## Thread controls

Type anywhere in a thread:

- `PIXOSTOP`: mutes Pixorpheus in that thread until directly mentioned
- `PIXOSTART`: unmutes it

---

## AI system

### When it replies

- Someone says its name (`pixorpheus`, `pixo`, `pix`)
- Someone @mentions it directly
- It decides to jump in uninvited (~45% chance when there's a good opening, "chime mode")
- Someone DMs it

Messages get batched, 1.5s if mentioned, 8s if chiming, so it's not replying to every message in a fast-moving conversation.

### Models

- Main channel replies: `claude-sonnet-4-5` via OpenRouter
- DMs: `claude-haiku-4-5` via Anthropic SDK, with web search
- Utility stuff (chime decisions, memory extraction, search queries): `deepseek/deepseek-v4-pro` via OpenRouter
- Urban Dictionary filtering: same deepseek model

### Memory

It picks up on people over time:

- **Facts**: pulled from every conversation (name, projects, skills, interests, whatever). Up to 100 per person, stored in Postgres.
- **Personality traits**: extracted ~20% of the time (blunt, chaotic, enthusiastic, etc.)
- **Server memory**: facts set via `/pixl-remember`, injected into every reply
- **Style notes**: from the listening/training system below, also injected into every reply

All of this gets fed into the system prompt before every reply.

### Web search

Searches via Brave when a message needs current info, news, prices, recent releases, whatever. It decides on its own whether to search.

### Emojis

It knows and uses a big list of custom emojis where they fit contextually: `:wiltedrose:` `:yay:` `:loll:` `:sad-pf:` `:skulk:` `:noooovanish:` `:angy:` `:yesyes:` `:blobhaj_party:` `:shocked:` `:upvote:` `:lets-fucking-gooo:` `:huh3d:` `:thumbs-up:` `:3c:` `:byee:` `:hii:` `:nono:` `:hehehe:` `:awww:` `:alibaba-admire:` `:alibaba-grin:` `:cryign:` `:heavysob:` `:brokenheart:` `:nyan:` `:cat-gun:` `:isob:` `:sob-pray:` `:agadance:` `:cat-woah:` `:cat-heart:` `:communist:` `:eyes_wtf:` `:eyes_shaking:` `:eyes-out-of-head:` `:orpheus-love:` `:orpheus-baguette:` `:orphanage:` `:orpheus-explode:` `:hyper-dino-wave:` `:pepedyingoflaughter:` `:pet-gabin:` `:pet-ridit:` `:pet-maxx:` `:yapa:` `:yay-gay:` `:wagay:` `:gay-flag:` `:bhjflag_gay:` `:spinny_cat_gay:` `:1984:`

Can also react with these, it decides when it makes sense.

### Other stuff it does

- Auto-replies "thx orphan" whenever Orpheus bot posts in the same channel
- Posts a random welcome when someone joins `#pixl`, pings Gabin in the thread
- Trained to text like an actual person: 2-8 words, most of the time

---

## Smart FAQ

When someone posts in the help channel, it checks if the question's already been answered before a ticket even gets made.

1. Pulls the last 60 resolved tickets (title + description)
2. Uses DeepSeek to check for a semantic match against the new question
3. If it finds one, the user gets an ephemeral message with a link and a "View FAQ" button, before anyone even has to reply
4. Ticket still gets created either way, so a helper can follow up

Runs in parallel with ticket creation, doesn't slow anything down. English only for now (bot will ask you to switch if needed). Only surfaces high-confidence matches, vague similarity gets ignored.

---

## Auto-close

Tickets open 5+ days with no activity get closed automatically. Runs at startup and then every 24h.

Rule: ticket's been open 5+ days AND the last thread message is also 5+ days old. On close, it posts in the thread explaining why and tells the user to open a new one if it's still relevant. Ticket channel message updates to reflect resolved status.

---

## Ticket system

### Flow

1. User posts in the help channel, gets a 🤔 reaction, a "someone will be here soon!" thread reply with a Resolve button, and an ephemeral prompt asking for a title (Set title / Skip)
2. Title modal (optional): text input, max 100 chars. Skip or ignore for 3 minutes and it just creates the ticket without one.
3. Ticket shows up in the private ticket channel:
   - Status: `🔴 Open - not claimed` / `🟡 Claimed by @X` / `✅ Resolved by @X`
   - Buttons: Claim/Unclaim, Mark Resolved (or Reopen if closed)
   - Title (or first 80 chars of the message)
   - Author, quoted description, "View in Slack" link, ticket number

### Who can do what

| Where | Action | Who |
|---|---|---|
| Help thread | Mark resolved (button) | author, helpers, support team |
| Help thread | `?resolve` / `?close` | helpers |
| Help thread | `?faq` | helpers, posts FAQ link + resolves |
| Help thread | `?reopen` | helpers |
| Ticket channel | Claim/Unclaim | helpers, support |
| Ticket channel | Mark Resolved | helpers, support |
| Ticket channel | Reopen | helpers, support |
| Dashboard | Reply | helpers (shows as their name) |
| Dashboard | Mark Resolved | helpers |

Macros go as the first word in a thread reply (e.g. `?resolve`), the message auto-deletes after running.

Status changes update the ticket channel message and post a notification in the help thread. Reactions: 🤔 = open, ✅ = resolved.

---

## Style listening

Lets you train how Pixorpheus talks based on real conversation. Only works in channels it's already in.

1. `pixo:kawaii`: it confirms it's watching
2. Talk normally, it collects messages
3. `pixo:notkawaii`: processes and saves the style
4. From then on, style notes get injected into every reply

One session at a time, needs at least 5 messages to process. Check status anytime with `pixo:kawaii?`.

---

## Training mode

More explicit version of the above, only in the designated training channel (`TRAINING_CHANNEL`, hardcoded `C0BD7JSTQNM`).

- `pixo:child labor training`: start, watches every message
- `pixo:stop child labor training`: stop, processes and saves

Needs 5+ messages. Overwrites the previous style (same table as the listening system).

---

## Dashboard

Runs separately from the bot (`dashboard.js`). Live at https://dashboard.gabintavernier.com, DM Gabin on Slack for access.

Slack OAuth login, restricted to helpers (`helpers` table) and admins (`SLACK_ADMIN_USER_IDS`).

What's there:
- Stats: totals, open/resolved counts, longest open ticket
- Activity chart: created vs resolved over 30 days
- Leaderboard: top resolvers, all-time / this week / today
- Ticket list: search, filter by status, click into threads
- Thread view: read the full thread inline
- Reply: post to a ticket thread (shows under your name in Slack)
- Resolve: mark resolved right from the dashboard

Same Postgres DB as the bot. Resolving from the dashboard posts to the thread and updates the ticket channel message like normal.

---

## Database

Everything's created automatically on startup via `initMemoryTables()`, except `tickets` and `helpers`, those need to be made manually.

- `user_memory`: per-user facts (JSONB), up to 100 per person
- `user_personality`: per-user traits (JSONB)
- `program_memory`: server-wide facts injected into replies
- `polls`: active timed polls
- `style_memory`: speaking style notes (single active row)
- `helpers`: Slack IDs of support team
- `tickets`: all ticket records

### `tickets` columns

| Column | Type | Notes |
|---|---|---|
| `msg_ts` | TEXT (PK) | timestamp of original message |
| `ticket_msg_ts` | TEXT | timestamp of the ticket channel message |
| `description` | TEXT | full original message text |
| `title` | TEXT | optional |
| `status` | TEXT | `open` / `closed` |
| `opened_by_slack_id` | TEXT | |
| `claimed_by_slack_id` | TEXT | |
| `closed_by_slack_id` | TEXT | |
| `closed_at` | TIMESTAMP | |
| `last_msg_at` | TIMESTAMP | |
| `permalink` | TEXT | direct Slack link |
| `ticket_number` | INTEGER | auto-increment |

---

## Env vars

### Bot (`index.js`)

- `SLACK_BOT_TOKEN`: `xoxb-...`
- `SLACK_SIGNING_SECRET`
- `SLACK_HELP_CHANNEL`: where users post questions
- `SLACK_TICKET_CHANNEL`: private support channel
- `SLACK_FAQ_URL`
- `SLACK_ADMIN_USER_IDS`: comma-separated, bypasses helper checks
- `SLACK_USER_TOKEN`: `xoxp-...`, needed to delete macro messages
- `DATABASE_URL`
- `OPENROUTER_API_KEY`
- `ANTHROPIC_API_KEY`: for DM replies via Haiku + web search
- `BRAVE_SEARCH_KEY`
- `PORT`: default 3000

### Dashboard (`dashboard.js`)

- `SLACK_CLIENT_ID`
- `SLACK_CLIENT_SECRET`
- `DASHBOARD_URL`
- `SESSION_SECRET`
- `DASHBOARD_PORT`: default 4000

Also needs `DATABASE_URL`, `SLACK_BOT_TOKEN`, `SLACK_ADMIN_USER_IDS`.

---

## Deployment

Runs on Railway, two services sharing one Postgres DB:

- **Bot**: `node index.js`, auto-deploys on push to `main`
- **Dashboard**: `node dashboard.js`, same repo, different start command

Slack app needs these event subscriptions: `message.channels`, `message.groups`, `message.im`, `message.mpim`, `reaction_added`, `member_joined_channel`.

Plus the slash commands registered and pointed at the bot's URL. Both services need to be running for everything to actually work.