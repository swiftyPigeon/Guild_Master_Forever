local ADDON, ns = ...

-- The guild's settings, read by every other file. Loaded right after Bootstrap.lua.

---------------------------------------------------------------------------
-- GUILD MASTER FOREVER SETTINGS (Phase 6 moves them to the setup screen). Every "CHANGEME_" below is a placeholder: no real character can carry
-- an underscore in its name, so each role it names stays empty (nobody has it) until it is
-- filled in. Names are exact, as the game writes them (Forever: "Firstname Surname").
---------------------------------------------------------------------------
ns.HOME_GUILD = nil                            -- the main guild's exact name; nil: the player's own guild (until the setup screen)
ns.NETWORK_TAG = nil                           -- the first word a network's guild names share (e.g. "Ironoak"); nil: one guild, no network
ns.GM_CHARACTER = nil                          -- the guild master, pinned by exact name; nil: rank 0 of the home guild (our roster)
ns.GM_REALM = nil                              -- a pinned guild master's realm group; nil: learned from their first message, see /gmf status
ns.GM_DISPLAY = nil                            -- the guild master's title on the lines and the crown; nil: the guild's word for it (Terms.lua, {leader})
ns.ALT_GUILD_NAME = nil                        -- the main guild's alt guild, one house with it (exact name); nil: none
ns.GM_ALT_CHARACTER = "CHANGEME_AltGuildMaster" -- its guild master: the guild master's alt (their title, not their powers)
ns.AUTHOR_CHARACTER = "CHANGEME_Author"        -- the addon keeper's character (open decision: keep the author tools or drop them) (the Workshop tab, bug reports, signed lists)
ns.REALM_GROUP = "CAMWOWUS2Realm5PvE"          -- the author's and Treasurer's realm group (e.g. "ClassicBetaPvP")
ns.TREASURER_CHARACTER = "CHANGEME_Treasurer"  -- the Treasurer (in the main guild)
ns.TREASURER_MAIL_CHARACTER = "CHANGEME_TreasurerMail" -- where dues and treasury mail go (any guild)
ns.TREASURY_OFF = true                        -- true turns the Treasury and Bank off (1.3.0: off in beta; on at launch, the Treasurer a guild rank)
ns.PVP_REALM = nil                            -- true: a PvP realm (the Board offers PvP flags); false: not; nil: guessed from the realm's name ("...PvP...")
ns.BLOCKED_GUILDS = {                          -- guilds cut off for good, whatever their name: exact names, e.g. ["Some Guild"] = true (never the guild master's)
}

-- Roles by rank in the home guilds (rank index 0 = guild master), read by ns.Role (Core.lua).
-- They decide who may send what, so every client of a network must hold the same values (Phase 5:
-- they travel in the join code). A role holds a rank by its index (`ranks`) or by a word in the
-- rank's name as the guild master wrote it (`rankName`, any case): { ranks = { 2 }, rankName = "recruit" }.
ns.ROLES = {
	officerMax = 1,                            -- ranks 1 to this are officers (rank 0 is the guild master)
	moderator = { ranks = {}, rankName = nil }, -- the officers always moderate; these ranks too
	recruiter = { ranks = {}, rankName = nil }, -- recruiters
	treasurer = { ranks = {}, rankName = nil }, -- the Treasurer by rank, besides TREASURER_CHARACTER
}
-- Officers (officers): the name most of the code knows the officers' last rank by.
ns.CAPTAIN_RANK = ns.ROLES.officerMax

---------------------------------------------------------------------------
-- The guild as the add-on sees it. Every file asks these, never the game's own functions, so
-- that a test copy's pretend guild can answer instead. The game's globals are never replaced:
-- that would reach Blizzard's UI and other add-ons.
---------------------------------------------------------------------------

-- Test copies only (install-test-mop.sh sets it; nil in a release): a pretend guild for a character
-- that has none, so every tab can be seen without one. { name = "Test Guild", rank = 0,
-- rankNames = { "Guild Master", "Officer", "Member" } }. The player holds `rank` (0 = guild master),
-- switched in game with /gmf testguild rank <n> (kept in ns.db.testGuildRank), or off and on again
-- (/gmf testguild off|on: a player in no guild); the roster is the
-- player plus one made-up offline member for each other rank. GUILD messages still need a real
-- guild: the server alone delivers them (Comm.lua asks the game's own IsInGuild for those).
ns.TEST_GUILD = nil

local function Copy()
	local t = ns.TEST_GUILD
	if type(t) ~= "table" or type(t.rankNames) ~= "table" or #t.rankNames == 0 then return nil end
	return t
end
-- The pretend guild, unless switched off for now (/gmf testguild off: the screen of a player in no guild).
local function Test()
	if ns.db and ns.db.testGuildOff then return nil end
	return Copy()
end
function ns.IsTestGuild() return Test() ~= nil end

function ns.TestGuildRank()
	local t = Test()
	if not t then return nil end
	local r = ns.db and tonumber(ns.db.testGuildRank) or tonumber(t.rank) or 0
	return math.max(0, math.min(#t.rankNames - 1, math.floor(r)))
end

local function IsPlayer(unit)
	if unit == "player" then return true end
	return type(unit) == "string" and UnitIsUnit ~= nil and UnitIsUnit(unit, "player") == true
end

-- The pretend roster, as GetGuildRosterInfo would give it: { name, rankIndex, level, class,
-- zone, online, classFile, guid }.
local function TestRoster(t)
	local rank = ns.TestGuildRank()
	local realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName() or ""):gsub("%s", "")
	local className, classFile = UnitClass("player")
	local rows = { { UnitName("player") .. "-" .. realm, rank, UnitLevel("player"), className,
		GetRealZoneText and GetRealZoneText() or "", true, classFile, UnitGUID and UnitGUID("player") } }
	for i = 0, #t.rankNames - 1 do
		if i ~= rank then
			local word = tostring(t.rankNames[i + 1]):gsub("[^%a]", ""):lower()
			rows[#rows + 1] = { "Test" .. word .. "-" .. realm, i, 60, className, "", false, classFile, nil }
		end
	end
	return rows
end

function ns.IsInGuild()
	if Test() then return true end
	return IsInGuild()
end
function ns.GetGuildInfo(unit)
	local t = Test()
	if t and IsPlayer(unit) then
		local r = ns.TestGuildRank()
		return t.name, t.rankNames[r + 1], r, nil
	end
	return GetGuildInfo(unit)
end
function ns.GetNumGuildMembers()
	local t = Test()
	if t then
		local n = #TestRoster(t)
		return n, 1, 1
	end
	return GetNumGuildMembers()
end
function ns.GetGuildRosterInfo(i)
	local t = Test()
	if t then
		local row = TestRoster(t)[i]
		if not row then return nil end
		local name, rank, level, class, zone, online, classFile, guid = unpack(row, 1, 8)
		return name, t.rankNames[rank + 1], rank, level, class, zone, "", "", online, 0, classFile,
			0, 0, false, false, 0, guid
	end
	return GetGuildRosterInfo(i)
end
function ns.GuildControlGetNumRanks()
	local t = Test()
	if t then return #t.rankNames end
	return GuildControlGetNumRanks()
end
function ns.GuildControlGetRankName(i)
	local t = Test()
	if t then return t.rankNames[i] end
	return GuildControlGetRankName(i)
end

-- /gmf testguild [rank <n>]: what the pretend guild is, or switch the player's rank in it.
function ns.TestGuildSlash(rest)
	local t = Copy()
	if not t then return ns.Print("No test guild: this is not a test copy.") end
	local word = tostring(rest or ""):lower()
	local n = word:match("^rank%s+(%d+)$")
	if word == "off" or word == "on" or n then
		ns.db.testGuildOff = word == "off" or nil
		if n then ns.db.testGuildRank = tonumber(n) end
		-- As when the game says our guild changed (Roster.lua, PLAYER_GUILD_UPDATE).
		ns.Roster.RequestScan(true)
		ns.Comm.CheckMembership()
		ns.Fire("DATA_CHANGED")
	end
	if ns.db.testGuildOff then
		return ns.Print("Test guild off: you are in no guild now. /gmf testguild on brings it back.")
	end
	local r = ns.TestGuildRank()
	ns.Print(("Test guild <%s>, rank %d (%s). /gmf testguild rank <0-%d> switches, off/on hides it; /reload if a tab still shows the old rank.")
		:format(t.name, r, t.rankNames[r + 1], #t.rankNames - 1))
end
