local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Layout = addon.Options.Pages.Layout or {}

local Layout = addon.Options.Pages.Layout

local page
local L = addon.L
local theme = addon.Options.Theme
local testModeButtonWidth = 116
local testModeButtonHeight = 22

local function GetTestModeButtonText()
	if addon.FrameRegistry and addon.FrameRegistry.GetActiveTestMode and addon.FrameRegistry:GetActiveTestMode() then
		return L["Lock"]
	end

	return L["Unlock"]
end

local function GetModeDefaults(mode)
	if mode == "raid" then
		return {
			positionX = 0,
			positionY = 0,
			spacingX = -1,
			spacingY = -1,
			groups = {
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = false,
				[7] = false,
				[8] = false,
			},
			direction = "HORIZONTAL",
			reverse = false,
		}
	end

	return {
		positionX = 0,
		positionY = 0,
		spacingX = -1,
		spacingY = -1,
		direction = "VERTICAL",
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Layout changes are disabled during combat."])
end

local function GetOrientationOptions()
	return {
		{ value = "HORIZONTAL", text = L["Horizontal"] },
		{ value = "VERTICAL", text = L["Vertical"] },
	}
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ApplyModeSetting(updateFn, notifyEvent)
	if InCombatLockdown() then
		ShowCombatLockMessage()
		if page and page.UpdateState then
			page:UpdateState(addon.Database:GetProfile())
		end
		return
	end

	local profile = addon.Database:GetProfile()
	local mode = addon.Options.State:GetMode()

	profile[mode] = profile[mode] or {}
	updateFn(profile[mode], mode)

	addon.UpdateScheduler:Notify(notifyEvent)
end

local function ApplyRaidSetting(updateFn, notifyEvent)
	if InCombatLockdown() then
		ShowCombatLockMessage()
		if page and page.UpdateState then
			page:UpdateState(addon.Database:GetProfile())
		end
		return
	end

	local profile = addon.Database:GetProfile()
	profile.raid = profile.raid or {}
	updateFn(profile.raid)

	addon.UpdateScheduler:Notify(notifyEvent)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

function Layout:Ensure(parent)
	if page then
		return page
	end

	page = CreateFrame("Frame", nil, parent)

	page.header = CreateFrame("Frame", nil, page)
	page.header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
	page.header:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)

	page.body = CreateFrame("Frame", nil, page)
	page.body:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
	page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

	page.header.title = page.header:CreateFontString(nil, "OVERLAY")
	page.header.title:SetPoint("LEFT", page.header, "LEFT", 0, 0)
	page.header.title:SetJustifyH("LEFT")
	theme:ApplyFont(page.header.title, "arialNarrow", 20, "")
	page.header.title:SetTextColor(theme:GetTextColor("highlight"))
	page.header.title:SetText(L["Layout"])

	page.modeToggle = addon.Options.Controls.SegmentedToggle:Create(
		page.header,
		{ value = "party", text = L["Party"] },
		{ value = "raid", text = L["Raid"] }
	)
	page.modeToggle:SetPoint("RIGHT", page.header, "RIGHT", 0, 0)
	page.modeToggle:SetOnValueChanged(function(_, value)
		addon.Options.Sections.Content:SetMode(value)
		if page and page.UpdateLayout then
			page:UpdateLayout()
		end
		if page and page.UpdateState then
			page:UpdateState(addon.Database:GetProfile())
		end
	end)

	page.testModeButton = addon.Options.Controls.Button:Create(page.header, GetTestModeButtonText())
	page.testModeButton:SetLayoutSize(testModeButtonWidth, testModeButtonHeight)
	page.testModeButton:SetOnClick(function()
		addon.FrameRegistry:ToggleTestMode(addon.Options.State:GetMode())
		if page and page.UpdateState then
			page:UpdateState(addon.Database:GetProfile())
		end
	end)

	page.horizontalPositionSlider = addon.Options.Controls.Slider:Create(page.body, L["Horizontal Position"])
	page.horizontalPositionSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.horizontalPositionSlider, -2000, 2000, 1)
	page.horizontalPositionSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.position = section.position or {}
			section.position.x = value
		end, "layoutChanged")
	end)

	page.verticalPositionSlider = addon.Options.Controls.Slider:Create(page.body, L["Vertical Position"])
	page.verticalPositionSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.verticalPositionSlider, -2000, 2000, 1)
	page.verticalPositionSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.position = section.position or {}
			section.position.y = value
		end, "layoutChanged")
	end)

	page.horizontalSpacingSlider = addon.Options.Controls.Slider:Create(page.body, L["Horizontal Spacing"])
	page.horizontalSpacingSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.horizontalSpacingSlider, -25, 25, 1)
	page.horizontalSpacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.spacing = section.spacing or {}
			section.spacing.x = value
		end, "layoutChanged")
	end)

	page.verticalSpacingSlider = addon.Options.Controls.Slider:Create(page.body, L["Vertical Spacing"])
	page.verticalSpacingSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.verticalSpacingSlider, -25, 25, 1)
	page.verticalSpacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.spacing = section.spacing or {}
			section.spacing.y = value
		end, "layoutChanged")
	end)

	page.orientationDropdown = addon.Options.Controls.Dropdown:Create(page.body, L["Orientation"])
	page.orientationDropdown:SetLayoutWidth(174)
	page.orientationDropdown:SetOptions(GetOrientationOptions())
	page.orientationDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.direction = value
		end, "layoutChanged")
	end)

	page.reverseGroupOrderCheckbox = addon.Options.Controls.Checkbox:Create(page.body, L["Reverse Group Order"])
	page.reverseGroupOrderCheckbox:SetLayoutWidth(174)
	page.reverseGroupOrderCheckbox:SetOnValueChanged(function(_, checked)
		ApplyRaidSetting(function(section)
			section.reverse = checked == true
		end, "layoutChanged")
	end)

	page.raidGroupCheckboxes = {}
	for groupIndex = 1, 8 do
		local checkbox = addon.Options.Controls.Checkbox:Create(page.body, (L["Group %d"]):format(groupIndex))
		checkbox:SetLayoutWidth(87)
		checkbox:SetOnValueChanged(function(_, checked)
			ApplyRaidSetting(function(section)
				section.groups = section.groups or {}
				section.groups[groupIndex] = checked == true
			end, "layoutChanged")
		end)

		page.raidGroupCheckboxes[groupIndex] = checkbox
	end

	page.controls = {
		modeToggle = page.modeToggle,
		testModeButton = page.testModeButton,
		horizontalPositionSlider = page.horizontalPositionSlider,
		verticalPositionSlider = page.verticalPositionSlider,
		horizontalSpacingSlider = page.horizontalSpacingSlider,
		verticalSpacingSlider = page.verticalSpacingSlider,
		orientationDropdown = page.orientationDropdown,
		reverseGroupOrderCheckbox = page.reverseGroupOrderCheckbox,
	}

	for groupIndex, checkbox in ipairs(page.raidGroupCheckboxes) do
		page.controls["raidGroupCheckbox" .. groupIndex] = checkbox
	end

	function page:UpdateLocale()
		self.header.title:SetText(L["Layout"])
		self.modeToggle:SetOptions(
			{ value = "party", text = L["Party"] },
			{ value = "raid", text = L["Raid"] }
		)
		self.testModeButton:SetText(GetTestModeButtonText())
		self.horizontalPositionSlider:SetLabel(L["Horizontal Position"])
		self.verticalPositionSlider:SetLabel(L["Vertical Position"])
		self.horizontalSpacingSlider:SetLabel(L["Horizontal Spacing"])
		self.verticalSpacingSlider:SetLabel(L["Vertical Spacing"])
		self.orientationDropdown:SetLabel(L["Orientation"])
		self.orientationDropdown:SetOptions(GetOrientationOptions())
		self.reverseGroupOrderCheckbox:SetText(L["Reverse Group Order"])

		for groupIndex, checkbox in ipairs(self.raidGroupCheckboxes or {}) do
			checkbox:SetText((L["Group %d"]):format(groupIndex))
		end
	end

	function page:UpdateLayout()
		local controls = self.controls
		local headerHeightPx = addon.Utilities:ToPixels(32)
		local firstControlOffsetPx = addon.Utilities:ToPixels(16)
		local headerControlGapPx = addon.Utilities:ToPixels(8)
		local rowStepPx = addon.Utilities:ToPixels(50)
		local sectionGapPx = addon.Utilities:ToPixels(16)
		local thirdRowOffsetPx = (rowStepPx * 2) + sectionGapPx
		local columnGapPx = addon.Utilities:ToPixels(30)
		local threeColumnSlotWidthPx = addon.Utilities:ToPixels(174)
		local threeColumnSecondOffsetPx = threeColumnSlotWidthPx + columnGapPx
		local reverseCheckboxHeightPx = addon.Utilities:ToPixels(controls.reverseGroupOrderCheckbox.layoutValues.height)
		local orientationFieldTopInsetPx = addon.Utilities:ToPixels(
			controls.orientationDropdown.layoutValues.labelHeight
				+ controls.orientationDropdown.layoutValues.labelSpacing
		)
		local orientationFieldHeightPx = addon.Utilities:ToPixels(controls.orientationDropdown.layoutValues.fieldHeight)
		local orientationControlHeightPx = orientationFieldTopInsetPx + orientationFieldHeightPx
		local reverseCheckboxOffsetPx = orientationFieldTopInsetPx
			+ addon.Utilities:RoundToNearestInt(math.max(0, (orientationFieldHeightPx - reverseCheckboxHeightPx) / 2))
		local groupCheckboxWidthPx = addon.Utilities:ToPixels(self.raidGroupCheckboxes[1].layoutValues.width)
		local groupCheckboxHeightPx = addon.Utilities:ToPixels(self.raidGroupCheckboxes[1].layoutValues.height)
		local groupSubColumnGapPx = addon.Utilities:ToPixels(14)
		local groupTopGapPx = addon.Utilities:ToPixels(16)
		local groupRowGapPx = addon.Utilities:ToPixels(8)
		local firstGroupRowOffsetPx = thirdRowOffsetPx + orientationControlHeightPx + groupTopGapPx
		local secondGroupRowOffsetPx = firstGroupRowOffsetPx + groupCheckboxHeightPx + groupRowGapPx
		local isRaidMode = addon.Options.State:GetMode() == "raid"

		self.header:SetHeight(addon.Utilities:ToUI(headerHeightPx))

		self.body:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))
		self.body:SetPoint("TOPRIGHT", self.header, "BOTTOMRIGHT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.testModeButton:ClearAllPoints()
		controls.testModeButton:SetPoint(
			"RIGHT",
			controls.modeToggle,
			"LEFT",
			-addon.Utilities:ToUI(headerControlGapPx),
			0
		)

		controls.horizontalPositionSlider:ClearAllPoints()
		controls.horizontalPositionSlider:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, 0)

		controls.verticalPositionSlider:ClearAllPoints()
		controls.verticalPositionSlider:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			0
		)

		controls.horizontalSpacingSlider:ClearAllPoints()
		controls.horizontalSpacingSlider:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -addon.Utilities:ToUI(rowStepPx))

		controls.verticalSpacingSlider:ClearAllPoints()
		controls.verticalSpacingSlider:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(rowStepPx)
		)

		controls.orientationDropdown:ClearAllPoints()
		controls.orientationDropdown:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(thirdRowOffsetPx)
		)

		controls.reverseGroupOrderCheckbox:ClearAllPoints()
		controls.reverseGroupOrderCheckbox:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(thirdRowOffsetPx + reverseCheckboxOffsetPx)
		)

		if isRaidMode then
			controls.reverseGroupOrderCheckbox:Show()
		else
			controls.reverseGroupOrderCheckbox:Hide()
		end

		for groupIndex, checkbox in ipairs(self.raidGroupCheckboxes) do
			local rowIndex = math.floor((groupIndex - 1) / 4)
			local rowColumnIndex = (groupIndex - 1) % 4
			local columnIndex = math.floor(rowColumnIndex / 2)
			local subColumnIndex = rowColumnIndex % 2
			local columnStartXPx = columnIndex == 0 and 0 or threeColumnSecondOffsetPx
			local offsetXPx = columnStartXPx + (subColumnIndex * (groupCheckboxWidthPx + groupSubColumnGapPx))
			local offsetYPx = rowIndex == 0 and firstGroupRowOffsetPx or secondGroupRowOffsetPx

			checkbox:ClearAllPoints()
			checkbox:SetPoint(
				"TOPLEFT",
				self.body,
				"TOPLEFT",
				addon.Utilities:ToUI(offsetXPx),
				-addon.Utilities:ToUI(offsetYPx)
			)

			if isRaidMode then
				checkbox:Show()
			else
				checkbox:Hide()
			end
		end
	end

	function page:UpdateState(profile)
		if not profile then
			return
		end

		local controls = self.controls

		local mode = addon.Options.State:GetMode()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults(mode)
		local position = section.position or {}
		local spacing = section.spacing or {}
		local direction = section.direction or defaults.direction
		local raidSection = profile.raid or {}
		local raidDefaults = GetModeDefaults("raid")
		local raidGroups = raidSection.groups or {}

		controls.modeToggle:SetValue(mode)
		controls.testModeButton:SetText(GetTestModeButtonText())
		controls.horizontalPositionSlider:SetValueSilently(position.x or defaults.positionX)
		controls.verticalPositionSlider:SetValueSilently(position.y or defaults.positionY)
		controls.horizontalSpacingSlider:SetValueSilently(spacing.x or defaults.spacingX)
		controls.verticalSpacingSlider:SetValueSilently(spacing.y or defaults.spacingY)
		controls.orientationDropdown:SetValue(direction)
		controls.reverseGroupOrderCheckbox:SetChecked(raidSection.reverse == true)

		for groupIndex, checkbox in ipairs(self.raidGroupCheckboxes) do
			local isEnabled = raidGroups[groupIndex]
			if isEnabled == nil then
				isEnabled = raidDefaults.groups[groupIndex]
			end

			checkbox:SetChecked(isEnabled == true)
		end
	end

	addon.Options.Data:RegisterForUpdates(page, function(profile)
		page:UpdateState(profile)
	end)

	page:UpdateLocale()
	page:UpdateLayout()
	page:UpdateState(addon.Database:GetProfile())

	return page
end
