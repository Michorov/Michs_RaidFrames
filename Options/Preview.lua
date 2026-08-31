local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Preview = addon.Options.Preview or {}

local Preview = addon.Options.Preview
local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
local _, _, _, interfaceVersion = GetBuildInfo()
local isRestrictedAuraAPI = (tonumber(interfaceVersion) or 0) >= 120100

local preview
local panel
local activeMode = "party"
local activePage = "general"

local layoutValues = {
	outerInset = 8,
	titleInset = 10,
	titleTopInset = 24,
	titleHeight = 24,
	bodyTopGap = 10,
	bodyWidth = 200,
	checkboxTopOffset = 220,
	checkboxGap = 4,
}

local auraPreviewControls = {
	"buffs",
	"debuffs",
	"bigDefensive",
	"dispels",
	"raidBuffReminder",
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
	dispels = {
		label = "Dispels",
		enabled = false,
		updateStateReason = "dispelsSettingsChanged",
	},
}

if not isRestrictedAuraAPI then
	table.insert(auraPreviewControls, 4, "privateAuras")
	previewWidgetFlags.privateAuras =
		{ label = "Private Auras", enabled = false, updateStateReason = "privateAurasSettingsChanged" }
end

local previewPageWidgets = {
	general = {
		enabled = { "background", "health", "border", "power", "name", "roleIcon" },
		controls = {},
		testData = { testHealthIndex = 1, testPowerIndex = 1 },
	},
	clickCasting = {
		enabled = { "background", "health", "border", "power", "name", "roleIcon" },
		controls = {},
		testData = { testHealthIndex = 1, testPowerIndex = 1 },
	},
	layout = {
		enabled = { "background", "health", "border", "power", "name", "roleIcon" },
		controls = {},
		testData = { testHealthIndex = 1, testPowerIndex = 1 },
	},
	frames = {
		enabled = { "background", "health", "border", "power", "name", "roleIcon" },
		controls = {},
		testData = { testHealthIndex = 2, testPowerIndex = 1 },
	},
	bars = {
		enabled = { "background", "health", "border", "name", "roleIcon" },
		controls = { "power", "absorbs", "healAbsorbs" },
		testData = { testHealthIndex = 1, testPowerIndex = 8 },
	},
	texts = {
		enabled = { "background", "health", "border", "power", "name", "roleIcon" },
		controls = { "name", "statusText", "away", "healAbsorbsText" },
		testData = { testHealthIndex = 1, testPowerIndex = 1, testStatusText = "Dead" },
	},
	auras = {
		enabled = { "background", "health", "border", "power", "name", "roleIcon" },
		controls = auraPreviewControls,
		testData = { testHealthIndex = 1, testPowerIndex = 1 },
	},
	indicators = {
		enabled = { "background", "health", "border", "power", "name" },
		controls = { "readyCheck", "pendingSummon", "raidMarker", "roleIcon", "groupStatus", "threat" },
		testData = { testHealthIndex = 1, testPowerIndex = 1 },
	},
	profiles = {
		enabled = { "background", "health", "border", "power", "name", "roleIcon" },
		controls = {},
		testData = { testHealthIndex = 1, testPowerIndex = 1 },
	},
}

Preview.WidgetFlags = previewWidgetFlags
Preview.PageWidgets = previewPageWidgets

local function Localize(key)
	return panel and panel:Localize(key) or (addon.L and addon.L[key]) or key
end

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

function Preview:Create(ownerPanel)
	if preview then
		return preview
	end

	panel = ownerPanel
	activeMode = panel:GetActiveMode() or activeMode

	local PP = panel.instance.PP
	local previewSection = panel.frame.preview
	local canvas = previewSection:GetCanvas()
	preview = CreateFrame("Frame", nil, canvas)
	preview:SetAllPoints(canvas)
	preview.controls = {}

	preview.title = preview:CreateFontString(nil, "OVERLAY")
	preview.title:SetJustifyH("CENTER")
	preview.title:SetTextColor(OptionsUILib.Theme:GetTextColor("highlight"))
	OptionsUILib.Theme:ApplyFont(preview.title, PP:ScaleFont(20), "")

	preview.body = CreateFrame("Frame", nil, preview)
	preview.frameAreaBackground = preview.body:CreateTexture(nil, "BACKGROUND")
	preview.frameAreaBackground:SetTexture(
		"Interface\\AddOns\\Michs_RaidFrames\\Media\\Textures\\Absorb",
		"REPEAT",
		"REPEAT"
	)
	preview.frameAreaBackground:SetHorizTile(true)
	preview.frameAreaBackground:SetVertTile(true)
	preview.frameAreaBackground:SetVertexColor(OptionsUILib.Theme:GetColor("buttonBackgroundHover", 0.45))

	preview.partyFrame, preview.raidFrame = addon.FrameRegistry:CreatePreviewFrames(preview.body)
	preview.partyFrame:SetParent(preview.body)
	preview.raidFrame:SetParent(preview.body)

	for widgetKey, flag in pairs(previewWidgetFlags) do
		local checkbox = OptionsUILib.Controls.Checkbox:Create(preview.body, PP, Localize(flag.label))
		local key = widgetKey

		checkbox:SetLayoutWidth(layoutValues.bodyWidth)
		checkbox:SetOnValueChanged(function(_, checked)
			Preview:SetWidgetEnabled(key, checked)
		end)
		checkbox:Hide()

		flag.checkbox = checkbox
		preview.controls[widgetKey .. "Checkbox"] = checkbox
	end

	previewSection:SetPageUpdater(function(pageKey)
		self:SetActivePage(pageKey)
	end)

	previewSection:SetLayoutUpdater(function()
		self:UpdateLayout()
	end)

	panel:RegisterStateUpdater(self, function(_, mode)
		self:SetMode(mode)
		self:UpdateLayout()
	end)

	self:UpdateLocale()
	self:UpdateLayout()
	self:SetMode(activeMode)
	self:SetActivePage(panel.activePageKey or activePage)

	return preview
end

function Preview:UpdateLocale()
	if not preview then
		return
	end

	preview.title:SetText(Localize("Preview"))

	for _, flag in pairs(previewWidgetFlags) do
		if flag.checkbox then
			flag.checkbox:SetText(Localize(flag.label))
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

	local PP = panel.instance.PP
	local titleInset = PP:ToUIScaled(layoutValues.titleInset)
	local titleTopInset = PP:ToUIScaled(layoutValues.titleTopInset)
	local titleHeight = PP:ToUIScaled(layoutValues.titleHeight)
	local bodyTopGap = PP:ToUIScaled(layoutValues.bodyTopGap)
	local bodyWidth = PP:ToUIScaled(layoutValues.bodyWidth)
	local checkboxTopOffset = layoutValues.checkboxTopOffset
	local checkboxGap = layoutValues.checkboxGap

	preview.title:ClearAllPoints()
	preview.title:SetPoint("TOPLEFT", preview, "TOPLEFT", titleInset, -titleTopInset)
	preview.title:SetPoint("TOPRIGHT", preview, "TOPRIGHT", -titleInset, -titleTopInset)
	preview.title:SetHeight(titleHeight)
	OptionsUILib.Theme:ApplyFont(preview.title, PP:ScaleFont(20), "")

	preview.body:ClearAllPoints()
	preview.body:SetPoint("TOPLEFT", preview.title, "BOTTOMLEFT", 0, -bodyTopGap)
	preview.body:SetPoint("TOPRIGHT", preview.title, "BOTTOMRIGHT", 0, -bodyTopGap)
	preview.body:SetPoint("BOTTOMLEFT", preview, "BOTTOMLEFT", titleInset, titleInset)
	preview.body:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", -titleInset, titleInset)

	preview.frameAreaBackground:ClearAllPoints()
	preview.frameAreaBackground:SetPoint("TOPLEFT", preview.body, "TOPLEFT", 0, 0)
	preview.frameAreaBackground:SetSize(bodyWidth, bodyWidth)

	local profile = addon.Database:GetProfile()
	self:UpdateFrameLayout(preview.partyFrame, profile.party or {})
	self:UpdateFrameLayout(preview.raidFrame, profile.raid or {})

	for _, control in pairs(preview.controls) do
		control:SetLayoutWidth(layoutValues.bodyWidth)
		control:UpdateLayout()
		control:Hide()
	end

	local checkboxIndex = 0
	for _, widgetKey in ipairs((previewPageWidgets[activePage] or {}).controls or {}) do
		local flag = previewWidgetFlags[widgetKey]
		local checkbox = flag and flag.checkbox

		if checkbox then
			local offsetY = checkboxTopOffset + (checkboxIndex * (checkbox.layout.height + checkboxGap))

			checkbox:SetLayoutPoint("TOPLEFT", preview.body, "TOPLEFT", 0, -offsetY)
			checkbox:SetChecked(flag.enabled == true)
			checkbox:Show()

			checkboxIndex = checkboxIndex + 1
		end
	end
end
