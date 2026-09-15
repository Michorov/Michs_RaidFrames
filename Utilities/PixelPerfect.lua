local _, addon = ...

addon.Utilities = addon.Utilities or {}

local PixelPerfect = {}
addon.Utilities.PixelPerfect = PixelPerfect

local step
local resolutionMultiplier
local globalScale = 1

function PixelPerfect:SetGlobalScale(value)
	if type(value) ~= "number" then
		value = 1
	end

	globalScale = math.min(2, math.max(0.5, value))
end

function PixelPerfect:RefreshScaling()
	local _, physicalHeight = GetPhysicalScreenSize()
	local uiScale = UIParent:GetEffectiveScale()

	local pixelScale = 768 / physicalHeight
	step = pixelScale / uiScale

	resolutionMultiplier = physicalHeight / 1080
end

function PixelPerfect:Scale(value)
	if type(value) ~= "number" or (value > -1 and value < 1) then
		return 0
	end

	local resolutionScaledValue = value * resolutionMultiplier
	local globalScaledValue = resolutionScaledValue * globalScale
	local roundedValue = addon.Utilities.Math:RoundToNearestInt(globalScaledValue)

	return roundedValue
end

function PixelPerfect:ToUI(pixelCount)
	return (pixelCount or 0) * step
end
