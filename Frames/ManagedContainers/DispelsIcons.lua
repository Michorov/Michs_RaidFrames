local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.DispelsIcons = addon.Frames.ManagedContainers.DispelsIcons or {}

local DispelsIcons = addon.Frames.ManagedContainers.DispelsIcons

local function CreateDispelIcon(button, container, atlas)
	button:EnableMouse(false)
	button:SetFrameLevel(container:GetFrameLevel())
	button:SetSize(container.iconSize, container.iconSize)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAtlas(atlas, false)
	icon:SetSize(container.iconSize, container.iconSize)
	icon:SetPoint("CENTER", button, "CENTER", 0, 0)
	button.icon = icon
	container.iconButtons[button] = true
end

function DispelsIcons:UpdateSettings(frame, cachedSettings, dispelSlots, filter)
	local container = frame.managedContainers.dispels.iconsContainer
	local iconSize = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.iconSizePx))
	local spacing = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.spacingPx))
	container.iconSize = iconSize
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

	for index, slot in ipairs(dispelSlots) do
		container:SetAuraGroupFilterString(slot.key, filter)
		container:SetAuraGroupLayout(slot.key, {
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

function DispelsIcons:Ensure(frame, cachedSettings, dispelSlots, filter)
	if frame.managedContainers.dispels.iconsContainer then
		return
	end

	local iconContainer = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	iconContainer:SetFrameLevel(20)
	iconContainer.iconButtons = {}
	iconContainer.iconSize = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.iconSizePx))
	frame.managedContainers.dispels.iconsContainer = iconContainer
	iconContainer.isEnabled = false
	iconContainer:SetEnabled(false)

	for index, slot in ipairs(dispelSlots) do
		local atlas = "RaidFrame-Icon-Debuff" .. slot.dispelType
		iconContainer:AddAuraGroup(slot.key, filter, {
			maxFrameCount = 1,
			candidateFilters = {
				includeDispelTypes = {
					[slot.dispelType] = true,
				},
			},
			sortMethod = AuraContainerSortMethod.Default,
			sortDirection = AuraContainerSortDirection.Normal,
			layout = {
				layoutIndex = index,
				forceNewLine = false,
			},
			initializeFrame = function(button)
				CreateDispelIcon(button, iconContainer, atlas)
			end,
		})
	end

	self:UpdateSettings(frame, cachedSettings, dispelSlots, filter)
end
