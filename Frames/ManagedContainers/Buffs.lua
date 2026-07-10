local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.Buffs = addon.Frames.ManagedContainers.Buffs or {}

local Buffs = addon.Frames.ManagedContainers.Buffs
local AuraButtons = addon.Frames.ManagedContainers.AuraButtons

local settingsCache = setmetatable({}, { __mode = "k" })

local CUSTOM_BUFF_SPELL_IDS = {
	[17] = true,
	[139] = true,
	[774] = true,
	[974] = true,
	[8936] = true,
	[33763] = true,
	[41635] = true,
	[48438] = true,
	[53563] = true,
	[61295] = true,
	[77489] = true,
	[115175] = true,
	[119611] = true,
	[124682] = true,
	[155777] = true,
	[156322] = true,
	[156910] = true,
	[194384] = true,
	[207400] = true,
	[355941] = true,
	[360827] = true,
	[363502] = true,
	[364343] = true,
	[366155] = true,
	[367364] = true,
	[373267] = true,
	[376788] = true,
	[382024] = true,
	[383648] = true,
	[395152] = true,
	[410089] = true,
	[410263] = true,
	[410686] = true,
	[413984] = true,
	[450769] = true,
	[1244893] = true,
	[1253593] = true,
}

local function ShouldUseManagedContainer(frame)
	return addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility
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
		borderSizePx = addon.Utilities:ToPixels(buffs.borderSizePx or 1),
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

	container:SetAuraLayoutAnchorPoint(anchor)
	container:SetAuraLayoutRowWidth(addon.Utilities:ToUI(rowWidthPx))

	if anchor == "TOPLEFT" then
		container:SetAuraLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
	end

	if anchor == "TOPRIGHT" then
		container:SetAuraLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Down)
	end

	if anchor == "BOTTOMRIGHT" then
		container:SetAuraLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Up)
	end

	if anchor == "BOTTOMLEFT" then
		container:SetAuraLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Up)
	end
end

local function UpdateAuraGroupSettings(frame, settings)
	local container = frame.managedContainers.buffs
	local cachedSettings = settingsCache[settings]

	local spacing = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.spacingPx))
	local maxFrameCount = cachedSettings.enabled and cachedSettings.maxIcons or 0

	container:SetAuraGroupMaxFrameCount("buffs", maxFrameCount)
	container:SetAuraGroupLayout("buffs", {
		elementSpacingX = spacing,
		elementSpacingY = spacing,
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
	end
end

function Buffs:Ensure(frame, settings)
	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	frame.managedContainers = frame.managedContainers or {}

	if frame.managedContainers.buffs then
		return
	end

	local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	container:SetFrameLevel(42)
	frame.managedContainers.buffs = container

	UpdateContainerSettings(frame, settings)

	container:AddAuraGroup("buffs", "HELPFUL|PLAYER", {
		maxFrameCount = 0,
		candidateFilters = {
			includeSpellIDs = CUSTOM_BUFF_SPELL_IDS,
		},
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = function(button)
			AuraButtons:Initialize(button, container)
		end,
	})

	UpdateButtonsSettings(frame, settings)
	UpdateContainerSettings(frame, settings)
	UpdateAuraGroupSettings(frame, settings)
end

function Buffs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not frame.managedContainers or not frame.managedContainers.buffs then
		self:Ensure(frame, settings)
	end

	UpdateButtonsSettings(frame, settings)
	UpdateContainerSettings(frame, settings)
	UpdateAuraGroupSettings(frame, settings)
end

function Buffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "buffAurasSettingsChanged",
	})
end
