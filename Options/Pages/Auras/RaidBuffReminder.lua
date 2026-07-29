local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.RaidBuffReminder = addon.Options.Pages.Auras.RaidBuffReminder or {}

local RaidBuffReminder = addon.Options.Pages.Auras.RaidBuffReminder

local anchorOptions = {
	{ value = "TOPLEFT", textKey = "Top Left" },
	{ value = "TOP", textKey = "Top" },
	{ value = "TOPRIGHT", textKey = "Top Right" },
	{ value = "LEFT", textKey = "Left" },
	{ value = "CENTER", textKey = "Center" },
	{ value = "RIGHT", textKey = "Right" },
	{ value = "BOTTOMLEFT", textKey = "Bottom Left" },
	{ value = "BOTTOM", textKey = "Bottom" },
	{ value = "BOTTOMRIGHT", textKey = "Bottom Right" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

function RaidBuffReminder:Create(page)
	local subpage = page:RegisterSubPage("raidBuffReminder", { titleKey = "Raid Buff Reminder" })

	local settingsRow = subpage:CreateRow(2)
	settingsRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local checkboxSlot = settingsRow:CreateCheckboxSlot("top")
	local enabledCheckbox = checkboxSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.raidBuffReminder.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.raidBuffReminder.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidBuffReminderSettingsChanged")
		end,
	})

	local showInCombatCheckbox = checkboxSlot:CreateControl("Checkbox", { labelKey = "Show in Combat" })
	showInCombatCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.raidBuffReminder.showInCombat
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.raidBuffReminder.showInCombat = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidBuffReminderSettingsChanged")
		end,
	})

	local anchorRow = subpage:CreateRow(4)
	anchorRow:SetLayoutPoint("TOPLEFT", settingsRow.frame, "BOTTOMLEFT", 0, -16)

	local anchorDropdown = anchorRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.raidBuffReminder.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.raidBuffReminder.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidBuffReminderSettingsChanged")
		end,
	})

	local offsetXSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-300, 300)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.raidBuffReminder.offsetX
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.raidBuffReminder.offsetX = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidBuffReminderSettingsChanged")
		end,
	})

	local offsetYSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-300, 300)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.raidBuffReminder.offsetY
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.raidBuffReminder.offsetY = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidBuffReminderSettingsChanged")
		end,
	})

	local iconRow = subpage:CreateRow(4)
	iconRow:SetLayoutPoint("TOPLEFT", anchorRow.frame, "BOTTOMLEFT", 0, -16)

	local iconSizeSlider = iconRow:CreateControl("Slider", { labelKey = "Icon Size" })
	iconSizeSlider:SetMinMaxValues(8, 128)
	iconSizeSlider:SetStep(1)
	iconSizeSlider:SetValueFormatter(FormatInteger)
	iconSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.raidBuffReminder.iconSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.raidBuffReminder.iconSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidBuffReminderSettingsChanged")
		end,
	})

	local borderRow = subpage:CreateRow(4)
	borderRow:SetLayoutPoint("TOPLEFT", iconRow.frame, "BOTTOMLEFT", 0, -16)

	local borderSizeSlider = borderRow:CreateControl("Slider", { labelKey = "Border Size" })
	borderSizeSlider:SetMinMaxValues(0, 6)
	borderSizeSlider:SetStep(1)
	borderSizeSlider:SetValueFormatter(FormatInteger)
	borderSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.raidBuffReminder.borderSizePx
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.raidBuffReminder.borderSizePx = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidBuffReminderSettingsChanged")
		end,
	})

	local borderColorPicker = borderRow:CreateControl("ColorPicker", { labelKey = "Border Color" })
	borderColorPicker:SetHasOpacity(false)
	borderColorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.raidBuffReminder.borderColor
		end,
		set = function(profile, mode, value)
			value.a = 1
			profile[mode].widgets.icons.raidBuffReminder.borderColor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidBuffReminderSettingsChanged")
		end,
	})

	return subpage
end
