local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.Debuffs = addon.Frames.ManagedContainers.Debuffs or {}

local Debuffs = addon.Frames.ManagedContainers.Debuffs
local AuraButtons = addon.Frames.ManagedContainers.AuraButtons

local settingsCache = setmetatable({}, { __mode = "k" })

local DEBUFF_BLACKLIST = {
	[57723] = true, -- Exhaustion
	[57724] = true, -- Sated
	[80354] = true, -- Temporal Displacement
	[95809] = true, -- Hunter Pet Insanity
	[160455] = true, -- Hunter Pet Fatigued
	[264689] = true, -- Hunter Pet Fatigued
	[390435] = true, -- Exhaustion

	[26013] = true, -- BG Deserter
	[71041] = true, -- Dungeon Deserter

	[427490] = true, -- Ride Along Available
	[447959] = true, -- Ride Along Active
	[447960] = true, -- Ride Along Inactive
}

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local debuffs = icons.debuffs or {}

	local result = {
		enabled = debuffs.enabled ~= false,
		anchor = debuffs.anchor or "BOTTOMLEFT",
		offsetXPx = addon.Utilities:ToPixels(debuffs.offsetX or 2),
		offsetYPx = addon.Utilities:ToPixels(debuffs.offsetY or 2),
		maxIcons = math.max(1, debuffs.maxIcons or 6),
		iconsPerRow = math.max(1, debuffs.iconsPerRow or 3),
		iconSizePx = addon.Utilities:ToPixels(debuffs.iconSize or 20),
		spacingPx = addon.Utilities:ToPixels(debuffs.spacing or -1),
		showStacks = debuffs.showStacks ~= false,
		stacksFontSize = debuffs.stacksFontSize or 10,
		showCooldown = debuffs.showCooldown == true,
		cooldownFontSize = debuffs.cooldownFontSize or 10,
		showTooltips = debuffs.showTooltips == true,
		borderColorByDebuffType = debuffs.borderColorByDebuffType == true,
		borderSizePx = addon.Utilities:ToPixels((debuffs.borderSizePx ~= 0) and 1 or 0),
	}

	settingsCache[settings] = result
end

local function UpdateContainerSettings(frame, settings)
	local container = frame.managedContainers.debuffs
	local cachedSettings = settingsCache[settings]

	local containerOffsetXPx = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local containerOffsetYPx = addon.Utilities:Scale(cachedSettings.offsetYPx)
	local iconSizePx = addon.Utilities:Scale(cachedSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(cachedSettings.spacingPx)
	local visibleCols = math.min(cachedSettings.maxIcons, cachedSettings.iconsPerRow)
	local rowWidthPx = (iconSizePx * visibleCols) + (spacingPx * (visibleCols - 1)) + 1
	local anchor = cachedSettings.anchor

	container:ClearAllPoints()
	container:SetPoint(
		anchor,
		frame,
		anchor,
		addon.Utilities:ToUI(containerOffsetXPx),
		addon.Utilities:ToUI(containerOffsetYPx)
	)

	container:SetFlowLayoutAnchorPoint(anchor)
	container:SetFlowLayoutMaximumLineSize(addon.Utilities:ToUI(rowWidthPx))

	if anchor == "TOPLEFT" then
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
	end

	if anchor == "TOPRIGHT" then
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Down)
	end

	if anchor == "BOTTOMRIGHT" then
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Up)
	end

	if anchor == "BOTTOMLEFT" then
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Up)
	end
end

local function UpdateAuraGroupSettings(frame, settings)
	local container = frame.managedContainers.debuffs
	local cachedSettings = settingsCache[settings]

	local spacing = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.spacingPx))
	local maxFrameCount = cachedSettings.enabled and cachedSettings.maxIcons or 0

	container:SetAuraGroupMaxFrameCount("debuffs", maxFrameCount)
	container:SetAuraGroupLayout("debuffs", {
		elementSpacing = spacing,
		lineSpacing = spacing,
	})
end

local function UnregisterDebuffBorder(button)
	local edges = button.innerBorder.edges

	if button.debuffBorderTextureIndexes then
		for i = #button.debuffBorderTextureIndexes, 1, -1 do
			button:RemoveDispelTypeTexture(button.debuffBorderTextureIndexes[i])
		end
	end

	for _, edge in pairs(edges) do
		edge:SetColorTexture(1, 1, 1, 0)
	end

	button.debuffBorderTextureIndexes = nil
	button.debuffBorderRegistered = false
end

local function RegisterDebuffBorder(button)
	if button.debuffBorderRegistered then
		return
	end

	local edges = button.innerBorder.edges

	local options = {
		showWhenHarmful = true,
		showWithoutDispelType = true,
		style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
	}

	button.debuffBorderTextureIndexes = {}

	for _, edge in pairs(edges) do
		edge:SetColorTexture(1, 1, 1, 1)
		local index = button:AddDispelTypeTexture(edge, options)
		if index then
			table.insert(button.debuffBorderTextureIndexes, index)
		end
	end

	button.debuffBorderRegistered = true
end

local function UpdateButtonsSettings(frame, settings)
	local container = frame.managedContainers.debuffs
	local cachedSettings = settingsCache[settings]

	for button in pairs(container.auraButtons or {}) do
		AuraButtons:ApplyIconSettings(button, cachedSettings)
		AuraButtons:ApplyBorderSettings(button, cachedSettings)
		AuraButtons:ApplyCooldownSettings(button, cachedSettings)
		AuraButtons:ApplyCountSettings(button, cachedSettings)
		AuraButtons:ApplyTooltipSettings(button, cachedSettings)

		if cachedSettings.borderColorByDebuffType then
			RegisterDebuffBorder(button)
		else
			UnregisterDebuffBorder(button)
		end
	end
end

function Debuffs:Ensure(frame, settings)
	if frame.isPreview then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	if frame.managedContainers.debuffs then
		return
	end

	local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	container:SetFrameLevel(45)

	frame.managedContainers.debuffs = container
	UpdateContainerSettings(frame, settings)

	local excludeSpellIDs = {}
	for spellID in pairs(DEBUFF_BLACKLIST) do
		excludeSpellIDs[spellID] = true
	end

	container:AddAuraGroup("debuffs", "HARMFUL", {
		maxFrameCount = 0,
		candidateFilters = {
			excludeSpellIDs = excludeSpellIDs,
		},
		sortMethod = AuraContainerSortMethod.UnitFrameDebuff,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = function(button)
			AuraButtons:Initialize(button, container)
			if settingsCache[settings].borderColorByDebuffType then
				RegisterDebuffBorder(button)
			else
				UnregisterDebuffBorder(button)
			end
		end,
	})
end

function Debuffs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if frame.isPreview then
		return
	end

	UpdateButtonsSettings(frame, settings)
	UpdateContainerSettings(frame, settings)
	UpdateAuraGroupSettings(frame, settings)
end

function Debuffs:UpdateState(frame, settings)
	if frame.isPreview then
		return
	end

	local container = frame.managedContainers.debuffs
	if not container then
		return
	end

	local unit = frame.unit
	local shouldShow = addon.Utilities:IsManagedAuraUnitVisible(unit)

	if container.isShown ~= shouldShow then
		container.isShown = shouldShow
		container:SetShown(shouldShow)
	end
end

function Debuffs:SetUnit(frame, settings)
	if frame.isPreview then
		return
	end

	local container = frame.managedContainers.debuffs

	container:SetUnit(addon.Utilities:GetManagedAuraUnit(frame.unit) or "none")
	container:UpdateAllAuras()
	self:UpdateState(frame, settings)
end

function Debuffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "debuffAurasSettingsChanged",
	})
end
