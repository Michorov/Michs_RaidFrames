local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.Preview = addon.Options.Sections.Preview or {}

local Preview = addon.Options.Sections.Preview

local preview
local activeMode = (addon.Options.ControllerState and addon.Options.ControllerState.mode) or "party"
local activePage = "general"
local L = addon.L
local theme = addon.Options.Theme

local layoutValues = {
	outerInset = 8,
	titleInset = 10,
	titleTopInset = 24,
	titleHeight = 24,
	bodyTopGap = 10,
	bodyWidth = 200,
	checkboxTopOffset = 220,
	checkboxGap = 8,
}

local previewWidgetFlags = {
	background = { label = "Background", enabled = false, updateStateReason = "backgroundSettingsChanged" },
	health = { label = "Health", enabled = false, updateStateReason = "healthStateChanged" },
	border = { label = "Border", enabled = false, updateStateReason = "borderSettingsChanged" },
	power = { label = "Power Bar", enabled = false, updateStateReason = "powerStateChanged" },
	readyCheck = { label = "Ready Check", enabled = false, updateStateReason = "readyCheckStateChanged" },
	pendingSummon = { label = "Summon", enabled = false, updateStateReason = "pendingSummonStateChanged" },
	raidMarker = { label = "Raid Marker", enabled = false, updateStateReason = "raidMarkerStateChanged" },
	roleIcon = { label = "Role", enabled = false, updateStateReason = "roleIconStateChanged" },
	groupStatus = { label = "Group Leader", enabled = false, updateStateReason = "groupStatusStateChanged" },
	threat = { label = "Threat", enabled = false, updateStateReason = "threatStateChanged" },
	name = { label = "Name", enabled = false, updateStateReason = "nameStateChanged" },
	away = { label = "Away", enabled = false, updateStateReason = "awayStateChanged" },
	statusText = { label = "Status", enabled = false, updateStateReason = "statusStateChanged" },
	absorbs = { label = "Absorbs", enabled = false, updateStateReason = "absorbsStateChanged" },
	healAbsorbs = { label = "Heal Absorbs", enabled = false, updateStateReason = "healAbsorbsStateChanged" },
	healAbsorbsText = { label = "Heal Absorbs", enabled = false, updateStateReason = "healAbsorbsStateChanged" },
	buffs = {
		label = "Buffs",
		enabled = false,
		updateStateReason = "aurasStateChanged",
		linkedWidgets = { "customBuffs", "buffOverlay" },
	},
	customBuffs = { label = "Buffs Custom", enabled = false, updateStateReason = "aurasStateChanged" },
	buffOverlay = { label = "Buffs Overlay", enabled = false, updateStateReason = "aurasStateChanged" },
	raidBuffReminder = { label = "Buff Reminder", enabled = false, updateStateReason = "aurasStateChanged" },
	debuffs = { label = "Debuffs", enabled = false, updateStateReason = "aurasStateChanged" },
	bigDefensive = { label = "Big Defensive", enabled = false, updateStateReason = "aurasStateChanged" },
	privateAuras = { label = "Private Auras", enabled = false, updateStateReason = "privateAurasSettingsChanged" },
	dispels = {
		label = "Dispels",
		enabled = false,
		updateStateReason = "dispelsSettingsChanged",
	},
}

local previewPageWidgets = {
	general = { enabled = { "background", "health", "border", "power", "name", "roleIcon" }, controls = {}, testData = { testHealthIndex = 1, testPowerIndex = 1 } },
	layout = { enabled = { "background", "health", "border", "power", "name", "roleIcon" }, controls = {}, testData = { testHealthIndex = 1, testPowerIndex = 1 } },
	frames = { enabled = { "background", "health", "border", "power", "name", "roleIcon" }, controls = {}, testData = { testHealthIndex = 3, testPowerIndex = 1 } },
	bars = {
		enabled = { "background", "health", "border", "name", "roleIcon" },
		controls = { "power", "absorbs", "healAbsorbs" },
		testData = { testHealthIndex = 1, testPowerIndex = 8 },
	},
	texts = {
		enabled = { "background", "health", "border", "power", "name", "roleIcon" },
		controls = { "name", "away", "healAbsorbsText" },
		testData = { testHealthIndex = 1, testPowerIndex = 1 },
	},
	auras = {
		enabled = { "background", "health", "border", "power", "name", "roleIcon" },
		controls = {
			"buffs",
			"debuffs",
			"bigDefensive",
			"privateAuras",
			"dispels",
			"raidBuffReminder",
		},
		testData = { testHealthIndex = 1, testPowerIndex = 1 },
	},
	indicators = {
		enabled = { "background", "health", "border", "power", "name" },
		controls = { "readyCheck", "pendingSummon", "raidMarker", "roleIcon", "groupStatus", "threat" },
		testData = { testHealthIndex = 1, testPowerIndex = 1 },
	},
	profiles = { enabled = { "background", "health", "border", "power", "name", "roleIcon" }, controls = {}, testData = { testHealthIndex = 1, testPowerIndex = 1 } },
}

Preview.WidgetFlags = previewWidgetFlags
Preview.PageWidgets = previewPageWidgets

local function NotifyPreviewStateChanged(changedWidgets)
	local notifiedReasons = {}

	for widgetKey in pairs(changedWidgets or {}) do
		local flag = previewWidgetFlags[widgetKey]

		if flag.updateStateReason and not notifiedReasons[flag.updateStateReason] then
			notifiedReasons[flag.updateStateReason] = true
			addon.UpdateScheduler:Notify(flag.updateStateReason)
		end
	end
end

local function NotifyPreviewWidgetStateChanged(widgetKey)
	local flag = previewWidgetFlags[widgetKey]
	if flag and flag.updateStateReason then
		addon.UpdateScheduler:Notify(flag.updateStateReason)
	end
end

local function ApplyPreviewWidgetFlag(widgetKey)
	local flag = previewWidgetFlags[widgetKey]
	if not preview or not flag then
		return
	end

	for _, frame in ipairs({ preview.partyFrame, preview.raidFrame }) do
		if frame and frame.previewWidgetVisibility then
			frame.previewWidgetVisibility[widgetKey] = flag.enabled == true
		end
	end
end

function Preview:Ensure(parent)
	if preview then
		return preview
	end

	preview = CreateFrame("Frame", nil, parent)
	preview.controls = {}

	preview.leftBorder = preview:CreateTexture(nil, "OVERLAY")
	preview.leftBorder:SetColorTexture(theme:GetColor("border"))

	preview.title = preview:CreateFontString(nil, "OVERLAY")
	preview.title:SetJustifyH("CENTER")
	theme:ApplyFont(preview.title, "arialNarrow", 20, "")
	preview.title:SetTextColor(theme:GetTextColor("highlight"))

	preview.body = CreateFrame("Frame", nil, preview)
	preview.frameAreaBackground = preview.body:CreateTexture(nil, "BACKGROUND")
	preview.frameAreaBackground:SetTexture(
		"Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\Absorb",
		"REPEAT",
		"REPEAT"
	)
	preview.frameAreaBackground:SetHorizTile(true)
	preview.frameAreaBackground:SetVertTile(true)
	preview.frameAreaBackground:SetVertexColor(theme:GetColor("buttonBackgroundHover", 0.45))

	preview.partyFrame, preview.raidFrame = addon.FrameRegistry:CreatePreviewFrames(preview.body)

	for widgetKey, flag in pairs(previewWidgetFlags) do
		local checkbox = addon.Options.Controls.Checkbox:Create(preview.body, L[flag.label])
		local key = widgetKey

		checkbox:SetLayoutWidth(layoutValues.bodyWidth)
		checkbox:SetOnValueChanged(function(_, checked)
			Preview:SetWidgetEnabled(key, checked)
		end)
		checkbox:Hide()

		flag.checkbox = checkbox
		preview.controls[widgetKey .. "Checkbox"] = checkbox
	end

	self:UpdateLocale()
	self:UpdateLayout()
	self:SetMode(activeMode)
	self:SetActivePage(activePage)

	return preview
end

function Preview:UpdateLocale()
	if not preview then
		return
	end

	preview.title:SetText(L["Preview"])

	for _, flag in pairs(previewWidgetFlags) do
		if flag.checkbox then
			flag.checkbox:SetText(L[flag.label])
		end
	end
end

function Preview:SetMode(mode)
	activeMode = mode or activeMode

	if not preview then
		return
	end

	if preview.partyFrame then
		preview.partyFrame:SetShown(activeMode == "party")
	end

	if preview.raidFrame then
		preview.raidFrame:SetShown(activeMode == "raid")
	end
end

function Preview:SetActivePage(pageKey)
	activePage = pageKey or activePage

	if not preview then
		return
	end

	local activeWidgets = {}
	local visibleWidgets = {}
	local changedWidgets = {}
	local pageWidgets = previewPageWidgets[activePage] or {}
	local hasTestData = next(pageWidgets.testData or {}) ~= nil

	for _, frame in ipairs({ preview.partyFrame, preview.raidFrame }) do
		if frame then
			for key, value in pairs(pageWidgets.testData or {}) do
				frame[key] = value
			end
		end
	end

	for _, widgetKey in ipairs(pageWidgets.enabled or {}) do
		activeWidgets[widgetKey] = true

		local flag = previewWidgetFlags[widgetKey]
		for _, linkedWidgetKey in ipairs((flag and flag.linkedWidgets) or {}) do
			activeWidgets[linkedWidgetKey] = true
		end
	end

	for _, widgetKey in ipairs(pageWidgets.controls or {}) do
		activeWidgets[widgetKey] = true
		visibleWidgets[widgetKey] = true

		local flag = previewWidgetFlags[widgetKey]
		for _, linkedWidgetKey in ipairs((flag and flag.linkedWidgets) or {}) do
			activeWidgets[linkedWidgetKey] = true
		end
	end

	for widgetKey, flag in pairs(previewWidgetFlags) do
		local enabled = activeWidgets[widgetKey] == true

		if flag.enabled ~= enabled or (enabled and hasTestData) then
			changedWidgets[widgetKey] = true
		end

		if enabled then
			changedWidgets[widgetKey] = true
		end

		flag.enabled = enabled

		if flag.checkbox then
			flag.checkbox:SetChecked(flag.enabled)
			flag.checkbox:SetShown(visibleWidgets[widgetKey] == true)
		end
	end

	for _, frame in ipairs({ preview.partyFrame, preview.raidFrame }) do
		if frame and frame.previewWidgetVisibility then
			for key, flag in pairs(previewWidgetFlags) do
				frame.previewWidgetVisibility[key] = flag and flag.enabled == true
			end
		end
	end

	NotifyPreviewStateChanged(changedWidgets)
	self:UpdateLayout()
end

function Preview:SetWidgetEnabled(widgetKey, enabled)
	local flag = previewWidgetFlags[widgetKey]
	if not flag then
		return
	end

	flag.enabled = enabled == true
	if flag.checkbox then
		flag.checkbox:SetChecked(flag.enabled)
	end

	ApplyPreviewWidgetFlag(widgetKey)

	for _, linkedWidgetKey in ipairs(flag.linkedWidgets or {}) do
		local linkedFlag = previewWidgetFlags[linkedWidgetKey]

		if linkedFlag then
			linkedFlag.enabled = flag.enabled

			if linkedFlag.checkbox then
				linkedFlag.checkbox:SetChecked(flag.enabled)
			end

			ApplyPreviewWidgetFlag(linkedWidgetKey)
		end
	end

	NotifyPreviewWidgetStateChanged(widgetKey)
end

function Preview:UpdateFrameLayout(frame, settings)
	if not preview or not frame then
		return
	end

	local frameWidthPx, frameHeightPx = addon.Frames:UpdatePreviewFrameLayout(frame, settings)
	local bodyWidthPx = addon.Utilities:ToPixels(layoutValues.bodyWidth)
	local offsetXPx = addon.Utilities:RoundToNearestInt((bodyWidthPx - frameWidthPx) / 2)
	local offsetYPx = addon.Utilities:RoundToNearestInt((bodyWidthPx - frameHeightPx) / 2)

	frame:ClearAllPoints()
	frame:SetPoint(
		"TOPLEFT",
		preview.body,
		"TOPLEFT",
		addon.Utilities:ToUI(offsetXPx),
		-addon.Utilities:ToUI(offsetYPx)
	)

	return frameWidthPx, frameHeightPx
end

function Preview:UpdateLayout()
	if not preview then
		return
	end

	local outerInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.outerInset))
	local titleInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.titleInset))
	local titleTopInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.titleTopInset))
	local titleHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.titleHeight))
	local bodyTopGap = addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.bodyTopGap))
	local bodyWidthPx = addon.Utilities:ToPixels(layoutValues.bodyWidth)
	local checkboxTopOffsetPx = addon.Utilities:ToPixels(layoutValues.checkboxTopOffset)
	local checkboxGapPx = addon.Utilities:ToPixels(layoutValues.checkboxGap)

	preview.leftBorder:ClearAllPoints()
	preview.leftBorder:SetPoint("TOPLEFT", preview, "TOPLEFT", 0, -outerInset)
	preview.leftBorder:SetPoint("BOTTOMLEFT", preview, "BOTTOMLEFT", 0, outerInset)
	preview.leftBorder:SetWidth(addon.Utilities:ToUI(addon.Utilities:ToPixels(1)))

	preview.title:ClearAllPoints()
	preview.title:SetPoint("TOPLEFT", preview, "TOPLEFT", titleInset, -titleTopInset)
	preview.title:SetPoint("TOPRIGHT", preview, "TOPRIGHT", -titleInset, -titleTopInset)
	preview.title:SetHeight(titleHeight)

	preview.body:ClearAllPoints()
	preview.body:SetPoint("TOPLEFT", preview.title, "BOTTOMLEFT", 0, -bodyTopGap)
	preview.body:SetPoint("TOPRIGHT", preview.title, "BOTTOMRIGHT", 0, -bodyTopGap)
	preview.body:SetPoint("BOTTOMLEFT", preview, "BOTTOMLEFT", titleInset, titleInset)
	preview.body:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", -titleInset, titleInset)

	preview.frameAreaBackground:ClearAllPoints()
	preview.frameAreaBackground:SetPoint("TOPLEFT", preview.body, "TOPLEFT", 0, 0)
	preview.frameAreaBackground:SetSize(addon.Utilities:ToUI(bodyWidthPx), addon.Utilities:ToUI(bodyWidthPx))

	local profile = addon.Database:GetProfile()
	self:UpdateFrameLayout(preview.partyFrame, profile.party or {})
	self:UpdateFrameLayout(preview.raidFrame, profile.raid or {})
	local checkboxIndex = 0

	for _, control in pairs(preview.controls) do
		if control.layoutValues then
			control.layoutValues.width = addon.Utilities:ToUI(bodyWidthPx)
		end

		if control.UpdateLayout then
			control:UpdateLayout()
		end

		if control.Hide then
			control:Hide()
		end
	end

	for _, widgetKey in ipairs((previewPageWidgets[activePage] or {}).controls or {}) do
		local flag = previewWidgetFlags[widgetKey]
		local checkbox = flag and flag.checkbox

		if checkbox then
			local checkboxHeightPx = addon.Utilities:ToPixels(checkbox.layoutValues.height)
			local offsetYPx = checkboxTopOffsetPx + (checkboxIndex * (checkboxHeightPx + checkboxGapPx))

			checkbox:ClearAllPoints()
			checkbox:SetPoint("TOPLEFT", preview.body, "TOPLEFT", 0, -addon.Utilities:ToUI(offsetYPx))
			checkbox:SetChecked(flag.enabled == true)
			checkbox:Show()

			checkboxIndex = checkboxIndex + 1
		end
	end
end
