local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.Dispels = addon.Frames.ManagedContainers.Dispels or {}

local Dispels = addon.Frames.ManagedContainers.Dispels

local settingsCache = setmetatable({}, { __mode = "k" })

local DISPEL_SLOTS = {
	{ key = "Magic", dispelType = "Magic", color = DEBUFF_TYPE_MAGIC_COLOR },
	{ key = "Curse", dispelType = "Curse", color = DEBUFF_TYPE_CURSE_COLOR },
	{ key = "Poison", dispelType = "Poison", color = DEBUFF_TYPE_POISON_COLOR },
	{ key = "Disease", dispelType = "Disease", color = DEBUFF_TYPE_DISEASE_COLOR },
	{ key = "Bleed", dispelType = "Bleed", color = DEBUFF_TYPE_BLEED_COLOR },
}

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local dispels = icons.dispels or {}
	local size = (settings and settings.size) or {}
	local border = (settings and settings.border) or {}
	local gradientDirection = dispels.gradientDirection == 1 and 1 or 0

	local result = {
		enabled = dispels.enabled ~= false,
		style = dispels.style == "modern" and "modern" or "blizzard",
		showOnlyPlayerDispellable = dispels.showOnlyPlayerDispellable ~= false,
		texture = dispels.texture == "Flat" and "Flat" or "Gradient",
		gradientDirection = gradientDirection,
		frameWidthPx = addon.Utilities:ToPixels(size.width or 128),
		frameHeightPx = addon.Utilities:ToPixels(size.height or 64),
		frameBorderThicknessPx = addon.Utilities:ToPixels(border.thicknessPx or 1),
		iconSizePx = addon.Utilities:ToPixels(dispels.iconSize or 14),
		spacingPx = addon.Utilities:ToPixels(dispels.spacing or 1),
		offsetXPx = addon.Utilities:ToPixels(dispels.offsetX or -2),
		offsetYPx = addon.Utilities:ToPixels(dispels.offsetY or -2),
	}

	settingsCache[settings] = result
end

function Dispels:SetEnabled(frame, enabled)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	local dispels = frame.managedContainers.dispels
	for _, key in ipairs({ "overlayContainer", "iconsContainer" }) do
		local container = dispels[key]
		if container.isEnabled ~= enabled then
			container.isEnabled = enabled
			container:SetEnabled(enabled)
		end
	end
end

function Dispels:Ensure(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	local cachedSettings = settingsCache[settings]
	local filter = cachedSettings.showOnlyPlayerDispellable and "HARMFUL|RAID_PLAYER_DISPELLABLE" or "HARMFUL"
	addon.Frames.ManagedContainers.DispelsOverlay:Ensure(frame, cachedSettings, DISPEL_SLOTS, filter)
	addon.Frames.ManagedContainers.DispelsIcons:Ensure(frame, cachedSettings, DISPEL_SLOTS, filter)
end

function Dispels:UpdateSettings(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]
	local dispels = frame.managedContainers.dispels

	if cachedSettings.style ~= "modern" then
		self:SetEnabled(frame, false)
		dispels.overlayContainer:SetUnit("none")
		dispels.iconsContainer:SetUnit("none")

		return
	end

	local filter = cachedSettings.showOnlyPlayerDispellable and "HARMFUL|RAID_PLAYER_DISPELLABLE" or "HARMFUL"

	addon.Frames.ManagedContainers.DispelsOverlay:UpdateSettings(frame, cachedSettings, DISPEL_SLOTS, filter)
	addon.Frames.ManagedContainers.DispelsIcons:UpdateSettings(frame, cachedSettings, DISPEL_SLOTS, filter)
	self:SetUnit(frame, settings)
end

function Dispels:UpdateState(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if cachedSettings.style ~= "modern" then
		self:SetEnabled(frame, false)

		return
	end

	local shouldEnable = cachedSettings.enabled and addon.Utilities:IsManagedAuraUnitVisible(frame.unit)

	self:SetEnabled(frame, shouldEnable)
end

function Dispels:SetUnit(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end
	local dispels = frame.managedContainers.dispels

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	if settingsCache[settings].style ~= "modern" then
		self:SetEnabled(frame, false)
		dispels.overlayContainer:SetUnit("none")
		dispels.iconsContainer:SetUnit("none")
		return
	end

	local unit = addon.Utilities:GetManagedAuraUnit(frame.unit) or "none"
	dispels.overlayContainer:SetUnit(unit)
	dispels.overlayContainer:UpdateAllAuras()
	dispels.iconsContainer:SetUnit(unit)
	dispels.iconsContainer:UpdateAllAuras()
	self:UpdateState(frame, settings)
end

function Dispels:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "dispelsSettingsChanged",
	})
end
