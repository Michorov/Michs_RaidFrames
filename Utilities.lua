local _, addon = ...

local Utilities = {}
addon.Utilities = Utilities

local cachedPixelStep = nil

local function RoundToNearestInt(value)
	return math.floor((value or 0) + 0.5)
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

-- Normalizes Values from Db. Sets scale for Monitor Size
function Utilities:ToPixels(value)
	local step = GetPixelStep()
	return math.floor((value or 0) / step + 0.5)
end

-- Calculates with the Scaling %
function Utilities:Scale(pixelCount)
	local scaledPx = (pixelCount or 0) * GetGlobalScale()
	return RoundToNearestInt(scaledPx)
end

-- Calculates with the Scaling % to even number for frames
function Utilities:ScaleEven(pixelCount)
	local px = self:Scale(pixelCount)
	if (px % 2) ~= 0 then
		px = px + 1
	end
	return px
end

-- Calculates the UI Units from Value
function Utilities:ToUI(pixelCount)
	return (pixelCount or 0) * GetPixelStep()
end

-- Calculates the Font Scale
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
