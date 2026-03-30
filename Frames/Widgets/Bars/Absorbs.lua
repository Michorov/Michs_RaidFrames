local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Bars = addon.Frames.Widgets.Bars or {}
addon.Frames.Widgets.Bars.Absorbs = addon.Frames.Widgets.Bars.Absorbs or {}

local Absorbs = addon.Frames.Widgets.Bars.Absorbs

local settingsCache = setmetatable({}, { __mode = "k" })

local ABSORB_TEXTURES = {
	Flat = "Interface\\Buttons\\WHITE8x8",
	Striped = "Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\Absorb",
}

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local widgets = (settings and settings.widgets) or {}
	local bars = widgets.bars or {}
	local absorbs = bars.absorbs or {}
	local color = absorbs.color or {}

	local result = {
		texture = ABSORB_TEXTURES[absorbs.texture] or ABSORB_TEXTURES.Flat,
		color = {
			r = color.r or 0.2,
			g = color.g or 0.8,
			b = color.b or 1.0,
			a = color.a or 0.5,
		},
	}

	settingsCache[settings] = result
end

function Absorbs:Ensure(frame)
	if not frame.absorbBar then
		local bar = CreateFrame("StatusBar", nil, frame)
		bar:SetFrameLevel(15)
		bar:SetOrientation("HORIZONTAL")
		bar:SetReverseFill(true)
		bar:SetAllPoints(frame)
		bar:Hide()

		local tex = bar:CreateTexture(nil, "ARTWORK")
		tex:SetTexture("Interface\\Buttons\\WHITE8x8", "REPEAT", "REPEAT")
		tex:SetHorizTile(true)
		tex:SetVertTile(true)

		bar:SetStatusBarTexture(tex)
		bar:SetStatusBarColor(1, 1, 1, 1)

		frame.absorbBar = bar
	end
end

function Absorbs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local bar = frame.absorbBar

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

function Absorbs:UpdateState(frame)
	local bar = frame.absorbBar

	local absorbValue, maxHealth = frame.dataProvider:GetAbsorbs(frame)
	if absorbValue == nil or maxHealth == nil then
		bar:Hide()
		return
	end

	bar:SetMinMaxValues(0, maxHealth)
	bar:SetValue(absorbValue)
	bar:Show()
end

function Absorbs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "absorbsSettingsChanged",
		stateReason = "absorbsStateChanged",
	})
end
