local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.HealPrediction = addon.Frames.Widgets.Indicators.HealPrediction or {}

local HealPrediction = addon.Frames.Widgets.Indicators.HealPrediction

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local prediction = indicators.healPrediction or {}
	local color = prediction.color or {}

	settingsCache[settings] = {
		enabled = prediction.enabled == true,
		color = {
			r = color.r or 0.1,
			g = color.g or 0.6,
			b = color.b or 0.2,
			a = color.a or 1,
		},
	}
end

function HealPrediction:Ensure(frame)
	if not frame.healPredictionBar then
		local clip = CreateFrame("Frame", nil, frame)
		clip:SetAllPoints(frame.healthBar)
		clip:SetFrameLevel(14)
		clip:SetClipsChildren(true)

		local bar = CreateFrame("StatusBar", nil, clip)
		local healthTexture = frame.healthBar:GetStatusBarTexture()
		bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		bar:SetPoint("TOPLEFT", healthTexture, "TOPRIGHT", 0, 0)
		bar:SetPoint("BOTTOMLEFT", healthTexture, "BOTTOMRIGHT", 0, 0)
		bar:SetOrientation("HORIZONTAL")
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(0)
		bar:Hide()
		frame.healPredictionBar = bar
	end
end

function HealPrediction:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]
	local bar = frame.healPredictionBar

	bar:SetWidth(frame.healthBar:GetWidth())
	bar:SetStatusBarColor(cachedSettings.color.r, cachedSettings.color.g, cachedSettings.color.b, cachedSettings.color.a)
end

function HealPrediction:UpdateState(frame, settings)
	local bar = frame.healPredictionBar
	local cachedSettings = settingsCache[settings]
	if not cachedSettings.enabled
		or (frame.previewWidgetVisibility and frame.previewWidgetVisibility.healPrediction ~= true)
	then
		bar:Hide()
		return
	end

	local incomingHeals, maxHealth = frame.dataProvider:GetHealPrediction(frame)
	if incomingHeals == nil or maxHealth == nil then
		bar:Hide()
		return
	end

	bar:SetMinMaxValues(0, maxHealth)
	bar:SetValue(incomingHeals)
	bar:Show()
end

function HealPrediction:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healPredictionSettingsChanged",
		stateReason = "healPredictionStateChanged",
	})
end
