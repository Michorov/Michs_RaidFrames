local _, addon = ...

local Utilities = {}
addon.Utilities = Utilities

local cachedPixelStep = nil

local function RoundToNearestInt(value)
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
	return RoundToNearestInt((value or 0) / step)
end

function Utilities:Scale(pixelCount)
	local scaledPx = (pixelCount or 0) * GetGlobalScale()
	return RoundToNearestInt(scaledPx)
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

function Utilities:GetUnitClassColor(unit, fallbackColor)
	local fallback = fallbackColor or {}
	local fr = fallback.r or 1
	local fg = fallback.g or 1
	local fb = fallback.b or 1
	local fa = fallback.a or 1

	if not unit or not UnitExists(unit) then
		return fr, fg, fb, fa
	end

	local classFilename = select(2, UnitClass(unit))
	if not classFilename then
		return fr, fg, fb, fa
	end

	local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename]
	if not classColor then
		return fr, fg, fb, fa
	end

	return classColor.r or fr, classColor.g or fg, classColor.b or fb, fa
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
