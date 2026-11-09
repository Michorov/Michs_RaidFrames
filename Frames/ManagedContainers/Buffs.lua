local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.Buffs = addon.Frames.ManagedContainers.Buffs or {}

local Buffs = addon.Frames.ManagedContainers.Buffs
local AuraButtons = addon.Frames.ManagedContainers.AuraButtons

local settingsCache = setmetatable({}, { __mode = "k" })

local function GetEnabledBuffSpellIDs(buffs)
	local customAuraValues = buffs.customAuraValues or {}
	local classAuras = customAuraValues[addon.Utilities:GetPlayerClassFileName() or ""] or {}
	local specID = addon.Utilities:GetPlayerSpecID()
	local specAuras = classAuras[specID] or classAuras[-1] or {}
	local spellIDs = {}

	for _, entry in pairs(specAuras) do
		if entry.enabled == true then
			for _, spellID in ipairs(entry.spellIDs) do
				spellIDs[spellID] = true
			end
		end
	end

	return spellIDs
end

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local buffs = icons.buffs or {}

	local result = {
		enabled = buffs.enabled ~= false,
		anchor = buffs.anchor or "BOTTOMRIGHT",
		offsetXPx = addon.Utilities:ToPixels(buffs.offsetX or -2),
		offsetYPx = addon.Utilities:ToPixels(buffs.offsetY or 2),
		maxIcons = math.max(1, buffs.maxIcons or 6),
		iconsPerRow = math.max(1, buffs.iconsPerRow or 3),
		iconSizePx = addon.Utilities:ToPixels(buffs.iconSize or 20),
		spacingPx = addon.Utilities:ToPixels(buffs.spacing or -1),
		showStacks = buffs.showStacks ~= false,
		stacksFontSize = buffs.stacksFontSize or 10,
		showCooldown = buffs.showCooldown == true,
		cooldownFontSize = buffs.cooldownFontSize or 10,
		showTooltips = buffs.showTooltips == true,
		borderSizePx = addon.Utilities:ToPixels((buffs.borderSizePx ~= 0) and 1 or 0),
		includeSpellIDs = GetEnabledBuffSpellIDs(buffs),
	}

	settingsCache[settings] = result
end

local function UpdateContainerSettings(frame, settings)
	local container = frame.managedContainers.buffs
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
	local container = frame.managedContainers.buffs
	local cachedSettings = settingsCache[settings]

	local spacing = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.spacingPx))
	local maxFrameCount = cachedSettings.enabled and cachedSettings.maxIcons or 0

	container:SetAuraGroupMaxFrameCount("buffs", maxFrameCount)
	container:SetAuraGroupLayout("buffs", {
		elementSpacing = spacing,
		lineSpacing = spacing,
	})
end

local function UpdateButtonsSettings(frame, settings)
	local container = frame.managedContainers.buffs
	local cachedSettings = settingsCache[settings]

	for button in pairs(container.auraButtons or {}) do
		AuraButtons:ApplyIconSettings(button, cachedSettings)
		AuraButtons:ApplyBorderSettings(button, cachedSettings)
		AuraButtons:ApplyCooldownSettings(button, cachedSettings)
		AuraButtons:ApplyCountSettings(button, cachedSettings)
		AuraButtons:ApplyTooltipSettings(button, cachedSettings)
	end
end

function Buffs:Ensure(frame, settings)
	if frame.frameType == "preview" then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if frame.managedContainers.buffs then
		return
	end

	local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	container:SetFrameLevel(55)
	frame.managedContainers.buffs = container

	UpdateContainerSettings(frame, settings)

	container:AddAuraGroup("buffs", "HELPFUL|PLAYER", {
		maxFrameCount = 0,
		candidateFilters = {
			includeSpellIDs = cachedSettings.includeSpellIDs,
		},
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = function(button)
			AuraButtons:Initialize(button, container)
		end,
	})
end

function Buffs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if frame.frameType == "preview" then
		return
	end

	UpdateButtonsSettings(frame, settings)
	UpdateContainerSettings(frame, settings)
	UpdateAuraGroupSettings(frame, settings)
end

function Buffs:UpdateFilters(frame, settings)
	UpdateSettingsCache(settings)

	if frame.frameType == "preview" then
		return
	end

	local container = frame.managedContainers.buffs
	local cachedSettings = settingsCache[settings]
	local auraUnit = addon.Utilities:GetManagedAuraUnit(frame.unit)

	if auraUnit == "vehicle" then
		container:SetAuraGroupCandidateFilters("buffs", {})
	else
		container:SetAuraGroupCandidateFilters("buffs", {
			includeSpellIDs = cachedSettings.includeSpellIDs,
		})
	end
end

function Buffs:UpdateState(frame, settings)
	if frame.frameType == "preview" then
		return
	end

	local container = frame.managedContainers.buffs
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

function Buffs:SetUnit(frame, settings)
	if frame.frameType == "preview" then
		return
	end

	local container = frame.managedContainers.buffs

	local auraUnit = addon.Utilities:GetManagedAuraUnit(frame.unit)
	if container.SetAuraGroupFilter then
		container:SetAuraGroupFilter("buffs", auraUnit == "vehicle" and "HELPFUL" or "HELPFUL|PLAYER")
	end

	if auraUnit == "vehicle" then
		container:SetAuraGroupCandidateFilters("buffs", {})
	else
		local cachedSettings = settingsCache[settings]
		if not cachedSettings and settings then
			UpdateSettingsCache(settings)
			cachedSettings = settingsCache[settings]
		end

		container:SetAuraGroupCandidateFilters("buffs", {
			includeSpellIDs = cachedSettings and cachedSettings.includeSpellIDs or {},
		})
	end

	container:SetUnit(auraUnit or "none")
	container:UpdateAllAuras()
	self:UpdateState(frame, settings)
end

function Buffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "buffAurasSettingsChanged",
	})
end
