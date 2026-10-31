# Guild networks: who will notice the security

**Status:** networks of several guilds are **planned for version 0.2.0**. Today's version (0.1.x)
is for a **single guild**, and nothing on this page changes how it works for you now. This page
explains, ahead of time, what joining a network will be like for different kinds of guilds, so you
can decide whether a network suits yours.

## The short answer
- **Most guilds will never use a network**, and none of this touches them.
- **Established guilds with regular players across play times** will barely notice the network's
  security.
- **Mass-invite guilds with a lot of turnover** will notice it most: new recruits wait a few days
  before they see the network's shared chat. That wait is on purpose: it stops someone joining a
  guild for a day just to see a whole network's chat.

## How a network will work, in plain words
- One guild master is the **network leader**. Other guilds join only when the leader (with one of
  their officers) **approves** them; a guild name that looks similar doesn't get anyone in.
- The network shares one **private channel**. Nobody types or sees its key: the add-ons pass it on.
- **New members wait** a few days (or until promoted past your lowest rank) before the network's
  channel opens for them. Your guild's own chat and tools work for them from day one.
- The key **changes on its own** from time to time (weekly by default), so anyone who left loses
  access. Anyone trusted who is online passes the new key on; after a change, the key in the window
  may stay grey for a minute or two.
- Guild masters compare a short **network code** with the leader once, when joining, to be sure the
  invite is genuine.

## Who notices what

| Kind of guild | What you'd notice | How much |
|---|---|---|
| **Single guild, no network** | Nothing. | ⚪ None |
| **Established "house" of guilds** (same name family), officers active | Compare the network code once; a short grey key now and then. | 🟢 Minimal |
| **Raiding / progression guild**, applicants only | Trials wait a few days for the network chat (they're usually on a trial rank anyway). | 🟢 Minimal |
| **Alliance of friendly guilds** (different names) | Compare the network code once; a second person clicks to approve. | 🟢 Low |
| **Casual / social guild**, many people online | A short grey key after a key change, filled quickly by whoever is online. | 🟢 Low |
| **Lowest rank is "Alt"** | Your alts won't get the network chat until you change one setting. | 🟡 Until set |
| **Small guild** (5–20 people, officers rarely online) | A member back from a break may wait for the key; approvals can take longer. | 🟡 Medium |
| **Guild master only, no officers** | Two-person approval can't work until switched off. | 🟡 Until set |
| **Network whose leader is often away** | Approvals wait; taking over from a vanished leader takes days. | 🟠 High |
| **Big network** (8+ guilds) | More work for the leader: approvals, officer lists, key changes. | 🟠 High (for the leader) |
| **Open recruiting / mass invites**, high turnover | **Every recruit waits** for the network chat. | 🔴 Highest |

```
LEAST NOTICE ◄──────────────────────────────────────────────► MOST NOTICE

Single  House     Raid/    Friendly  Casual  "Alt"   Small   GM-only  Away     Big      Open
guild   network   progress alliance  social  rank    guild   guild    leader   network  recruiting
 ⚪       🟢        🟢        🟢        🟢       🟡      🟡       🟡       🟠       🟠        🔴
```

## How common is each kind? (rough)
Blizzard doesn't publish guild types, so these are rough figures from published WoW research
(retail WoW, 2006–2008) plus our own estimates. Take them as a sense of scale, not exact numbers.

- **Most guilds will stay single guilds**: likely 90% or more (our estimate; alliances are the exception).
- **Most players are in casual or in-between guilds**: about 52% casual, 42% in-between, 6% serious;
  about half of players were in guilds that raid at some level ([Nick Yee][yee]).
- **Most guilds are small**: about 90% of players were in guilds of 35 or fewer ([Ducheneaut and
  others, cited here][duch]); about a quarter in guilds of 10 or fewer ([Yee][yee]).
- **Turnover is high**: 64% of players had been in their guild a year or less ([Yee][yee]), and many
  guilds don't last long, often because leaders run out of time ([Mein-MMO][mein]).
- **At a fresh launch** there are many more mass-invite leveling guilds than later on, so the
  first weeks are when the waiting period matters most.

So by number of guilds, the middle of the chart (small guilds, "Alt" ranks, guild-master-only)
is the big group, and good settings matter most there. By number of players, most people are in
the green rows.

## Tips to keep it smooth
- **Mass-invite guilds:** set the waiting period short (1–2 days) and promote recruits you know.
  Recruits see a message explaining when the network chat opens for them.
- **"Alt" as the lowest rank:** let the "Alt" rank get the network key, and make "Trial" (or
  similar) your lowest rank instead.
- **Small guilds:** trusted members pass new keys on, not only officers, so it rarely matters who
  is online.
- **Guild master only:** switch two-person approval off for your guild.
- **Network leaders:** name an active **deputy**, keep the officer list current, and post the
  network code where your guilds can check it (your Discord, for example).
- **Any guild master** can always leave a network and go back to a single guild with a fresh key.

## Limits, said plainly
The network's channel is locked, not encrypted: anyone who holds the key can read it, and a trusted
member can always repeat what they read. Removing someone and changing the key keeps that window
short.

Questions or ideas: [GitHub issues](https://github.com/swiftyPigeon/Guild_Master_Forever/issues).

[yee]: https://nickyee.com/daedalus/archives/print/001635.php
[duch]: https://arxiv.org/pdf/1112.4915
[mein]: https://mein-mmo.de/en/wow-profigilden-sterben-ist-normal,141681
