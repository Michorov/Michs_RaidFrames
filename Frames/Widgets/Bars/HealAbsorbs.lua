local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Bars = addon.Frames.Widgets.Bars or {}
addon.Frames.Widgets.Bars.HealAbsorbs = addon.Frames.Widgets.Bars.HealAbsorbs or {}

local HealAbsorbs = addon.Frames.Widgets.Bars.HealAbsorbs

local settingsCache = setmetatable({}, { __mode = "k" })

local HEAL_ABSORB_TEXTURES = {
	Flat = "Interface\\Buttons\\WHITE8x8",
	Striped = "Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\Absorb",
}

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local widgets = (settings and settings.widgets) or {}
	local bars = widgets.bars or {}
	local healAbsorbs = bars.healAbsorbs or {}
	local color = healAbsorbs.color or {}

	local result = {
		texture = HEAL_ABSORB_TEXTURES[healAbsorbs.texture] or HEAL_ABSORB_TEXTURES.Flat,
		color = {
			r = color.r or 1,
			g = color.g or 0,
			b = color.b or 0,
			a = color.a or 0.5,
		},
	}

	settingsCache[settings] = result
end

function HealAbsorbs:Ensure(frame)
	if not frame.healAbsorbBar then
		local bar = CreateFrame("StatusBar", nil, frame)
		bar:SetFrameLevel(15)
		bar:SetOrientation("HORIZONTAL")
		bar:SetReverseFill(false)
		bar:SetAllPoints(frame)
		bar:Hide()
		frame.healAbsorbBar = bar
	end
end

function HealAbsorbs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local bar = frame.healAbsorbBar

	local healthTex = frame.healthBar:GetStatusBarTexture()
	if healthTex then
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", healthTex, "TOPLEFT", 0, 0)
		bar:SetPoint("BOTTOMRIGHT", healthTex, "BOTTOMRIGHT", 0, 0)
	end

	bar:SetStatusBarTexture(cachedSettings.texture)
	local tex = bar:GetStatusBarTexture()
	if tex then
		tex:SetTexture(cachedSettings.texture, "REPEAT", "REPEAT")
		tex:SetHorizTile(true)
		tex:SetVertTile(true)
	end

	bar:SetStatusBarColor(
		cachedSettings.color.r,
		cachedSettings.color.g,
		cachedSettings.color.b,
		cachedSettings.color.a
	)
end

function HealAbsorbs:UpdateState(frame)
	local bar = frame.healAbsorbBar

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.healAbsorbs ~= true then
		bar:Hide()
		return
	end

	local healAbsorbValue = frame.dataProvider:GetHealAbsorbs(frame)
	if healAbsorbValue == nil then
		bar:Hide()
		return
	end

	local currentHealth = frame.dataProvider:GetHealth(frame)
	if currentHealth == nil then
		bar:Hide()
		return
	end

	bar:SetMinMaxValues(0, currentHealth)
	bar:SetValue(healAbsorbValue)
	bar:Show()
end

function HealAbsorbs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healAbsorbsSettingsChanged",
		stateReason = "healAbsorbsStateChanged",
	})
end
