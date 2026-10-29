local ADDON, ns = ...
local L = ns.L

-- The Leader tab: a tab for the leader alone (the guild master of the guild named exactly
-- the home guild of their faction, and that very character where the addon knows them by name,
-- ns.KING_CHARACTER), and for the helpers they name. What they send goes out on the network
-- channel as T1 messages, and every client checks that the sender really is them (their name,
-- which the server sets: never a census vote, which anyone on the channel can cast), or one
-- of their helpers for the tools they lend them (HAND_MAY). Answers go back to whoever asked,
-- alone (T2, T3 as whispered addon messages).
--   T1~S~<id>~<guild>                      Summon the leaders (roll call)
--   T1~A~<id>~<guild>~<minutes>~<zone>~<title>   The leader's Agenda (resent every 5 min)
--   T1~X~<id>~<guild>                      Agenda cancelled
--   T1~H~<id>~<guild>~<Name-Realm,...>     the helpers of the leader (their alone; resent every 5 min)
--   T1~N~<id>~<guild>~<Name-Realm,...>     a Steward's own helpers (1.0.0: their alone; resent every 5 min)
--   T2~<id>~<P|B>~<guild>                  a leader's answer to the roll call
-- (1.3.0: the Royal Inspection (I, T3) and the untabarded list (U) are gone, the user's call:
-- other clients ignore those kinds from older versions.)
-- Other modules add their own kinds (King.Register): Vox Populi (V, E), writs (W), the court
-- (C, Z), the gates (G), the treasury's switches and keepers (T, K: their and their
-- Steward's), the leader's week and its signup sheet (D, R, 1.1: Week.lua), the dues' weekly
-- amount (Y, 1.1: their and their Steward's, Dues.lua).
-- The leader's Steward (1.0.0, ns.IsSteward: the character the author marks in the signed titles
-- list) has the Leader tab as the leader has it, "acting for the leader": they name and removes helpers of
-- their own beside the leader's, the treasury's keepers and its switches, and uses every tool of a
-- helper (STEWARD_MAY). Never the leader's own list of helpers, their crown on the map and their layer, the
-- court, writs, or the leader's own book of the treasury and their yes
-- to share it.

local King = {}
ns.King = King

King.SUMMON_OPEN = 60        -- the popup stays this long
King.SUMMON_GAP = 60         -- one roll call a minute at most (sent or accepted)
King.AGENDA_RESEND = 300     -- the leader's client repeats the agenda for late logins
King.AGENDA_GAP = 60         -- one new agenda a minute at most (each one is a raid warning)
King.MAX_ANSWERS = 150       -- roll-call answers kept

King.MAX_HANDS = 40          -- helpers of the leader (the list goes out in pieces when long)
King.HANDS_EVERY = 300       -- the leader's client repeats the list for late logins
King.HANDS_FRESH = 20 * 60   -- a list the leader stopped repeating (they left) ends

King.mode = nil              -- what the tab shows: home or hands (nil: home, the Leader tab Room)
local summon                 -- the leader's own roll call in progress
local agenda                 -- the agenda everyone sees: { id, title, at, zone, by }
local lastSummonSeen = -math.huge
local lastSummonSent = -math.huge
local lastAgendaSent, lastAgendaWarn = -math.huge, -math.huge

-- Text other players send that ends up on the leader's screen (on stream): only what looks
-- like a character name ("Firstname Surname") or a network guild name, nothing else.
local function CleanName(s)
	s = tostring(s or ""):gsub("%-.*$", "")
	if #s > 30 or not s:match("^[%a\128-\255]+ ?[%a\128-\255]*$") then return nil end
	return s
end
local function CleanGuild(s)
	s = tostring(s or ""):gsub("[%c|]", "")
	if #s > 24 or not ns.IsNetworkGuild(s) or not s:match("^[%w\128-\255 ]+$") then return nil end
	return s
end

-- Someone we can place: our own guild (the server's roster) or a leader or officer the census
-- confirms (Data.KnownRank). Only they may put names on the leader's page.
local function Verified(sender, guild)
	if ns.Roster.RankOf(sender) then return true end
	local rank = guild and ns.Data.KnownRank(sender, guild)
	return rank ~= nil and rank <= ns.CAPTAIN_RANK
end

---------------------------------------------------------------------------
-- Who
---------------------------------------------------------------------------

-- Where the leader is pinned by name, another guild master of their guild is not them: nobody
-- would obey the powers the Leader tab gave that character.
function King.IsKing()
	if not ns.IsMember() then return false end
	local guild, _, rank = ns.GetGuildInfo("player")
	if not (ns.IsKingGuild(guild) and rank == 0) then return false end
	return ns.KingCharacter() == nil or ns.IsKingCharacter(ns.me)
end

-- The author's test build (Dev.lua, never published) shows the tab without the powers:
-- nothing it does reaches anyone. The author turns this "the guild master's view" on and off from the
-- Workshop (ns.db.devKingView).
function King.Preview()
	if King.IsKing() then return false end
	local view = ns.db and ns.db.devKingView
	if view ~= nil and ns.Workshop and ns.Workshop.Visible and ns.Workshop.Visible() then return view == true end
	local dev = ns.devThrone
	if type(dev) == "table" then dev = dev[UnitName and UnitName("player") or ""] == true or dev[ns.ShortName(ns.me or "")] == true end
	return dev == true and not King.IsKing()
end
function King.Visible() return King.IsKing() or King.IsSteward() or King.IsHand() or King.Preview() end

-- The leader's Steward (1.0.0): this character, where the signed titles list marks it for our
-- leader (ns.IsSteward), and not the leader themselves.
function King.IsSteward() return not King.IsKing() and ns.IsSteward(ns.me) end
-- A sender the list marks (the server sets the name): their word counts for what STEWARD_MAY lends.
function King.IsStewardName(name) return type(name) == "string" and not ns.IsKingCharacter(name) and ns.IsSteward(name) end

-- The leader themselves, or their Steward: the lists of the Leader tab are theirs to set (each their own list
-- of helpers; the treasury's keepers and switches), and their clients repeat them.
function King.SetsLists() return King.IsKing() or King.IsSteward() end

-- Where the leader is pinned by name (ns.KING_CHARACTER): that character alone, speaking for
-- the leader's guild. No census vote can crown anyone else, nor silence them. Where they are not
-- (the Horde, until their name is known) nobody's commands are obeyed; soft: what only shows
-- (their position, their name on the lines) still comes from the census there (Data.KnownRank).
local function KingSender(sender, guild, soft)
	if not ns.IsKingGuild(guild) then return false end
	if ns.KingCharacter() then
		if not ns.IsKingCharacter(sender) then return false end
		ns.LearnKingRealm(sender) -- (the Horde's, while unknown: from the server's name)
		if ns.Hop and ns.Hop.HeardKing then ns.Hop.HeardKing(sender) end -- (their realm: their own word, 1.0.0)
		return true
	end
	return soft == true and ns.Data.KnownRank(sender, guild, true) == 0
end

-- The page refreshes at most once a second, whatever arrives.
local changePending = false
local function Changed()
	if changePending then return end
	changePending = true
	ns.After(1, "throne refresh", function()
		changePending = false
		ns.Fire("THRONE_CHANGED")
	end)
end

-- kind: the alert's sound switch (1.1, ns.SOUND_KINDS). o (1.1, ns.Alert): its popup or window
-- (show), how long it is current (open), its words while it waits (what), one line for the
-- same one repeated (key), the player's own click (own). The chat line always comes now; the
-- raid warning, the sound and the popup wait in an instance or on Busy.
local function Warn(text, loud, kind, o)
	ns.Print("|cffffd200" .. text .. "|r")
	o = o or {}
	return ns.Alert(kind or "throne", loud and "loud" or "soft", { text = text, color = { r = 1, g = 0.82, b = 0 },
		what = o.what, open = o.open, show = o.show, key = o.key, own = o.own })
end

local function NewId() return math.random(1, 99999) end

---------------------------------------------------------------------------
-- The helpers of the leader: the players they name use the Leader tab's tools in their name (HAND_MAY:
-- the roll call, the inspection, the agenda, Vox Populi, the gates), never what is their alone
-- (the helpers, writs, the court, pardons, their position). Each client keeps the list of the
-- leader it trusts, as they last sent it; a list they stopped repeating ends (HANDS_FRESH).
-- 1.0.0: each of their Stewards names helpers too, in a list of their own that only their client sends
-- (T1~N, STEWARD_MAY; clients before 1.0.0 know no such kind and leave it out):
--   T1~N~<id>~<guild>~<Name-Realm,...>     a Steward's helpers (their alone; resent every 5 min)
-- The helpers are the leader's list and every Steward's together, each list its owner's alone:
-- nobody changes anyone else's. The leader's list is the same message as before 1.0.0, from their
-- client alone. Each client keeps the list it last heard from each Steward (by their name, which
-- the server stamps); it ends HANDS_FRESH after their client stopped repeating it, and at once, on
-- every client, when the author's signed titles list no longer names them (for good: named again,
-- they start from none, King.StewardsChanged). A helper's powers are the same whoever named them.
-- The leader never removes a Steward's helper: that Steward does, or the author, by removing them
-- (the helpers page shows the others' lists, to read only).
---------------------------------------------------------------------------

King.HAND_MAY = { S = true, A = true, X = true, V = true, E = true, G = true }
-- The Steward's: everything a helper may, their own list of helpers (N), and the treasury's switches
-- and keepers (T, K, Treasury.lua), and its dues' amount (Y, 1.1, Dues.lua). Never the leader's
-- list of helpers (H), their crown on the map (P, Q), the court (C, Z) or writs (W).
King.STEWARD_MAY = { S = true, A = true, X = true, V = true, E = true, G = true, N = true, T = true, K = true, Y = true }
-- 1.1: the calls to the network a helper or a Steward sends (popups, raid warnings, windows, the gates'
-- news): none shows from a name the moderators took off (net-off, Moderation.lua). Their lists (the
-- helpers, the treasury's words) are not calls: they still count. The same for the leader's week (1.1,
-- review): its entries and their cancels (D), and the signup sheets (R, Week.lua). A client
-- the moderators took off sends none of them (Moderation.Blocks), but its setter's cancel of their
-- own entry, which every client takes for that entry alone (1.1 review).
King.HIDDEN_CALLS = { S = true, I = true, A = true, X = true, V = true, E = true, G = true, D = true, R = true }
-- A word of the treasury (its switches, its keepers: Treasury.lua) dated further ahead of the
-- server's clock is not taken. A minute: every client reads the same server clock, so a word
-- dated further ahead comes from a modified client, which would otherwise keep its word over
-- the leader's newer one for as long (a review asked for a minute, not ten).
King.DATE_AHEAD = 60

local hands = {}         -- [name-realm, lower case] = true, as the leader last sent it
local handsOrder = {}    -- the same names, in their order (the helpers page)
local handsAt = -math.huge
local handsKing          -- who sent that list (the leader's name on a helper's Leader tab Room)
local myHands = {}       -- the leader's own list, in order: { "Name-Realm", ... } (saved: rdb.kingHands)
local lastHandsSent = -math.huge
local handsSendPending = false
-- 1.0.0: each Steward's list as this client last heard it from them:
-- [their Name-Realm] = { names = { "Name-Realm", ... }, set = { [name-realm, lower case] = true }, at = when }
local stewardHands = {}
-- A Steward's own list, on their client, in order (saved: rdb.stewardHands[their Name-Realm]: the
-- characters of one account on a realm group share what they save).
local myStewardHands = {}
local lastStewardSent = -math.huge

-- A Steward's list as heard here, while it counts: they are still a Steward (the signed titles
-- list names them) and their client kept repeating it.
local function StewardList(steward)
	local s = stewardHands[steward]
	if not s or not King.IsStewardName(steward) or ns.Now() - s.at > King.HANDS_FRESH then return nil end
	return s
end

-- On the leader's own client their list is the one they keep (their broadcast never comes back to
-- them); everyone else trusts the list they last sent, while they keep sending it. A Steward's
-- the same (1.0.0): their own on their client, the one they last sent on everyone else's.
-- Whatever the case a name is written in (1.1, review): the leader types a helper's name as
-- they like, and a net-off word's target is free text, while the server spells a sender's name
-- its own way; they are one character (hands and each Steward's set are kept in lower case).
local function Named(list, key)
	for _, n in ipairs(list) do if type(n) == "string" and n:lower() == key then return true end end
	return false
end
local function Hand(name)
	local full = ns.FullName(name)
	if type(full) ~= "string" then return false end
	local key = full:lower()
	if King.IsKing() then
		if Named(myHands, key) then return true end
	elseif ns.Now() - handsAt <= King.HANDS_FRESH and hands[key] == true then
		return true
	end
	if King.IsSteward() and Named(myStewardHands, key) then return true end
	for steward in pairs(stewardHands) do
		local s = StewardList(steward)
		if s and s.set[key] then return true end
	end
	return false
end

function King.IsHand() return not King.SetsLists() and ns.IsMember() and Hand(ns.me) end
-- Whether the leader's list or a Steward's names this sender (1.0.0): their word alone, never a
-- census vote. Their helpers speak with their Crown for their guild on every client outside it
-- (Decree.lua, Channels.VerifiedLevel); on its own members' clients its roster says who speaks
-- for it.
function King.IsHandName(name) return type(name) == "string" and Hand(name) end

-- This client's own list, the one its helpers page changes: the leader's; a Steward's own (1.0.0);
-- the author's guild master view's, as the leader's (sent nowhere).
local function Own()
	if not King.IsKing() and King.IsSteward() then return myStewardHands end
	return myHands
end
function King.Hands() return Own() end

-- A Steward's name as the leader's screen shows it: cut short while the council's names are hidden
-- there (their stream, ns.CouncilMasked), like every network moderator's.
local function StewardLabel(name)
	local shown = ns.DisplayName(name) or "?"
	return ns.CouncilMasked() and ns.MaskName(shown) or shown
end
King.StewardLabel = StewardLabel

-- The others' lists this client's helpers page shows, to read only (1.0.0): the leader's (on a
-- Steward's client), then each Steward's but its own, while they count, none empty:
-- { { steward = <Name-Realm, nil for the leader's>, names = { ... } }, ... }
function King.OthersHands()
	local out = {}
	if not King.IsKing() and ns.Now() - handsAt <= King.HANDS_FRESH and #handsOrder > 0 then
		out[1] = { names = handsOrder }
	end
	local names = {}
	for steward in pairs(stewardHands) do
		local s = StewardList(steward)
		if s and #s.names > 0 and not (King.IsSteward() and steward == ns.FullName(ns.me)) then names[#names + 1] = steward end
	end
	table.sort(names)
	for _, steward in ipairs(names) do out[#out + 1] = { steward = steward, names = stewardHands[steward].names } end
	return out
end

-- The leader may send it; a Steward what STEWARD_MAY lends them (their own list of helpers among it:
-- never a list of the leader's); one of their helpers what is theirs to use too (soft: their
-- position).
function King.Authorized(kind, sender, guild)
	if KingSender(sender, guild, kind == "P" or kind == "Q") then return true end
	-- 1.3.0: a recruiter (an ambassador) opens and closes the portal for recruits, and nothing else.
	if kind == "G" and ns.IsRecruiter(sender) then return true end
	if King.STEWARD_MAY[kind] == true and King.IsStewardName(sender) then return true end
	return King.HAND_MAY[kind] == true and Hand(sender)
end

-- The leader, their Steward, or a helper: the tools of the Leader tab.
function King.CanCommand() return King.IsKing() or King.IsSteward() or King.IsHand() end

-- The leader themselves sent it (not a helper): for how it is shown.
function King.FromKing(sender, guild) return KingSender(sender, guild, true) end

-- The leader's list, kept across sessions (a /reload must not drop their helpers); a Steward's own
-- the same (1.0.0), under their name: it ends with them (King.StewardsChanged), whichever character
-- of their account on that realm group sees the list without them.
local function SaveHands()
	if not ns.rdb then return end
	local own, copy = Own(), {}
	for i, n in ipairs(own) do copy[i] = n end
	if own ~= myStewardHands then ns.rdb.kingHands = copy; return end
	if type(ns.rdb.stewardHands) ~= "table" then ns.rdb.stewardHands = {} end
	ns.rdb.stewardHands[ns.FullName(ns.me)] = copy
end

-- Several changes in a row go out as one list, a few seconds after the last one.
local function SendHandsSoon()
	if handsSendPending then return end
	handsSendPending = true
	ns.After(3, "leader helpers", function()
		handsSendPending = false
		King.SendHands(true)
		King.SendStewardHands(true)
	end)
end

-- The leader's list goes out whole: short in one message, long in pieces (Comm.SendChunked).
function King.SendHands(force)
	if not King.IsKing() then return end
	local now = ns.Now()
	if not force and now - lastHandsSent < King.HANDS_EVERY then return end
	if #myHands == 0 and lastHandsSent == -math.huge then return end -- nobody named yet
	lastHandsSent = now
	local msg = ("T1~H~%d~%s~%s"):format(NewId(), ns.GetGuildInfo("player") or "", table.concat(myHands, ","))
	if #msg <= 250 then ns.Comm.Send("CHANNEL", msg, "hands") else ns.Comm.SendChunked(msg) end
end

-- A Steward's own list (1.0.0), from their client alone, the same way.
function King.SendStewardHands(force)
	if King.IsKing() or not King.IsSteward() then return end
	local now = ns.Now()
	if not force and now - lastStewardSent < King.HANDS_EVERY then return end
	if #myStewardHands == 0 and lastStewardSent == -math.huge then return end -- nobody named yet
	lastStewardSent = now
	local msg = ("T1~N~%d~%s~%s"):format(NewId(), ns.GetGuildInfo("player") or "", table.concat(myStewardHands, ","))
	if #msg <= 250 then ns.Comm.Send("CHANNEL", msg, "stewardhands") else ns.Comm.SendChunked(msg) end
end

-- A name typed or targeted, as the server writes it; nil if it can't be a character.
local function HandName(input)
	local name = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		name = UnitIsPlayer and UnitIsPlayer("target") and ns.UnitFullName("target") or ""
	end
	name = ns.Normal(name)
	local short = CleanName(name)
	if not short then return nil end
	return ns.FullName(short, ns.RealmOf(name))
end

-- The leader names a helper in their list, a Steward in their own (1.0.0).
function King.AddHand(input)
	if not King.SetsLists() and not King.Preview() then return ns.Print(L.THRONE_ONLY_KING) end
	local name = HandName(input)
	if not name then return ns.Print(L.HANDS_WHO) end
	if name == ns.me then return end
	local own = Own()
	for _, n in ipairs(own) do if n == name then return end end
	if #own >= King.MAX_HANDS then return ns.Print(L.HANDS_FULL:format(King.MAX_HANDS)) end
	own[#own + 1] = name
	SaveHands()
	ns.Print(L.HANDS_ADDED:format(ns.DisplayName(name)))
	if King.SetsLists() then SendHandsSoon() end
	King.mode = "hands"
	Changed()
end

-- From this client's own list alone: never a helper another one named (1.0.0).
function King.RemoveHand(name)
	local own = Own()
	for i, n in ipairs(own) do
		if n == name then
			table.remove(own, i)
			SaveHands()
			ns.Print(L.HANDS_REMOVED:format(ns.DisplayName(name)))
			if King.SetsLists() then SendHandsSoon() end
			return Changed()
		end
	end
end

-- This client became a helper (the Leader tab's tab appears; `told`: by whom), or is one no more.
local function HandChanged(was, told)
	local now = King.IsHand()
	if now and not was then
		ns.Print(told())
		ns.PlayAlert("soft", "throne")
		ns.Fire("DATA_CHANGED") -- the Leader tab's tab appears
	elseif was and not now then
		ns.Fire("DATA_CHANGED")
	end
	Changed()
end

local function OnHands(king, rest)
	local list, n, order = {}, 0, {}
	for name in tostring(rest or ""):gmatch("[^,]+") do
		local short = CleanName(name)
		if short and n < King.MAX_HANDS then
			local full = ns.FullName(short, ns.RealmOf(name))
			if not list[full:lower()] then order[#order + 1] = full end
			list[full:lower()] = true
			n = n + 1
		end
	end
	local was = King.IsHand()
	hands, handsOrder, handsAt, handsKing = list, order, ns.Now(), ns.FullName(king)
	HandChanged(was, function() return L.HANDS_YOU:format(ns.KingName(king)) end)
end

-- A Steward's own list (1.0.0), from their own client: kept as they last sent it. Nobody else's
-- word (the leader's character sending one too: King.Authorized lets them send any kind).
local function OnStewardHands(sender, rest)
	if not King.IsStewardName(sender) then
		return ns.Log("steward helpers from %s ignored: no Steward here", tostring(sender))
	end
	local steward = ns.FullName(sender)
	local names, set = {}, {}
	for name in tostring(rest or ""):gmatch("[^,]+") do
		local short = CleanName(name)
		local full = short and ns.FullName(short, ns.RealmOf(name))
		if full and not set[full:lower()] and #names < King.MAX_HANDS then
			set[full:lower()] = true
			names[#names + 1] = full
		end
	end
	local was = King.IsHand()
	stewardHands[steward] = { names = names, set = set, at = ns.Now() }
	HandChanged(was, function() return L.HANDS_YOU_STEWARD:format(ns.DisplayName(steward) or "?") end)
end

-- The lists this client kept, at login: the leader's (as before 1.0.0) and a Steward's own.
function King.LoadHands()
	local function Load(into, saved)
		wipe(into)
		for _, n in ipairs(type(saved) == "table" and saved or {}) do
			if type(n) == "string" and #into < King.MAX_HANDS then into[#into + 1] = n end
		end
	end
	Load(myHands, ns.rdb and ns.rdb.kingHands)
	local stewards = ns.rdb and ns.rdb.stewardHands
	Load(myStewardHands, type(stewards) == "table" and stewards[ns.FullName(ns.me)])
end

-- A signed titles list was taken (Workshop.TakeTitles, 1.0.0): the list of each Steward it no
-- longer names ends here for good, as heard from them and as their account kept it, their own
-- client's with it. Named again later, a Steward starts from none: nothing they named before comes
-- back until they name it again. (Their account forgets it when one of its characters on that realm
-- group takes a list without them: if none did before the list naming them again, what it kept
-- comes back with them.)
function King.StewardsChanged()
	local changed = false
	for steward in pairs(stewardHands) do
		if not King.IsStewardName(steward) then stewardHands[steward], changed = nil, true end
	end
	local saved = ns.rdb and ns.rdb.stewardHands
	if type(saved) == "table" then
		for owner in pairs(saved) do
			if not King.IsStewardName(owner) then saved[owner] = nil end
		end
		if next(saved) == nil then ns.rdb.stewardHands = nil end
	end
	if not King.IsSteward() and (#myStewardHands > 0 or lastStewardSent ~= -math.huge) then
		wipe(myStewardHands)
		lastStewardSent, changed = -math.huge, true
	end
	if changed then Changed() end
end

StaticPopupDialogs["GMF_KING_HAND"] = {
	text = L.HANDS_PROMPT,
	button1 = OKAY or "OK",
	button2 = CANCEL or "Cancel",
	hasEditBox = true,
	editBoxWidth = 240,
	maxLetters = 40,
	OnShow = function(self)
		local eb = self.editBox or self.EditBox
		if eb then
			local target = UnitIsPlayer and UnitIsPlayer("target") and ns.UnitFullName("target")
			eb:SetText(target and ns.DisplayName(target) or "")
			eb:SetFocus()
		end
	end,
	OnAccept = function(self)
		local eb = self.editBox or self.EditBox
		ns.SafeCall("add helper", King.AddHand, eb and eb:GetText())
	end,
	EditBoxOnEnterPressed = function(self)
		ns.SafeCall("add helper", King.AddHand, self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["GMF_KING_UNHAND"] = {
	text = L.HANDS_REMOVE_CONFIRM,
	button1 = YES or "Yes",
	button2 = NO or "No",
	OnAccept = function(self, data) ns.SafeCall("remove helper", King.RemoveHand, data or (self and self.data)) end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- Other modules' kinds of T1 (Vox Populi, writs, the court, the gates, pardons):
-- fn(sender, id, rest, guild), called once King.Authorized agreed.
local kinds = {}
function King.Register(kind, fn) kinds[kind] = fn end
King.Changed = function() Changed() end
King.Warn = function(text, loud, kind, o) return Warn(text, loud, kind, o) end
King.NewId = function() return NewId() end
King.CleanName = function(s) return CleanName(s) end
King.CleanGuild = function(s) return CleanGuild(s) end
King.Verified = function(sender, guild) return Verified(sender, guild) end

---------------------------------------------------------------------------
-- Summon the leaders
---------------------------------------------------------------------------

function King.Summon()
	local now = ns.Now()
	if King.Preview() then
		summon = { id = 0, t = now, answers = {}, preview = true }
		ns.Print(L.THRONE_PREVIEW_NOTE)
		return Changed()
	end
	if not King.CanCommand() then return end
	if now - lastSummonSent < King.SUMMON_GAP then
		ns.Print(L.THRONE_WAIT:format(math.ceil(King.SUMMON_GAP - (now - lastSummonSent))))
		return Changed()
	end
	lastSummonSent = now
	summon = { id = NewId(), t = now, answers = {} }
	ns.Comm.Send("CHANNEL", ("T1~S~%d~%s"):format(summon.id, ns.GetGuildInfo("player")))
	ns.Log("throne: summon %d", summon.id)
	Changed()
end

local function OnSummon(king, id, guild)
	local now = ns.Now()
	if now - lastSummonSeen < King.SUMMON_GAP then return end
	if not ns.IsMember() or ns.Roster.MyRank() > ns.CAPTAIN_RANK then return end
	lastSummonSeen = now
	-- The leader by the network's name for them; a helper by theirs.
	local who = King.FromKing(king, guild) and L.THRONE_SUMMONED:format(ns.KingName(king)) or L.THRONE_SUMMONED_HAND:format(ns.DisplayName(king))
	-- In an instance or on Busy (1.1): a chat line; the popup once the player is out, while it
	-- is open (never answered for them).
	local shown = ns.Alert("throne", "soft", {
		what = L.HELD_SUMMON, key = "summon" .. tostring(id),
		open = function() return ns.Now() - now < King.SUMMON_OPEN end,
		show = function() ns.ShowDialog("GMF_KING_SUMMON", who, nil, { king = king, id = id }) end,
	})
	if not shown then ns.Print("|cffffd200" .. who .. "|r  |cff9d9d9d" .. L.HELD_LATER .. "|r") end
end

local function Answer(data, word)
	if not data or not data.king then return end
	ns.Comm.Whisper(data.king, ("T2~%d~%s~%s"):format(data.id, word, ns.GetGuildInfo("player") or ""))
end

StaticPopupDialogs["GMF_KING_SUMMON"] = {
	text = "%s",
	button1 = L.THRONE_PRESENT,
	button2 = L.THRONE_BUSY,
	OnAccept = function(self, data) ns.SafeCall("throne answer", Answer, data or self.data, "P") end,
	OnCancel = function(self, data, reason)
		if reason == "clicked" then ns.SafeCall("throne answer", Answer, data or self.data, "B") end
	end,
	timeout = King.SUMMON_OPEN,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- The leaders and officers the census knows online, answered or not: { name, guild, rank }.
local function LordsOnline()
	local out = {}
	for _, e in ipairs(ns.Data.Summary().guilds) do
		local g = e.g
		if e.fresh then
			local home = g.realm or ns.realm
			if g.leader and g.leaderOnline then out[#out + 1] = { name = ns.FullName(g.leader, home), guild = e.name, rank = 0 } end
			for _, o in ipairs(g.officers or {}) do
				if o.online then out[#out + 1] = { name = ns.FullName(o.name, home), guild = e.name, rank = 1 } end
			end
		end
	end
	return out
end

function King.HandleAnswer(dist, sender, text)
	if dist ~= "WHISPER" or not summon or summon.preview then return end
	local id, word, guild = text:match("^T2~(%d+)~([PB])~(.*)$")
	if tonumber(id) ~= summon.id or ns.Now() - summon.t > 300 then return end
	sender = ns.FullName(sender)
	if summon.answers[sender] then return end -- one answer each
	guild = CleanGuild(guild)
	-- Only confirmed leaders and officers are listed by name; anyone else is just counted.
	if not guild or not Verified(sender, guild) then
		summon.others = summon.others or {}
		if not summon.others[sender] then
			local n = 0
			for _ in pairs(summon.others) do n = n + 1 end
			if n < King.MAX_ANSWERS then summon.others[sender] = word end
		end
		return Changed()
	end
	local n = 0
	for _ in pairs(summon.answers) do n = n + 1 end
	if n >= King.MAX_ANSWERS then return end
	summon.answers[sender] = { word = word, guild = guild, verified = true, t = ns.Now() }
	Changed()
end
ns.Comm.Handle("T2", function(...) King.HandleAnswer(...) end)

-- The addons online the census knows of (fresh reports), at least 1 (Workshop.lua's roll calls).
function King.AddonsOnline()
	local n = 0
	for _, e in ipairs(ns.Data.Summary().guilds) do
		if e.fresh then n = n + (tonumber(e.g.users) or 0) end
	end
	return math.max(n, 1)
end

---------------------------------------------------------------------------
-- The leader's Agenda
---------------------------------------------------------------------------

local function ZoneName()
	return (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
end

local function Clean(s, n) return ns.Cut((tostring(s or ""):gsub("[~|\n]", " ")), n) end

-- "30 Raid on Crossroads": minutes first, then the title.
function King.ParseAgenda(input)
	local minutes, title = tostring(input or ""):match("^%s*(%d+)%s+(.-)%s*$")
	minutes = tonumber(minutes)
	if not minutes or minutes < 1 or minutes > 720 or title == "" then return nil end
	return minutes, Clean(title, 60)
end

function King.SetAgenda(input)
	local minutes, title = King.ParseAgenda(input)
	local W = ns.Week
	-- 1.1: a day and an hour, then what: an entry of the leader's week (Week.lua). After a number
	-- too ("30 Sat 20:00 Raid night", the 1.0 box's "30 " kept): the week's, never a 30-minute
	-- Agenda with its raid warning and popup for the whole network.
	if W and W.LooksLikeEntry and W.LooksLikeEntry(minutes and title or input) then
		local text = minutes and title or input
		if W.Parse(text) then return W.SetEntry(text) end
		ns.Print(L.THRONE_AGENDA_USAGE)
		return false
	end
	if not minutes then
		ns.Print(L.THRONE_AGENDA_USAGE)
		return false
	end
	local now = ns.Now()
	if not King.Preview() and now - lastAgendaSent < King.AGENDA_GAP then
		ns.Print(L.THRONE_WAIT:format(math.ceil(King.AGENDA_GAP - (now - lastAgendaSent))))
		return false
	end
	lastAgendaSent = now
	local mine = { id = NewId(), title = title, at = now + minutes * 60, zone = Clean(ZoneName(), 40), by = ns.me, mine = true, fired = {} }
	if King.Preview() then
		agenda = mine
		ns.Print(L.THRONE_PREVIEW_NOTE)
		return Changed() or true
	end
	if not King.CanCommand() then return false end
	agenda = mine
	King.SendAgenda()
	Warn(L.THRONE_AGENDA_SET:format(title, minutes, mine.zone), false, "agenda", { own = true })
	Changed()
	return true
end

function King.SendAgenda()
	if not agenda or not agenda.mine or King.Preview() then return end
	-- Seconds left, so a resend never moves the time (minutes rounded up did).
	local left = math.floor(agenda.at - ns.Now())
	if left < 30 then return end
	ns.Comm.Send("CHANNEL", ("T1~A~%d~%s~%d~%s~%s"):format(agenda.id, ns.GetGuildInfo("player") or "", left, agenda.zone, agenda.title), "agenda")
end

function King.CancelAgenda()
	if not agenda then return end
	-- The leader or a helper cancels it for everyone, whoever set it (its setter's client stops
	-- repeating it when the cancel reaches it).
	if (agenda.mine or King.CanCommand()) and not King.Preview() then
		ns.Comm.Send("CHANNEL", ("T1~X~%d~%s"):format(agenda.id, ns.GetGuildInfo("player") or ""), "agenda")
	end
	if ns.Week and ns.Week.Forget then ns.Week.Forget(agenda.id) end -- (1.1: a signup for it, and its nudge)
	agenda = nil
	Changed()
end

function King.Agenda()
	if agenda and agenda.at < ns.Now() - 600 then agenda = nil end -- over for 10 minutes
	return agenda
end

local function OnAgenda(king, id, rest, guild)
	local seconds, zone, title = rest:match("^(%d+)~([^~]*)~(.*)$")
	seconds = tonumber(seconds)
	if not seconds or seconds < 30 or seconds > 720 * 60 or title == "" then return end
	local now = ns.Now()
	if agenda and agenda.id == id then
		-- A resend: keep our time unless it is really off (late login, clock drift).
		if math.abs((now + seconds) - agenda.at) > 60 then agenda.at = now + seconds end
		return Changed()
	end
	agenda = { id = id, title = Clean(title, 60), at = now + seconds, zone = Clean(zone, 40), by = king, fired = {},
		guild = King.CleanGuild(guild) } -- (1.1: its setter's guild, for the net-off: Week.lua)
	-- A new agenda is a raid warning and a popup (the appointment: what, when, where), but
	-- not more than once a minute whatever arrives.
	if now - lastAgendaWarn >= King.AGENDA_GAP then
		lastAgendaWarn = now
		local a, byKing = agenda, King.FromKing(king, guild)
		-- The popup says the minutes left when it shows (later, after an instance: 1.1).
		local function Popup()
			local minutes = math.max(1, math.ceil((a.at - ns.Now()) / 60))
			-- The leader by the network's name for them; a helper by theirs (as OnSummon).
			local where = a.zone ~= "" and a.zone or "?"
			local text = byKing and L.THRONE_AGENDA_POPUP:format(ns.KingName(king), a.title, minutes, where)
				or L.THRONE_AGENDA_POPUP_HAND:format(ns.DisplayName(king), a.title, minutes, where)
			ns.ShowDialog("GMF_AGENDA_CALL", text)
		end
		Warn(L.THRONE_AGENDA_SET:format(a.title, math.ceil(seconds / 60), a.zone), false, "agenda", King.AgendaHeld(a, Popup))
	end
	Changed()
end

-- The Agenda's raid warnings in an instance or on Busy (1.1, ns.Alert): one line for it and its
-- reminders, current until it is due (and while it is still the Agenda).
function King.AgendaHeld(a, show)
	return { what = L.HELD_AGENDA:format(a.title), key = "agenda" .. tostring(a.id), show = show,
		open = function() return agenda == a and a.at > ns.Now() end }
end

StaticPopupDialogs["GMF_AGENDA_CALL"] = {
	text = "%s",
	button1 = OKAY or "OK",
	timeout = 120,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

---------------------------------------------------------------------------
-- The leader on the map: when they turn it on (Leader tab tab), their client sends where they are and
-- every addon shows a crown on the world map and the minimap. Off by default, and a button
-- away: their position is on stream.
--   T1~P~<id>~<guild>~<mapID>~<x 0-1000>~<y 0-1000>   where they are (every few seconds while moving)
--   T1~Q~<id>~<guild>                                  hidden again
---------------------------------------------------------------------------

King.LOCATION_EVERY = 5      -- seconds between sends while moving
King.LOCATION_STILL = 20     -- standing still, repeated this often (for late logins)
King.LOCATION_EXPIRE = 45    -- a crown with no news this long is removed

local kingAt                 -- where the leader is, for everyone: { name, mapID, x, y, t }
local locationId = NewId()
local lastLocation = { t = -math.huge }
local Pins = ns.Pins()
local SHOW_FLAG = HBD_PINS_WORLDMAP_SHOW_CONTINENT or 2
local crowns                 -- { world, mini } pin frames, made on first use
local crownAt                -- where they are drawn now (drawn again only when they moved)

function King.SharingLocation() return ns.db.throneLocation == true end

local function SendLocation(force)
	if not King.SharingLocation() or not King.IsKing() then return end
	if IsInInstance and IsInInstance() then return end
	local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	local pos = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
	if not pos then return end
	local x, y = pos:GetXY()
	if not x or (x == 0 and y == 0) then return end
	local now = ns.Now()
	local moved = lastLocation.mapID ~= mapID or math.abs((lastLocation.x or 0) - x) > 0.003 or math.abs((lastLocation.y or 0) - y) > 0.003
	if not force and (now - lastLocation.t < King.LOCATION_EVERY or (not moved and now - lastLocation.t < King.LOCATION_STILL)) then return end
	lastLocation = { mapID = mapID, x = x, y = y, t = now }
	ns.Comm.Send("CHANNEL", ("T1~P~%d~%s~%d~%d~%d"):format(locationId, ns.GetGuildInfo("player") or "", mapID,
		math.floor(x * 1000 + 0.5), math.floor(y * 1000 + 0.5)), "kinglocation")
end

function King.ToggleLocation()
	if King.Preview() then return ns.Print(L.THRONE_PREVIEW_NOTE) end
	if not King.IsKing() then return end
	ns.db.throneLocation = not King.SharingLocation()
	if King.SharingLocation() then
		ns.Print(L.THRONE_LOCATION_SHOWN)
		-- Their crown is their yes for their layer too (Layers.lua): the network asks to join them there.
		-- Both go out now (1.0.0: their layer waited for its next announcement, up to ten minutes).
		ns.Print(L.THRONE_LOCATION_LAYER)
		SendLocation(true)
		ns.Layers.AnnounceNow()
	else
		ns.Print(L.THRONE_LOCATION_HIDDEN)
		lastLocation = { t = -math.huge }
		ns.Comm.Send("CHANNEL", ("T1~Q~%d~%s"):format(locationId, ns.GetGuildInfo("player") or ""), "kinglocation")
		-- Their layer goes with it, at once, and their hello stops naming their zone (Layers.Sharing).
		ns.Layers.Withdraw()
		ns.Comm.Hello(true)
	end
	-- Taking donations (1.1): their zone in it follows their crown at once.
	if ns.Treasury and ns.Treasury.DonationsMoved then ns.Treasury.DonationsMoved() end
	Changed()
end

local function CrownTip(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(L.THRONE_LOCATION_PIN:format(kingAt and kingAt.name or "?"), 1, 0.82, 0)
	GameTooltip:Show()
end
local function Crown(size)
	local f = CreateFrame("Frame", nil, UIParent)
	f.gmf = true -- (ours: photo mode leaves it shown, UI.TogglePhoto)
	f:SetSize(size, size)
	f.icon = f:CreateTexture(nil, "OVERLAY")
	f.icon:SetTexture(ns.CROWN_ICON)
	f.icon:SetAllPoints()
	f:EnableMouse(true)
	f:SetScript("OnEnter", CrownTip)
	f:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return f
end
-- The world map's crown sits beside the zone circles, never over their numbers (1.0.0,
-- Map.Badge); the minimap's is a plain crown (no circles there).
local function WorldCrown()
	local f = ns.Map.Badge(20, false)
	ns.Map.SetBadge(f, ns.CROWN_ICON)
	f.badge:SetScript("OnEnter", CrownTip)
	f.badge:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return f
end

-- Draws (or removes) the crown on the world map and the minimap. The world map's only with
-- mouse and keyboard (ns.WorldMapIcons); drawn again when that changes, even where they stand still.
function King.RefreshCrown()
	if not Pins then return end
	local world = ns.WorldMapIcons(Pins, King)
	if kingAt and ns.Now() - kingAt.t > King.LOCATION_EXPIRE then kingAt = nil end
	if not kingAt then
		if crowns and crownAt then
			if world then Pins:RemoveWorldMapIcon(King, crowns.world) end
			Pins:RemoveMinimapIcon(King, crowns.mini)
			crowns.world:Hide()
			crowns.mini:Hide()
		end
		crownAt = nil
		return
	end
	if crownAt and crownAt.mapID == kingAt.mapID and crownAt.x == kingAt.x and crownAt.y == kingAt.y and crownAt.world == world then return end
	crowns = crowns or { world = WorldCrown(), mini = Crown(16) }
	-- Taken off before it is put back: the map library makes a new map pin on every add.
	if crownAt then
		if world then Pins:RemoveWorldMapIcon(King, crowns.world) end
		Pins:RemoveMinimapIcon(King, crowns.mini)
	end
	crownAt = { mapID = kingAt.mapID, x = kingAt.x, y = kingAt.y, world = world }
	if world then Pins:AddWorldMapIconMap(King, crowns.world, kingAt.mapID, kingAt.x, kingAt.y, SHOW_FLAG) end
	Pins:AddMinimapIconMap(King, crowns.mini, kingAt.mapID, kingAt.x, kingAt.y, true, true)
end

local function OnLocation(king, rest)
	local mapID, x, y = rest:match("^(%d+)~(%d+)~(%d+)$")
	mapID, x, y = tonumber(mapID), tonumber(x), tonumber(y)
	if not mapID or x > 1000 or y > 1000 then return end
	kingAt = { from = ns.FullName(king), name = ns.KingName(king), mapID = mapID, x = x / 1000, y = y / 1000, t = ns.Now() }
	ns.SafeCall("leader crown", King.RefreshCrown)
	Changed()
end

-- Where the leader is, while they share it: { name, mapID, x, y, t } or nil.
function King.Location()
	if kingAt and ns.Now() - kingAt.t > King.LOCATION_EXPIRE then return nil end
	return kingAt
end

function King.HandleCommand(dist, sender, text)
	if dist ~= "CHANNEL" then return end
	local kind, id, guild, rest = text:match("^T1~(%a)~(%d+)~([^~]*)~?(.*)$")
	if not kind then return end
	if not King.Authorized(kind, sender, guild) then
		-- Positions come every few seconds: not logged.
		if kind ~= "P" then
			ns.Log("throne %s from %s ignored: not the leader of %s nor their helper%s", kind, sender, tostring(guild),
				ns.KingCharacter() and "" or " (no leader known on this side: nobody commands)")
		end
		return
	end
	id = tonumber(id)
	-- 1.1: a helper (or a Steward) the moderators took off (net-off, Moderation.lua): none of their
	-- calls to the network shows. (Never the leader: nobody takes them off.)
	-- But a setter taking their own entry off the leader's week (a D of 0 seconds): Week.lua takes it
	-- for their own entry alone (1.1 review: held, it showed again everywhere once they were back).
	if King.HIDDEN_CALLS[kind] and ns.Moderation.Hides and ns.Moderation.Hides(sender, guild) and not (kind == "D" and rest:find("^0~")) then
		return ns.Log("throne %s from %s ignored: net-off", kind, sender)
	end
	-- The leader's own client takes their helpers' news (the agenda, the gates, a cancel), not
	-- their calls to the network: no roll call popup, patrol or poll window for them.
	if King.IsKing() and (kind == "S" or kind == "V") and not KingSender(sender, guild) then return end
	if kind == "S" then OnSummon(sender, id, guild)
	elseif kind == "H" then OnHands(sender, rest)
	elseif kind == "N" then OnStewardHands(sender, rest)
	elseif kinds[kind] then kinds[kind](sender, id, rest, guild)
	elseif kind == "A" then OnAgenda(sender, id, rest, guild)
	elseif kind == "P" then OnLocation(sender, rest)
	elseif kind == "Q" then
		-- Only whoever put the crown there takes it off.
		if kingAt and kingAt.from ~= ns.FullName(sender) then return end
		kingAt = nil
		ns.SafeCall("leader crown", King.RefreshCrown)
		Changed()
	elseif kind == "X" then
		if agenda and agenda.id == id then
			agenda = nil
			Changed()
		end
		-- 1.1: our signup for it goes, and its nudge (held after a /reload too: Week.lua).
		if ns.Week and ns.Week.Forget then ns.Week.Forget(id) end
	end
end
ns.Comm.Handle("T1", function(...) King.HandleCommand(...) end)

ns.On("LOGIN", function()
	-- The leader's position, while they share it; everyone's crown expires on its own.
	ns.Every(King.LOCATION_EVERY, "leader location", function()
		SendLocation()
		King.RefreshCrown()
	end)
	-- Their helpers from the last session; they repeat them for late logins (HANDS_EVERY). A
	-- Steward's own list the same, from their client (1.0.0).
	King.LoadHands()
	ns.Every(60, "leader helpers", function()
		King.SendHands()
		King.SendStewardHands()
	end)
	-- The guild is not always known at login yet: checked when the note is due.
	ns.After(20, "leader location note", function()
		if King.SharingLocation() and King.IsKing() then ns.Print(L.THRONE_LOCATION_SHOWN) end
		-- A leader no update has named yet (the Horde's): their commands reach nobody (KingSender).
		if King.IsKing() and not ns.KingCharacter() then ns.Print(L.THRONE_NOT_NAMED) end
	end)
	ns.Every(60, "agenda", function()
		local a = King.Agenda()
		if not a then return end
		local left = a.at - ns.Now()
		-- Reminders for everyone, and the leader's client repeats it for late logins.
		a.fired = a.fired or {}
		for _, mark in ipairs({ 600, 60 }) do
			if left <= mark and left > 0 and not a.fired[mark] then
				a.fired[mark] = true
				Warn(L.THRONE_AGENDA_SOON:format(a.title, math.max(1, math.ceil(left / 60)), a.zone), false, "agenda", King.AgendaHeld(a))
			end
		end
		if a.mine and (not a.sentAt or ns.Now() - a.sentAt >= King.AGENDA_RESEND) then
			a.sentAt = ns.Now()
			King.SendAgenda()
		end
		Changed()
	end)
end)

StaticPopupDialogs["GMF_KING_AGENDA"] = {
	text = L.THRONE_AGENDA_PROMPT,
	button1 = OKAY or "OK",
	button2 = CANCEL or "Cancel",
	hasEditBox = true,
	editBoxWidth = 260,
	maxLetters = 70,
	OnShow = function(self)
		-- Empty (1.1): the box takes minutes or a day and an hour, and a "30 " put there first
		-- would turn a week entry into a 30-minute Agenda.
		local eb = self.editBox or self.EditBox
		if eb then eb:SetText(""); eb:SetFocus() end
	end,
	OnAccept = function(self)
		local eb = self.editBox or self.EditBox
		ns.SafeCall("agenda", King.SetAgenda, eb and eb:GetText())
	end,
	EditBoxOnEnterPressed = function(self)
		ns.SafeCall("agenda", King.SetAgenda, self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

function King.AgendaPrompt()
	ns.ShowDialog("GMF_KING_AGENDA")
	Changed()
end

---------------------------------------------------------------------------
-- What the tab shows (parchment, dark text: line.font)
---------------------------------------------------------------------------

local INK, TITLE = "QuestFont", "QuestTitleFont"

local function Line(text, font, extra)
	local l = { text = text, font = font or INK }
	for k, v in pairs(extra or {}) do l[k] = v end
	return l
end

-- A paragraph, wrapped to the page's width (line.wrap, Views.Render; 1.3.0: no longer cut at a
-- count of letters). It takes `extra` (gapAfter...).
local function Para(lines, text, font, extra)
	text = tostring(text or ""):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
	if text == "" then return lines end
	local l = Line(text, font, extra)
	l.wrap = true
	lines[#lines + 1] = l
	return lines
end
King.Para = Para

---------------------------------------------------------------------------
-- Where the leader's calls show: the roll call in the Realm tab (next to the leaders it calls).
-- Plain rows (not the parchment), for the leader and
-- their helpers (and the author's guild master view).
---------------------------------------------------------------------------

local function Grey(s) return "|cff9d9d9d" .. s .. "|r" end
local function Gold(s) return "|cffffd200" .. s .. "|r" end
local function Green(s) return "|cff40ff40" .. s .. "|r" end
local READY = "|TInterface\\RaidFrame\\ReadyCheck-Ready:13:13|t "
local NOT_READY = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:13:13|t "
local WAITING = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:13:13|t "
King.ROLL_SHOWN = 15 * 60    -- the marks next to the leaders stay this long after a roll call

function King.CanCall() return King.CanCommand() or King.Preview() end

-- Who answered the roll call: present and busy (confirmed leaders and officers), the others
-- the census can't confirm (counted), and the leaders online who stayed silent.
local function RollCall()
	if not summon then return nil end
	local present, busy, silent, others = {}, {}, {}, 0
	for name, a in pairs(summon.answers) do
		local row = ("%s <%s>"):format(ns.DisplayName(name), a.guild)
		if a.word == "P" then present[#present + 1] = row else busy[#busy + 1] = row end
	end
	for _ in pairs(summon.others or {}) do others = others + 1 end
	for _, lord in ipairs(LordsOnline()) do
		local answered = summon.answers[lord.name] or (summon.others and summon.others[lord.name])
		if not answered and lord.name ~= ns.me then silent[#silent + 1] = ("%s <%s>"):format(ns.DisplayName(lord.name), lord.guild) end
	end
	table.sort(present); table.sort(busy); table.sort(silent)
	return present, busy, silent, others
end

-- The mark next to a leader or officer in the Realm tree while a roll call is fresh: answered
-- present, busy, or (online) not answered yet.
function King.RollCallMark(name, online)
	if not summon or not King.CanCall() or ns.Now() - summon.t > King.ROLL_SHOWN then return "" end
	local full = ns.FullName(name)
	if full == ns.me then return "" end -- who called
	local a = summon.answers[full]
	if a then return a.word == "P" and READY or NOT_READY end
	-- An answer the census could not confirm (counted apart) is still an answer: the mark only.
	local o = summon.others and summon.others[full]
	if o then return o == "P" and READY or NOT_READY end
	return online and WAITING or ""
end

local rollOpen = false
function King.RollCallLines()
	if not King.CanCall() then return {} end
	local present, busy, silent, others = RollCall()
	local lines = {
		{
			header = true, text = READY .. L.THRONE_SUMMON_TITLE,
			right = present and Grey(L.ROLL_COUNTS:format(#present, #busy, #silent) .. "  " .. ns.Ago(summon.t)) or Gold(L.ROLL_CALL),
			-- A call while there is none; once called, "call again" below (the results stay).
			onClick = not present and function() King.Summon() end or nil,
			tooltip = function(tt)
				tt:AddLine(L.THRONE_SUMMON_TITLE, 1, 0.82, 0)
				tt:AddLine(L.THRONE_SUMMON_TIP, 1, 1, 1, true)
				tt:AddLine(L.ROLL_CLICK, 0.6, 0.6, 0.6, true)
			end,
		},
	}
	if present then
		lines[#lines + 1] = { indent = 1, text = Gold((rollOpen and "[-] " or "[+] ") .. L.ROLL_WHO),
			onClick = function()
				rollOpen = not rollOpen
				if ns.UI and ns.UI.Refresh then ns.UI.Refresh() end
			end }
		if rollOpen then
			-- (1.1.2's review: Silent and the unconfirmed say why they can be off, the answer bank's.)
			local function Why(tt) if ns.Answers and ns.Answers.WhyTip then ns.Answers.WhyTip(tt, "count-throne-silent") end end
			for _, group in ipairs({ { L.THRONE_PRESENT_N, present, Green }, { L.THRONE_BUSY_N, busy, Grey }, { L.THRONE_SILENT_N, silent, Grey } }) do
				local label = group[1]:format(#group[2])
				lines[#lines + 1] = { indent = 1, text = group[3](label), tooltip = group[2] == silent and function(tt)
					tt:AddLine(label, 1, 0.82, 0)
					Why(tt)
				end or nil }
				for _, row in ipairs(group[2]) do lines[#lines + 1] = { indent = 2, text = row } end
			end
			if others > 0 then
				local label = L.THRONE_UNCONFIRMED:format(others)
				lines[#lines + 1] = { indent = 1, text = Grey(label), tooltip = function(tt)
					tt:AddLine(label, 1, 0.82, 0)
					Why(tt)
				end }
			end
		end
		lines[#lines + 1] = { indent = 1, text = Gold("> " .. L.ROLL_AGAIN), onClick = function() King.Summon() end }
	end
	lines[#lines].gapAfter = true
	return lines
end

local function HandsLines()
	local steward = King.IsSteward()
	local lines = Para({ Line(L.HANDS_TITLE, TITLE) }, steward and L.HANDS_HINT_STEWARD or L.HANDS_HINT, INK, { gapAfter = true })
	if King.SetsLists() or King.Preview() then
		local list = King.Hands()
		lines[#lines + 1] = Line("+ " .. L.HANDS_ADD, TITLE, { onClick = function() ns.ShowDialog("GMF_KING_HAND") end })
		for _, name in ipairs(list) do
			lines[#lines + 1] = Line(ns.DisplayName(name), INK, { indent = 1, key = name,
				onClick = function() ns.ShowDialog("GMF_KING_UNHAND", ns.DisplayName(name), nil, name) end,
				tooltip = function(tt) tt:AddLine(ns.DisplayName(name), 1, 0.82, 0); tt:AddLine(L.HANDS_CLICK_REMOVE, 1, 1, 1, true) end })
		end
		if #list == 0 then lines[#lines + 1] = Line(L.HANDS_NONE, INK, { indent = 1 }) end
		lines[#lines].gapAfter = true
		-- The helpers the others named (1.0.0: the leader, each Steward), under who named them: theirs
		-- to remove, lines to read here (no button).
		for _, o in ipairs(King.OthersHands()) do
			lines[#lines + 1] = Line(o.steward and L.HANDS_NAMED_BY_STEWARD:format(StewardLabel(o.steward)) or L.HANDS_NAMED_BY_KING, TITLE)
			for _, name in ipairs(o.names) do lines[#lines + 1] = Line(ns.DisplayName(name), INK, { indent = 1 }) end
			lines[#lines].gapAfter = true
		end
		Para(lines, steward and L.HANDS_NOTE_STEWARD or L.HANDS_NOTE, INK)
	end
	return lines
end

King.Line, King.INK, King.TITLE = Line, INK, TITLE

local function Go(mode) return function() King.Show(mode) end end

-- The Leader tab Room: what is the leader's alone. Each tool lives where it belongs (the agenda and
-- the court on the buttons below, the roll call in the Realm, the inspection in the Tabards,
-- Vox Populi and the treasury on their own tabs): here, the court's queue while it is open and
-- the treasury. A helper's: where their tools are. Their Steward's (1.0.0): the leader's, with what is
-- their to do in the leader's name (they hold no court: no queue).
local function HomeLines()
	local mine = King.IsKing() or King.Preview()
	local steward = not mine and King.IsSteward()
	local title = (mine or steward) and L.THRONE_ROOM or L.THRONE_ROOM_HAND:format(ns.KingName(handsKing or ns.KingCharacter()))
	local lines = { Line(title, TITLE, { gapAfter = true }) }
	if steward then
		Para(lines, L.THRONE_STEWARD_HINT, INK, { gapAfter = true })
	elseif not mine then
		return Para(lines, L.THRONE_HAND_HINT, INK)
	end
	for _, l in ipairs(ns.Court and ns.Court.HomeLines and ns.Court.HomeLines() or {}) do lines[#lines + 1] = l end
	-- 1.1: the network's key, the leader's to rotate, or their Steward's for them (Keys.lua).
	if mine or steward then
		for _, l in ipairs(ns.Keys.ThroneLines and ns.Keys.ThroneLines() or {}) do lines[#lines + 1] = l end
	end
	if #lines > 1 then lines[#lines].gapAfter = true end
	-- 1.3.0: their simple roll call: who in their guild is out of date (Versions.LeaderLines).
	if mine and ns.Versions and ns.Versions.LeaderLines then
		for _, l in ipairs(ns.Versions.LeaderLines(Line, INK, TITLE)) do lines[#lines + 1] = l end
	end
	for _, l in ipairs(ns.Treasury and ns.Treasury.ThroneLines and ns.Treasury.ThroneLines() or {}) do lines[#lines + 1] = l end
	return lines
end

-- The leader's own pages (and their Steward's): a helper's Leader tab Room has no link to them.
King.KING_PAGES = { hands = true }

-- For Views.Build("throne"): lines, detail title, detail text.
-- The Leader tab opens on the Leader tab Room (the leader's: their court's queue while it is open, the
-- treasury; a helper's: where their tools are), and holding court takes them there. (1.0.0: no
-- letter before it any more.) Their Steward's says on top, on every page, that they act for the leader.
function King.Build(s)
	local lines, home
	if not King.mode then King.mode = "home" end
	local mode = King.mode
	if King.KING_PAGES[mode] and not (King.SetsLists() or King.Preview()) then mode = "home" end
	if mode == "hands" then lines = HandsLines()
	else lines, home = HomeLines(), true end
	-- Every other page leads back to the Leader tab Room.
	if not home then table.insert(lines, 1, Line("< " .. L.THRONE_ROOM, INK, { onClick = Go("home"), gapAfter = true })) end
	-- While the network sees them on the map, the page says so on top, whatever it shows.
	if King.SharingLocation() and King.IsKing() then
		table.insert(lines, 1, Line("|T" .. ns.CROWN_ICON .. ":0|t " .. L.THRONE_LOCATION_LIVE, TITLE, { gapAfter = true }))
	end
	local steward = King.IsSteward()
	if steward then table.insert(lines, 1, Line("|T" .. ns.CROWN_ICON .. ":0|t " .. L.STEWARD_ACTING, TITLE, { gapAfter = true })) end
	local detail = steward and L.THRONE_YOU_ARE_STEWARD:format(ns.KingName(ns.KingCharacter()))
		or King.IsHand() and L.THRONE_YOU_ARE_HAND:format(ns.KingName(handsKing or ns.KingCharacter())) or L.THRONE_YOU_ARE_KING
	return lines, L.TAB_THRONE, detail
end

function King.Show(mode)
	King.mode = mode
	Changed()
end

-- For tests.
function King.CancelAgendaButton()
	if not King.Agenda() then return ns.Print(L.THRONE_AGENDA_NONE) end
	King.CancelAgenda()
	ns.Print(L.THRONE_AGENDA_CANCELLED)
end

function King.State() return { summon = summon, agenda = agenda } end

-- /gmf status (1.0.0): the leader's Steward as this client knows them (the signed titles list), and
-- the lists of helpers it holds, each its owner's: how many, and whether it still lasts here.
function King.StewardStatusLine()
	local who
	if King.IsSteward() then
		who = "you, acting for the leader"
	elseif not ns.KingCharacter() then
		who = "none (no leader known on this side)"
	elseif not ns.CouncilTitles() then
		who = "none known (no signed titles list here yet)"
	else
		local shown = {}
		for i, n in ipairs(ns.Stewards()) do shown[i] = StewardLabel(n) end
		who = #shown > 0 and table.concat(shown, ", ") or "none named"
	end
	local function Heard(at) return ns.Now() - at <= King.HANDS_FRESH and ("heard " .. ns.Ago(at)) or "lapsed here" end
	local held = {}
	if King.IsKing() then held[1] = ("the leader's %d (yours)"):format(#myHands)
	elseif handsAt ~= -math.huge then held[1] = ("the leader's %d (%s)"):format(#handsOrder, Heard(handsAt)) end
	if King.IsSteward() then held[#held + 1] = ("yours %d"):format(#myStewardHands) end
	local stewards = {}
	for steward in pairs(stewardHands) do stewards[#stewards + 1] = steward end
	table.sort(stewards)
	for _, steward in ipairs(stewards) do
		local s = stewardHands[steward]
		local state = King.IsStewardName(steward) and Heard(s.at) or "ended: no longer a recruiter"
		held[#held + 1] = ("%s's %d (%s)"):format(StewardLabel(steward), #s.names, state)
	end
	return ("%s  |  helpers: %s"):format(who, #held > 0 and table.concat(held, ", ") or "none")
end

-- The author's Workshop: the guild master's view on or off (the Leader tab, Vox Populi, the leader's calls in
-- the Realm and the Tabards), to see and try them. Nothing the view does reaches anyone.
function King.SetDevView(on)
	ns.db.devKingView = on and true or false
	-- The preview's treasury switches and keepers were its own: gone with it.
	if not on then ns.db.previewTreasuryFlags, ns.db.previewTreasuryKeepers = nil, nil end
	ns.Print(on and L.DEV_KING_VIEW_NOW_ON or L.DEV_KING_VIEW_NOW_OFF)
	ns.Fire("DATA_CHANGED")
	Changed()
end
function King.Reset()
	summon, agenda, kingAt, crownAt = nil, nil, nil, nil
	hands, handsOrder, handsAt, lastHandsSent, handsKing, handsSendPending = {}, {}, -math.huge, -math.huge, nil, false
	wipe(myHands)
	wipe(stewardHands); wipe(myStewardHands)
	lastStewardSent = -math.huge
	lastLocation = { t = -math.huge }
	lastSummonSeen, lastSummonSent = -math.huge, -math.huge
	lastAgendaSent, lastAgendaWarn, changePending = -math.huge, -math.huge, false
	King.mode, rollOpen = nil, false
end
