local _, addon = ...

local Utilities = {}
addon.Utilities = Utilities

local cachedPixelStep
local ALLOWED_FONT_OUTLINE_VALUES = {
	[""] = true,
	["OUTLINE"] = true,
	["THICKOUTLINE"] = true,
	["MONOCHROME"] = true,
	["MONOCHROME,OUTLINE"] = true,
	["OUTLINE,MONOCHROME"] = true,
	["MONOCHROME,THICKOUTLINE"] = true,
	["THICKOUTLINE,MONOCHROME"] = true,
}

function Utilities:RoundToNearestInt(value)
	value = value or 0

	if value >= 0 then
		return math.floor(value + 0.5)
	end

	return math.ceil(value - 0.5)
end

local function GetGlobalScale()
	local db = addon.Database and addon.Database.db
	local s = db and db.profile and db.profile.core and db.profile.core.uiScale
	if type(s) ~= "number" then
		return 1
	end
	return math.min(2, math.max(0.5, s))
end

local function GetPixelStep()
	if not cachedPixelStep then
		Utilities:RefreshPixelGrid()
	end
	return cachedPixelStep
end

function Utilities:RefreshPixelGrid()
	local _, physicalHeight = GetPhysicalScreenSize()
	local uiScale = UIParent:GetEffectiveScale()

	local pixelScale = 768 / physicalHeight
	cachedPixelStep = pixelScale / uiScale
end

function Utilities:ToPixels(value)
	local step = GetPixelStep()
	return self:RoundToNearestInt((value or 0) / step)
end

function Utilities:Scale(pixelCount)
	local scaledPx = (pixelCount or 0) * GetGlobalScale()
	return self:RoundToNearestInt(scaledPx)
end

function Utilities:Unscale(pixelCount)
	local unscaledPx = (pixelCount or 0) / GetGlobalScale()
	return self:RoundToNearestInt(unscaledPx)
end

function Utilities:ScaleEven(pixelCount)
	local px = self:Scale(pixelCount)
	if (px % 2) ~= 0 then
		px = px + 1
	end
	return px
end

function Utilities:ToUI(pixelCount)
	return (pixelCount or 0) * GetPixelStep()
end

function Utilities:ScaleFont(size)
	return math.max(1, self:Scale(size))
end

function Utilities:NormalizeFontOutline(outline, fallback)
	local normalizedFallback = fallback
	if normalizedFallback == "NONE" or normalizedFallback == nil then
		normalizedFallback = ""
	end

	if outline == nil or outline == "NONE" then
		return normalizedFallback
	end

	if ALLOWED_FONT_OUTLINE_VALUES[outline] then
		return outline
	end

	return normalizedFallback
end

function Utilities.IsSupportedUnit(unit)
	if issecretvalue and issecretvalue(unit) then
		return false
	end

	return type(unit) == "string" and (unit == "player" or unit:match("^party%d$") or unit:match("^raid%d+$"))
end

function Utilities:IsManagedAuraUnitVisible(unit)
	return unit and UnitExists(unit) and UnitIsVisible(unit)
end

function Utilities:GetManagedAuraUnit(unit)
	if not Utilities.IsSupportedUnit(unit) then
		return nil
	end

	if not UnitTargetsVehicleInRaidUI or not UnitTargetsVehicleInRaidUI(unit) then
		return unit
	end

	if
		unit == "player"
		and UnitExists("vehicle")
	then
		return "vehicle"
	end

	local partyIndex = unit:match("^party(%d)$")
	if partyIndex then
		local vehicleUnit = "partypet" .. partyIndex
		if UnitExists(vehicleUnit) then
			return vehicleUnit
		end
	end

	local raidIndex = unit:match("^raid(%d+)$")
	if raidIndex then
		local vehicleUnit = "raidpet" .. raidIndex
		if UnitExists(vehicleUnit) then
			return vehicleUnit
		end
	end

	return unit
end

function Utilities:GetGameFontNormalPath()
	return (GameFontNormal and select(1, GameFontNormal:GetFont()))
		or STANDARD_TEXT_FONT
		or "Fonts\\FRIZQT__.TTF"
end

function Utilities:GetPlayerClassFileName()
	local _, classFileName = UnitClass("player")
	return classFileName
end

function Utilities:GetPlayerSpecID()
	local specIndex = GetSpecialization and GetSpecialization()
	if not specIndex then
		return nil
	end

	return select(1, GetSpecializationInfo(specIndex))
end
