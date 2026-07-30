local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Dispels = addon.Frames.Widgets.Icons.Dispels or {}

local Dispels = addon.Frames.Widgets.Icons.Dispels

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local dispels = icons.dispels or {}
	local gradientDirection = dispels.gradientDirection == 1 and 1 or 0

	local result = {
		enabled = dispels.enabled ~= false,
		showOnlyPlayerDispellable = dispels.showOnlyPlayerDispellable ~= false,
		gradientDirection = gradientDirection,
	}

	settingsCache[settings] = result
end

local function RemoveAnchor(frame)
	if frame.dispelsAnchorID and C_UnitAuras and C_UnitAuras.RemovePrivateAuraAnchor then
		C_UnitAuras.RemovePrivateAuraAnchor(frame.dispelsAnchorID)
	end

	frame.dispelsAnchorID = nil
	frame.dispelsAnchoredUnit = nil
end

local function HidePreview(container)
	if not container then
		return
	end

	if container.previewGradient then
		container.previewGradient:Hide()
	end

	if container.previewBorder then
		container.previewBorder:Hide()
	end

	for _, icon in ipairs(container.previewIcons or {}) do
		icon:Hide()
	end
end

local function CreatePreviewIcon(container)
	local icon = CreateFrame("Frame", nil, container)
	icon:EnableMouse(false)

	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints(icon)

	icon:Hide()
	return icon
end

local function EnsurePreview(container)
	if container.previewGradient then
		return
	end

	container.previewGradient = container:CreateTexture(nil, "ARTWORK")
	container.previewGradient:SetTexture("Interface\\Buttons\\WHITE8x8")
	container.previewGradient:SetBlendMode("BLEND")

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

local function ApplyPreviewBorder(frame, border, color)
	border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = addon.Utilities:ToUI(frame.dataProvider:Scale(frame, addon.Utilities:ToPixels(1))),
	})
	border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
	border:Show()
end

local function ShowPreview(frame, cachedSettings)
	local container = frame.dispelsContainer
	EnsurePreview(container)

	if
		not cachedSettings.enabled or (frame.previewWidgetVisibility and frame.previewWidgetVisibility.dispels ~= true)
	then
		HidePreview(container)
		container:Hide()
		return
	end

	local auras = GetPreviewAuras(frame)
	local firstAura = auras[1]
	local color = GetPreviewColor(frame, firstAura)

	container:Show()

	ApplyPreviewGradient(container.previewGradient, firstAura, color, cachedSettings.gradientDirection)
	local borderInset = addon.Utilities:ToUI(frame.dataProvider:Scale(frame, addon.Utilities:ToPixels(1)))
	container.previewBorder:ClearAllPoints()
	container.previewBorder:SetPoint("TOPLEFT", container, "TOPLEFT", borderInset, -borderInset)
	container.previewBorder:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -borderInset, borderInset)
	container.previewBorder:SetFrameLevel(container:GetFrameLevel() + 1)
	ApplyPreviewBorder(frame, container.previewBorder, color)

	local iconSizePx = frame.dataProvider:Scale(frame, addon.Utilities:ToPixels(15))
	local spacingPx = frame.dataProvider:Scale(frame, addon.Utilities:ToPixels(0))
	local insetPx = frame.dataProvider:Scale(frame, addon.Utilities:ToPixels(2))
	local iconSize = addon.Utilities:ToUI(iconSizePx)

	for index = 1, 3 do
		local icon = container.previewIcons[index]
		local aura = auras[index]

		if aura then
			local xOffsetPx = insetPx + ((index - 1) * (iconSizePx + spacingPx))

			icon:SetFrameLevel(container:GetFrameLevel() + 2)
			icon:ClearAllPoints()
			icon:SetPoint(
				"TOPRIGHT",
				container,
				"TOPRIGHT",
				-addon.Utilities:ToUI(xOffsetPx),
				-addon.Utilities:ToUI(insetPx)
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
	if not frame.dispelsContainer then
		local container = CreateFrame("Frame", nil, frame)
		container:EnableMouse(false)
		container:ClearAllPoints()
		container:SetAllPoints(frame)
		container:SetFrameLevel(17)
		frame.dispelsContainer = container
	end

	if frame.previewWidgetVisibility then
		EnsurePreview(frame.dispelsContainer)
	end
end

function Dispels:UpdateSettings(frame, settings)
	local container = frame.dispelsContainer

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	if frame.previewWidgetVisibility then
		RemoveAnchor(frame)
		ShowPreview(frame, cachedSettings)
		return
	end

	HidePreview(container)

	local unit = frame.unit
	local canRegister = cachedSettings.enabled and unit and C_UnitAuras and C_UnitAuras.AddPrivateAuraAnchor

	if not canRegister then
		RemoveAnchor(frame)
		container:Hide()
		return
	end

	local groupType = 5
	if unit:find("^party") then
		groupType = 4
	end

	local dispelIndicatorOption = cachedSettings.showOnlyPlayerDispellable and 1 or 2
	local dispelIndicatorOverlayType = Enum.RaidDispelOverlayType and Enum.RaidDispelOverlayType.UseDebuffColor

	container:SetAttribute("max-buffs", 0)
	container:SetAttribute("max-debuffs", 0)
	container:SetAttribute("max-dispel-debuffs", 5)
	container:SetAttribute("ignore-buffs", true)
	container:SetAttribute("ignore-debuffs", true)
	container:SetAttribute("ignore-dispel-debuffs", true)
	container:SetAttribute("show-dispel-indicator-overlay", true)
	container:SetAttribute("suppress-dispel-border-icons", true)
	container:SetAttribute("dispel-indicator-option", dispelIndicatorOption)
	container:SetAttribute("aura-organization-type", cachedSettings.gradientDirection)
	container:SetAttribute("group-type", groupType)
	container:SetAttribute("power-bar-used-height", 0)
	container:SetAttribute("icon-size", 12)
	container:SetAttribute("debuff-size", 12)
	container:SetAttribute("buff-size", 12)
	container:SetAttribute("debuff-border-scale", 1)
	container:SetAttribute("buff-border-scale", 1)
	container:SetAttribute("set-aura-size-to-icon-size", true)
	container:SetAttribute("always-hide-duration", true)
	if dispelIndicatorOverlayType then
		container:SetAttribute("dispel-indicator-overlay-type", dispelIndicatorOverlayType)
		container:SetAttribute("dispel-indicator-overlay-animation", false)
	end
	container:SetAttribute("update-settings", true)
	container:Show()

	if frame.dispelsAnchorID and frame.dispelsAnchoredUnit == unit then
		return
	end

	RemoveAnchor(frame)

	local ok, anchorID = pcall(C_UnitAuras.AddPrivateAuraAnchor, {
		unitToken = unit,
		auraIndex = 1,
		parent = container,
		isContainer = true,
		showCountdownFrame = false,
		showCountdownNumbers = false,
	})

	if ok and anchorID then
		frame.dispelsAnchorID = anchorID
		frame.dispelsAnchoredUnit = unit
	else
		container:Hide()
	end
end

function Dispels:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "dispelsSettingsChanged",
	})
end
