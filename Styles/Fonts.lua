local _, addon = ...

addon.Styles = addon.Styles or {}
addon.Styles.Fonts = addon.Styles.Fonts or {}

local Fonts = addon.Styles.Fonts
local LSM = LibStub("LibSharedMedia-3.0")
local fontTable = LSM:HashTable("font")
local WOW_DEFAULT_FONT = -2
local callbacksRegistered = false

local fontSettingReasons = {
	{ key = "name", reason = "nameSettingsChanged" },
	{ key = "healthText", reason = "healthTextSettingsChanged" },
	{ key = "powerText", reason = "powerTextSettingsChanged" },
	{ key = "away", reason = "awayTextSettingsChanged" },
	{ key = "healAbsorbs", reason = "healAbsorbsTextSettingsChanged" },
	{ key = "statusText", reason = "statusTextSettingsChanged" },
}

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

function Fonts:Resolve(fontName)
	if fontName == -1 then
		local profile = addon.Database:GetProfile()
		fontName = profile and profile.core and profile.core.lsmFont
	end

	return self:Fetch(fontName)
end

local function GetTextFont(profile, mode, key)
	return profile
		and profile[mode]
		and profile[mode].widgets
		and profile[mode].widgets.texts
		and profile[mode].widgets.texts[key]
		and profile[mode].widgets.texts[key].lsmFont
end

local function ShouldUpdateTextFont(profile, key, fontName)
	local coreFont = profile and profile.core and profile.core.lsmFont
	local partyFont = GetTextFont(profile, "party", key)
	local raidFont = GetTextFont(profile, "raid", key)

	return partyFont == fontName or raidFont == fontName or (coreFont == fontName and (partyFont == -1 or raidFont == -1))
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
		for _, setting in ipairs(fontSettingReasons) do
			if ShouldUpdateTextFont(profile, setting.key, fontName) then
				addon.UpdateScheduler:Notify(setting.reason)
			end
		end
	end)

	callbacksRegistered = true
end
