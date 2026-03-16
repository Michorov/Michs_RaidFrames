local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Bars = addon.Frames.Widgets.Bars or {}
addon.Frames.Widgets.Bars.Absorbs = addon.Frames.Widgets.Bars.Absorbs or {}

local Absorbs = addon.Frames.Widgets.Bars.Absorbs

local ABSORB_TEXTURES = {
	Flat = "Interface\\Buttons\\WHITE8x8",
	Striped = "Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\Absorb",
}

local function ResolveAbsorbTexture(textureKey)
	if type(textureKey) == "string" and ABSORB_TEXTURES[textureKey] then
		return ABSORB_TEXTURES[textureKey]
	end

	if type(textureKey) == "string" and textureKey ~= "" then
		return textureKey
	end

	return ABSORB_TEXTURES.Striped
end

local function GetAbsorbSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local bars = widgets.bars or {}
	local absorbs = bars.absorbs or {}
	local color = absorbs.color or {}

	return {
		texture = ResolveAbsorbTexture(absorbs.texture),
		color = {
			r = color.r or 0.2,
			g = color.g or 0.8,
			b = color.b or 1.0,
			a = color.a or 0.5,
		},
	}
end

function Absorbs:Ensure(frame)
	if not frame then
		return
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not widgetsOverlay then
		return
	end

	if not frame.absorbBar then
		local bar = CreateFrame("StatusBar", nil, widgetsOverlay)
		bar:SetFrameStrata(widgetsOverlay:GetFrameStrata())
		bar:SetFrameLevel(widgetsOverlay:GetFrameLevel() + 5)
		bar:SetOrientation("HORIZONTAL")
		bar:SetReverseFill(true)
		bar:Hide()

		local tex = bar:CreateTexture(nil, "ARTWORK")
		tex:SetTexture("Interface\\Buttons\\WHITE8x8", "REPEAT", "REPEAT")
		tex:SetHorizTile(true)
		tex:SetVertTile(true)

		bar:SetStatusBarTexture(tex)
		bar:SetStatusBarColor(1, 1, 1, 1)

		frame.absorbBar = bar
	end

	local bar = frame.absorbBar
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", widgetsOverlay, "TOPLEFT", 0, 0)
	bar:SetPoint("BOTTOMRIGHT", widgetsOverlay, "BOTTOMRIGHT", 0, 0)
end

function Absorbs:UpdateSettings(frame, settings)
	local absorbSettings = GetAbsorbSettings(settings)
	local bar = frame and frame.absorbBar
	if not bar then
		return
	end

	local tex = bar:GetStatusBarTexture()
	if tex then
		tex:SetTexture(absorbSettings.texture, "REPEAT", "REPEAT")
		tex:SetHorizTile(true)
		tex:SetVertTile(true)
	end

	bar:SetStatusBarColor(
		absorbSettings.color.r,
		absorbSettings.color.g,
		absorbSettings.color.b,
		absorbSettings.color.a
	)
end

function Absorbs:UpdateState(frame)
	local bar = frame and frame.absorbBar
	if not bar then
		return
	end

	local provider = frame and frame.dataProvider

	local absorbValue, maxHealth = provider:GetAbsorbs(frame)
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
