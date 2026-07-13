local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.Defensives = addon.Frames.ManagedContainers.Defensives or {}

local Defensives = addon.Frames.ManagedContainers.Defensives
local AuraButtons = addon.Frames.ManagedContainers.AuraButtons

local settingsCache = setmetatable({}, { __mode = "k" })

local function ShouldUseManagedContainer(frame)
	return addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility
end

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local bigDefensive = icons.bigDefensive or {}

	local result = {
		anchor = bigDefensive.anchor or "CENTER",
		relativeAnchor = bigDefensive.relativeAnchor or "CENTER",
		offsetXPx = addon.Utilities:ToPixels(bigDefensive.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(bigDefensive.offsetY or 0),
		maxIcons = math.max(1, bigDefensive.maxIcons or 1),
		iconSizePx = addon.Utilities:ToPixels(bigDefensive.iconSize or 32),
		useEvenIconSize = true,
		borderSizePx = addon.Utilities:ToPixels(bigDefensive.borderSizePx or 1),
		showStacks = bigDefensive.showStacks ~= false,
		stacksFontSize = bigDefensive.stacksFontSize or 16,
		showCooldown = bigDefensive.showCooldown == true,
		cooldownFontSize = bigDefensive.cooldownFontSize or 10,
		showTooltips = false,
	}

	settingsCache[settings] = result
end

local function UpdateContainerSettings(frame, settings)
	local container = frame.managedContainers.defensives
	local cachedSettings = settingsCache[settings]

	local containerOffsetXPx = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local containerOffsetYPx = addon.Utilities:Scale(cachedSettings.offsetYPx)
	local iconSizePx = addon.Utilities:ScaleEven(cachedSettings.iconSizePx)
	local rowWidthPx = (iconSizePx * cachedSettings.maxIcons) + 1

	container:ClearAllPoints()
	container:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.relativeAnchor,
		addon.Utilities:ToUI(containerOffsetXPx),
		addon.Utilities:ToUI(containerOffsetYPx)
	)

	container:SetAuraLayoutAnchorPoint(cachedSettings.anchor)
	container:SetAuraLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
	container:SetAuraLayoutRowWidth(addon.Utilities:ToUI(rowWidthPx))
end

local function UpdateAuraGroupSettings(frame, settings)
	local container = frame.managedContainers.defensives
	local cachedSettings = settingsCache[settings]

	container:SetAuraGroupMaxFrameCount("defensives", cachedSettings.maxIcons)
end

local function UpdateButtonsSettings(frame, settings)
	local container = frame.managedContainers.defensives
	local cachedSettings = settingsCache[settings]

	for button in pairs(container.auraButtons or {}) do
		AuraButtons:ApplyIconSettings(button, cachedSettings)
		AuraButtons:ApplyBorderSettings(button, cachedSettings)
		AuraButtons:ApplyCooldownSettings(button, cachedSettings)
		AuraButtons:ApplyCountSettings(button, cachedSettings)
		AuraButtons:ApplyTooltipSettings(button, cachedSettings)
	end
end

function Defensives:Ensure(frame, settings)
	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	frame.managedContainers = frame.managedContainers or {}

	if frame.managedContainers.defensives then
		return
	end

	local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	container:SetFrameLevel(44)

	frame.managedContainers.defensives = container
	UpdateContainerSettings(frame, settings)

	container:AddAuraGroup("defensives", "HELPFUL|BIG_DEFENSIVE", {
		maxFrameCount = 0,
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = function(button)
			AuraButtons:Initialize(button, container)
		end,
	})
end

function Defensives:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not frame.managedContainers or not frame.managedContainers.defensives then
		self:Ensure(frame, settings)
	end

	UpdateButtonsSettings(frame, settings)
	UpdateContainerSettings(frame, settings)
	UpdateAuraGroupSettings(frame, settings)
end

function Defensives:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "bigDefensiveAurasSettingsChanged",
	})
end
