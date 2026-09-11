local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.Dispels = addon.Frames.ManagedContainers.Dispels or {}

local Dispels = addon.Frames.ManagedContainers.Dispels

local settingsCache = setmetatable({}, { __mode = "k" })

local DISPEL_TYPES = {
	{ type = "Magic", color = DEBUFF_TYPE_MAGIC_COLOR },
	{ type = "Curse", color = DEBUFF_TYPE_CURSE_COLOR },
	{ type = "Poison", color = DEBUFF_TYPE_POISON_COLOR },
	{ type = "Disease", color = DEBUFF_TYPE_DISEASE_COLOR },
	{ type = "Bleed", color = DEBUFF_TYPE_BLEED_COLOR },
}

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local dispels = icons.dispels or {}

	local result = {
		enabled = dispels.enabled ~= false,
		showOverlay = dispels.showOverlay ~= false,
		showIcons = dispels.showIcons ~= false,
		showOnlyPlayerDispellable = dispels.showOnlyPlayerDispellable ~= false,
		filters = {},
	}

	local filter = result.showOnlyPlayerDispellable and "HARMFUL|RAID_PLAYER_DISPELLABLE" or "HARMFUL"
	for _, dispel in ipairs(DISPEL_TYPES) do
		result.filters[dispel.type] = filter
	end

	local playerClass = addon.Utilities:GetPlayerClassFileName()
	if playerClass == "SHAMAN" and dispels.showPoisonForShaman == true then
		result.filters.Poison = "HARMFUL"
	end
	if playerClass == "WARLOCK" and dispels.showMagicForWarlock == true then
		result.filters.Magic = "HARMFUL"
	end

	settingsCache[settings] = result
end

function Dispels:Ensure(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]
	
	addon.Frames.ManagedContainers.DispelsOverlay:Ensure(frame, settings, DISPEL_TYPES, cachedSettings.filters)
	addon.Frames.ManagedContainers.DispelsIcons:Ensure(frame, settings, DISPEL_TYPES, cachedSettings.filters)
end

function Dispels:UpdateSettings(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	addon.Frames.ManagedContainers.DispelsOverlay:UpdateSettings(frame, settings, DISPEL_TYPES, cachedSettings.filters)
	addon.Frames.ManagedContainers.DispelsIcons:UpdateSettings(frame, settings, DISPEL_TYPES, cachedSettings.filters)
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

	local shouldEnable = cachedSettings.enabled and addon.Utilities:IsManagedAuraUnitVisible(frame.unit)

	self:SetEnabled(frame, shouldEnable, cachedSettings)
end

function Dispels:SetUnit(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end
	local dispels = frame.managedContainers.dispels

	local unit = addon.Utilities:GetManagedAuraUnit(frame.unit) or "none"
	dispels.overlayContainer:SetUnit(unit)
	dispels.overlayContainer:UpdateAllAuras()
	dispels.iconsContainer:SetUnit(unit)
	dispels.iconsContainer:UpdateAllAuras()
	self:UpdateState(frame, settings)
end

function Dispels:SetEnabled(frame, enabled, cachedSettings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	local dispels = frame.managedContainers.dispels
	local overlayEnabled = enabled and cachedSettings.showOverlay
	if dispels.overlayContainer.isEnabled ~= overlayEnabled then
		dispels.overlayContainer.isEnabled = overlayEnabled
		dispels.overlayContainer:SetEnabled(overlayEnabled)
	end

	local iconsEnabled = enabled and cachedSettings.showIcons
	if dispels.iconsContainer.isEnabled ~= iconsEnabled then
		dispels.iconsContainer.isEnabled = iconsEnabled
		dispels.iconsContainer:SetEnabled(iconsEnabled)
	end
end

function Dispels:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "dispelsSettingsChanged",
	})
end
