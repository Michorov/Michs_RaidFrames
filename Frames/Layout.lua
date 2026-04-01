local _, addon = ...

addon.Frames = addon.Frames or {}
local Frames = addon.Frames

local ARENA_RAID_MAX_UNITS = 3

local function GetLayoutSettings(settings, defaultWidth, defaultHeight, defaultDirection)
	settings = settings or {}

	local position = settings.position or {}
	local size = settings.size or {}
	local spacing = settings.spacing or {}

	local direction = settings.direction or defaultDirection
	local isHorizontal = (direction == "HORIZONTAL")

	return {
		direction = direction,
		isHorizontal = isHorizontal,
		enabled = settings.groups or {},
		reverse = settings.reverse == true,
		positionX = addon.Utilities:ToPixels(position.x or 0),
		positionY = addon.Utilities:ToPixels(position.y or 0),
		frameWidthPx = addon.Utilities:ToPixels(size.width or defaultWidth),
		frameHeightPx = addon.Utilities:ToPixels(size.height or defaultHeight),
		spacingXPx = addon.Utilities:ToPixels(spacing.x or 0),
		spacingYPx = addon.Utilities:ToPixels(spacing.y or 0),
	}
end

local function UpdateTestRaidLayout(group, settings)
	local layout = GetLayoutSettings(settings, 112, 56, "HORIZONTAL")

	local enabled = layout.enabled
	local direction = layout.direction
	local reverse = layout.reverse

	local positionX = layout.positionX
	local positionY = layout.positionY
	local frameWidthPx = layout.frameWidthPx
	local frameHeightPx = layout.frameHeightPx
	local spacingXPx = layout.spacingXPx
	local spacingYPx = layout.spacingYPx

	local slotMap = {}
	local frameIndex = 1

	for subgroup = 1, 8 do
		slotMap[subgroup] = {}
		for slot = 1, 5 do
			slotMap[subgroup][slot] = group.frames[frameIndex]
			frameIndex = frameIndex + 1
		end
	end

	local orderedGroups = {}
	for subgroup = 1, 8 do
		local isEnabled = enabled[subgroup]
		if isEnabled == nil then
			isEnabled = true
		end

		if isEnabled then
			table.insert(orderedGroups, subgroup)
		end
	end

	if reverse then
		local i, j = 1, #orderedGroups
		while i < j do
			orderedGroups[i], orderedGroups[j] = orderedGroups[j], orderedGroups[i]
			i = i + 1
			j = j - 1
		end
	end

	if #orderedGroups == 0 then
		local scaledPositionX = addon.Utilities:Scale(positionX)
		local scaledPositionY = addon.Utilities:Scale(positionY)
		local scaledOnePx = addon.Utilities:ScaleEven(1)

		group.container:ClearAllPoints()
		group.container:SetPoint(
			"CENTER",
			UIParent,
			"CENTER",
			addon.Utilities:ToUI(scaledPositionX),
			addon.Utilities:ToUI(scaledPositionY)
		)
		group.container:SetSize(addon.Utilities:ToUI(scaledOnePx), addon.Utilities:ToUI(scaledOnePx))

		for _, frame in ipairs(group.frames) do
			if frame then
				frame:Hide()
			end
		end

		return
	end

	local enabledSet = {}
	for _, subgroup in ipairs(orderedGroups) do
		enabledSet[subgroup] = true
	end

	for subgroup = 1, 8 do
		local isGroupEnabled = enabledSet[subgroup] == true
		for slot = 1, 5 do
			local frame = slotMap[subgroup][slot]
			if frame then
				if isGroupEnabled then
					frame:Show()
				else
					frame:Hide()
				end
			end
		end
	end

	local isVertical = (direction == "VERTICAL")
	local groupCount = #orderedGroups

	local totalCols = isVertical and 5 or groupCount
	local totalRows = isVertical and groupCount or 5

	local scaledFrameWidthPx = addon.Utilities:ScaleEven(frameWidthPx)
	local scaledFrameHeightPx = addon.Utilities:ScaleEven(frameHeightPx)
	local scaledSpacingXPx = addon.Utilities:Scale(spacingXPx)
	local scaledSpacingYPx = addon.Utilities:Scale(spacingYPx)
	local scaledPositionX = addon.Utilities:Scale(positionX)
	local scaledPositionY = addon.Utilities:Scale(positionY)

	local scaledContainerWidthPx = (totalCols * scaledFrameWidthPx) + ((totalCols - 1) * scaledSpacingXPx)
	local scaledContainerHeightPx = (totalRows * scaledFrameHeightPx) + ((totalRows - 1) * scaledSpacingYPx)

	if (scaledContainerWidthPx % 2) ~= 0 then
		scaledContainerWidthPx = scaledContainerWidthPx + 1
	end
	if (scaledContainerHeightPx % 2) ~= 0 then
		scaledContainerHeightPx = scaledContainerHeightPx + 1
	end

	group.container:ClearAllPoints()
	group.container:SetPoint(
		"CENTER",
		UIParent,
		"CENTER",
		addon.Utilities:ToUI(scaledPositionX),
		addon.Utilities:ToUI(scaledPositionY)
	)
	group.container:SetSize(addon.Utilities:ToUI(scaledContainerWidthPx), addon.Utilities:ToUI(scaledContainerHeightPx))

	for groupPos, subgroup in ipairs(orderedGroups) do
		for slot = 1, 5 do
			local frame = slotMap[subgroup][slot]
			if frame then
				local colIndex
				local rowIndex

				if isVertical then
					colIndex = slot - 1
					rowIndex = groupPos - 1
				else
					colIndex = groupPos - 1
					rowIndex = slot - 1
				end

				local offsetXPx = colIndex * (scaledFrameWidthPx + scaledSpacingXPx)
				local offsetYPx = rowIndex * (scaledFrameHeightPx + scaledSpacingYPx)

				frame:ClearAllPoints()
				frame:SetPoint(
					"TOPLEFT",
					group.container,
					"TOPLEFT",
					addon.Utilities:ToUI(offsetXPx),
					-addon.Utilities:ToUI(offsetYPx)
				)
				frame:SetSize(addon.Utilities:ToUI(scaledFrameWidthPx), addon.Utilities:ToUI(scaledFrameHeightPx))
				frame:Show()
			end
		end
	end
end

local function UpdateRaidHeaderLayoutArena(group, partySettings)
	for i = 2, 8 do
		local header = group.containers[i]
		if header then
			header:Hide()
		end
	end

	local header = group.containers[1]
	if not header then
		return
	end

	local layout = GetLayoutSettings(partySettings, 128, 64, "VERTICAL")

	local frameWidth = addon.Utilities:ToUI(addon.Utilities:ScaleEven(layout.frameWidthPx))
	local frameHeight = addon.Utilities:ToUI(addon.Utilities:ScaleEven(layout.frameHeightPx))
	local spacingY = addon.Utilities:ToUI(addon.Utilities:Scale(layout.spacingYPx))
	local posX = addon.Utilities:ToUI(addon.Utilities:Scale(layout.positionX))
	local posY = addon.Utilities:ToUI(addon.Utilities:Scale(layout.positionY))

	header:SetAttribute("frameWidth", frameWidth)
	header:SetAttribute("frameHeight", frameHeight)
	header:SetAttribute("point", "TOP")
	header:SetAttribute("xOffset", 0)
	header:SetAttribute("yOffset", -spacingY)
	header:SetAttribute("columnAnchorPoint", "TOPLEFT")

	for i = 1, 5 do
		local child = header:GetAttribute("child" .. i)
		if child then
			child:ClearAllPoints()
		end
	end
	header:SetAttribute("unitsPerColumn", 5)

	for i = 1, 5 do
		local child = header:GetAttribute("child" .. i)
		if child then
			child:SetSize(frameWidth, frameHeight)
		end
	end

	local totalHeight = (ARENA_RAID_MAX_UNITS * frameHeight) + ((ARENA_RAID_MAX_UNITS - 1) * spacingY)
	header:ClearAllPoints()
	header:SetPoint("TOP", UIParent, "CENTER", posX, posY + totalHeight / 2)
	header:Show()
end

local function UpdateRaidHeaderLayout(group, settings)
	local _, instanceType = IsInInstance()
	if instanceType == "arena" then
		local profile = addon.Database:GetProfile()
		return UpdateRaidHeaderLayoutArena(group, profile.party or {})
	end

	local layout = GetLayoutSettings(settings, 112, 56, "HORIZONTAL")

	local frameWidth = addon.Utilities:ToUI(addon.Utilities:ScaleEven(layout.frameWidthPx))
	local frameHeight = addon.Utilities:ToUI(addon.Utilities:ScaleEven(layout.frameHeightPx))
	local spacingX = addon.Utilities:ToUI(addon.Utilities:Scale(layout.spacingXPx))
	local spacingY = addon.Utilities:ToUI(addon.Utilities:Scale(layout.spacingYPx))
	local posX = addon.Utilities:ToUI(addon.Utilities:Scale(layout.positionX))
	local posY = addon.Utilities:ToUI(addon.Utilities:Scale(layout.positionY))
	local isVertical = not layout.isHorizontal

	local enabled = layout.enabled
	local reverse = layout.reverse

	local orderedGroups = {}
	for subgroup = 1, 8 do
		if enabled[subgroup] then
			table.insert(orderedGroups, subgroup)
		end
	end

	if reverse then
		local i, j = 1, #orderedGroups
		while i < j do
			orderedGroups[i], orderedGroups[j] = orderedGroups[j], orderedGroups[i]
			i = i + 1
			j = j - 1
		end
	end

	local groupCount = #orderedGroups

	local totalWidth = isVertical and ((5 * frameWidth) + (4 * spacingX))
		or (groupCount * frameWidth + math.max(0, groupCount - 1) * spacingX)

	local totalHeight = isVertical and (groupCount * frameHeight + math.max(0, groupCount - 1) * spacingY)
		or ((5 * frameHeight) + (4 * spacingY))

	local originX = posX - totalWidth / 2
	local originY = posY + totalHeight / 2

	local groupPos = 0
	for _, subgroup in ipairs(orderedGroups) do
		local header = group.containers[subgroup]
		if header then
			header:SetAttribute("frameWidth", frameWidth)
			header:SetAttribute("frameHeight", frameHeight)
			if isVertical then
				header:SetAttribute("point", "LEFT")
				header:SetAttribute("xOffset", spacingX)
				header:SetAttribute("yOffset", 0)
				header:SetAttribute("columnAnchorPoint", "TOPLEFT")
			else
				header:SetAttribute("point", "TOP")
				header:SetAttribute("xOffset", 0)
				header:SetAttribute("yOffset", -spacingY)
				header:SetAttribute("columnAnchorPoint", "TOPLEFT")
			end

			for i = 1, 5 do
				local child = header:GetAttribute("child" .. i)
				if child then
					child:ClearAllPoints()
				end
			end
			header:SetAttribute("unitsPerColumn", 5)

			for i = 1, 5 do
				local child = header:GetAttribute("child" .. i)
				if child then
					child:SetSize(frameWidth, frameHeight)
				end
			end

			header:ClearAllPoints()
			if isVertical then
				header:SetPoint("TOPLEFT", UIParent, "CENTER", originX, originY - groupPos * (frameHeight + spacingY))
			else
				header:SetPoint(
					"TOP",
					UIParent,
					"CENTER",
					originX + groupPos * (frameWidth + spacingX) + frameWidth / 2,
					originY
				)
			end

			groupPos = groupPos + 1
		end
	end
end

local function UpdateTestPartyLayout(group, settings)
	local layout = GetLayoutSettings(settings, 128, 64, "VERTICAL")
	local isHorizontal = layout.isHorizontal

	local frameWidth = addon.Utilities:ScaleEven(layout.frameWidthPx)
	local frameHeight = addon.Utilities:ScaleEven(layout.frameHeightPx)
	local spacingX = addon.Utilities:Scale(layout.spacingXPx)
	local spacingY = addon.Utilities:Scale(layout.spacingYPx)
	local positionX = addon.Utilities:Scale(layout.positionX)
	local positionY = addon.Utilities:Scale(layout.positionY)
	local frameCount = #group.frames

	local containerWidth = isHorizontal and (frameCount * frameWidth + (frameCount - 1) * spacingX) or frameWidth
	local containerHeight = isHorizontal and frameHeight or (frameCount * frameHeight + (frameCount - 1) * spacingY)

	if (containerWidth % 2) ~= 0 then
		containerWidth = containerWidth + 1
	end
	if (containerHeight % 2) ~= 0 then
		containerHeight = containerHeight + 1
	end

	group.container:ClearAllPoints()
	group.container:SetPoint(
		"CENTER",
		UIParent,
		"CENTER",
		addon.Utilities:ToUI(positionX),
		addon.Utilities:ToUI(positionY)
	)
	group.container:SetSize(addon.Utilities:ToUI(containerWidth), addon.Utilities:ToUI(containerHeight))

	for i, frame in ipairs(group.frames) do
		local offsetX = isHorizontal and (i - 1) * (frameWidth + spacingX) or 0
		local offsetY = isHorizontal and 0 or (i - 1) * (frameHeight + spacingY)

		frame:ClearAllPoints()
		frame:SetPoint(
			"TOPLEFT",
			group.container,
			"TOPLEFT",
			addon.Utilities:ToUI(offsetX),
			-addon.Utilities:ToUI(offsetY)
		)
		frame:SetSize(addon.Utilities:ToUI(frameWidth), addon.Utilities:ToUI(frameHeight))
	end
end

local function UpdatePartyHeaderLayout(group, settings)
	local header = group.container
	local layout = GetLayoutSettings(settings, 128, 64, "VERTICAL")

	local frameWidth = addon.Utilities:ToUI(addon.Utilities:ScaleEven(layout.frameWidthPx))
	local frameHeight = addon.Utilities:ToUI(addon.Utilities:ScaleEven(layout.frameHeightPx))
	local spacingX = addon.Utilities:ToUI(addon.Utilities:Scale(layout.spacingXPx))
	local spacingY = addon.Utilities:ToUI(addon.Utilities:Scale(layout.spacingYPx))
	local posX = addon.Utilities:ToUI(addon.Utilities:Scale(layout.positionX))
	local posY = addon.Utilities:ToUI(addon.Utilities:Scale(layout.positionY))
	local isHorizontal = layout.isHorizontal

	if isHorizontal then
		header:SetAttribute("point", "LEFT")
		header:SetAttribute("xOffset", spacingX)
		header:SetAttribute("yOffset", 0)
		header:SetAttribute("columnSpacing", spacingX)
		header:SetAttribute("columnAnchorPoint", "LEFT")
	else
		header:SetAttribute("point", "TOP")
		header:SetAttribute("xOffset", 0)
		header:SetAttribute("yOffset", -spacingY)
	end

	header:SetAttribute("frameWidth", frameWidth)
	header:SetAttribute("frameHeight", frameHeight)

	for i = 1, 5 do
		local child = header:GetAttribute("child" .. i)
		if child then
			child:ClearAllPoints()
		end
	end

	header:SetAttribute("unitsPerColumn", isHorizontal and 1 or 5)

	for i = 1, 5 do
		local child = header:GetAttribute("child" .. i)
		if child then
			child:SetSize(frameWidth, frameHeight)
		end
	end

	if isHorizontal then
		local totalWidth = (5 * frameWidth) + (4 * spacingX)
		header:ClearAllPoints()
		header:SetPoint("LEFT", UIParent, "CENTER", posX - totalWidth / 2, posY)
	else
		local totalHeight = (5 * frameHeight) + (4 * spacingY)
		header:ClearAllPoints()
		header:SetPoint("TOP", UIParent, "CENTER", posX, posY + totalHeight / 2)
	end
end

function Frames:UpdateLayout(group, settings)
	if group.type == "party" then
		if group.isTestGroup then
			UpdateTestPartyLayout(group, settings)
		else
			UpdatePartyHeaderLayout(group, settings)
		end
	else
		if group.isTestGroup then
			UpdateTestRaidLayout(group, settings)
		else
			UpdateRaidHeaderLayout(group, settings)
		end
	end
end
