local _, addon = ...

addon.Frames = addon.Frames or {}
local Frames = addon.Frames

local function SaveTestGroupPosition(group)
	local groupType = group and group.testGroupType
	if groupType ~= "party" and groupType ~= "raid" then
		return
	end

	local centerX, centerY = group:GetCenter()
	local parentCenterX, parentCenterY = UIParent:GetCenter()
	if not centerX or not centerY or not parentCenterX or not parentCenterY then
		return
	end

	local positionXPx = addon.Utilities:Unscale(addon.Utilities:ToPixels(centerX - parentCenterX))
	local positionYPx = addon.Utilities:Unscale(addon.Utilities:ToPixels(centerY - parentCenterY))

	local profile = addon.Database:GetProfile()
	profile[groupType] = profile[groupType] or {}
	profile[groupType].position = profile[groupType].position or {}
	profile[groupType].position.x = addon.Utilities:RoundToNearestInt(addon.Utilities:ToUI(positionXPx))
	profile[groupType].position.y = addon.Utilities:RoundToNearestInt(addon.Utilities:ToUI(positionYPx))

	if addon.Options and addon.Options.Data and addon.Options.Data.RefreshProfile then
		addon.Options.Data:RefreshProfile()
	end

	if addon.OptionsNew and addon.OptionsNew.RefreshState then
		addon.OptionsNew:RefreshState()
	end

	addon.UpdateScheduler:Notify("layoutChanged")
end

local function CreateTestGroupDragOverlay(group)
	local overlay = CreateFrame("Frame", nil, group)
	overlay:SetAllPoints(group)
	overlay:SetFrameLevel(40)
	overlay:EnableMouse(false)

	local background = overlay:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints(overlay)
	background:SetColorTexture(0.005, 0.015, 0.035, 0.78)
	overlay.background = background

	local handle = overlay:CreateTexture(nil, "ARTWORK")
	handle:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
	handle:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
	handle:SetHeight(addon.Utilities:ToUI(addon.Utilities:Scale(4)))
	handle:SetColorTexture(0.00, 0.42, 1.00, 0.85)
	overlay.handle = handle

	local textPadding = addon.Utilities:ToUI(addon.Utilities:Scale(8))
	local text = overlay:CreateFontString(nil, "OVERLAY")
	text:SetPoint("LEFT", overlay, "LEFT", textPadding, 0)
	text:SetPoint("RIGHT", overlay, "RIGHT", -textPadding, 0)
	text:SetFont(addon.Utilities:GetGameFontNormalPath(), addon.Utilities:ScaleFont(18), "OUTLINE")
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	text:SetWordWrap(true)
	text:SetTextColor(1, 1, 1, 1)
	text:SetText("Drag to Move")
	overlay.text = text

	local border = {}
	local thickness = addon.Utilities:ToUI(addon.Utilities:Scale(4))

	border.top = overlay:CreateTexture(nil, "BORDER")
	border.top:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
	border.top:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
	border.top:SetHeight(thickness)

	border.bottom = overlay:CreateTexture(nil, "BORDER")
	border.bottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
	border.bottom:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
	border.bottom:SetHeight(thickness)

	border.left = overlay:CreateTexture(nil, "BORDER")
	border.left:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
	border.left:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
	border.left:SetWidth(thickness)

	border.right = overlay:CreateTexture(nil, "BORDER")
	border.right:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
	border.right:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
	border.right:SetWidth(thickness)

	for _, texture in pairs(border) do
		texture:SetColorTexture(0.00, 0.42, 1.00, 0.90)
	end

	overlay.border = border

	return overlay
end

function Frames:CreateRaidHeader(raidSettings, groupIndex)
	local size = raidSettings.size or {}
	local spacing = raidSettings.spacing or {}

	local frameWidth = addon.Utilities:ToUI(addon.Utilities:ScaleEven(addon.Utilities:ToPixels(size.width or 112)))
	local frameHeight = addon.Utilities:ToUI(addon.Utilities:ScaleEven(addon.Utilities:ToPixels(size.height or 56)))
	local spacingY = addon.Utilities:ToUI(addon.Utilities:Scale(addon.Utilities:ToPixels(spacing.y or 0)))

	local header = CreateFrame("Frame", "MRF_RaidHeader" .. groupIndex, UIParent, "SecureGroupHeaderTemplate")
	header.HeaderKind = "raid"

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
	header.HeaderKind = "party"

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
	group.testGroupType = string.lower(groupType)

	group:SetSize(1, 1)
	group:ClearAllPoints()
	group:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	group:SetMovable(true)
	group:SetClampedToScreen(true)
	group:EnableMouse(true)
	group:RegisterForDrag("LeftButton")
	group.dragOverlay = CreateTestGroupDragOverlay(group)

	group:SetScript("OnDragStart", function(self)
		if InCombatLockdown() then
			return
		end

		self:StartMoving()
	end)

	group:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SaveTestGroupPosition(self)
	end)

	return group
end

function Frames:CreateTestFrame(group, frameIndex)
	if not group then
		error("Frames:CreateTestFrame requires group", 2)
	end

	local frameName = group.name .. "_Frame" .. frameIndex
	local frame = CreateFrame("Button", frameName, group)

	frame.unit = nil
	frame.testName = "Test Frame"

	frame.testIndex = frameIndex
	frame.testClassIndex = math.random(1, 13)
	frame.testHealthIndex = 1
	frame.testPowerIndex = math.random(1, 8)
	frame.testAbsorbIndex = math.random(1, 8)
	frame.testHealAbsorbIndex = math.random(1, 8)

	frame.dataProvider = addon.Frames.DataProvider.Test

	frame.testBackground = frame:CreateTexture(nil, "BACKGROUND")
	frame.testBackground:SetAllPoints(frame)
	frame.testBackground:SetColorTexture(0.10, 0.10, 0.10, 1)

	local borderThickness = addon.Utilities:ToUI(addon.Utilities:Scale(1))
	frame.testBorder = {}

	frame.testBorder.top = frame:CreateTexture(nil, "BORDER")
	frame.testBorder.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.testBorder.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	frame.testBorder.top:SetHeight(borderThickness)

	frame.testBorder.bottom = frame:CreateTexture(nil, "BORDER")
	frame.testBorder.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	frame.testBorder.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	frame.testBorder.bottom:SetHeight(borderThickness)

	frame.testBorder.left = frame:CreateTexture(nil, "BORDER")
	frame.testBorder.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.testBorder.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	frame.testBorder.left:SetWidth(borderThickness)

	frame.testBorder.right = frame:CreateTexture(nil, "BORDER")
	frame.testBorder.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	frame.testBorder.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	frame.testBorder.right:SetWidth(borderThickness)

	for _, texture in pairs(frame.testBorder) do
		texture:SetColorTexture(0.00, 0.42, 1.00, 0.85)
	end

	local textPadding = addon.Utilities:ToUI(addon.Utilities:Scale(4))
	frame.testText = frame:CreateFontString(nil, "OVERLAY")
	frame.testText:SetPoint("LEFT", frame, "LEFT", textPadding, 0)
	frame.testText:SetPoint("RIGHT", frame, "RIGHT", -textPadding, 0)
	frame.testText:SetFont(addon.Utilities:GetGameFontNormalPath(), addon.Utilities:ScaleFont(10), "OUTLINE")
	frame.testText:SetJustifyH("CENTER")
	frame.testText:SetJustifyV("MIDDLE")
	frame.testText:SetWordWrap(true)
	frame.testText:SetTextColor(1, 1, 1, 1)
	frame.testText:SetText("Test Frame")

	frame:EnableMouse(false)
	frame:SetSize(1, 1)

	return frame
end

function Frames:CreatePreviewFrame(parent)
	if not parent then
		error("Frames:CreatePreviewFrame requires parent", 2)
	end

	local frame = CreateFrame("Button", nil, parent)

	frame.unit = nil
	frame.testName = UnitName("player") or ""

	frame.testIndex = 2
	frame.testClassIndex = 5
	frame.testHealthIndex = 1
	frame.testPowerIndex = 2
	frame.testAbsorbIndex = 7
	frame.testHealAbsorbIndex = 7

	frame.previewWidgetVisibility = {
		power = false,
		readyCheck = false,
		pendingSummon = false,
		raidMarker = false,
		roleIcon = false,
		groupStatus = false,
		threat = false,
		name = false,
		away = false,
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
	}

	frame.dataProvider = addon.Frames.DataProvider.Test

	frame:RegisterForClicks("AnyUp")
	frame:SetSize(1, 1)

	return frame
end
