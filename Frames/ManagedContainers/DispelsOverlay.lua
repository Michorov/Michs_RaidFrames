local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.DispelsOverlay = addon.Frames.ManagedContainers.DispelsOverlay or {}

local DispelsOverlay = addon.Frames.ManagedContainers.DispelsOverlay

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local dispels = icons.dispels or {}
	local size = (settings and settings.size) or {}
	local border = (settings and settings.border) or {}
	local gradientDirection = dispels.gradientDirection == 1 and 1 or 0

	local result = {
		showBorder = dispels.showBorder ~= false,
		texture = dispels.texture == "Flat" and "Flat" or "Gradient",
		gradientDirection = gradientDirection,
		frameWidthPx = addon.Utilities:ToPixels(size.width or 128),
		frameHeightPx = addon.Utilities:ToPixels(size.height or 64),
		frameBorderThicknessPx = addon.Utilities:ToPixels(border.thicknessPx or 1),
	}

	settingsCache[settings] = result
end

local function UpdateBorder(button, cachedSettings)
	local border = button.border
	local inset = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.frameBorderThicknessPx))
	local thickness = addon.Utilities:ToUI(addon.Utilities:Scale(addon.Utilities:ToPixels(1)))

	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
	border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)

	border.left:SetWidth(thickness)
	border.right:SetWidth(thickness)
	border.top:SetHeight(thickness)
	border.bottom:SetHeight(thickness)

	border:SetShown(cachedSettings.showBorder and cachedSettings.texture ~= "Flat")
end

local function UpdateTexture(button, textureType, gradientDirection)
	local color = button.color
	local gradientTexture = button.gradientTexture
	local flatTexture = button.flatTexture

	if textureType == "Flat" then
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

local function InitializeButton(button, container, color)
	button:EnableMouse(false)
	button:SetFrameLevel(container:GetFrameLevel())

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
	flatTexture:SetAllPoints(button)
	flatTexture:SetColorTexture(color.r, color.g, color.b, 1)
	flatTexture:SetBlendMode("BLEND")
	flatTexture:Hide()

	local border = CreateFrame("Frame", nil, button, "DisableUntrustedLayoutScriptsTemplate")
	border:SetFrameLevel(button:GetFrameLevel())
	for _, edge in ipairs({ "left", "right", "top", "bottom" }) do
		local texture = border:CreateTexture(nil, "OVERLAY")
		texture:SetColorTexture(color.r, color.g, color.b, 1)
		texture:SetSnapToPixelGrid(true)
		texture:SetTexelSnappingBias(0)
		border[edge] = texture
	end
	border.left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
	border.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
	border.right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
	border.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
	border.top:SetPoint("TOPLEFT", border.left, "TOPRIGHT", 0, 0)
	border.top:SetPoint("TOPRIGHT", border.right, "TOPLEFT", 0, 0)
	border.bottom:SetPoint("BOTTOMLEFT", border.left, "BOTTOMRIGHT", 0, 0)
	border.bottom:SetPoint("BOTTOMRIGHT", border.right, "BOTTOMLEFT", 0, 0)
	button.border = border

	button.gradientTexture = gradientTexture
	button.flatTexture = flatTexture
	button.color = color
	container.overlayButtons[button] = true
end

function DispelsOverlay:Ensure(frame, settings, dispelTypes, filters)
	if frame.managedContainers.dispels.overlayContainer then
		return
	end

	local wrapper = CreateFrame("Frame", nil, frame, "DisableUntrustedLayoutScriptsTemplate")
	wrapper:EnableMouse(false)
	wrapper:SetAllPoints(frame)
	wrapper:SetFrameLevel(10)
	wrapper:SetClipsChildren(true)

	local container = CreateFrame("AuraContainer", nil, wrapper, "CustomAuraContainerTemplate")
	container:SetFrameLevel(10)
	container.wrapper = wrapper
	container.overlayButtons = {}
	container:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
	container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
	container:SetFlowLayoutAnchorPoint("TOPLEFT")
	container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
	container:SetFlowLayoutMaximumLineSize(math.huge)
	container:SetFlowLayoutPadding(0, 0, 0, 0)
	frame.managedContainers.dispels.overlayContainer = container
	container.isEnabled = false
	container:SetEnabled(false)

	for index, dispel in ipairs(dispelTypes) do
		local color = dispel.color or DEBUFF_TYPE_NONE_COLOR
		container:AddAuraGroup(dispel.type, filters[dispel.type], {
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
			initializeFrame = function(auraButton)
				InitializeButton(auraButton, container, color)
			end,
		})
	end

	self:UpdateSettings(frame, settings, dispelTypes, filters)
end

function DispelsOverlay:UpdateSettings(frame, settings, dispelTypes, filters)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]
	local container = frame.managedContainers.dispels.overlayContainer
	local wrapper = container.wrapper
	local width = addon.Utilities:ToUI(addon.Utilities:ScaleEven(cachedSettings.frameWidthPx))
	local height = addon.Utilities:ToUI(addon.Utilities:ScaleEven(cachedSettings.frameHeightPx))

	wrapper:ClearAllPoints()
	if cachedSettings.texture == "Flat" then
		wrapper:SetAllPoints(frame.healthBar:GetStatusBarTexture())
	else
		wrapper:SetAllPoints(frame)
	end

	for button in pairs(container.overlayButtons) do
		button:SetSize(width, height)
		UpdateBorder(button, cachedSettings)
		UpdateTexture(button, cachedSettings.texture, cachedSettings.gradientDirection)
	end

	for index, dispel in ipairs(dispelTypes) do
		container:SetAuraGroupFilterString(dispel.type, filters[dispel.type])
		container:SetAuraGroupLayout(dispel.type, {
			layoutIndex = index,
			groupSpacing = 0,
			elementSpacing = 0,
			forceNewLine = false,
			elementWidth = width,
			elementHeight = height,
		})
	end
end