local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Dispels = addon.Frames.Widgets.Icons.Dispels or {}

local Dispels = addon.Frames.Widgets.Icons.Dispels

local function BuildPreviewSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local dispels = icons.dispels or {}
	local border = (settings and settings.border) or {}
	local gradientDirection = dispels.gradientDirection == 1 and 1 or 0

	return {
		enabled = dispels.enabled ~= false,
		showOverlay = dispels.showOverlay ~= false,
		showIcons = dispels.showIcons ~= false,
		anchor = dispels.anchor or "TOPRIGHT",
		iconSizePx = addon.Utilities:ToPixels(dispels.iconSize or 14),
		spacingPx = addon.Utilities:ToPixels(dispels.spacing or 0),
		showBorder = dispels.showBorder ~= false,
		frameBorderSizePx = addon.Utilities:ToPixels(border.thicknessPx or 1),
		texture = dispels.texture == "Flat" and "Flat" or "Gradient",
		gradientDirection = gradientDirection,
	}
end

local function CreatePreviewIcon(container)
	local icon = CreateFrame("Frame", nil, container)
	icon:EnableMouse(false)

	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints(icon)

	icon:Hide()
	return icon
end

local function CreatePreview(container)
	container.previewGradient = container:CreateTexture(nil, "ARTWORK")
	container.previewGradient:SetTexture("Interface\\Buttons\\WHITE8x8")
	container.previewGradient:SetBlendMode("BLEND")

	container.previewFlat = container:CreateTexture(nil, "ARTWORK")
	container.previewFlat:SetBlendMode("BLEND")
	container.previewFlat:Hide()

	container.previewBorder = CreateFrame("Frame", nil, container, BackdropTemplateMixin and "BackdropTemplate")
	container.previewBorder:SetAllPoints(container)

	container.previewIcons = {}
	for index = 1, 3 do
		container.previewIcons[index] = CreatePreviewIcon(container)
	end
end

local function GetPreviewAuras(frame)
	local provider = frame.dataProvider
	local auras = provider and provider.GetDispelPreviewAuras and provider:GetDispelPreviewAuras(frame)
	local result = {}

	for _, aura in pairs(auras or {}) do
		if aura and aura.atlas then
			table.insert(result, aura)
		end
	end

	table.sort(result, function(left, right)
		return (left.auraInstanceID or left.spellId or 0) < (right.auraInstanceID or right.spellId or 0)
	end)

	return result
end

local function GetPreviewColor(frame, aura)
	local provider = frame.dataProvider
	local color = provider and provider.GetAuraDispelTypeColor and provider:GetAuraDispelTypeColor(frame, aura)
	return color or DEBUFF_TYPE_MAGIC_COLOR or { r = 0.2, g = 0.6, b = 1, a = 1 }
end

local function ApplyPreviewGradientDirection(texture, gradientDirection)
	if gradientDirection ~= 1 then
		return
	end

	local upperLeftX, upperLeftY, lowerLeftX, lowerLeftY, upperRightX, upperRightY, lowerRightX, lowerRightY =
		texture:GetTexCoord()
	if upperRightX then
		texture:SetTexCoord(
			lowerLeftX,
			lowerLeftY,
			upperLeftX,
			upperLeftY,
			lowerRightX,
			lowerRightY,
			upperRightX,
			upperRightY
		)
	else
		texture:SetTexCoord(upperLeftX, upperLeftY, lowerLeftY, lowerLeftX)
	end
end

local function ApplyPreviewGradient(texture, aura, color, gradientDirection)
	texture:ClearAllPoints()
	texture:SetAllPoints(texture:GetParent())
	texture:SetTexCoord(0, 1, 0, 1)

	if SetTextureWithAddressModeOptions and TextureKitConstants then
		SetTextureWithAddressModeOptions(
			texture,
			"_RaidFrame-Dispel-Highlight-Horizontal",
			TextureKitConstants.IgnoreAtlasSize,
			TextureKitConstants.AddressModeWrap,
			TextureKitConstants.AddressModeClamp
		)
		ApplyPreviewGradientDirection(texture, gradientDirection)
	elseif texture.SetAtlas then
		texture:SetAtlas("_RaidFrame-Dispel-Highlight-Horizontal", false)
		ApplyPreviewGradientDirection(texture, gradientDirection)
	elseif texture.SetGradientAlpha then
		texture:SetTexture("Interface\\Buttons\\WHITE8x8")
		if gradientDirection == 1 then
			texture:SetGradientAlpha("VERTICAL", color.r, color.g, color.b, 0.65, color.r, color.g, color.b, 0)
		else
			texture:SetGradientAlpha("VERTICAL", color.r, color.g, color.b, 0, color.r, color.g, color.b, 0.65)
		end
	else
		texture:SetColorTexture(color.r, color.g, color.b, 0.35)
	end

	if aura and aura.dispelName and AuraUtil and AuraUtil.SetAuraBorderColor then
		AuraUtil.SetAuraBorderColor(texture, aura.dispelName)
	else
		texture:SetVertexColor(color.r, color.g, color.b, color.a or 1)
	end

	texture:Show()
end

local function ApplyPreviewFlat(frame, texture, color)
	local healthTexture = frame.healthBar:GetStatusBarTexture()

	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", healthTexture, "TOPLEFT", 0, 0)
	texture:SetPoint("BOTTOMRIGHT", healthTexture, "BOTTOMRIGHT", 0, 0)
	texture:SetColorTexture(color.r, color.g, color.b, 1)
	texture:Show()
end

local function ApplyPreviewBorder(frame, border, color)
	border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = addon.Utilities:ToUI(frame.dataProvider:Scale(frame, addon.Utilities:ToPixels(1))),
	})
	border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
	border:Show()
end

local function ShowPreview(frame, previewSettings)
	local container = frame.dispelsContainer

	if
		not previewSettings.enabled or (frame.previewWidgetVisibility and frame.previewWidgetVisibility.dispels ~= true)
	then
		container:Hide()
		return
	end

	local auras = GetPreviewAuras(frame)
	local firstAura = auras[1]
	local color = GetPreviewColor(frame, firstAura)

	container:Show()

	if not previewSettings.showOverlay then
		container.previewGradient:Hide()
		container.previewFlat:Hide()
	elseif previewSettings.texture == "Flat" then
		container.previewGradient:Hide()
		ApplyPreviewFlat(frame, container.previewFlat, color)
	else
		container.previewFlat:Hide()
		ApplyPreviewGradient(container.previewGradient, firstAura, color, previewSettings.gradientDirection)
	end

	local borderInset = addon.Utilities:ToUI(frame.dataProvider:Scale(frame, previewSettings.frameBorderSizePx))
	container.previewBorder:ClearAllPoints()
	container.previewBorder:SetPoint("TOPLEFT", container, "TOPLEFT", borderInset, -borderInset)
	container.previewBorder:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -borderInset, borderInset)
	container.previewBorder:SetFrameLevel(container:GetFrameLevel() + 1)

	if previewSettings.showOverlay and previewSettings.showBorder and previewSettings.texture ~= "Flat" then
		ApplyPreviewBorder(frame, container.previewBorder, color)
	else
		container.previewBorder:Hide()
	end

	local iconSizePx = frame.dataProvider:Scale(frame, previewSettings.iconSizePx)
	local spacingPx = frame.dataProvider:Scale(frame, previewSettings.spacingPx)
	local insetPx = frame.dataProvider:Scale(frame, addon.Utilities:ToPixels(2))
	local iconSize = addon.Utilities:ToUI(iconSizePx)
	local anchor = previewSettings.anchor
	local growRight = anchor == "TOPLEFT" or anchor == "BOTTOMLEFT"
	local offsetXPx = growRight and insetPx or -insetPx
	local offsetYPx = (anchor == "BOTTOMLEFT" or anchor == "BOTTOMRIGHT") and insetPx or -insetPx

	for index = 1, 3 do
		local icon = container.previewIcons[index]
		local aura = auras[index]

		if previewSettings.showIcons and aura then
			local xOffsetPx = offsetXPx + (growRight and 1 or -1) * (index - 1) * (iconSizePx + spacingPx)

			icon:SetFrameLevel(38)
			icon:ClearAllPoints()
			icon:SetPoint(
				anchor,
				container,
				anchor,
				addon.Utilities:ToUI(xOffsetPx),
				addon.Utilities:ToUI(offsetYPx)
			)
			icon:SetSize(iconSize, iconSize)
			icon.texture:SetAtlas(aura.atlas)
			icon:Show()
		else
			icon:Hide()
		end
	end
end

function Dispels:Ensure(frame)
	if frame.frameType ~= "preview" then
		return
	end

	if frame.dispelsContainer then
		return
	end

	local container = CreateFrame("Frame", nil, frame)
	container:EnableMouse(false)
	container:SetAllPoints(frame)
	container:SetFrameLevel(18)
	frame.dispelsContainer = container
	CreatePreview(container)
end

function Dispels:UpdateSettings(frame, settings)
	if frame.frameType ~= "preview" then
		return
	end

	ShowPreview(frame, BuildPreviewSettings(settings))
end

function Dispels:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "dispelsSettingsChanged",
	})
end
