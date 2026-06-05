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

local function GetClassHealthColor(frame, classToken)
	if frame.previewWidgetVisibility then
		return addon.Style.Colors:GetUnitClassBackgroundColor("player")
	end

	return addon.Style.Colors:GetClassBackgroundColor(classToken)
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
	healthBar.classToken = nil
	healthBar:SetStatusBarTexture(cachedSettings.texture)
end

function Health:UpdateState(frame, settings)
	local healthBar = frame.healthBar

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	local current, max = frame.dataProvider:GetHealth(frame)
	if current == nil or max == nil then
		return
	end

	healthBar:SetMinMaxValues(0, max)
	healthBar:SetValue(current)

	if not cachedSettings.classColor then
		if healthBar.classToken == false then
			return
		end

		healthBar.classToken = false
		local color = cachedSettings.color
		healthBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
		return
	end

	local classToken = frame.dataProvider:GetClassToken(frame)
	if classToken == healthBar.classToken then
		return
	end

	healthBar.classToken = classToken
	healthBar:SetStatusBarColor(GetClassHealthColor(frame, classToken))
end

function Health:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healthSettingsChanged",
		stateReason = "healthStateChanged",
	})
end
