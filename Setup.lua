local ADDON, ns = ...
local L = ns.L

-- The guild's setup (Phase 3.7): which ranks are officers, moderators, recruiters and treasurer, the
-- alt guild, and the Treasury switch, set by the guild master in game (/gmf setup) instead of in
-- Config.lua, and handed to every guildmate's client over GUILD, where the server delivers it to our
-- guild alone. These decide who may send what, so every client of the guild must hold the same ones.
--   S1~<at>~<guild>~<alt>~<officerMax>~<mod ranks>~<rec ranks>~<tre ranks>~<treasury 0|1>
--      the settings (ranks as "2.3"), from the guild master on Save, or from an officer or the
--      guild master answering an ask. Taken only from our guild master or an officer (our roster),
--      only for our guild, only if newer than ours and not dated ahead.
--   S0~<at held>   over GUILD after login: a guildmate asks whether newer settings exist.
-- Saved per realm in ns.rdb.settings, applied only while the player is in that guild.

local Setup = {}
ns.Setup = Setup

Setup.DATE_AHEAD = 60   -- settings dated further ahead of the server's clock are not taken
Setup.ASK_AFTER = 25    -- the ask goes this long after login
Setup.OFFER_AFTER = 10  -- a guild master without settings sees the screen this long after login
Setup.ALT_MAX = 24      -- the game's longest guild name
Setup.MAX_RANKS = 10
-- 0.1.0: the Treasury and guild bank wait for their review (the plan's Phase 6): no Treasurer column,
-- no switch, and off whatever the settings say. True brings them back.
Setup.TREASURY_READY = false

-- Config.lua's values, for a guild with no settings.
local DEFAULTS = {
	officerMax = ns.ROLES.officerMax,
	mod = ns.ROLES.moderator.ranks, rec = ns.ROLES.recruiter.ranks, tre = ns.ROLES.treasurer.ranks,
	modWord = ns.ROLES.moderator.rankName, recWord = ns.ROLES.recruiter.rankName, treWord = ns.ROLES.treasurer.rankName,
	alt = ns.ALT_GUILD_NAME, treasuryOff = ns.TREASURY_OFF,
}

local function Clock() return ns.Data and ns.Data.ServerTime and ns.Data.ServerTime() or ns.Now() end
local function MyGuild() return ns.IsInGuild() and ns.GetGuildInfo("player") or nil end
local function Clean(s, max)
	s = tostring(s or ""):gsub("[~|%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	return s:sub(1, max)
end
local function Ranks(list)
	local out, seen = {}, {}
	for _, r in ipairs(type(list) == "table" and list or {}) do
		r = tonumber(r)
		if r and r >= 1 and r < Setup.MAX_RANKS and r == math.floor(r) and not seen[r] then
			seen[r] = true
			out[#out + 1] = r
		end
	end
	table.sort(out)
	return out
end

-- The settings that apply now: ours if saved for the guild the player is in, else nil.
function Setup.Current()
	local s = ns.rdb and ns.rdb.settings
	if type(s) ~= "table" or s.guild ~= MyGuild() then return nil end
	return s
end

-- Into the live values (ns.ROLES and the rest), or back to Config.lua's without settings.
function Setup.Apply()
	local s = Setup.Current()
	local R = ns.ROLES
	if s then
		R.officerMax = math.max(0, math.min(Setup.MAX_RANKS - 1, tonumber(s.officerMax) or DEFAULTS.officerMax))
		R.moderator = { ranks = Ranks(s.mod), rankName = DEFAULTS.modWord }
		R.recruiter = { ranks = Ranks(s.rec), rankName = DEFAULTS.recWord }
		R.treasurer = { ranks = Ranks(s.tre), rankName = DEFAULTS.treWord }
		ns.ALT_GUILD_NAME = s.alt ~= "" and s.alt or nil
		ns.TREASURY_OFF = not (s.treasury and Setup.TREASURY_READY)
	else
		R.officerMax = DEFAULTS.officerMax
		R.moderator = { ranks = DEFAULTS.mod, rankName = DEFAULTS.modWord }
		R.recruiter = { ranks = DEFAULTS.rec, rankName = DEFAULTS.recWord }
		R.treasurer = { ranks = DEFAULTS.tre, rankName = DEFAULTS.treWord }
		ns.ALT_GUILD_NAME = DEFAULTS.alt
		ns.TREASURY_OFF = DEFAULTS.treasuryOff
	end
	ns.CAPTAIN_RANK = R.officerMax
end

---------------------------------------------------------------------------
-- The message
---------------------------------------------------------------------------

local function Join(list) return table.concat(Ranks(list), ".") end
local function Split(text)
	local out = {}
	for r in tostring(text or ""):gmatch("%d+") do out[#out + 1] = tonumber(r) end
	return Ranks(out)
end

function Setup.Encode(s)
	return ("S1~%d~%s~%s~%d~%s~%s~%s~%d"):format(s.at, Clean(s.guild, 64), Clean(s.alt, Setup.ALT_MAX), s.officerMax,
		Join(s.mod), Join(s.rec), Join(s.tre), s.treasury and 1 or 0)
end

function Setup.Decode(text)
	local at, guild, alt, om, mod, rec, tre, treasury =
		tostring(text):match("^S1~(%d+)~([^~]*)~([^~]*)~(%d+)~([%d%.]*)~([%d%.]*)~([%d%.]*)~([01])$")
	at, om = tonumber(at), tonumber(om)
	if not at or not om or guild == "" or om >= Setup.MAX_RANKS then return nil end
	return { at = at, guild = guild, alt = Clean(alt, Setup.ALT_MAX), officerMax = om,
		mod = Split(mod), rec = Split(rec), tre = Split(tre), treasury = treasury == "1" }
end

-- May this sender's settings be taken: our guild master or an officer, by our roster.
local function Trusted(sender)
	local rank = ns.Roster and ns.Roster.RankOf(sender)
	return rank ~= nil and rank <= ns.ROLES.officerMax
end

local answerAt = -math.huge -- GetTime() an S1 was last heard (an answer already given)

function Setup.HandleSettings(dist, sender, text)
	if dist ~= "GUILD" then return end
	answerAt = GetTime()
	local s = Setup.Decode(text)
	if not s or not ns.rdb then return end
	if s.guild ~= MyGuild() then return ns.Log("setup from %s ignored: another guild's", sender) end
	if not Trusted(sender) then return ns.Log("setup from %s ignored: not an officer", sender) end
	if s.at > Clock() + Setup.DATE_AHEAD then return ns.Log("setup from %s ignored: dated ahead", sender) end
	local held = Setup.Current()
	if held and s.at <= (held.at or 0) then return end
	s.by = ns.FullName(sender)
	ns.rdb.settings = s
	Setup.Apply()
	ns.Log("setup taken from %s (dated %d)", sender, s.at)
	ns.Print(L.SETUP_RECEIVED:format(ns.DisplayName(s.by)))
	Setup.Refresh()
	ns.Fire("DATA_CHANGED")
end

function Setup.HandleAsk(dist, sender, text)
	if dist ~= "GUILD" then return end
	local asked = tonumber(tostring(text):match("^S0~(%d+)")) or 0
	local s = Setup.Current()
	if not s or (s.at or 0) <= asked or not ns.Roster.IsOfficer() then return end
	local askedAt = GetTime()
	ns.After(1 + math.random() * 4, "setup answer", function()
		local now = Setup.Current()
		if not now or answerAt > askedAt then return end -- (another officer answered first)
		ns.Comm.Send("GUILD", Setup.Encode(now), "setup")
	end)
end

ns.Comm.Handle("S1", function(...) Setup.HandleSettings(...) end)
ns.Comm.Handle("S0", function(...) Setup.HandleAsk(...) end)

function Setup.Ask()
	if not ns.IsMember() then return end
	local s = Setup.Current()
	ns.Comm.Send("GUILD", ("S0~%d"):format(s and s.at or 0), "setupask")
end

---------------------------------------------------------------------------
-- Saving (the guild master)
---------------------------------------------------------------------------

-- The guild's rank names now, rank 1 on (rank 0, the guild master, left out): what a setup was
-- saved against. Ranks are kept by their number, so a rank added, removed or moved since gives its
-- roles to whichever rank holds that number now (a rename alone changes nothing, but can't be told
-- apart from a move: the guild master is asked to check either way).
function Setup.RankNames()
	local out = {}
	local n = math.min(Setup.MAX_RANKS, ns.GuildControlGetNumRanks() or 0)
	for rank = 1, n - 1 do out[rank] = ns.GuildControlGetRankName(rank + 1) or "" end
	return out
end
function Setup.RanksChanged()
	local s = Setup.Current()
	if not s or type(s.names) ~= "table" then return false end
	local now = Setup.RankNames()
	if #now == 0 then return false end -- (not read yet)
	if #now ~= #s.names then return true end
	for i, name in ipairs(now) do if name ~= s.names[i] then return true end end
	return false
end
local ranksTold = false
function Setup.CheckRanks()
	if ranksTold or not Setup.CanEdit() or not Setup.RanksChanged() then return end
	ranksTold = true
	ns.Log("setup: the guild's ranks changed since it was saved")
	ns.Print(L.SETUP_RANKS_CHANGED)
	Setup.Refresh()
end

function Setup.CanEdit()
	local guild, _, rank = ns.GetGuildInfo("player")
	return ns.IsMember() and rank == 0 and ns.IsKingGuild(guild)
end

function Setup.Save(draft)
	if not Setup.CanEdit() or not ns.rdb then return ns.Print(L.SETUP_READONLY) end
	local held = Setup.Current()
	local at = Clock()
	if held and at <= (held.at or 0) then at = held.at + 1 end
	local s = { at = at, by = ns.me, guild = MyGuild(), alt = Clean(draft.alt, Setup.ALT_MAX),
		officerMax = math.max(0, math.min(Setup.MAX_RANKS - 1, tonumber(draft.officerMax) or 1)),
		mod = Ranks(draft.mod), rec = Ranks(draft.rec), tre = Ranks(draft.tre), treasury = draft.treasury == true,
		names = Setup.RankNames() } -- (kept here only, never sent: Setup.CheckRanks)
	ns.rdb.settings = s
	ranksTold = false
	Setup.Apply()
	ns.Comm.Send("GUILD", Setup.Encode(s), "setup")
	ns.Log("setup saved (dated %d)", at)
	ns.Print(L.SETUP_SAVED)
	ns.Fire("DATA_CHANGED")
end

---------------------------------------------------------------------------
-- The screen
---------------------------------------------------------------------------

local frame, draft
local COLS = { { "officer", "SETUP_OFFICER" }, { "mod", "SETUP_MODERATOR" }, { "rec", "SETUP_RECRUITER" } }
if Setup.TREASURY_READY then COLS[#COLS + 1] = { "tre", "SETUP_TREASURER" } end
local COL_X, COL_W, ROW_H, TOP = 170, 72, 24, -96

local function Has(list, r) for _, v in ipairs(list) do if v == r then return true end end return false end
local function Toggle(list, r, on)
	local out = {}
	for _, v in ipairs(list) do if v ~= r then out[#out + 1] = v end end
	if on then out[#out + 1] = r end
	return Ranks(out)
end

local function Draft()
	local s = Setup.Current()
	return {
		alt = s and s.alt or (DEFAULTS.alt or ""),
		officerMax = s and s.officerMax or DEFAULTS.officerMax,
		mod = Ranks(s and s.mod or DEFAULTS.mod), rec = Ranks(s and s.rec or DEFAULTS.rec), tre = Ranks(s and s.tre or DEFAULTS.tre),
		treasury = Setup.TREASURY_READY and (s and s.treasury or not DEFAULTS.treasuryOff) or false,
	}
end

local function Build()
	local f = CreateFrame("Frame", "GuildMasterForeverSetup", UIParent, "BasicFrameTemplateWithInset")
	f:SetSize(COL_X + COL_W * #COLS + 24, 200)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:Hide()
	f.onCloseCallback = function() f:Hide() return false end
	if f.TitleText then f.TitleText:SetText(L.SETUP_TITLE) end

	f.state = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.state:SetPoint("TOPLEFT", 14, -32)
	f.state:SetPoint("RIGHT", f, "RIGHT", -14, 0)
	f.state:SetJustifyH("LEFT")

	f.altLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.altLabel:SetPoint("TOPLEFT", 14, -54)
	f.altLabel:SetText(L.SETUP_ALT)
	local ok, alt = pcall(CreateFrame, "EditBox", "GuildMasterForeverSetupAlt", f, "InputBoxTemplate")
	if not ok or not alt then alt = CreateFrame("EditBox", "GuildMasterForeverSetupAlt", f) end
	alt:SetAutoFocus(false)
	alt.gmfBox = true
	alt:SetSize(180, 20)
	alt:SetMaxLetters(Setup.ALT_MAX)
	alt:SetFontObject("ChatFontNormal")
	alt:SetPoint("LEFT", f.altLabel, "RIGHT", 10, 0)
	alt:SetScript("OnTextChanged", function(self) if draft then draft.alt = self:GetText() end end)
	alt:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	alt:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	f.alt = alt

	f.rankHead = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.rankHead:SetPoint("TOPLEFT", 14, TOP + 18)
	f.rankHead:SetText(L.SETUP_RANK)
	for i, col in ipairs(COLS) do
		local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		h:SetPoint("TOP", f, "TOPLEFT", COL_X + COL_W * (i - 1) + COL_W / 2, TOP + 18)
		h:SetText(L[col[2]])
	end
	f.rows = {}

	local treasury = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	treasury:SetSize(24, 24)
	treasury.label = treasury:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	treasury.label:SetPoint("LEFT", treasury, "RIGHT", 4, 0)
	treasury.label:SetText(L.SETUP_TREASURY)
	treasury:SetScript("OnClick", function(self) if draft then draft.treasury = self:GetChecked() and true or false end end)
	f.treasury = treasury

	f.note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	f.note:SetJustifyH("LEFT")

	f.save = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.save:SetSize(100, 22)
	f.save:SetPoint("BOTTOMRIGHT", -12, 10)
	f.save:SetText(L.SETUP_SAVE)
	f.save:SetScript("OnClick", function()
		if draft then ns.SafeCall("setup save", Setup.Save, draft) end
		Setup.Refresh()
	end)
	f.close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.close:SetSize(100, 22)
	f.close:SetPoint("RIGHT", f.save, "LEFT", -8, 0)
	f.close:SetText(L.SETUP_CLOSE)
	f.close:SetScript("OnClick", function() f:Hide() end)
	return f
end

local function Row(f, i)
	local r = f.rows[i]
	if r then return r end
	r = { checks = {} }
	r.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	r.name:SetPoint("TOPLEFT", 16, TOP - (i - 1) * ROW_H - 4)
	r.name:SetWidth(COL_X - 24)
	r.name:SetJustifyH("LEFT")
	r.name:SetWordWrap(false)
	for c, col in ipairs(COLS) do
		local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
		cb:SetSize(24, 24)
		cb:SetPoint("TOP", f, "TOPLEFT", COL_X + COL_W * (c - 1) + COL_W / 2, TOP - (i - 1) * ROW_H)
		cb:SetScript("OnClick", function(self)
			if not draft or not r.rank then return end
			local on = self:GetChecked() and true or false
			if col[1] == "officer" then
				draft.officerMax = on and r.rank or r.rank - 1 -- (0: the guild master alone)
			else
				draft[col[1]] = Toggle(draft[col[1]], r.rank, on)
			end
			Setup.Refresh(true)
		end)
		r.checks[c] = cb
	end
	f.rows[i] = r
	return r
end

local function Enable(cb, on)
	cb:SetEnabled(on)
	if cb.Text then cb.Text:SetTextColor(on and 1 or 0.5, on and 1 or 0.5, on and 1 or 0.5) end
end

-- keep: the draft as it is (a click on the screen), else drawn again from what is saved.
function Setup.Refresh(keep)
	local f = frame
	if not f or not f:IsShown() then return end
	if not keep or not draft then draft = Draft() end
	local edit = Setup.CanEdit()
	local s = Setup.Current()
	local guild = MyGuild()
	if not guild then
		f.state:SetText(L.SETUP_NO_GUILD)
	elseif s and edit and Setup.RanksChanged() then
		f.state:SetText(("<%s>  |cffff8040%s|r"):format(guild, L.SETUP_RANKS_CHANGED_LINE))
	elseif s then
		f.state:SetText(("<%s>  " .. L.SETUP_SAVED_BY):format(guild, ns.DisplayName(s.by or "?"), date("%Y-%m-%d %H:%M", s.at)))
	else
		f.state:SetText(("<%s>  %s"):format(guild, L.SETUP_DEFAULTS))
	end
	if f.alt:GetText() ~= draft.alt and not f.alt:HasFocus() then f.alt:SetText(draft.alt) end
	f.alt:SetEnabled(edit)
	local n = math.min(Setup.MAX_RANKS, ns.GuildControlGetNumRanks() or 0)
	local shown = 0
	for rank = 1, n - 1 do
		shown = shown + 1
		local r = Row(f, shown)
		r.rank = rank
		r.name:SetText(("%d. %s"):format(rank, ns.GuildControlGetRankName(rank + 1) or ("Rank " .. rank)))
		r.name:Show()
		local officer = rank <= draft.officerMax
		local states = { officer = officer, mod = officer or Has(draft.mod, rank), rec = Has(draft.rec, rank), tre = Has(draft.tre, rank) }
		for c, cb in ipairs(r.checks) do
			cb:SetChecked(states[COLS[c][1]])
			-- Officers always moderate: their Moderator box is ticked and fixed.
			Enable(cb, edit and not (c == 2 and officer))
			cb:Show()
		end
	end
	for i = shown + 1, #f.rows do
		f.rows[i].name:Hide()
		for _, cb in ipairs(f.rows[i].checks) do cb:Hide() end
	end
	local y = TOP - shown * ROW_H - 8
	f.treasury:ClearAllPoints()
	f.treasury:SetPoint("TOPLEFT", 12, y)
	f.treasury:SetChecked(draft.treasury)
	Enable(f.treasury, edit)
	f.treasury:SetShown(Setup.TREASURY_READY)
	if Setup.TREASURY_READY then y = y - 30 end
	f.note:ClearAllPoints()
	f.note:SetPoint("TOPLEFT", 16, y)
	f.note:SetPoint("RIGHT", f, "RIGHT", -16, 0)
	f.note:SetText(edit and L.SETUP_EDIT_NOTE or L.SETUP_READONLY)
	f.save:SetShown(edit)
	f:SetHeight(-y + 44) -- (the note, then Save)
end

function Setup.Show()
	if not ns.IsMember() then return ns.Print(L.SETUP_NO_GUILD) end
	frame = frame or Build()
	frame:Show()
	draft = nil
	Setup.Refresh()
end

function Setup.Toggle()
	if frame and frame:IsShown() then frame:Hide() else Setup.Show() end
end

---------------------------------------------------------------------------
-- When
---------------------------------------------------------------------------

ns.On("LOGIN", function()
	Setup.Apply()
	ns.After(Setup.ASK_AFTER, "setup ask", Setup.Ask)
	-- A guild master whose guild has no settings yet: the screen once (never in combat).
	ns.After(Setup.OFFER_AFTER, "setup offer", function()
		Setup.CheckRanks()
		if not Setup.CanEdit() or Setup.Current() or not ns.rdb or ns.rdb.setupOffered then return end
		if InCombatLockdown and InCombatLockdown() then return end
		ns.rdb.setupOffered = true
		ns.Print(L.SETUP_OFFER)
		Setup.Show()
	end)
end)
ns.RegisterEvent("PLAYER_GUILD_UPDATE", function() ns.After(2, "setup guild", Setup.Apply) end)
-- The guild master changed the ranks (Guild Control): checked once the game has the new ones.
ns.RegisterEvent("GUILD_RANKS_UPDATE", function()
	ns.After(2, "setup ranks", function()
		ranksTold = false
		Setup.CheckRanks()
		Setup.Refresh(true)
	end)
end)
ns.On("DATA_CHANGED", function() Setup.Apply() end)
