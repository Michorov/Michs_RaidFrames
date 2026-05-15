local _, addon = ...

addon.Style = addon.Style or {}
addon.Style.Colors = addon.Style.Colors or {}

local Colors = addon.Style.Colors

local BACKGROUND_CLASS_COLORS = {
	WARRIOR = { r = 0.624, g = 0.490, b = 0.345 }, -- #9F7D58
	PALADIN = { r = 0.769, g = 0.439, b = 0.584 }, -- #C47095
	HUNTER = { r = 0.537, g = 0.667, b = 0.361 }, -- #89AA5C
	ROGUE = { r = 0.800, g = 0.769, b = 0.329 }, -- #CCC454
	PRIEST = { r = 0.800, g = 0.800, b = 0.800 }, -- #CCCCCC
	DEATHKNIGHT = { r = 0.616, g = 0.098, b = 0.184 }, -- #9D192F
	SHAMAN = { r = 0.000, g = 0.353, b = 0.698 }, -- #005AB2
	MAGE = { r = 0.200, g = 0.624, b = 0.737 }, -- #339FBC
	WARLOCK = { r = 0.424, g = 0.427, b = 0.745 }, -- #6C6DBE
	MONK = { r = 0.000, g = 0.800, b = 0.478 }, -- #00CC7A
	DRUID = { r = 0.800, g = 0.388, b = 0.031 }, -- #CC6308
	DEMONHUNTER = { r = 0.510, g = 0.149, b = 0.631 }, -- #8226A1
	EVOKER = { r = 0.161, g = 0.463, b = 0.400 }, -- #297666
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
