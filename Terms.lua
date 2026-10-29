local ADDON, ns = ...
local L = ns.L

-- The guild's words (Phase 4.2): what the add-on calls the guild master, the officers, the members,
-- its tabs and its calls. A text names one by its token, "{officers}", and the token is filled in
-- place in ns.L: once here, right after the translation files, and again when the guild's own words
-- change (Terms.Apply; the setup will carry them). The text with its tokens is kept aside so it can
-- be filled again; code that reads ns.L directly (rawget, the translation checks) sees filled text.
-- A window built at login (a popup) shows a renamed word after a /reload.
-- Terms are used as written, never re-cased.

local Terms = {}
ns.Terms = Terms

-- In the order the setup will show them.
Terms.NAMES = {
	"leader", "officer", "officers", "moderator", "moderators", "recruiter", "recruiters", "helper", "helpers",
	"guildmaster", "guildmasters", "member", "members", "treasurer",
	"censusTab", "guildTab", "callsTab", "tabardsTab", "leaderTab", "pollsTab",
	"leaderCall", "rareCall", "gathering",
}
Terms.MAX = 24 -- letters a guild's own word may have

Terms.DEFAULTS = {
	enUS = {
		leader = "Guild Master", officer = "Officer", officers = "Officers", moderator = "Moderator", moderators = "Moderators",
		recruiter = "Recruiter", recruiters = "Recruiters", helper = "Helper", helpers = "Helpers",
		guildmaster = "Guild Master", guildmasters = "Guild Masters", member = "Member", members = "Members", treasurer = "Treasurer",
		censusTab = "Census", guildTab = "Guild", callsTab = "Calls", tabardsTab = "Tabards", leaderTab = "Leader", pollsTab = "Polls",
		leaderCall = "Leader Call", rareCall = "Rare Call", gathering = "Gathering",
	},
	ptBR = {
		leader = "Mestre da Guilda", officer = "Oficial", officers = "Oficiais", moderator = "Moderador", moderators = "Moderadores",
		recruiter = "Recrutador", recruiters = "Recrutadores", helper = "Ajudante", helpers = "Ajudantes",
		guildmaster = "Mestre da Guilda", guildmasters = "Mestres de Guilda", member = "Membro", members = "Membros", treasurer = "Tesoureiro",
		censusTab = "Censo", guildTab = "Guilda", callsTab = "Chamados", tabardsTab = "Tabardos", leaderTab = "Líder", pollsTab = "Enquetes",
		leaderCall = "Chamado do Líder", rareCall = "Chamado Raro", gathering = "Reunião",
	},
	deDE = {
		leader = "Gildenmeister", officer = "Offizier", officers = "Offiziere", moderator = "Moderator", moderators = "Moderatoren",
		recruiter = "Werber", recruiters = "Werber", helper = "Helfer", helpers = "Helfer",
		guildmaster = "Gildenmeister", guildmasters = "Gildenmeister", member = "Mitglied", members = "Mitglieder", treasurer = "Schatzmeister",
		censusTab = "Zensus", guildTab = "Gilde", callsTab = "Rufe", tabardsTab = "Wappenröcke", leaderTab = "Anführer", pollsTab = "Umfragen",
		leaderCall = "Ruf des Anführers", rareCall = "Seltener Ruf", gathering = "Sammeln",
	},
	frFR = {
		leader = "Maître de guilde", officer = "Officier", officers = "Officiers", moderator = "Modérateur", moderators = "Modérateurs",
		recruiter = "Recruteur", recruiters = "Recruteurs", helper = "Assistant", helpers = "Assistants",
		guildmaster = "Maître de guilde", guildmasters = "Maîtres de guilde", member = "Membre", members = "Membres", treasurer = "Trésorier",
		censusTab = "Recensement", guildTab = "Guilde", callsTab = "Appels", tabardsTab = "Tabards", leaderTab = "Chef", pollsTab = "Sondages",
		leaderCall = "Appel du chef", rareCall = "Appel rare", gathering = "Rassemblement",
	},
	esES = {
		leader = "Maestro de hermandad", officer = "Oficial", officers = "Oficiales", moderator = "Moderador", moderators = "Moderadores",
		recruiter = "Reclutador", recruiters = "Reclutadores", helper = "Ayudante", helpers = "Ayudantes",
		guildmaster = "Maestro de hermandad", guildmasters = "Maestros de hermandad", member = "Miembro", members = "Miembros", treasurer = "Tesorero",
		censusTab = "Censo", guildTab = "Hermandad", callsTab = "Llamadas", tabardsTab = "Tabardos", leaderTab = "Líder", pollsTab = "Encuestas",
		leaderCall = "Llamada del líder", rareCall = "Llamada rara", gathering = "Reunión",
	},
}
Terms.DEFAULTS.esMX = Terms.DEFAULTS.esES

local raw = {}     -- [key] = the text with its tokens
local current = {} -- [token] = the word now
local tracked = {} -- { t, key, text }: texts outside ns.L (the help answers: Terms.Track)

local function Clean(s)
	s = tostring(s or ""):gsub("[~|{}%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	return s:sub(1, Terms.MAX)
end

local function Fill(s)
	return (tostring(s):gsub("{(%a+)}", function(name) return current[name] or ("{" .. name .. "}") end))
end
Terms.Fill = Fill

function Terms.Get(name) return current[name] end

-- The default word for a token in the player's language (English where it has none).
function Terms.Default(name)
	local mine = Terms.DEFAULTS[GetLocale and GetLocale() or "enUS"]
	return mine and mine[name] or Terms.DEFAULTS.enUS[name]
end

-- The words now: the defaults, with the guild's own (a { [token] = word } table) over them.
function Terms.Apply(overrides)
	local words = {}
	for _, name in ipairs(Terms.NAMES) do words[name] = Terms.Default(name) end
	for name, word in pairs(type(overrides) == "table" and overrides or {}) do
		word = Clean(word)
		if words[name] ~= nil and word ~= "" then words[name] = word end
	end
	current = words
	for key, text in pairs(raw) do L[key] = Fill(text) end
	for _, e in ipairs(tracked) do e[1][e[2]] = Fill(e[3]) end
	-- The leader's title on the lines and the crown (Core.lua; Config.lua's GM_DISPLAY first if set).
	if ns.GM_DISPLAY == nil then ns.KING_NAME = current.leader end
end

-- Texts kept outside ns.L (a table of tables of strings, e.g. ns.ANSWER_BANK): filled now and again
-- whenever the words change.
function Terms.Track(t, seen)
	seen = seen or {}
	if type(t) ~= "table" or seen[t] then return end
	seen[t] = true
	for key, v in pairs(t) do
		if type(v) == "string" and v:find("{%a+}") then
			tracked[#tracked + 1] = { t, key, v }
			t[key] = Fill(v)
		elseif type(v) == "table" then
			Terms.Track(v, seen)
		end
	end
end

-- Every text with a token, as the translation files left it.
for key, text in pairs(L) do
	if type(text) == "string" and text:find("{%a+}") then raw[key] = text end
end
Terms.Apply(nil)
