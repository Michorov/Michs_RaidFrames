local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}
addon.Options.Pages.Indicators.GroupStatus = addon.Options.Pages.Indicators.GroupStatus or {}

local GroupStatus = addon.Options.Pages.Indicators.GroupStatus

local anchorOptions = {
	{ value = "TOPLEFT", textKey = "Top Left" },
	{ value = "TOP", textKey = "Top Center" },
	{ value = "TOPRIGHT", textKey = "Top Right" },
	{ value = "LEFT", textKey = "Left" },
	{ value = "CENTER", textKey = "Center" },
	{ value = "RIGHT", textKey = "Right" },
	{ value = "BOTTOMLEFT", textKey = "Bottom Left" },
	{ value = "BOTTOM", textKey = "Bottom Center" },
	{ value = "BOTTOMRIGHT", textKey = "Bottom Right" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

function GroupStatus:Create(page)
	local subpage = page:RegisterSubPage("groupStatus", { titleKey = "Group Leader" })

	local enabledRow = subpage:CreateRow(4)
	enabledRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local enabledSlot = enabledRow:CreateCheckboxSlot()
	local enabledCheckbox = enabledSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.groupStatus.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.groupStatus.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("groupStatusSettingsChanged")
		end,
	})

	local leaderCheckbox = enabledSlot:CreateControl("Checkbox", { labelKey = "Leader" })
	leaderCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.groupStatus.showLeader
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.groupStatus.showLeader = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("groupStatusSettingsChanged")
		end,
	})

	local assistantSlot = enabledRow:CreateCheckboxSlot("bottom")
	local assistantCheckbox = assistantSlot:CreateControl("Checkbox", { labelKey = "Assistant" })
	assistantCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.groupStatus.showAssistant
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.groupStatus.showAssistant = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("groupStatusSettingsChanged")
		end,
	})

	local anchorRow = subpage:CreateRow(4)
	anchorRow:SetLayoutPoint("TOPLEFT", enabledRow.frame, "BOTTOMLEFT", 0, -24)

	local anchorDropdown = anchorRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.groupStatus.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.groupStatus.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("groupStatusSettingsChanged")
		end,
	})

	local offsetXSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-100, 100)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.groupStatus.offsetX
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.groupStatus.offsetX = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("groupStatusSettingsChanged")
		end,
	})

	local offsetYSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-100, 100)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.groupStatus.offsetY
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.groupStatus.offsetY = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("groupStatusSettingsChanged")
		end,
	})

	local sizeRow = subpage:CreateRow(4)
	sizeRow:SetLayoutPoint("TOPLEFT", anchorRow.frame, "BOTTOMLEFT", 0, -16)

	local sizeSlider = sizeRow:CreateControl("Slider", { labelKey = "Size" })
	sizeSlider:SetMinMaxValues(8, 64)
	sizeSlider:SetStep(1)
	sizeSlider:SetValueFormatter(FormatInteger)
	sizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.groupStatus.size
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.groupStatus.size = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("groupStatusSettingsChanged")
		end,
	})

	return subpage
end
