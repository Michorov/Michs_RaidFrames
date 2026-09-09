local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.DispelsIcons = addon.Frames.ManagedContainers.DispelsIcons or {}

local DispelsIcons = addon.Frames.ManagedContainers.DispelsIcons

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local dispels = icons.dispels or {}

	local result = {
		iconSizePx = addon.Utilities:ToPixels(dispels.iconSize or 14),
		spacingPx = addon.Utilities:ToPixels(dispels.spacing or 0),
		offsetXPx = addon.Utilities:ToPixels(dispels.offsetX or -2),
		offsetYPx = addon.Utilities:ToPixels(dispels.offsetY or -2),
	}

	settingsCache[settings] = result
end

local function InitializeButton(button, container, atlas)
	button:EnableMouse(false)
	button:SetFrameLevel(container:GetFrameLevel())

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAtlas(atlas, false)
	icon:SetPoint("CENTER", button, "CENTER", 0, 0)
	button.icon = icon
	container.iconButtons[button] = true
end

local function UpdateButtonSettings(button, cachedSettings)
	local iconSize = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.iconSizePx))
	button:SetSize(iconSize, iconSize)
	button.icon:SetSize(iconSize, iconSize)
end

function DispelsIcons:UpdateSettings(frame, settings, dispelTypes, filter)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local container = frame.managedContainers.dispels.iconsContainer
	local iconSize = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.iconSizePx))
	local spacing = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.spacingPx))
	
	container:ClearAllPoints()
	container:SetPoint(
		"TOPRIGHT",
		frame,
		"TOPRIGHT",
		addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.offsetXPx)),
		addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.offsetYPx))
	)
	container:SetFlowLayoutAnchorPoint("TOPRIGHT")
	container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Down)
	container:SetFlowLayoutMaximumLineSize(math.huge)

	for index, dispel in ipairs(dispelTypes) do
		container:SetAuraGroupFilterString(dispel.type, filter)
		container:SetAuraGroupLayout(dispel.type, {
			layoutIndex = index,
			groupSpacing = spacing,
			forceNewLine = false,
			elementWidth = iconSize,
			elementHeight = iconSize,
		})
	end

	for button in pairs(container.iconButtons) do
		UpdateButtonSettings(button, cachedSettings)
	end
end

function DispelsIcons:Ensure(frame, settings, dispelTypes, filter)
	if frame.managedContainers.dispels.iconsContainer then
		return
	end

	local iconContainer = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	iconContainer:SetFrameLevel(20)
	iconContainer.iconButtons = {}
	frame.managedContainers.dispels.iconsContainer = iconContainer
	iconContainer.isEnabled = false
	iconContainer:SetEnabled(false)

	for index, dispel in ipairs(dispelTypes) do
		local atlas = "RaidFrame-Icon-Debuff" .. dispel.type
		iconContainer:AddAuraGroup(dispel.type, filter, {
			maxFrameCount = 1,
			candidateFilters = {
				includeDispelTypes = {
					[dispel.type] = true,
				},
			},
			sortMethod = AuraContainerSortMethod.Default,
			sortDirection = AuraContainerSortDirection.Normal,
			layout = {
				layoutIndex = index,
				forceNewLine = false,
			},
			initializeFrame = function(button)
				InitializeButton(button, iconContainer, atlas)
			end,
		})
	end

	self:UpdateSettings(frame, settings, dispelTypes, filter)
end
