local _, addon = ...

local Utilities = {}
addon.Utilities = Utilities

local cachedPixelStep = nil

function Utilities:RefreshPixelGrid()
    local _, physicalHeight = GetPhysicalScreenSize()
    local uiScale = UIParent:GetEffectiveScale()

    local pixelScale = 768 / physicalHeight
    cachedPixelStep = pixelScale / uiScale
end

function Utilities:GetPixelStep()
    if not cachedPixelStep then
        self:RefreshPixelGrid()
    end
    return cachedPixelStep
end

function Utilities:ToPixels(value)
    local step = self:GetPixelStep()
    return math.floor((value or 0) / step + 0.5)
end

function Utilities:FromPixels(pixelCount)
    return (pixelCount or 0) * self:GetPixelStep()
end

function Utilities:SnapPixels(value)
    return self:FromPixels(self:ToPixels(value))
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
