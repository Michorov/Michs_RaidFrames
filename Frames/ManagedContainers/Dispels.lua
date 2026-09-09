local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.Dispels = addon.Frames.ManagedContainers.Dispels or {}

local Dispels = addon.Frames.ManagedContainers.Dispels

local settingsCache = setmetatable({}, { __mode = "k" })

local DISPEL_SLOTS = {
	{ key = "Magic", dispelType = "Magic", color = DEBUFF_TYPE_MAGIC_COLOR, priority = 4 },
	{ key = "Curse", dispelType = "Curse", color = DEBUFF_TYPE_CURSE_COLOR, priority = 3 },
	{ key = "Poison", dispelType = "Poison", color = DEBUFF_TYPE_POISON_COLOR, priority = 2 },
	{ key = "Disease", dispelType = "Disease", color = DEBUFF_TYPE_DISEASE_COLOR, priority = 1 },
	{ key = "Bleed", dispelType = "Bleed", color = DEBUFF_TYPE_BLEED_COLOR, priority = 0 },
}

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local dispels = icons.dispels or {}
	local gradientDirection = dispels.gradientDirection == 1 and 1 or 0

	local result = {
		enabled = dispels.enabled ~= false,
		style = dispels.style == "modern" and "modern" or "blizzard",
		showOnlyPlayerDispellable = dispels.showOnlyPlayerDispellable ~= false,
		texture = dispels.texture == "Flat" and "Flat" or "Gradient",
		gradientDirection = gradientDirection,
		iconSizePx = addon.Utilities:ToPixels(12),
		-- iconSizePx = addon.Utilities:ToPixels(dispels.iconSize or 12),
		spacingPx = addon.Utilities:ToPixels(dispels.spacing or 1),
		offsetXPx = addon.Utilities:ToPixels(dispels.offsetX or -2),
		offsetYPx = addon.Utilities:ToPixels(dispels.offsetY or -2),
	}

	settingsCache[settings] = result
end

local function UpdateTexture(button, textureType, gradientDirection)
	local color = button.color
	local gradientTexture = button.gradientTexture
	local flatTexture = button.flatTexture

	if textureType == "Flat" then
		local healthTexture = button.unitFrame.healthBar:GetStatusBarTexture()

		flatTexture:ClearAllPoints()
		flatTexture:SetPoint("TOPLEFT", healthTexture, "TOPLEFT", 0, 0)
		flatTexture:SetPoint("BOTTOMRIGHT", healthTexture, "BOTTOMRIGHT", 0, 0)
		flatTexture:Show()
		gradientTexture:Hide()
		return
	end

	gradientTexture:SetTexCoord(0, 1, 0, 1)

	if gradientDirection == 1 then
		local upperLeftX, upperLeftY, lowerLeftX, lowerLeftY, upperRightX, upperRightY, lowerRightX, lowerRightY =
			gradientTexture:GetTexCoord()
		if upperRightX then
			gradientTexture:SetTexCoord(
				lowerLeftX,
				lowerLeftY,
				upperLeftX,
				upperLeftY,
				lowerRightX,
				lowerRightY,
				upperRightX,
				upperRightY
			)
		else
			gradientTexture:SetTexCoord(upperLeftX, upperLeftY, lowerLeftY, lowerLeftX)
		end
	end

	gradientTexture:SetVertexColor(color.r, color.g, color.b, 1)
	gradientTexture:Show()
	flatTexture:Hide()
end

local function CreateSlotButton(button, frame, color)
	button:EnableMouse(false)
	button:SetAllPoints(frame)

	local gradientTexture = button:CreateTexture(nil, "ARTWORK")
	gradientTexture:SetAllPoints(button)
	gradientTexture:SetBlendMode("BLEND")
	SetTextureWithAddressModeOptions(
		gradientTexture,
		"_RaidFrame-Dispel-Highlight-Horizontal",
		TextureKitConstants.IgnoreAtlasSize,
		TextureKitConstants.AddressModeWrap,
		TextureKitConstants.AddressModeClamp
	)

	local flatTexture = button:CreateTexture(nil, "ARTWORK")
	flatTexture:SetColorTexture(color.r, color.g, color.b, 1)
	flatTexture:SetBlendMode("BLEND")
	flatTexture:Hide()

	button.unitFrame = frame
	button.gradientTexture = gradientTexture
	button.flatTexture = flatTexture
	button.color = color
end

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

local function UpdateIconContainerSettings(frame, cachedSettings)
	local container = frame.managedContainers.dispelsIcons
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

	for index, slot in ipairs(DISPEL_SLOTS) do
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

function Dispels:SetEnabled(frame, enabled)
	for _, key in ipairs({ "dispels", "dispelsIcons" }) do
		local container = frame.managedContainers[key]
		if container and container.isEnabled ~= enabled then
			container.isEnabled = enabled
			container:SetEnabled(enabled)
		end
	end
end

function Dispels:Ensure(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	if frame.managedContainers.dispels then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	container:SetAllPoints(frame)
	container:SetFrameLevel(10)
	container.slotsButtons = {}
	frame.managedContainers.dispels = container
	local filter = settingsCache[settings].showOnlyPlayerDispellable and "HARMFUL|RAID_PLAYER_DISPELLABLE" or "HARMFUL"

	for _, slot in ipairs(DISPEL_SLOTS) do
		local color = slot.color or DEBUFF_TYPE_NONE_COLOR
		local button = container:AddAuraSlot(slot.key, filter, {
			candidateFilters = {
				includeDispelTypes = {
					[slot.dispelType] = true,
				},
			},
			sortMethod = AuraContainerSortMethod.Default,
			sortDirection = AuraContainerSortDirection.Normal,
			initializeFrame = function(auraButton)
				CreateSlotButton(auraButton, frame, color)
			end,
		})

		button:SetFrameLevel(container:GetFrameLevel() + slot.priority)
		container.slotsButtons[slot.key] = button
	end

	local cachedSettings = settingsCache[settings]
	for _, button in pairs(container.slotsButtons) do
		UpdateTexture(button, cachedSettings.texture, cachedSettings.gradientDirection)
	end

	local iconContainer = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	iconContainer:SetFrameLevel(20)
	iconContainer.iconButtons = {}
	iconContainer.iconSize = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.iconSizePx))
	frame.managedContainers.dispelsIcons = iconContainer
	self:SetEnabled(frame, false)

	for index, slot in ipairs(DISPEL_SLOTS) do
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

	UpdateIconContainerSettings(frame, cachedSettings)
end

function Dispels:UpdateSettings(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]
	local container = frame.managedContainers.dispels
	local iconContainer = frame.managedContainers.dispelsIcons

	if cachedSettings.style ~= "modern" then
		self:SetEnabled(frame, false)
		container:SetUnit("none")
		iconContainer:SetUnit("none")

		return
	end

	local filter = cachedSettings.showOnlyPlayerDispellable and "HARMFUL|RAID_PLAYER_DISPELLABLE" or "HARMFUL"

	for slotKey, button in pairs(container.slotsButtons) do
		container:SetAuraSlotFilterString(slotKey, filter)
		iconContainer:SetAuraGroupFilterString(slotKey, filter)
		UpdateTexture(button, cachedSettings.texture, cachedSettings.gradientDirection)
	end

	UpdateIconContainerSettings(frame, cachedSettings)
	self:SetUnit(frame, settings)
end

function Dispels:UpdateState(frame, settings)
	if frame.frameType == "preview" or frame.frameType == "boss" then
		return
	end

	local container = frame.managedContainers.dispels
	if not container then
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
	local container = frame.managedContainers.dispels
	if not container then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	if settingsCache[settings].style ~= "modern" then
		self:SetEnabled(frame, false)
		container:SetUnit("none")
		frame.managedContainers.dispelsIcons:SetUnit("none")
		return
	end

	local iconContainer = frame.managedContainers.dispelsIcons
	local unit = addon.Utilities:GetManagedAuraUnit(frame.unit) or "none"
	container:SetUnit(unit)
	container:UpdateAllAuras()
	iconContainer:SetUnit(unit)
	iconContainer:UpdateAllAuras()
	self:UpdateState(frame, settings)
end

function Dispels:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "dispelsSettingsChanged",
	})
end
