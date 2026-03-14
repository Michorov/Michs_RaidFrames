local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Dispels = addon.Frames.Widgets.Icons.Dispels or {}

local Dispels = addon.Frames.Widgets.Icons.Dispels

local DISPEL_TEXTURE = "Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\DispelIconFill"
local DISPEL_BORDER_TEXTURE = "Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\DispelIconBorder"

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

local function GetDispelsSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.icons or {}
	local dispels = indicators.dispels or {}

	return {
		enabled = dispels.enabled ~= false,
		anchor = dispels.anchor or "TOPRIGHT",
		relativeAnchor = dispels.relativeAnchor or "TOPRIGHT",
		growDirection = dispels.growDirection or "LEFT",
		offsetXPx = addon.Utilities:ToPixels(dispels.offsetX or -2),
		offsetYPx = addon.Utilities:ToPixels(dispels.offsetY or -2),
		iconSizePx = addon.Utilities:ToPixels(dispels.iconSize or 12),
		spacingPx = addon.Utilities:ToPixels(dispels.spacing or 2),
		alpha = dispels.alpha or 1,
		maxIcons = math.max(1, dispels.maxIcons or 4),
	}
end

local function GetGrowthOffsets(growDirection, stepPx)
	if growDirection == "RIGHT" then
		return stepPx, 0
	elseif growDirection == "UP" then
		return 0, stepPx
	elseif growDirection == "DOWN" then
		return 0, -stepPx
	end

	return -stepPx, 0
end

function Dispels:Ensure(frame, settings)
	local dispelSettings = GetDispelsSettings(settings)
	if not frame then
		return
	end

	if not frame.dispelsContainer then
		frame.dispelsContainer = CreateFrame("Frame", nil, frame.widgetsOverlay)
	end

	local container = frame.dispelsContainer
	container.icons = container.icons or {}

	for i = 1, dispelSettings.maxIcons do
		local icon = container.icons[i]
		if not icon then
			icon = CreateFrame("Frame", nil, container)
			icon:SetFrameLevel(container:GetFrameLevel() + 20)

			icon.texture = icon:CreateTexture(nil, "ARTWORK")
			icon.texture:SetAllPoints()
			icon.texture:SetTexture(DISPEL_TEXTURE)

			icon.border = icon:CreateTexture(nil, "OVERLAY")
			icon.border:SetAllPoints()
			icon.border:SetTexture(DISPEL_BORDER_TEXTURE)
			icon.border:SetVertexColor(0, 0, 0, 1)

			container.icons[i] = icon
		end
	end
end

function Dispels:UpdateSettings(frame, settings)
	local dispelSettings = GetDispelsSettings(settings)
	local container = frame and frame.dispelsContainer
	if not container then
		return
	end

	local iconSizePx = addon.Utilities:ScaleEven(dispelSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(dispelSettings.spacingPx)
	local offsetXPx = addon.Utilities:Scale(dispelSettings.offsetXPx)
	local offsetYPx = addon.Utilities:Scale(dispelSettings.offsetYPx)
	local stepPx = iconSizePx + spacingPx

	container:ClearAllPoints()
	container:SetPoint(
		dispelSettings.anchor,
		container:GetParent(),
		dispelSettings.relativeAnchor,
		addon.Utilities:ToUI(offsetXPx),
		addon.Utilities:ToUI(offsetYPx)
	)

	local widthPx
	local heightPx
	if dispelSettings.growDirection == "UP" or dispelSettings.growDirection == "DOWN" then
		widthPx = iconSizePx
		heightPx = (dispelSettings.maxIcons * iconSizePx) + ((dispelSettings.maxIcons - 1) * spacingPx)
	else
		widthPx = (dispelSettings.maxIcons * iconSizePx) + ((dispelSettings.maxIcons - 1) * spacingPx)
		heightPx = iconSizePx
	end

	container:SetSize(addon.Utilities:ToUI(widthPx), addon.Utilities:ToUI(heightPx))

	local dx, dy = GetGrowthOffsets(dispelSettings.growDirection, stepPx)

	for i = 1, dispelSettings.maxIcons do
		local icon = container.icons[i]
		if not icon then
			icon = CreateFrame("Frame", nil, container)
			icon:SetFrameLevel(container:GetFrameLevel() + 20)

			icon.texture = icon:CreateTexture(nil, "ARTWORK")
			icon.texture:SetAllPoints()
			icon.texture:SetTexture(DISPEL_TEXTURE)

			icon.border = icon:CreateTexture(nil, "OVERLAY")
			icon.border:SetAllPoints()
			icon.border:SetTexture(DISPEL_BORDER_TEXTURE)
			icon.border:SetVertexColor(0, 0, 0, 1)

			container.icons[i] = icon
		end

		icon:SetSize(addon.Utilities:ToUI(iconSizePx), addon.Utilities:ToUI(iconSizePx))
		icon:SetAlpha(dispelSettings.alpha)

		local xPx = dx * (i - 1)
		local yPx = dy * (i - 1)

		icon:ClearAllPoints()
		icon:SetPoint(
			dispelSettings.anchor,
			container,
			dispelSettings.anchor,
			addon.Utilities:ToUI(xPx),
			addon.Utilities:ToUI(yPx)
		)
	end

	for i = dispelSettings.maxIcons + 1, #(container.icons or {}) do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end
end

function Dispels:UpdateState(frame, settings)
	local dispelSettings = GetDispelsSettings(settings)
	local container = frame and frame.dispelsContainer
	if not container then
		return
	end

	if not dispelSettings.enabled then
		for i = 1, dispelSettings.maxIcons do
			local icon = container.icons[i]
			if icon then
				icon:Hide()
			end
		end
		container:Hide()
		return
	end

	local provider = frame and frame.dataProvider
	local unit = frame and frame.unit
	local isTestProvider = provider == addon.Frames.DataProvider.Test

	if not isTestProvider and (not unit or not UnitExists(unit) or not UnitIsVisible(unit)) then
		container:Hide()
		return
	end

	local shown = 0
	local maxIcons = dispelSettings.maxIcons
	local auras = provider:GetUnitAuras(frame, "harmfulRaidPlayerDispellable")

	for _, aura in ipairs(auras) do
		if shown >= maxIcons then
			break
		end

		local color = provider:GetAuraDispelTypeColor(frame, aura, dispelCurve)
		if color then
			local icon = container.icons[shown + 1]
			if icon and icon.texture then
				shown = shown + 1
				icon.texture:SetTexture(DISPEL_TEXTURE)
				icon.texture:SetVertexColor(color.r, color.g, color.b, dispelSettings.alpha or 1)
				icon:SetAlpha(dispelSettings.alpha or 1)
				icon:Show()
			end
		end
	end

	for i = shown + 1, maxIcons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end

	container:SetShown(shown > 0)
end

function Dispels:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "dispelsSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
