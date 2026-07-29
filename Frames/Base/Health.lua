local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Health = addon.Frames.Base.Health or {}

local Health = addon.Frames.Base.Health

local settingsCache = setmetatable({}, { __mode = "k" })
local CLASS_COLOR_TEXTURE = "Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\M-SolidDarker"
local STATIC_COLOR_TEXTURE = "Interface\\Buttons\\WHITE8x8"

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local health = (settings and settings.health) or {}
	local color = health.color or {}

	local result = {
		classColor = health.classColor == true,
		color = {
			r = color.r or 0.10,
			g = color.g or 0.80,
			b = color.b or 0.10,
			a = color.a or 1.0,
		},
	}

	result.texture = result.classColor and CLASS_COLOR_TEXTURE or STATIC_COLOR_TEXTURE

	settingsCache[settings] = result
end

local function ApplyHealthColor(healthBar, frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	local color = cachedSettings.color
	if not cachedSettings.classColor then
		healthBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
		return
	end

	local classToken

	if frame.previewWidgetVisibility then
		classToken = select(2, UnitClass("player"))
	else
		local unit = frame and frame.unit
		if unit and UnitExists(unit) then
			classToken = select(2, UnitClass(unit))
		end
	end

	local classColor = classToken and C_ClassColor.GetClassColor(classToken)
	if classColor then
		healthBar:SetStatusBarColor(classColor:GetRGBA())
	else
		healthBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
	end
end

function Health:Ensure(frame)
	if not frame.healthBar then
		local healthBar = CreateFrame("StatusBar", nil, frame)
		healthBar:SetAllPoints()
		healthBar:SetMinMaxValues(0, 1)
		healthBar:SetValue(0)
		frame.healthBar = healthBar
	end
end

function Health:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local healthBar = frame.healthBar
	healthBar:SetStatusBarTexture(cachedSettings.texture)
end

function Health:UpdateState(frame, settings)
	local healthBar = frame.healthBar

	local current, max = frame.dataProvider:GetHealth(frame)
	if current == nil or max == nil then
		return
	end

	healthBar:SetMinMaxValues(0, max)
	healthBar:SetValue(current)

	ApplyHealthColor(healthBar, frame, settings)
end

function Health:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healthSettingsChanged",
		stateReason = "healthStateChanged",
	})
end
