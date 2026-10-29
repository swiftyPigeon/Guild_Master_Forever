# Guild Master Forever

Guild tools for **WoW: Forever**: guild chats, layer hop, party gathering, map calls, an LFG board
and officer tools. Main command: **`/gmf`**.

Version **0.1.0**, for a single guild (networks of several guilds come in 0.2.0).
How to use it: **[GUIDE.md](GUIDE.md)**. What changed: [CHANGELOG.md](CHANGELOG.md).

## Install
Get it from [CurseForge](https://www.curseforge.com/wow/addons/guild-master-forever) (pick your
WoW: Forever install), then restart the game.

By hand: unzip the release so you get an `Interface/AddOns/GuildMasterForever/` folder in your
`World of Warcraft/_forever_/` install. **Don't use Code → Download ZIP** on GitHub: its folder name
is wrong and the game won't load it.

## Commands
| Command | What it does |
|---|---|
| `/gmf` | open the window |
| `/gmf status` | what the add-on detects (guild, channel, layer) |
| `/gmf privacy` | sharing switches (location, layer help, chats…) |
| `/gmf hop` | ask for an invite to another layer |
| `/gma`, `/gmo`, `/gml` | chats: everyone, officers, guild masters |
| `/gmf backup`, `/gmf restore` | save and restore settings as text |
| `/gmf bug` | copyable error report |

## Bugs and ideas
Please open an issue at https://github.com/swiftyPigeon/Guild_Master_Forever/issues.
For a bug, type `/gmf bug` in game (or open the window's help, then **Report a bug**),
press Ctrl+C and paste the whole report into the issue, with a line on what you were doing.

## Credits and licenses
- Guild Master Forever by SwiftyPigeon512, released under the MIT license (`LICENSE.txt`), which
  also carries the notice of the MIT-licensed add-on it is derived from.
- Libraries, each under its own license: HereBeDragons (BSD, `libs/HereBeDragons/LICENSE.txt`),
  CallbackHandler-1.0 (BSD, `libs/CallbackHandler-1.0/LICENSE-Ace3.txt`), LibStub (public domain),
  QREncode (BSD, notice in `libs/QREncode/qrencode.lua`).
