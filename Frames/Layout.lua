local _, addon = ...

addon.Frames = addon.Frames or {}
local Frames = addon.Frames

local ARENA_RAID_MAX_UNITS = 3

local function GetLayoutPixels(position, size, spacing, defaultWidth, defaultHeight)
	local xPx = addon.Utilities:ToPixels((position and position.x) or 0)
	local yPx = addon.Utilities:ToPixels((position and position.y) or 0)

	local frameWidthPx = addon.Utilities:ToPixels((size and size.width) or defaultWidth)
	local frameHeightPx = addon.Utilities:ToPixels((size and size.height) or defaultHeight)
	local spacingXPx = addon.Utilities:ToPixels((spacing and spacing.x) or 0)
	local spacingYPx = addon.Utilities:ToPixels((spacing and spacing.y) or 0)

	if (frameWidthPx % 2) ~= 0 then
		frameWidthPx = frameWidthPx + 1
	end
	if (frameHeightPx % 2) ~= 0 then
		frameHeightPx = frameHeightPx + 1
	end

	return xPx, yPx, frameWidthPx, frameHeightPx, spacingXPx, spacingYPx
end

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

local function UpdatePartyLayout(group, settings)
	local position = settings.position or {}
	local size = settings.size or {}
	local spacing = settings.spacing or {}

	local direction = settings.direction or "VERTICAL"
	local isHorizontal = (direction == "HORIZONTAL")

	local xPx, yPx, frameWidthPx, frameHeightPx, spacingXPx, spacingYPx =
		GetLayoutPixels(position, size, spacing, 128, 64)

	local frameCount = #group.frames

	local containerWidthPx = frameWidthPx
	local containerHeightPx = frameHeightPx

	if frameCount > 0 then
		if isHorizontal then
			containerWidthPx = (frameCount * frameWidthPx) + ((frameCount - 1) * spacingXPx)
			containerHeightPx = frameHeightPx
		else
			containerWidthPx = frameWidthPx
			containerHeightPx = (frameCount * frameHeightPx) + ((frameCount - 1) * spacingYPx)
		end
	end

	if (containerWidthPx % 2) ~= 0 then
		containerWidthPx = containerWidthPx + 1
	end
	if (containerHeightPx % 2) ~= 0 then
		containerHeightPx = containerHeightPx + 1
	end

	group.container:ClearAllPoints()
	group.container:SetPoint(
		"CENTER",
		UIParent,
		"CENTER",
		addon.Utilities:FromPixels(xPx),
		addon.Utilities:FromPixels(yPx)
	)
	group.container:SetSize(addon.Utilities:FromPixels(containerWidthPx), addon.Utilities:FromPixels(containerHeightPx))

	for frameIndex, frame in ipairs(group.frames) do
		local offsetXPx = 0
		local offsetYPx = 0

		if isHorizontal then
			offsetXPx = (frameIndex - 1) * (frameWidthPx + spacingXPx)
		else
			offsetYPx = (frameIndex - 1) * (frameHeightPx + spacingYPx)
		end

		frame:ClearAllPoints()
		frame:SetPoint(
			"TOPLEFT",
			group.container,
			"TOPLEFT",
			addon.Utilities:FromPixels(offsetXPx),
			-addon.Utilities:FromPixels(offsetYPx)
		)
		frame:SetSize(addon.Utilities:FromPixels(frameWidthPx), addon.Utilities:FromPixels(frameHeightPx))
	end
end

local function UpdateRaidLayoutAsPartyInArena(group, settings)
	local position = settings.position or {}
	local size = settings.size or {}
	local spacing = settings.spacing or {}

	local direction = settings.direction or "VERTICAL"
	local isHorizontal = (direction == "HORIZONTAL")

	local xPx, yPx, frameWidthPx, frameHeightPx, spacingXPx, spacingYPx =
		GetLayoutPixels(position, size, spacing, 128, 64)

	local frameCount = math.min(ARENA_RAID_MAX_UNITS, #group.frames)

	local containerWidthPx, containerHeightPx
	if isHorizontal then
		containerWidthPx = (frameCount * frameWidthPx) + ((frameCount - 1) * spacingXPx)
		containerHeightPx = frameHeightPx
	else
		containerWidthPx = frameWidthPx
		containerHeightPx = (frameCount * frameHeightPx) + ((frameCount - 1) * spacingYPx)
	end

	if (containerWidthPx % 2) ~= 0 then
		containerWidthPx = containerWidthPx + 1
	end
	if (containerHeightPx % 2) ~= 0 then
		containerHeightPx = containerHeightPx + 1
	end

	group.container:ClearAllPoints()
	group.container:SetPoint(
		"CENTER",
		UIParent,
		"CENTER",
		addon.Utilities:FromPixels(xPx),
		addon.Utilities:FromPixels(yPx)
	)
	group.container:SetSize(addon.Utilities:FromPixels(containerWidthPx), addon.Utilities:FromPixels(containerHeightPx))

	for i, frame in ipairs(group.frames) do
		if i <= frameCount then
			SetFrameWatchEnabled(frame, true)

			local offsetXPx, offsetYPx = 0, 0
			if isHorizontal then
				offsetXPx = (i - 1) * (frameWidthPx + spacingXPx)
			else
				offsetYPx = (i - 1) * (frameHeightPx + spacingYPx)
			end

			frame:ClearAllPoints()
			frame:SetPoint(
				"TOPLEFT",
				group.container,
				"TOPLEFT",
				addon.Utilities:FromPixels(offsetXPx),
				-addon.Utilities:FromPixels(offsetYPx)
			)
			frame:SetSize(addon.Utilities:FromPixels(frameWidthPx), addon.Utilities:FromPixels(frameHeightPx))
		else
			SetFrameWatchEnabled(frame, false)
		end
	end
end

local function UpdateRaidLayoutFromRaidGroups(group, settings)
	local position = settings.position or {}
	local size = settings.size or {}
	local spacing = settings.spacing or {}

	local enabled = settings.groups or {}
	local direction = settings.direction or "HORIZONTAL"
	local reverse = settings.reverse == true

	local xPx, yPx, frameWidthPx, frameHeightPx, spacingXPx, spacingYPx =
		GetLayoutPixels(position, size, spacing, 112, 56)

	local _, instanceType = IsInInstance()
	local isArena = (instanceType == "arena")
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
		group.container:ClearAllPoints()
		group.container:SetPoint(
			"CENTER",
			UIParent,
			"CENTER",
			addon.Utilities:FromPixels(xPx),
			addon.Utilities:FromPixels(yPx)
		)
		group.container:SetSize(addon.Utilities:FromPixels(1), addon.Utilities:FromPixels(1))
		return
	end

	local isVertical = (direction == "VERTICAL")
	local groupCount = #orderedGroups

	local totalCols = isVertical and 5 or groupCount
	local totalRows = isVertical and groupCount or 5

	local containerWidthPx = (totalCols * frameWidthPx) + ((totalCols - 1) * spacingXPx)
	local containerHeightPx = (totalRows * frameHeightPx) + ((totalRows - 1) * spacingYPx)

	if (containerWidthPx % 2) ~= 0 then
		containerWidthPx = containerWidthPx + 1
	end
	if (containerHeightPx % 2) ~= 0 then
		containerHeightPx = containerHeightPx + 1
	end

	group.container:ClearAllPoints()
	group.container:SetPoint(
		"CENTER",
		UIParent,
		"CENTER",
		addon.Utilities:FromPixels(xPx),
		addon.Utilities:FromPixels(yPx)
	)
	group.container:SetSize(addon.Utilities:FromPixels(containerWidthPx), addon.Utilities:FromPixels(containerHeightPx))

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

				local offsetXPx = colIndex * (frameWidthPx + spacingXPx)
				local offsetYPx = rowIndex * (frameHeightPx + spacingYPx)

				frame:ClearAllPoints()
				frame:SetPoint(
					"TOPLEFT",
					group.container,
					"TOPLEFT",
					addon.Utilities:FromPixels(offsetXPx),
					-addon.Utilities:FromPixels(offsetYPx)
				)
				frame:SetSize(addon.Utilities:FromPixels(frameWidthPx), addon.Utilities:FromPixels(frameHeightPx))
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
