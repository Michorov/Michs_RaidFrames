local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.Debuffs = addon.Frames.ManagedContainers.Debuffs or {}

local Debuffs = addon.Frames.ManagedContainers.Debuffs

local settingsCache = setmetatable({}, { __mode = "k" })

local function ShouldUseManagedContainer(frame)
	return addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility
end

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local debuffs = icons.debuffs or {}

	local result = {
		enabled = debuffs.enabled ~= false,
		borderColorByDebuffType = debuffs.borderColorByDebuffType == true,
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
		borderSizePx = addon.Utilities:ToPixels(debuffs.borderSizePx or 1),
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
	local rowWidthPx = (iconSizePx * cachedSettings.iconsPerRow) + (spacingPx * (cachedSettings.iconsPerRow - 1))
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
	local container = frame.managedContainers.debuffs
	local cachedSettings = settingsCache[settings]

	local spacing = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.spacingPx))
	local maxFrameCount = cachedSettings.enabled and cachedSettings.maxIcons or 0

	container:SetAuraGroupMaxFrameCount("debuffs", maxFrameCount)
	container:SetAuraGroupLayout("debuffs", {
		elementSpacingX = spacing,
		elementSpacingY = spacing,
	})
end

local function UpdateButtonSettings(button, settings)
	local cachedSettings = settingsCache[settings]
	local scaledIconSizePx = addon.Utilities:Scale(cachedSettings.iconSizePx)
	local scaledStacksFontSize = addon.Utilities:ScaleFont(cachedSettings.stacksFontSize)
	local scaledBorderSizePx = math.max(1, addon.Utilities:Scale(cachedSettings.borderSizePx))

	button:SetSize(addon.Utilities:ToUI(scaledIconSizePx), addon.Utilities:ToUI(scaledIconSizePx))

	button.cooldown:SetHideCountdownNumbers(not cachedSettings.showCooldown)

	button.count:SetFont("Fonts\\FRIZQT__.TTF", scaledStacksFontSize, "OUTLINE")
	button.count:ClearAllPoints()
	button.count:SetAlpha(cachedSettings.showStacks and 1 or 0)
	button.count:SetPoint(
		"BOTTOMRIGHT",
		button,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(scaledBorderSizePx - 2),
		addon.Utilities:ToUI(scaledBorderSizePx - 2)
	)

	if cachedSettings.showCooldown and button.cooldown.SetCountdownFont then
		local scaledSize = addon.Utilities:ScaleFont(cachedSettings.cooldownFontSize)
		local fontName = "MRF_CooldownFont_" .. tostring(scaledSize)
		local cooldownFont = _G[fontName]
		if not cooldownFont then
			cooldownFont = CreateFont(fontName)
		end
		cooldownFont:SetFont("Fonts\\FRIZQT__.TTF", scaledSize, "OUTLINE")
		button.cooldown:SetCountdownFont(fontName)
	end
end

local function UpdateButtonsSettings(frame, settings)
	local container = frame.managedContainers.debuffs

	for button in pairs(container.auraButtons or {}) do
		UpdateButtonSettings(button, settings)
	end
end

local function InitializeButton(button, container)
	container.auraButtons = container.auraButtons or {}
	container.auraButtons[button] = true

	button:EnableMouse(false)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(button)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon = icon
	button:SetIcon(icon)

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(button)
	cooldown:SetReverse(true)
	button.cooldown = cooldown
	button:SetDurationCooldown(cooldown)

	local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	count:SetTextColor(1, 1, 1, 1)
	button.count = count
	button:SetApplicationCount(count, {})
end

function Debuffs:Ensure(frame, settings)
	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	frame.managedContainers = frame.managedContainers or {}

	if frame.managedContainers.debuffs then
		return
	end

	local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	container:SetFrameLevel(41)

	frame.managedContainers.debuffs = container
	UpdateContainerSettings(frame, settings)

	container:AddAuraGroup("debuffs", "HARMFUL", {
		maxFrameCount = 0,
		sortMethod = AuraContainerSortMethod.UnitFrameDebuff,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = function(button)
			InitializeButton(button, container)
		end,
	})

	UpdateAuraGroupSettings(frame, settings)
	UpdateButtonsSettings(frame, settings)
end

function Debuffs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not frame.managedContainers or not frame.managedContainers.debuffs then
		self:Ensure(frame, settings)
	end

	UpdateContainerSettings(frame, settings)
	UpdateAuraGroupSettings(frame, settings)
	UpdateButtonsSettings(frame, settings)
end

function Debuffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "debuffAurasSettingsChanged",
	})
end
