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
		anchor = dispels.anchor or "TOPRIGHT",
		iconSizePx = addon.Utilities:ToPixels(dispels.iconSize or 14),
		spacingPx = addon.Utilities:ToPixels(dispels.spacing or 0),
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

function DispelsIcons:UpdateSettings(frame, settings, dispelTypes, filter)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local container = frame.managedContainers.dispels.iconsContainer
	local anchor = cachedSettings.anchor
	local iconSize = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.iconSizePx))
	local spacing = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.spacingPx))
	local inset = addon.Utilities:ToUI(addon.Utilities:Scale(addon.Utilities:ToPixels(2)))
	
	container:ClearAllPoints()
	container:SetPoint(
		anchor,
		frame,
		anchor,
		(anchor == "TOPLEFT" or anchor == "BOTTOMLEFT") and inset or -inset,
		(anchor == "BOTTOMLEFT" or anchor == "BOTTOMRIGHT") and inset or -inset
	)
	
	container:SetFlowLayoutAnchorPoint(anchor)
	if anchor == "TOPLEFT" then
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
	elseif anchor == "TOPRIGHT" then
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Down)
	elseif anchor == "BOTTOMLEFT" then
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Up)
	elseif anchor == "BOTTOMRIGHT" then
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Up)
	end
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
		button:SetSize(iconSize, iconSize)
		button.icon:SetSize(iconSize, iconSize)
	end
end

function DispelsIcons:Ensure(frame, settings, dispelTypes, filter)
	if frame.managedContainers.dispels.iconsContainer then
		return
	end

	local iconContainer = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	iconContainer:SetFrameLevel(38)
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
