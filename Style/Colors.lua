local _, addon = ...

addon.Style = addon.Style or {}
addon.Style.Colors = addon.Style.Colors or {}

local Colors = addon.Style.Colors

local BACKGROUND_CLASS_COLORS = {
	WARRIOR = { r = 0.584, g = 0.459, b = 0.322 }, -- #957552
	PALADIN = { r = 0.722, g = 0.412, b = 0.549 }, -- #B8688C
	HUNTER = { r = 0.502, g = 0.624, b = 0.341 }, -- #809F57
	ROGUE = { r = 0.749, g = 0.722, b = 0.310 }, -- #BFB84F
	PRIEST = { r = 0.749, g = 0.749, b = 0.749 }, -- #BFBFBF
	DEATHKNIGHT = { r = 0.576, g = 0.090, b = 0.173 }, -- #93172C
	SHAMAN = { r = 0.000, g = 0.329, b = 0.651 }, -- #0053A6
	MAGE = { r = 0.188, g = 0.588, b = 0.690 }, -- #3096B0
	WARLOCK = { r = 0.396, g = 0.400, b = 0.702 }, -- #6566B3
	MONK = { r = 0.000, g = 0.749, b = 0.447 }, -- #00BF72
	DRUID = { r = 0.749, g = 0.365, b = 0.031 }, -- #BF5D08
	DEMONHUNTER = { r = 0.478, g = 0.141, b = 0.592 }, -- #7A2497
	EVOKER = { r = 0.149, g = 0.435, b = 0.373 }, -- #266F5F
}

local TEXT_CLASS_COLORS = {
	WARRIOR = { r = 0.780, g = 0.612, b = 0.431 }, -- #C79C6E
	PALADIN = { r = 0.961, g = 0.549, b = 0.729 }, -- #F58CBA
	HUNTER = { r = 0.671, g = 0.831, b = 0.451 }, -- #ABD473
	ROGUE = { r = 1.000, g = 0.961, b = 0.412 }, -- #FFF569
	PRIEST = { r = 1.000, g = 1.000, b = 1.000 }, -- #FFFFFF
	DEATHKNIGHT = { r = 0.769, g = 0.122, b = 0.231 }, -- #C41F3B
	SHAMAN = { r = 0.000, g = 0.439, b = 0.871 }, -- #0070DE
	MAGE = { r = 0.247, g = 0.780, b = 0.922 }, -- #3FC7EB
	WARLOCK = { r = 0.529, g = 0.533, b = 0.933 }, -- #8788EE
	MONK = { r = 0.000, g = 1.000, b = 0.596 }, -- #00FF98
	DRUID = { r = 1.000, g = 0.486, b = 0.039 }, -- #FF7C0A
	DEMONHUNTER = { r = 0.639, g = 0.188, b = 0.788 }, -- #A330C9
	EVOKER = { r = 0.200, g = 0.576, b = 0.498 }, -- #33937F
}

local function GetFallbackChannels(fallbackColor)
	local fallback = fallbackColor or {}
	return fallback.r or 1, fallback.g or 1, fallback.b or 1, fallback.a or 1
end

local function GetClassColorChannels(colors, classToken, fr, fg, fb, fa)
	local color = classToken and colors[classToken]
	if not color then
		return fr, fg, fb, fa
	end

	return color.r or fr, color.g or fg, color.b or fb, color.a or fa
end

function Colors:GetClassBackgroundColor(classToken, fallbackColor)
	return GetClassColorChannels(BACKGROUND_CLASS_COLORS, classToken, GetFallbackChannels(fallbackColor))
end

function Colors:GetUnitClassBackgroundColor(unit, fallbackColor)
	local fr, fg, fb, fa = GetFallbackChannels(fallbackColor)
	if not unit or not UnitExists(unit) then
		return fr, fg, fb, fa
	end

	local classToken = select(2, UnitClass(unit))
	return GetClassColorChannels(BACKGROUND_CLASS_COLORS, classToken, fr, fg, fb, fa)
end

function Colors:GetClassTextColor(classToken, fallbackColor)
	return GetClassColorChannels(TEXT_CLASS_COLORS, classToken, GetFallbackChannels(fallbackColor))
end

function Colors:GetUnitClassTextColor(unit, fallbackColor)
	local fr, fg, fb, fa = GetFallbackChannels(fallbackColor)
	if not unit or not UnitExists(unit) then
		return fr, fg, fb, fa
	end

	local classToken = select(2, UnitClass(unit))
	return GetClassColorChannels(TEXT_CLASS_COLORS, classToken, fr, fg, fb, fa)
end
