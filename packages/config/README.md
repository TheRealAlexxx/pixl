# @pixl/config

`pixl.json` is the one place the program's facts live: the name, the launch date,
the canonical URLs, the Slack channel, the economy rates. Change it here and
every app picks it up.

## Consuming it

**TypeScript apps** (`server`, `dashboard`, `landing`, `pixorpheus`) import the
package directly, so they can never drift:

```ts
import { config, launchDate, hackatimeCutoffUnix } from "@pixl/config";
```

**The Godot game** (`res://pixl.json`) and **the game's web pages**
(`apps/game/web/pixl.js`) cannot import a workspace package - one runs inside an
exported PCK, the other is plain `<script>`-tag JS. Both get a *generated copy*
instead, written by the sync script:

```bash
bun run config:sync
```

Run that after editing `pixl.json`. It rewrites:

- `apps/game/pixl.json` - read by `apps/game/scripts/pixl_config.gd`
- the generated block inside `apps/game/web/pixl.js` - exposed as `Pixl.config`

Both are committed (the game needs them at runtime) but are **generated - do not
hand-edit them**, the next sync overwrites your changes.

## Dates

Every timestamp here is UTC and ISO-8601. Parse it as an instant, not a local
wall-clock time - `new Date("2026-08-18T00:00:00")` without the `Z` means
midnight *in the reader's timezone*, which is a different moment for every
player and is exactly the bug this file exists to prevent.

`hackatimeCutoff` is deliberately its own field rather than an alias for
`launchDate`: it is the moment coding time starts counting toward shipping, and
there are good reasons to want it to differ from the launch moment later.
