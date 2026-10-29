# Guild Master Forever: player guide

Guild tools for **WoW: Forever**, for your whole guild: guild chats, layer hop, party gathering,
map calls, a group-finding Board, crafters, polls, and tools for officers and the guild master.
Everyone in the guild who installs it gets the same tools; nothing has to be edited by hand.

> **Words in this guide.** The add-on calls the roles **Guild Master**, **Officers**,
> **Moderators**, **Recruiters** and **Helpers**, and the tabs **Census**, **Guild**, **Calls**,
> **Tabards**, **Leader** and **Polls**. Commands start with `/gmf`.

---

## Start here (five minutes)

1. **Install** from the CurseForge app (search *Guild Master Forever*, game version *WoW: Forever*),
   then **restart the game** (not just `/reload`).
2. **Log in** on a character in your guild.
3. **Answer the privacy page** that opens. Each line stays off until you say **Yes**. For layer hop,
   say Yes to **Your zone and layer** and **Help others join your layer**.
4. **Open the window:** `/gmf`, the minimap button, or **Shift-J**.
5. **Guild master:** the **Guild setup** window opens once by itself. Tick which ranks are officers,
   moderators and recruiters, then **Save** (details in [For the guild master](#for-the-guild-master)).

Then try these:

| Try this | How |
|---|---|
| **Talk to your guild** | `/gma hello!`, or `/gma` alone for the **Chat** tab |
| **Jump to the guild master's layer** | go to their zone, then the swirling portal on the **Guild** tab (`/gmf hop`) |
| **Get a party going** | **Calls** tab → **Gather Party**, or **Party Call** so solo guildmates get a Join button |
| **Find a group** | **Guild** → **Board** → **Raise a flag** (dungeon, raid or layer) |
| **Share your camp** | light a campfire and click **Share camp**: it shows on your guildmates' maps |
| **Find a crafter** | **Guild** → **Crafters** → **Ask who can make an item...** |
| **Help a lower-level guildmate** | **Tabards** → **Guildmates nearby** |
| **Call a rare** | target a rare enemy, then **Calls** → **Rare Call** |
| **See your week** | **Guild** → **Your week** (or `/gmf brief`) |

Stuck? `/gmf help` lists every command in chat, and `/gma help` lists the chat ones.

---

## Who is who

The add-on gives tools by **rank position** in your guild, not by rank name. Renaming a rank changes
nothing; moving ranks around does (the add-on then asks the guild master to check the setup).

| Role | Who | Gets |
|---|---|---|
| **Guild Master** | your guild's leader (rank 0) | everything, the **Leader** tab and the setup |
| **Officers** | rank 1 by default; the setup can make more ranks officers | the officers' chat, Gathering, the zone gather, musters, loot notes, gear checks |
| **Moderators** | officers, plus any rank the setup ticks | help requests, hiding a player from the add-on, the shared word filter |
| **Recruiters** | ranks the setup ticks | join requests from players without a guild come to them first |
| **Helpers** | players the guild master names on the **Leader** tab | polls, the agenda, pinned lines, the zone gather, in the guild master's name |
| **Members** | everyone | everything in [For everyone](#for-everyone) |

---

## For everyone

### The window
- **Header:** how many members are online with the add-on. The small **key** is **gold** when your
  add-on is on your guild's sealed channel and **grey** while it is still joining.
- **Census:** your guild's members online and where they are, by zone and continent. Column titles
  sort the list. A line ending in **i** has more to say: hover it.
- **Guild:** the leaders and officers, ranks, layers, the **Board**, **Your week**, **Crafters**,
  **Officer musters** and **Raid Loot**.
- **Calls:** the map calls and party buttons, with a **cog** for sounds and party settings.
- **Tabards:** who wears the guild tabard, and guildmates near you.
- **Chat:** the guild chats, with a box to write in.
- **Help** (the button left of the X): what each tab is for, the privacy switches, the links and
  **Report a bug**.

### Layer hop
- **Join the guild master's layer:** while they show their crown, go to their zone and click the
  **swirling portal** next to the search box on the **Guild** tab (or `/gmf hop`).
- A guildmate on that layer invites you, the game moves you to their layer, and the add-on takes you
  out of the group again.
- **Help others:** `/gmf layerhelp on` lets guildmates ask you for an invite to your layer;
  `/gmf layerauto on` invites them without a window.
- Your layer is read from nearby NPCs: target or mouse over an NPC if the add-on doesn't know it yet.

### Parties
Party invites from guildmates are **on by default**; auto-join is off until you turn it on. Both
switches are behind the **cog** on the **Calls** tab, on the privacy page, and in commands.

| Want to... | Do |
|---|---|
| Gather a party (up to 5) of solo guildmates in your zone | **Calls** → **Gather Party**, or `/gmf party gather` |
| Tell solo guildmates nearby you're forming a party | **Calls** → **Party Call**, or `/gmf party call <note>`: they get a **Join** button |
| Stop (or allow) guildmates inviting you when you're solo | `/gmf party off` / `on` |
| Join those invites without the popup | `/gmf partyauto on` |

- Each click shows what happens: who is invited, how many can answer, or why nobody can.
- Invites go one at a time: same layer first, then the closest level.
- Nobody is invited in a dungeon, in combat, while Busy (`/dnd`), or when already grouped.
- A Party Call can go out once every 2 minutes.

### Map calls (Calls tab)
- **Rare Call:** any member targets a **rare** (or tougher) enemy and calls (`/gmf rare`, or the
  button). A **skull** shows on the map; members in that zone or the next one get an alert. The skull
  goes when the target dies, or after 5 minutes.
- **Gathering:** officers and moderators call everyone to a spot (a run, a raid, a guild event).
- **Leader Call:** an announcement from the guild master or the officers, on a parchment scroll.
- **Assemble the Loyal:** tabards on, gather here (from the **Tabards** tab).

All current calls are on the **Calls** tab (`/gmf calls`). **Officer musters** are quieter: no
sound, no alert and no map pin. They're listed under **Guild** → **Officer musters** (`/gmf musters`)
for 20 minutes.

### Chat
| Type | To |
|---|---|
| `/gma <text>` | your guild (everyone with the add-on) |
| `/gmo <text>` | officers |
| `/gma` alone | opens or closes the **Chat** tab (also `/gmf talk`, or Shift-click the minimap button) |
| `/gmf mute guild` / `officers` | hide or show that channel in your chat window |
| `/gmf chatwindow tab` | the chats in a chat tab named **Guild Master** (make that tab first: right-click a chat tab, Create New Window) |

These chats are **not private**: never type passwords or secrets there.

**Mentions.** Type `@` and the start of a name in the Chat tab's box to pick a guildmate. When a line
names you, a small card slides out beside the minimap (it waits while you're in a dungeon or Busy),
and the minimap button shows a red count until you've read it. The **@** button on the Chat tab lists
your last mentions. Turn the cards off with `/gmf mentions off`.

### When the guild master asks something
- **Polls:** a window pops up: tick your answer. Prefer chat only? `/gmf polls off`.
- **Hold Court:** when the guild master holds court, a line appears if you're in their zone. Click it
  to ask to speak with them. If they call you with a note, it stays in your log (`/gmf log`).
- **Summon:** a roll call for officers; answer **Present** or **Busy**.
- **Letters:** the guild master's letters, on parchment. Officers click **Acknowledge**.

### Groups, crafting and more
| Want to... | Do |
|---|---|
| Find a group | **Guild** → **Board** → **Raise a flag**: a dungeon, a raid or a layer (PvP on PvP realms), with a note. **Lower my flag** takes it down. Or `/gmf lfg dungeon` / `/gmf lfg off` |
| Share a camp | light a campfire and click **Share camp**, or **Board** → **Drop a camp** (`/gmf camp [note]`). It needs your zone shared. **Take down my camp** removes it |
| See the guild's week | `/gmf week`: events and their signups. **Your week** on the **Guild** tab, or `/gmf brief`, sums up yours in five lines |
| Find a crafter | **Guild** → **Crafters** → **Ask who can make an item...**, or `/gmf craft <item>`; click a crafter to whisper them or see their recipes |
| List your professions | open a profession and it's listed. The round button in the profession window's title bar (left of the X) lists or unlists that one; **Go private** on the Crafters page takes you off |
| Link your alts | `/gmf alt add <name>` on your main, then log in on the alt and confirm. Linked alts count once |
| Help a lower-level guildmate | **Tabards** → **Guildmates nearby**: guildmates below your level in your zone, nearest first |
| See loot decisions | `/gmf loot`: your officers' notes on who got what, and any points |
| Ask the moderators for help | `/gmf helpme <question>` |

### Tabards
The **Tabards** tab celebrates who wears the guild tabard; nobody is listed for not wearing it.
**Loyalists** are guildmates seen in the tabard on 3 different days or more. What it shows is what
your own add-on saw around you; nothing is sent.

### Quiet and privacy
| Want to... | Do |
|---|---|
| Change what you share | `/gmf privacy` |
| Silence alert sounds | `/gmf sound off`, or one kind: `/gmf sound rare off` |
| Hold alerts in dungeons and while Busy | on by default (`/gmf alerts quiet`) |
| Ignore a player's add-on messages | `/gmf block <name>` (`/gmf unblock <name>`) |
| Hide lines with a word | `/gmf filter add <word>` |
| Turn the guild chats off on this character | `/gmf chat off` |
| Hide the minimap button | `/gmf minimap` |
| Back up your settings | `/gmf backup` copies them as text; `/gmf restore` pastes them back |

### Something's wrong?
1. `/gmf status` shows what the add-on sees (your guild, the channel, your layer).
2. `/gmf bug` opens a **bug report** (also **Help** → **Report a bug**). Press **Ctrl+C**, then open a
   new issue at **https://github.com/swiftyPigeon/Guild_Master_Forever/issues**, paste the report and
   add a line on what you were doing. The report never contains your guild's channel key.

| You see | It means |
|---|---|
| A grey key in the header | your add-on is still joining your guild's channel: an officer online hands it the key |
| *"Guild Master Forever 0.2.0 is out and you have 0.1.0..."* | a newer version is out: update in the CurseForge app, then restart the game |
| *"Rebuilding the census..."* | normal for a few minutes after login |

---

## For officers

Everything above, plus:

| Want to... | Do |
|---|---|
| Talk to the officers | `/gmo <text>` |
| Call a Gathering | `/gmf gather <note>`, or **Calls** → **Gathering**. Add `test` for a preview only you see |
| Invite every solo guildmate in the zone | **Calls** → **Gather the zone**, or `/gmf party zone` (past five, you're asked to make it a raid) |
| Call a quiet muster to your zone | **Guild** → **Officer musters** → **Call a muster**, or `/gmf musters` (20 minutes, no alert) |
| Call the guild together in tabards | **Assemble the Loyal** on the **Tabards** tab |
| See who's been away | `/gmf inactive 7` (or 14, 30). Removing someone asks first, one per click |
| Check a player's gear | target them in range, then `/gmf gear` |
| Write loot decisions and points | **Guild** → **Raid Loot** (`/gmf loot`): click a drop, pick who gets it and why |
| Answer recruits | a recruit's request shows **Invite** and **Decline** buttons |

**The guild's channel is sealed automatically.** The first officer online makes a random key nobody
sees, and the add-on hands it to guildmates over guild chat. If you think it leaked, `/gmf key rotate`
makes a new one and moves the guild to it.

**Moderators** (officers, and any rank the setup adds) also get help requests (`/gmf helpme`), can
hide a player from every add-on screen (`/gmf netoff <name>: <reason>`, `/gmf neton <name>`) and keep
the shared word filter.

---

## For helpers

The guild master names you on the **Leader** tab (**Helpers** button). You then see the **Leader**
tab and can, in their name:

| Tool | Where |
|---|---|
| **Polls** | the **Polls** tab |
| **Agenda** (events on the guild's week, e.g. `Sat 20:00 Raid night`) | **Agenda** on the **Leader** tab |
| **Pin a line** for every member, 2 hours | `/gmf pin <text>`; `/gmf pin off` |
| **Hide a player** from add-on screens | `/gmf netoff <name>: <reason>` |
| **Gather the zone** | **Calls** → **Gather the zone** |

---

## For the guild master

Everything above, plus the **Leader** tab and the setup.

### First steps
1. **Guild setup** (`/gmf setup`; it opens once by itself). Each of your guild's ranks is a row:
   - **Officer:** tick the lowest officer rank; every rank above it is an officer too, and officers
     always moderate.
   - **Moderator** and **Recruiter:** tick any ranks.
   - **Alt guild** (optional): the exact name of your guild's alt guild, if it has one.

   **Save** sends the setup to every guildmate with the add-on; officers and members can open it to
   read it. If you later rename, add or move ranks, the add-on reminds you to check it and Save again.
2. **Name your helpers:** **Leader** tab → **Helpers**.
3. **Show your crown** on the map (the **Leader** tab), so members can find you and hop to your layer.
   On your layer and not in a group, the add-on may offer to invite the guildmates who want to join it.

### Your tools
| Tool | What it does |
|---|---|
| **Hold Court** (**Leader** tab) | members in your zone queue to speak with you; you call them one by one, with an optional note |
| **Letters** (**Write a letter**) | a letter on parchment to the officers or to everyone; you see how many acknowledged |
| **Polls** | quick polls, 2 to 6 answers |
| **Agenda** | dated events on the guild's week, with signups |
| **Leader Call** | a free-text announcement shown to every member |
| **Gather the zone** | invites every solo guildmate in your zone who takes party invites |
| **Thank the Loyal in guild chat** (**Tabards**) | names your Loyalists in guild chat, with thanks for wearing the colors |
| **Add-on versions** (**Leader** tab) | who is up to date and who is behind; click one to ask them to update |
| **Key rotation** (`/gmf key rotate`) | a new channel key nobody sees |

---

## Not in this version
- **Networks of several guilds** (guilds whose names share a word, joined by a code): planned for
  0.2.0. Until then each guild runs on its own.
- **Treasury and guild bank:** built, but switched off until they're reviewed.
- **Discord Link:** off.

## Quick reference
| Command | Who | What |
|---|---|---|
| `/gmf` | all | open or close the window (`/gmf open`, `/gmf close`) |
| `/gmf help` | all | every command, in chat |
| `/gmf status` | all | what the add-on sees |
| `/gmf privacy` | all | sharing switches |
| `/gmf setup` | guild master (others read it) | ranks for officers, moderators and recruiters |
| `/gmf hop` | all | an invite to the guild master's layer |
| `/gmf layerhelp on` / `layerauto on` | all | let guildmates ask you for invites / without a window |
| `/gma` / `/gmo` | all / officers | chats |
| `/gmf calls` | all | the Calls tab |
| `/gmf rare [note]` | all | Rare Call (a rare or tougher enemy targeted) |
| `/gmf gather [note]` | officers, moderators | Gathering |
| `/gmf party gather` / `call` / `zone` | all / all / officers, moderators, helpers, guild master | gather a party / Party Call / the whole zone |
| `/gmf party on/off`, `/gmf partyauto on/off` | all | party invites when solo; join without the popup |
| `/gmf polls on/off` | all | polls in a window, or in chat only |
| `/gmf lfg ...`, `/gmf week`, `/gmf brief` | all | the Board, the guild's week, your week |
| `/gmf camp [note]` / `off` | all | drop your camp / take it down |
| `/gmf craft <item>` | all | who can make it |
| `/gmf tabard` | all | the Tabards tab |
| `/gmf alt add <name>` | all | link an alt |
| `/gmf loot` | all (officers write) | loot notes and points |
| `/gmf helpme <text>` | all | ask the moderators |
| `/gmf pin <text>` | guild master, helpers | pin a line for 2 hours |
| `/gmf netoff <name>: <reason>` | guild master, helpers, moderators | hide a player from add-on screens |
| `/gmf key rotate` | officers | a new channel key |
| `/gmf inactive 7` | officers | members away that long |
| `/gmf musters` | all | officer musters |
| `/gmf letters` | all | what's new in each version |
| `/gmf hotkey on/off` | all | the Shift-J shortcut |
| `/gmf bug` | all | a bug report for a GitHub issue |
