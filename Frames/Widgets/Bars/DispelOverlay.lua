local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Bars = addon.Frames.Widgets.Bars or {}
addon.Frames.Widgets.Bars.DispelOverlay = addon.Frames.Widgets.Bars.DispelOverlay or {}

local DispelOverlay = addon.Frames.Widgets.Bars.DispelOverlay

local settingsCache = setmetatable({}, { __mode = "k" })

local OVERLAY_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local OVERLAY_MASK_TEXTURE = "Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\VerticalGradientMask"
local OVERLAY_MASK_EDGE_TEXCOORD = 0.0625
local OVERLAY_STYLE_FULL = "FULL"
local OVERLAY_STYLE_GRADIENT = "GRADIENT"

local DISPEL_CURVE_DEFAULTS = {
	None = { 0, DEBUFF_TYPE_NONE_COLOR },
	Magic = { 1, DEBUFF_TYPE_MAGIC_COLOR },
	Curse = { 2, DEBUFF_TYPE_CURSE_COLOR },
	Disease = { 3, DEBUFF_TYPE_DISEASE_COLOR },
	Poison = { 4, DEBUFF_TYPE_POISON_COLOR },
	Enrage = { 9, DEBUFF_TYPE_BLEED_COLOR },
	Bleed = { 11, DEBUFF_TYPE_BLEED_COLOR },
}

local dispelCurve = C_CurveUtil.CreateColorCurve()
dispelCurve:SetType(Enum.LuaCurveType.Step)

for _, data in pairs(DISPEL_CURVE_DEFAULTS) do
	dispelCurve:AddPoint(data[1], data[2])
end

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local dispelOverlay = icons.dispelOverlay or {}
	local style = dispelOverlay.style

	settingsCache[settings] = {
		enabled = dispelOverlay.enabled ~= false,
		style = style == OVERLAY_STYLE_GRADIENT and OVERLAY_STYLE_GRADIENT or OVERLAY_STYLE_FULL,
	}
end

local function GetColorRGBA(color)
	if not color then
		return nil
	end

	if type(color.GetRGBA) == "function" then
		local ok, r, g, b, a = pcall(color.GetRGBA, color)
		if ok and r ~= nil and g ~= nil and b ~= nil then
			return r, g, b, a
		end
	end

	local ok, r, g, b, a = pcall(function()
		return color.r, color.g, color.b, color.a
	end)
	if ok and r ~= nil and g ~= nil and b ~= nil then
		return r, g, b, a
	end

	return nil
end

local function ApplyColor(texture, color)
	if not color then
		return false
	end

	local r, g, b = GetColorRGBA(color)
	if r ~= nil and g ~= nil and b ~= nil then
		texture:SetColorTexture(r, g, b, 1)
		texture:SetAlpha(1)
		return true
	end

	if texture.SetGradient then
		local ok = pcall(texture.SetGradient, texture, "VERTICAL", color, color)
		if ok then
			texture:SetAlpha(1)
			return true
		end
	end

	return false
end

function DispelOverlay:Ensure(frame)
	if not frame.dispelOverlay then
		local overlay = CreateFrame("Frame", nil, frame)
		overlay:SetFrameLevel(6)
		overlay:Hide()

		overlay.texture = overlay:CreateTexture(nil, "ARTWORK")
		overlay.texture:SetAllPoints(overlay)
		overlay.texture:SetTexture(OVERLAY_TEXTURE)

		overlay.gradientTexture = overlay:CreateTexture(nil, "ARTWORK")
		overlay.gradientTexture:SetAllPoints(overlay)
		overlay.gradientTexture:SetTexture(OVERLAY_TEXTURE)
		overlay.gradientTexture:Hide()

		if overlay.CreateMaskTexture and overlay.gradientTexture.AddMaskTexture then
			overlay.gradientMask = overlay:CreateMaskTexture(nil, "ARTWORK")
			overlay.gradientMask:SetAllPoints(overlay.gradientTexture)
			overlay.gradientMask:SetTexture(OVERLAY_MASK_TEXTURE)
			overlay.gradientMask:SetTexCoord(OVERLAY_MASK_EDGE_TEXCOORD, 1 - OVERLAY_MASK_EDGE_TEXCOORD, 0, 1)
			overlay.gradientTexture:AddMaskTexture(overlay.gradientMask)
		end

		overlay:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
		overlay:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)

		overlay.activeTexture = overlay.texture

		frame.dispelOverlay = overlay
	end
end

function DispelOverlay:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	local overlay = frame.dispelOverlay
	local cachedSettings = settingsCache[settings]
	local activeTexture = overlay.texture
	local inactiveTexture = overlay.gradientTexture

	if cachedSettings.style == OVERLAY_STYLE_GRADIENT and overlay.gradientTexture and overlay.gradientMask then
		activeTexture = overlay.gradientTexture
		inactiveTexture = overlay.texture
	end

	overlay.activeTexture = activeTexture

	activeTexture:Show()
	inactiveTexture:Hide()
end

function DispelOverlay:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]
	local overlay = frame.dispelOverlay

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.dispelOverlay ~= true then
		overlay:Hide()
		return
	end

	if not cachedSettings.enabled then
		overlay:Hide()
		return
	end

	local provider = frame.dataProvider
	local unit = frame.unit
	local isTestProvider = provider == addon.Frames.DataProvider.Test

	if not isTestProvider and (not unit or not UnitExists(unit) or not UnitIsVisible(unit)) then
		overlay:Hide()
		return
	end

	local aura
	for _, currentAura in pairs(provider:GetUnitAuras(frame, "harmfulRaidPlayerDispellable")) do
		aura = currentAura
		break
	end

	if not aura then
		overlay:Hide()
		return
	end

	local color = provider:GetAuraDispelTypeColor(frame, aura, dispelCurve)
	if not color then
		overlay:Hide()
		return
	end

	local activeTexture = overlay.activeTexture
	if not ApplyColor(activeTexture, color) then
		overlay:Hide()
		return
	end

	overlay:Show()
end

function DispelOverlay:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "dispelOverlaySettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
