local _, addon = ...

addon.Styles = addon.Styles or {}
addon.Styles.Fonts = addon.Styles.Fonts or {}

local Fonts = addon.Styles.Fonts
local LSM = LibStub("LibSharedMedia-3.0")
local fontTable = LSM:HashTable("font")
local WOW_DEFAULT_FONT = -2
local callbacksRegistered = false

LSM:Register(
	"font",
	"Philosopher Bold",
	"Interface\\AddOns\\Michs_RaidFrames\\Media\\Fonts\\Philosopher-Bold.ttf"
)

function Fonts:GetOptions(selectedFontName, includeGlobal)
	local options = {}
	local selectedFontListed = false

	if includeGlobal then
		options[#options + 1] = {
			value = -1,
			textKey = "Use Global",
			textColor = { 0.50, 0.52, 0.56, 1 },
		}
	end

	options[#options + 1] = {
		value = WOW_DEFAULT_FONT,
		textKey = "Default",
		textColor = { 0.50, 0.52, 0.56, 1 },
	}

	for _, fontName in ipairs(LSM:List("font")) do
		options[#options + 1] = {
			value = fontName,
			text = fontName,
			font = fontTable[fontName],
		}

		if fontName == selectedFontName then
			selectedFontListed = true
		end
	end

	if selectedFontName and selectedFontName ~= -1 and selectedFontName ~= WOW_DEFAULT_FONT and not selectedFontListed then
		options[#options + 1] = {
			value = selectedFontName,
			text = selectedFontName .. " (Unavailable)",
		}
	end

	return options
end

function Fonts:Fetch(fontName)
	if fontName == WOW_DEFAULT_FONT or not LSM:IsValid("font", fontName) then
		return addon.Utilities:GetGameFontNormalPath()
	end

	return LSM:Fetch("font", fontName)
end

function Fonts:RegisterCallbacks()
	if callbacksRegistered then
		return
	end

	LSM.RegisterCallback(self, "LibSharedMedia_Registered", function(_, mediaType, fontName)
		if mediaType ~= "font" then
			return
		end

		if addon.Options and addon.Options.RefreshState then
			addon.Options:RefreshState()
		end

		local profile = addon.Database:GetProfile()
		local coreFont = profile and profile.core and profile.core.lsmFont
		local partyFont = profile
			and profile.party
			and profile.party.widgets
			and profile.party.widgets.texts
			and profile.party.widgets.texts.name
			and profile.party.widgets.texts.name.lsmFont
		local raidFont = profile
			and profile.raid
			and profile.raid.widgets
			and profile.raid.widgets.texts
			and profile.raid.widgets.texts.name
			and profile.raid.widgets.texts.name.lsmFont

		if
			partyFont == fontName
			or raidFont == fontName
			or (coreFont == fontName and (partyFont == -1 or raidFont == -1))
		then
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end
	end)

	callbacksRegistered = true
end
