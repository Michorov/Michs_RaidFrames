local _, addon = ...

addon.Frames = addon.Frames or {}
local Frames = addon.Frames

function Frames:CreateRaidHeader(raidSettings, groupIndex)
	local size = raidSettings.size or {}
	local spacing = raidSettings.spacing or {}

	local frameWidth = addon.Utilities:ToUI(addon.Utilities:ScaleEven(addon.Utilities:ToPixels(size.width or 112)))
	local frameHeight = addon.Utilities:ToUI(addon.Utilities:ScaleEven(addon.Utilities:ToPixels(size.height or 56)))
	local spacingY = addon.Utilities:ToUI(addon.Utilities:Scale(addon.Utilities:ToPixels(spacing.y or 0)))

	local header = CreateFrame("Frame", "MRF_RaidHeader" .. groupIndex, UIParent, "SecureGroupHeaderTemplate")
	header.mrfHeaderKind = "raid"

	header:SetAttribute("point", "TOP")
	header:SetAttribute("xOffset", 0)
	header:SetAttribute("yOffset", -spacingY)
	header:SetAttribute("columnAnchorPoint", "TOPLEFT")
	header:SetAttribute("template", "MRF_UnitFrameTemplate")
	header:SetAttribute("showPlayer", true)
	header:SetAttribute("showParty", false)
	header:SetAttribute("showRaid", true)
	header:SetAttribute("showSolo", false)
	header:SetAttribute("groupFilter", tostring(groupIndex))
	header:SetAttribute("frameWidth", frameWidth)
	header:SetAttribute("frameHeight", frameHeight)
	header:SetAttribute("sortMethod", "INDEX")
	header:SetAttribute("unitsPerColumn", 5)
	header:SetAttribute("maxColumns", 1)

	header:SetAttribute("startingIndex", -4)
	header:Show()
	header:SetAttribute("startingIndex", 1)

	return header
end

function Frames:CreatePartyHeader(partySettings)
	local size = partySettings.size or {}
	local spacing = partySettings.spacing or {}
	local position = partySettings.position or {}

	local frameWidth = addon.Utilities:ToUI(addon.Utilities:ScaleEven(addon.Utilities:ToPixels(size.width or 128)))
	local frameHeight = addon.Utilities:ToUI(addon.Utilities:ScaleEven(addon.Utilities:ToPixels(size.height or 64)))
	local spacingY = addon.Utilities:ToUI(addon.Utilities:Scale(addon.Utilities:ToPixels(spacing.y or 0)))
	local posX = addon.Utilities:ToUI(addon.Utilities:Scale(addon.Utilities:ToPixels(position.x or 0)))
	local posY = addon.Utilities:ToUI(addon.Utilities:Scale(addon.Utilities:ToPixels(position.y or 0)))

	local header = CreateFrame("Frame", "MRF_PartyHeader", UIParent, "SecureGroupHeaderTemplate")
	header.mrfHeaderKind = "party"

	local totalHeight = (5 * frameHeight) + (4 * spacingY)
	header:SetPoint("TOP", UIParent, "CENTER", posX, posY + totalHeight / 2)

	header:SetAttribute("point", "TOP")
	header:SetAttribute("xOffset", 0)
	header:SetAttribute("yOffset", -spacingY)
	header:SetAttribute("columnAnchorPoint", "TOPLEFT")
	header:SetAttribute("template", "MRF_UnitFrameTemplate")
	header:SetAttribute("showPlayer", true)
	header:SetAttribute("showParty", true)
	header:SetAttribute("showRaid", false)
	header:SetAttribute("showSolo", true)
	header:SetAttribute("frameWidth", frameWidth)
	header:SetAttribute("frameHeight", frameHeight)
	header:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
	header:SetAttribute("groupBy", "ASSIGNEDROLE")
	header:SetAttribute("sortMethod", "INDEX")
	header:SetAttribute("unitsPerColumn", 5)
	header:SetAttribute("maxColumns", 5)

	header:SetAttribute("startingIndex", -4)
	header:Show()
	header:SetAttribute("startingIndex", 1)

	return header
end

function Frames:CreateTestGroup(groupType)
	if type(groupType) ~= "string" or groupType == "" then
		error("Frames:CreateTestGroup requires a non-empty group type", 2)
	end

	local groupName = "MRF_Test" .. groupType .. "Group"
	local group = CreateFrame("Frame", groupName, UIParent)
	group.name = groupName

	group:SetSize(1, 1)
	group:ClearAllPoints()
	group:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	return group
end

function Frames:CreateTestFrame(group, frameIndex)
	if not group then
		error("Frames:CreateTestFrame requires group", 2)
	end

	local frameName = group.name .. "_Frame" .. frameIndex
	local frame = CreateFrame("Button", frameName, group)

	frame.unit = nil

	frame.testIndex = frameIndex
	frame.testClassIndex = math.random(1, 13)
	frame.testHealthIndex = math.random(1, 8)
	frame.testPowerIndex = math.random(1, 8)
	frame.testAbsorbIndex = math.random(1, 8)
	frame.testHealAbsorbIndex = math.random(1, 8)

	frame.dataProvider = addon.Frames.DataProvider.Test

	frame:RegisterForClicks("AnyUp")
	frame:SetSize(1, 1)

	return frame
end

function Frames:CreatePreviewFrame(parent)
	if not parent then
		error("Frames:CreatePreviewFrame requires parent", 2)
	end

	local frame = CreateFrame("Button", nil, parent)

	frame.unit = nil
	frame.previewWidgetVisibility = {
		power = false,
		readyCheck = false,
		pendingSummon = false,
		raidMarker = false,
		roleIcon = false,
		groupStatus = false,
		threat = false,
		name = false,
		statusText = false,
		absorbs = false,
		healAbsorbs = false,
		healAbsorbsText = false,
		buffs = false,
		customBuffs = false,
		buffOverlay = false,
		debuffs = false,
		bigDefensive = false,
		raidBuffReminder = false,
		privateAuras = false,
		dispels = false,
		dispelOverlay = false,
	}

	frame.testIndex = 1
	frame.testClassIndex = 5
	frame.testHealthIndex = 1
	frame.testPowerIndex = 2
	frame.testAbsorbIndex = 3
	frame.testHealAbsorbIndex = 1

	frame.dataProvider = addon.Frames.DataProvider.Test

	frame:RegisterForClicks("AnyUp")
	frame:SetSize(1, 1)

	return frame
end
