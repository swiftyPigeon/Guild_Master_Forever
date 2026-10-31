# Security

## Found a security problem? Please report it privately
If you find a way to get into a guild's hidden channel without being given the key, read or send
messages you shouldn't, pretend to be a guild master or officer, or break the add-on for other
players, please **don't post it in a public issue**. Report it privately instead:

**[Report a vulnerability](https://github.com/swiftyPigeon/Guild_Master_Forever/security/advisories/new)**
(GitHub: the repository's **Security** tab → **Report a vulnerability**). Only the maintainer sees it.

Helpful to include:
- the version of Guild Master Forever (`/gmf status`);
- what someone could do, and what they'd need first (be in the guild, hold the key, an edited add-on…);
- the steps to reproduce it, if you have them.

You'll get an answer as soon as possible. Once a fix is released, the report can be made public,
with credit to you if you'd like it.

Ordinary bugs (errors, things that look wrong) go to the public
[issues](https://github.com/swiftyPigeon/Guild_Master_Forever/issues), with the report from `/gmf bug`.

## What the add-on protects, and what it can't
- **The code is public on purpose.** The protection doesn't depend on hiding how it works: it
  depends on a random key each guild's add-on makes (never in the code) and on what the game's
  server guarantees (who sent a message, that guild messages reach only that guild, your own
  guild's roster).
- **The guild's channel is locked, not encrypted.** Anyone holding the key can read it, and a
  trusted member can always repeat what they read. After removing someone you don't trust, an
  officer types `/gmf key rotate` to move the guild to a new key.
- **Add-ons can't reach your account.** World of Warcraft keeps add-ons in a closed box: no add-on,
  this one or an edited copy, can touch your password, account, gold, items or files. The worst a
  flaw here could do is let someone read or disrupt the add-on's own chat.
- **Don't share anything in the add-on's chat** you wouldn't say in guild chat.

## Supported versions
Only the latest release on CurseForge gets fixes. Please update before reporting.
