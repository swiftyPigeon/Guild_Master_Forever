# Changelog

## 0.1.1

**Security fix: each guild's channel key now stays with that guild.**
Guild Master Forever saves its settings for your whole account, one set per realm. Before this fix,
the guild's channel key was saved the same way, so it followed your characters instead of your guild:
- an **alt in a different guild** on the same realm used your first guild's key and joined its
  hidden channel; as an officer, that alt could even hand the key to its own guild;
- a player who **left for another guild** kept the old key, and their add-on told the new guild
  "I hold a key", so the new guild never made a key of its own.

Now each guild's key belongs to that guild alone. In another guild your character gets that guild's
own key (or none until an officer hands it out); back in your first guild, its key comes back; with
no guild, no key is held.

Old keys don't pile up: once none of your characters on the realm is in a guild any more, that
guild's saved key is forgotten. A character who joins another guild lets go of the old guild's key
at once; one left with no guild keeps it 3 more days; one you haven't played for 90 days no longer
keeps its guild's key (if you play it again, the guild hands the key out again).

Nothing to type. After the update, each character lets go of the key 0.1.0 saved (it can't tell
which guild that key came from) and gets its guild's key again from an officer online; if no
officer holds one, the first officer online makes a new one. For a minute or two after logging in,
the key in the window's header stays grey, then turns gold.

New page: **NETWORKS.md** explains ahead of time how networks of guilds (coming in 0.2.0) will
work and which kinds of guilds will notice their security. Nothing changes for single guilds.

New page: **SECURITY.md**: found a security problem? Report it privately on GitHub (Security tab →
Report a vulnerability), not in a public issue.

Tip for officers: after removing a member you don't trust, type `/gmf key rotate` so the guild moves
to a new key they never had.

## 0.1.0 (first release)

The first public version of Guild Master Forever, for **WoW: Forever**, for a **single guild**:
everyone in your guild who installs it shares the same tools, with no files to edit.

**For every member**
- **Guild chats** (`/gma`, officers `/gmo`) with a Chat tab, mentions (`@name`) and cards beside
  the minimap.
- **Layer hop** to the guild master's layer (`/gmf hop`), and layer help between guildmates.
- **Parties:** Gather Party and Party Call for solo guildmates in your zone.
- **Map calls:** Rare Call on a rare enemy, Gathering, Leader Call, Assemble the Loyal.
- **The Board:** raise a flag for a dungeon, raid or layer; share a camp on the map; the guild's week
  with signups.
- **Crafters:** your professions listed when you open them; ask who can make an item.
- **Census** of your guild online by zone, **Tabards** (who wears the guild tabard, guildmates
  nearby), **Polls**, Hold Court, letters from the guild master, loot notes and points.
- **Privacy first:** nothing optional is shared until you say Yes (`/gmf privacy`).

**For officers and the guild master**
- **Guild setup** (`/gmf setup`): pick which ranks are officers, moderators and recruiters; saved
  once, sent to every guildmate.
- **Sealed guild channel**, automatic: the first officer online makes a random key nobody sees.
- Officer musters, the zone gather, inactive members, gear checks, helpers named by the guild master,
  pinned lines, add-on versions of your guild.

**Not yet:** networks of several guilds (planned for 0.2.0); the Treasury and guild bank (switched
off until they're reviewed); Discord Link.

**Bugs and ideas:** `/gmf bug`, then paste the report in a new issue at
https://github.com/swiftyPigeon/Guild_Master_Forever/issues
