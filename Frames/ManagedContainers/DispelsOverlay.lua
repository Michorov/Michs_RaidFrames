local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.DispelsOverlay = addon.Frames.ManagedContainers.DispelsOverlay or {}

local DispelsOverlay = addon.Frames.ManagedContainers.DispelsOverlay

local function UpdateBorder(button, container)
	local border = button.border
	local inset = container.borderInset
	local thickness = container.borderThickness
	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
	border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
	border.left:SetWidth(thickness)
	border.right:SetWidth(thickness)
	border.top:SetHeight(thickness)
	border.bottom:SetHeight(thickness)
end

local function UpdateTexture(button, textureType, gradientDirection)
	local color = button.color
	local gradientTexture = button.gradientTexture
	local flatTexture = button.flatTexture
	button.border:SetShown(textureType ~= "Flat")

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

local function CreateOverlayButton(button, container, color)
	button:EnableMouse(false)
	button:SetFrameLevel(container:GetFrameLevel())
	button:SetSize(container.overlayWidth, container.overlayHeight)

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

	-- The border moves with its aura button, so lower-priority borders are
	-- clipped along with their gradients. Keep it below the outer frame border.
	local border = CreateFrame("Frame", nil, button, "DisableUntrustedLayoutScriptsTemplate")
	border:SetFrameLevel(24)
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
	UpdateBorder(button, container)

	button.gradientTexture = gradientTexture
	button.flatTexture = flatTexture
	button.color = color
	container.overlayButtons[button] = true
	UpdateTexture(button, container.textureType, container.gradientDirection)
end

function DispelsOverlay:UpdateSettings(frame, cachedSettings, dispelSlots, filter)
	local container = frame.managedContainers.dispels.overlayContainer
	local wrapper = container.wrapper
	-- Match the even-pixel dimensions used by the secure header layout.
	local width = addon.Utilities:ToUI(addon.Utilities:ScaleEven(cachedSettings.frameWidthPx))
	local height = addon.Utilities:ToUI(addon.Utilities:ScaleEven(cachedSettings.frameHeightPx))
	container.overlayWidth = width
	container.overlayHeight = height
	container.textureType = cachedSettings.texture
	container.gradientDirection = cachedSettings.gradientDirection
	container.borderInset = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.frameBorderThicknessPx))
	container.borderThickness = addon.Utilities:ToUI(addon.Utilities:Scale(addon.Utilities:ToPixels(1)))

	wrapper:ClearAllPoints()
	if cachedSettings.texture == "Flat" then
		-- Clip to the live health fill without reading its secret dimensions.
		wrapper:SetAllPoints(frame.healthBar:GetStatusBarTexture())
	else
		wrapper:SetAllPoints(frame)
	end

	for button in pairs(container.overlayButtons) do
		button:SetSize(width, height)
		UpdateBorder(button, container)
		UpdateTexture(button, cachedSettings.texture, cachedSettings.gradientDirection)
	end

	for index, slot in ipairs(dispelSlots) do
		container:SetAuraGroupFilterString(slot.key, filter)
		container:SetAuraGroupLayout(slot.key, {
			layoutIndex = index,
			groupSpacing = 0,
			elementSpacing = 0,
			forceNewLine = false,
			elementWidth = width,
			elementHeight = height,
		})
	end
end

function DispelsOverlay:Ensure(frame, cachedSettings, dispelSlots, filter)
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
	container.overlayWidth = addon.Utilities:ToUI(addon.Utilities:ScaleEven(cachedSettings.frameWidthPx))
	container.overlayHeight = addon.Utilities:ToUI(addon.Utilities:ScaleEven(cachedSettings.frameHeightPx))
	container.textureType = cachedSettings.texture
	container.gradientDirection = cachedSettings.gradientDirection
	container.borderInset = addon.Utilities:ToUI(addon.Utilities:Scale(cachedSettings.frameBorderThicknessPx))
	container.borderThickness = addon.Utilities:ToUI(addon.Utilities:Scale(addon.Utilities:ToPixels(1)))
	-- Only the first active, full-frame group fits inside the wrapper. Other
	-- groups flow to its right and are clipped, so their colors cannot mix.
	container:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
	container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
	container:SetFlowLayoutAnchorPoint("TOPLEFT")
	container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)
	container:SetFlowLayoutMaximumLineSize(math.huge)
	container:SetFlowLayoutPadding(0, 0, 0, 0)
	frame.managedContainers.dispels.overlayContainer = container
	container.isEnabled = false
	container:SetEnabled(false)

	for index, slot in ipairs(dispelSlots) do
		local color = slot.color or DEBUFF_TYPE_NONE_COLOR
		container:AddAuraGroup(slot.key, filter, {
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
			initializeFrame = function(auraButton)
				CreateOverlayButton(auraButton, container, color)
			end,
		})
	end

	self:UpdateSettings(frame, cachedSettings, dispelSlots, filter)
end
