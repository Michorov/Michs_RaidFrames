local _, addon = ...

addon.Frames = addon.Frames or {}
local Frames = addon.Frames

local ARENA_RAID_MAX_UNITS = 3

local function GetUnitRaidGroup(unit)
	if type(unit) ~= "string" or unit == "" then
		return nil
	end

	local raidIndex = UnitInRaid(unit)
	if not raidIndex then
		return nil
	end

	local _, _, subgroup = GetRaidRosterInfo(raidIndex)
	if type(subgroup) == "number" and subgroup >= 1 and subgroup <= 8 then
		return subgroup
	end

	return nil
end

local function BuildRaidGroupMap(group)
	local map = {}
	for subgroup = 1, 8 do
		map[subgroup] = {}
	end

	if not group or not group.frames then
		return map
	end

	for _, frame in ipairs(group.frames) do
		local unit = frame and frame.unit
		local subgroup = GetUnitRaidGroup(unit)
		if subgroup then
			table.insert(map[subgroup], {
				frame = frame,
				unit = unit,
			})
		end
	end

	return map
end

local function SetFrameWatchEnabled(frame, enabled)
	if not frame then
		return
	end

	if enabled then
		RegisterUnitWatch(frame)
	else
		UnregisterUnitWatch(frame)
		frame:Hide()
	end
end

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

local function UpdatePartyLayout(group, settings)
	local layout = GetLayoutSettings(settings, 128, 64, "VERTICAL")
	local isHorizontal = layout.isHorizontal

	local frameCount = #group.frames

	local scaledFrameWidthPx = addon.Utilities:ScaleEven(layout.frameWidthPx)
	local scaledFrameHeightPx = addon.Utilities:ScaleEven(layout.frameHeightPx)
	local scaledSpacingXPx = addon.Utilities:Scale(layout.spacingXPx)
	local scaledSpacingYPx = addon.Utilities:Scale(layout.spacingYPx)
	local scaledPositionX = addon.Utilities:Scale(layout.positionX)
	local scaledPositionY = addon.Utilities:Scale(layout.positionY)

	local scaledContainerWidthPx
	local scaledContainerHeightPx

	if isHorizontal then
		scaledContainerWidthPx = (frameCount * scaledFrameWidthPx) + ((frameCount - 1) * scaledSpacingXPx)
		scaledContainerHeightPx = scaledFrameHeightPx
	else
		scaledContainerWidthPx = scaledFrameWidthPx
		scaledContainerHeightPx = (frameCount * scaledFrameHeightPx) + ((frameCount - 1) * scaledSpacingYPx)
	end

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

	for frameIndex, frame in ipairs(group.frames) do
		local offsetXPx = 0
		local offsetYPx = 0

		if isHorizontal then
			offsetXPx = (frameIndex - 1) * (scaledFrameWidthPx + scaledSpacingXPx)
		else
			offsetYPx = (frameIndex - 1) * (scaledFrameHeightPx + scaledSpacingYPx)
		end

		frame:ClearAllPoints()
		frame:SetPoint(
			"TOPLEFT",
			group.container,
			"TOPLEFT",
			addon.Utilities:ToUI(offsetXPx),
			-addon.Utilities:ToUI(offsetYPx)
		)
		frame:SetSize(addon.Utilities:ToUI(scaledFrameWidthPx), addon.Utilities:ToUI(scaledFrameHeightPx))
	end
end

local function UpdateRaidLayoutAsPartyInArena(group, settings)
	local layout = GetLayoutSettings(settings, 128, 64, "VERTICAL")
	local isHorizontal = layout.isHorizontal

	local frameCount = math.min(ARENA_RAID_MAX_UNITS, #group.frames)

	local scaledFrameWidthPx = addon.Utilities:ScaleEven(layout.frameWidthPx)
	local scaledFrameHeightPx = addon.Utilities:ScaleEven(layout.frameHeightPx)
	local scaledSpacingXPx = addon.Utilities:Scale(layout.spacingXPx)
	local scaledSpacingYPx = addon.Utilities:Scale(layout.spacingYPx)
	local scaledPositionX = addon.Utilities:Scale(layout.positionX)
	local scaledPositionY = addon.Utilities:Scale(layout.positionY)

	local scaledContainerWidthPx
	local scaledContainerHeightPx

	if isHorizontal then
		scaledContainerWidthPx = (frameCount * scaledFrameWidthPx) + ((frameCount - 1) * scaledSpacingXPx)
		scaledContainerHeightPx = scaledFrameHeightPx
	else
		scaledContainerWidthPx = scaledFrameWidthPx
		scaledContainerHeightPx = (frameCount * scaledFrameHeightPx) + ((frameCount - 1) * scaledSpacingYPx)
	end

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

	for i, frame in ipairs(group.frames) do
		if i <= frameCount then
			SetFrameWatchEnabled(frame, true)

			local offsetXPx, offsetYPx = 0, 0
			if isHorizontal then
				offsetXPx = (i - 1) * (scaledFrameWidthPx + scaledSpacingXPx)
			else
				offsetYPx = (i - 1) * (scaledFrameHeightPx + scaledSpacingYPx)
			end

			frame:ClearAllPoints()
			frame:SetPoint(
				"TOPLEFT",
				group.container,
				"TOPLEFT",
				addon.Utilities:ToUI(offsetXPx),
				-addon.Utilities:ToUI(offsetYPx)
			)
			frame:SetSize(addon.Utilities:ToUI(scaledFrameWidthPx), addon.Utilities:ToUI(scaledFrameHeightPx))
		else
			SetFrameWatchEnabled(frame, false)
		end
	end
end

local function UpdateRaidLayoutFromRaidGroups(group, settings)
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
	local maxFrames = 40

	local groupedUnits = BuildRaidGroupMap(group)

	local slotMap = {}
	for subgroup = 1, 8 do
		slotMap[subgroup] = { [1] = nil, [2] = nil, [3] = nil, [4] = nil, [5] = nil }
	end

	local guidToFrameByGroup = {}
	for subgroup = 1, 8 do
		guidToFrameByGroup[subgroup] = {}
		for _, entry in ipairs(groupedUnits[subgroup] or {}) do
			local unit = entry.unit
			local frame = entry.frame
			if unit and frame and UnitExists(unit) then
				local guid = UnitGUID(unit)
				if guid then
					guidToFrameByGroup[subgroup][guid] = frame
				end
			end
		end
	end

	local subgroupCounts = {}
	for subgroup = 1, 8 do
		subgroupCounts[subgroup] = 0
	end

	local rosterCount = math.min(GetNumGroupMembers() or 0, maxFrames)
	for raidIndex = 1, rosterCount do
		local _, _, subgroup = GetRaidRosterInfo(raidIndex)
		if type(subgroup) == "number" and subgroup >= 1 and subgroup <= 8 then
			subgroupCounts[subgroup] = subgroupCounts[subgroup] + 1
			local slot = subgroupCounts[subgroup]

			if slot <= 5 then
				local guid = UnitGUID("raid" .. raidIndex)
				if guid then
					local frame = guidToFrameByGroup[subgroup][guid]
					if frame then
						slotMap[subgroup][slot] = frame
					end
				end
			end
		end
	end

	for subgroup = 1, 8 do
		for _, entry in ipairs(groupedUnits[subgroup] or {}) do
			local frame = entry.frame
			if frame then
				local alreadyPlaced = false
				for slot = 1, 5 do
					if slotMap[subgroup][slot] == frame then
						alreadyPlaced = true
						break
					end
				end

				if not alreadyPlaced then
					for slot = 1, 5 do
						if slotMap[subgroup][slot] == nil then
							slotMap[subgroup][slot] = frame
							break
						end
					end
				end
			end
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

	local enabledSet = {}
	for _, subgroup in ipairs(orderedGroups) do
		enabledSet[subgroup] = true
	end

	for subgroup = 1, 8 do
		local isGroupEnabled = enabledSet[subgroup] == true
		for slot = 1, 5 do
			local frame = slotMap[subgroup][slot]
			if frame then
				SetFrameWatchEnabled(frame, isGroupEnabled)
			end
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
		return
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
				local colIndex, rowIndex
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
			end
		end
	end
end

local function UpdateRaidLayout(group, settings)
	local _, instanceType = IsInInstance()
	if instanceType == "arena" then
		return UpdateRaidLayoutAsPartyInArena(group, settings)
	end

	return UpdateRaidLayoutFromRaidGroups(group, settings)
end

function Frames:UpdateLayout(group, settings)
	if not group or not group.container then
		return
	end

	settings = settings or {}

	if group.type == "party" then
		UpdatePartyLayout(group, settings)
	else
		UpdateRaidLayout(group, settings)
	end
end
