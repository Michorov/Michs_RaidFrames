local MAJOR, MINOR = "MichsPixelPerfectLib-2.0", 5

assert(LibStub, MAJOR .. " requires LibStub")

local MichsPixelPerfect = LibStub:NewLibrary(MAJOR, MINOR)
if not MichsPixelPerfect then
	return
end

local cachedPixelStep
local resolutionMultiplier

local Scaler = MichsPixelPerfect.Scaler or {}
MichsPixelPerfect.Scaler = Scaler
Scaler.__index = Scaler

local activeScalers = MichsPixelPerfect.activeScalers or setmetatable({}, { __mode = "k" })
MichsPixelPerfect.activeScalers = activeScalers

local function RefreshPixelGrid()
	local _, physicalHeight = GetPhysicalScreenSize()
	local uiScale = UIParent and UIParent:GetEffectiveScale()

	if type(physicalHeight) ~= "number" or physicalHeight <= 0 then
		physicalHeight = 1080
	end

	if type(uiScale) ~= "number" or uiScale <= 0 then
		uiScale = 1
	end

	local pixelScale = 768 / physicalHeight
	cachedPixelStep = pixelScale / uiScale
	resolutionMultiplier = physicalHeight / 1080
end

local function GetPixelStep()
	if not cachedPixelStep then
		RefreshPixelGrid()
	end
	return cachedPixelStep
end

local function RoundToNearestInt(value)
	value = value or 0

	if value >= 0 then
		return math.floor(value + 0.5)
	end

	return math.ceil(value - 0.5)
end

local function Scale(scaler, value)
	if type(value) ~= "number" or (value > -1 and value < 1) then
		return 0
	end

	local scaledPixels = value * resolutionMultiplier * scaler.globalScale
	if scaledPixels > 0 then
		scaledPixels = math.max(1, scaledPixels)
	elseif scaledPixels < 0 then
		scaledPixels = math.min(-1, scaledPixels)
	end

	return RoundToNearestInt(scaledPixels)
end

local function ToPixels(uiUnits)
	return RoundToNearestInt((uiUnits or 0) / GetPixelStep())
end

local function ToRawUI(pixelCount)
	return (pixelCount or 0) * GetPixelStep()
end

local function RunUpdateCallbacks(scaler, updateEvent)
	local updateCallbacks = scaler.updateCallbacks
	if not updateCallbacks then
		return
	end

	for index = 1, #updateCallbacks do
		local callback = updateCallbacks[index]
		callback(updateEvent)
	end
end

local function RunAllUpdateCallbacks(updateEvent)
	for scaler in pairs(activeScalers) do
		RunUpdateCallbacks(scaler, updateEvent)
	end
end

function MichsPixelPerfect:CreateScaler()
	local scaler = {
		globalScale = 1,
		updateCallbacks = {},
	}

	activeScalers[scaler] = true

	return setmetatable(scaler, Scaler)
end

function Scaler:SetGlobalScale(value)
	if type(value) ~= "number" then
		return
	end

	local nextGlobalScale = math.min(2, math.max(0.5, value))
	if self.globalScale == nextGlobalScale then
		return
	end

	self.globalScale = nextGlobalScale
	RunUpdateCallbacks(self, "GLOBAL_SCALE_CHANGED")
end

function Scaler:RegisterForUpdate(callback)
	if type(callback) ~= "function" then
		return
	end

	self.updateCallbacks = self.updateCallbacks or {}
	self.updateCallbacks[#self.updateCallbacks + 1] = callback

	callback("REGISTERED")
end

function Scaler:ToUI(value)
	local step = GetPixelStep()
	return Scale(self, value) * step
end

function Scaler:CenterElement(element, parent, offsetX, offsetY)
	parent = parent or UIParent

	if not element or not parent then
		return
	end

	local parentWidthPx = ToPixels(parent:GetWidth())
	local parentHeightPx = ToPixels(parent:GetHeight())
	local elementWidthPx = ToPixels(element:GetWidth())
	local elementHeightPx = ToPixels(element:GetHeight())
	local offsetXPx = Scale(self, offsetX)
	local offsetYPx = Scale(self, offsetY)
	local leftPx = RoundToNearestInt(((parentWidthPx - elementWidthPx) / 2) + offsetXPx)
	local bottomPx = RoundToNearestInt(((parentHeightPx - elementHeightPx) / 2) + offsetYPx)

	element:ClearAllPoints()
	element:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", ToRawUI(leftPx), ToRawUI(bottomPx))
end

local pixelGridEventFrame = CreateFrame("Frame")
pixelGridEventFrame:RegisterEvent("PLAYER_LOGIN")
pixelGridEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
pixelGridEventFrame:RegisterEvent("UI_SCALE_CHANGED")
pixelGridEventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
pixelGridEventFrame:SetScript("OnEvent", function(_, event)
	C_Timer.After(0, function()
		RefreshPixelGrid()
		RunAllUpdateCallbacks(event)
	end)
end)

RefreshPixelGrid()
