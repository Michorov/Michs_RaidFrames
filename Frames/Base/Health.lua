local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Health = addon.Frames.Base.Health or {}

local Health = addon.Frames.Base.Health

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local health = (settings and settings.health) or {}
	local color = health.color or {}

	local result = {
		texture = health.texture or "Interface\\Buttons\\WHITE8x8",
		classColor = health.classColor == true,
		color = {
			r = color.r or 0.10,
			g = color.g or 0.80,
			b = color.b or 0.10,
			a = color.a or 1.0,
		},
	}

	settingsCache[settings] = result
end

local function GetHealthColor(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if cachedSettings.classColor then
		return frame.dataProvider:GetClassColor(frame, cachedSettings.color)
	end

	local color = cachedSettings.color
	return color.r, color.g, color.b, color.a
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
	healthBar:SetStatusBarColor(GetHealthColor(frame, settings))
end

function Health:UpdateState(frame, settings)
	local healthBar = frame.healthBar

	local current, max = frame.dataProvider:GetHealth(frame)
	if current == nil or max == nil then
		return
	end

	healthBar:SetMinMaxValues(0, max)
	healthBar:SetValue(current)
	healthBar:SetStatusBarColor(GetHealthColor(frame, settings))
end

function Health:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healthSettingsChanged",
		stateReason = "healthStateChanged",
	})
end
