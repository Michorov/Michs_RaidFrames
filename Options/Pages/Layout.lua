local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Layout = addon.Options.Pages.Layout or {}

local Layout = addon.Options.Pages.Layout

local function FormatInteger(value)
	return string.format("%d", value)
end

function Layout:Create(panel, config)
	config = config or {}

	local page = panel:RegisterPage("layout", {
		titleKey = "Layout",
		showHeader = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
		showHeaderButton = true,
		headerButtonText = config.headerButtonText,
		headerButtonCallback = config.headerButtonCallback,
	})
	local subpage = page:RegisterSubPage("layout", { titleKey = "Layout" })

	local positionRow = subpage:CreateRow(3)
	positionRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local horizontalPositionSlider = positionRow:CreateControl("Slider", { labelKey = "Horizontal Position" })
	horizontalPositionSlider:SetMinMaxValues(-2000, 2000)
	horizontalPositionSlider:SetStep(1)
	horizontalPositionSlider:SetValueFormatter(FormatInteger)
	horizontalPositionSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].position.x
		end,
		set = function(profile, mode, value)
			profile[mode].position.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local verticalPositionSlider = positionRow:CreateControl("Slider", { labelKey = "Vertical Position" })
	verticalPositionSlider:SetMinMaxValues(-2000, 2000)
	verticalPositionSlider:SetStep(1)
	verticalPositionSlider:SetValueFormatter(FormatInteger)
	verticalPositionSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].position.y
		end,
		set = function(profile, mode, value)
			profile[mode].position.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local spacingRow = subpage:CreateRow(3)
	spacingRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -8)

	local horizontalSpacingSlider = spacingRow:CreateControl("Slider", { labelKey = "Horizontal Spacing" })
	horizontalSpacingSlider:SetMinMaxValues(-25, 25)
	horizontalSpacingSlider:SetStep(1)
	horizontalSpacingSlider:SetValueFormatter(FormatInteger)
	horizontalSpacingSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].spacing.x
		end,
		set = function(profile, mode, value)
			profile[mode].spacing.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local verticalSpacingSlider = spacingRow:CreateControl("Slider", { labelKey = "Vertical Spacing" })
	verticalSpacingSlider:SetMinMaxValues(-25, 25)
	verticalSpacingSlider:SetStep(1)
	verticalSpacingSlider:SetValueFormatter(FormatInteger)
	verticalSpacingSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].spacing.y
		end,
		set = function(profile, mode, value)
			profile[mode].spacing.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local orientationRow = subpage:CreateRow(3)
	orientationRow:SetLayoutPoint("TOPLEFT", spacingRow.frame, "BOTTOMLEFT", 0, -16)

	local orientationDropdown = orientationRow:CreateControl("Dropdown", { labelKey = "Orientation" })
	orientationDropdown:SetOptions({
		{ value = "HORIZONTAL", textKey = "Horizontal" },
		{ value = "VERTICAL", textKey = "Vertical" },
	})
	orientationDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].direction
		end,
		set = function(profile, mode, value)
			profile[mode].direction = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local reverseSlot = orientationRow:CreateCheckboxSlot()
	local showGroupLabelCheckbox = reverseSlot:CreateControl("Checkbox", { labelKey = "Show Group Label" })
	showGroupLabelCheckbox:BindValue({
		get = function(profile)
			return profile.raid.showGroupLabel
		end,
		set = function(profile, _, value)
			profile.raid.showGroupLabel = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("rosterChanged")
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local reverseGroupOrderCheckbox = reverseSlot:CreateControl("Checkbox", { labelKey = "Reverse Group Order" })
	reverseGroupOrderCheckbox:BindValue({
		get = function(profile)
			return profile.raid.reverse
		end,
		set = function(profile, _, value)
			profile.raid.reverse = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local raidGroupCheckboxes = {}
	for groupIndex = 1, 8 do
		local checkbox = subpage:CreateControl("Checkbox", {
			labelKey = "Group %d",
			labelArgs = { groupIndex },
		})
		local rowIndex = math.floor((groupIndex - 1) / 4)
		local rowColumnIndex = (groupIndex - 1) % 4
		local columnIndex = math.floor(rowColumnIndex / 2)
		local subColumnIndex = rowColumnIndex % 2
		local columnStartX = columnIndex == 0 and 0 or 200
		local offsetX = columnStartX + (subColumnIndex * 100)
		local offsetY = -16 - (rowIndex * 32)

		checkbox:SetLayoutWidth(87)
		checkbox:SetLayoutPoint("TOPLEFT", orientationRow.frame, "BOTTOMLEFT", offsetX, offsetY)
		checkbox:BindValue({
			get = function(profile)
				return profile.raid.groups[groupIndex]
			end,
			set = function(profile, _, value)
				profile.raid.groups[groupIndex] = value
			end,
			onChange = function()
				addon.UpdateScheduler:Notify("layoutChanged")
			end,
		})

		raidGroupCheckboxes[groupIndex] = checkbox
	end

	local npcSettingsRow = subpage:CreateRow(3)
	npcSettingsRow:SetLayoutPoint("TOPLEFT", orientationRow.frame, "BOTTOMLEFT", 0, -96)

	local showNpcFramesDropdown = npcSettingsRow:CreateControl("Dropdown", { labelKey = "Show NPC Frames" })
	showNpcFramesDropdown:SetOptions({
		{ value = true, textKey = "Enabled" },
		{ value = false, textKey = "Disabled" },
	})
	showNpcFramesDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].npcEnabled
		end,
		set = function(profile, mode, value)
			profile[mode].npcEnabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local npcDirectionDropdown = npcSettingsRow:CreateControl("Dropdown", { labelKey = "NPC Frames Direction" })
	npcDirectionDropdown:SetOptions({
		{ value = "HORIZONTAL", textKey = "Horizontal" },
		{ value = "VERTICAL", textKey = "Vertical" },
	})
	npcDirectionDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].npcDirection
		end,
		set = function(profile, mode, value)
			profile[mode].npcDirection = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local npcPositionRow = subpage:CreateRow(3)
	npcPositionRow:SetLayoutPoint("TOPLEFT", npcSettingsRow.frame, "BOTTOMLEFT", 0, -8)

	local npcHorizontalPositionSlider = npcPositionRow:CreateControl("Slider", { labelKey = "NPC Horizontal Position" })
	npcHorizontalPositionSlider:SetMinMaxValues(-2000, 2000)
	npcHorizontalPositionSlider:SetStep(1)
	npcHorizontalPositionSlider:SetValueFormatter(FormatInteger)
	npcHorizontalPositionSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].npcPosition.x
		end,
		set = function(profile, mode, value)
			profile[mode].npcPosition.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local npcVerticalPositionSlider = npcPositionRow:CreateControl("Slider", { labelKey = "NPC Vertical Position" })
	npcVerticalPositionSlider:SetMinMaxValues(-2000, 2000)
	npcVerticalPositionSlider:SetStep(1)
	npcVerticalPositionSlider:SetValueFormatter(FormatInteger)
	npcVerticalPositionSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].npcPosition.y
		end,
		set = function(profile, mode, value)
			profile[mode].npcPosition.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	subpage:SetStateUpdater(function(_, mode)
		local isRaidMode = mode == "raid"

		showGroupLabelCheckbox:SetShown(isRaidMode)
		reverseGroupOrderCheckbox:SetShown(isRaidMode)
		for _, checkbox in ipairs(raidGroupCheckboxes) do
			checkbox:SetShown(isRaidMode)
		end
	end)

	return page
end
