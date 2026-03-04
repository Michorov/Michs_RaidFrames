local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Health = addon.Frames.Base.Health or {}

local Health = addon.Frames.Base.Health

local function GetHealthColor(frame, settings)
	local health = (settings and settings.health) or {}
	local color = health.color or {}

	if health.classColor then
		return addon.Utilities:GetUnitClassColor(frame and frame.unit, color)
	end

	return color.r or 0.10, color.g or 0.80, color.b or 0.10, color.a or 1.0
end

local function GetHealthTexture(settings)
	local health = (settings and settings.health) or {}
	return health.texture or "Interface\\Buttons\\WHITE8x8"
end

function Health:Ensure(frame)
	if not frame then
		return
	end

	local healthBar = frame.healthBar

	if not healthBar then
		healthBar = CreateFrame("StatusBar", nil, frame)

		healthBar:SetAllPoints()
		healthBar:SetMinMaxValues(0, 1)
		healthBar:SetValue(0)

		frame.healthBar = healthBar
	end
end

function Health:UpdateSettings(frame, settings)
	local healthBar = frame and frame.healthBar
	if not healthBar then
		return
	end

	local texturePath = GetHealthTexture(settings)
	local r, g, b, a = GetHealthColor(frame, settings)

	healthBar:SetStatusBarTexture(texturePath)
	healthBar:SetStatusBarColor(r, g, b, a)
end

function Health:UpdateState(frame, settings)
	local healthBar = frame and frame.healthBar
	if not healthBar then
		return
	end

	local unit = frame.unit
	if not UnitExists(unit) then
		healthBar:Hide()
		return
	end

	local maxHealth = UnitHealthMax(unit)
	local currentHealth = UnitHealth(unit)

	healthBar:SetMinMaxValues(0, maxHealth)
	healthBar:SetValue(currentHealth)

	local r, g, b, a = GetHealthColor(frame, settings)
	healthBar:SetStatusBarColor(r, g, b, a)

	healthBar:Show()
end

function Health:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healthSettingsChanged",
		stateReason = "healthStateChanged",
	})
end
