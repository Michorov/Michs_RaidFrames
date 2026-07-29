local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Indicators = addon.OptionsNew.Pages.Indicators or {}
addon.OptionsNew.Pages.Indicators.RoleIndicator = addon.OptionsNew.Pages.Indicators.RoleIndicator or {}

local RoleIndicator = addon.OptionsNew.Pages.Indicators.RoleIndicator

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

function RoleIndicator:Create(page)
	local subpage = page:RegisterSubPage("roleIcon", { titleKey = "Role Indicator" })

	local enabledRow = subpage:CreateRow(4)
	enabledRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local enabledSlot = enabledRow:CreateCheckboxSlot()
	local enabledCheckbox = enabledSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.roleIcon.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.roleIcon.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("roleIconSettingsChanged")
		end,
	})

	local tankCheckbox = enabledSlot:CreateControl("Checkbox", { labelKey = "Tank" })
	tankCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.roleIcon.showTank
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.roleIcon.showTank = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("roleIconSettingsChanged")
		end,
	})

	local healerSlot = enabledRow:CreateCheckboxSlot("bottom")
	local healerCheckbox = healerSlot:CreateControl("Checkbox", { labelKey = "Healer" })
	healerCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.roleIcon.showHealer
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.roleIcon.showHealer = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("roleIconSettingsChanged")
		end,
	})

	local dpsSlot = enabledRow:CreateCheckboxSlot("bottom")
	local dpsCheckbox = dpsSlot:CreateControl("Checkbox", { labelKey = "DPS" })
	dpsCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.roleIcon.showDps
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.roleIcon.showDps = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("roleIconSettingsChanged")
		end,
	})

	local anchorRow = subpage:CreateRow(4)
	anchorRow:SetLayoutPoint("TOPLEFT", enabledRow.frame, "BOTTOMLEFT", 0, -24)

	local anchorDropdown = anchorRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.roleIcon.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.roleIcon.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("roleIconSettingsChanged")
		end,
	})

	local offsetXSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-100, 100)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.roleIcon.offsetX
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.roleIcon.offsetX = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("roleIconSettingsChanged")
		end,
	})

	local offsetYSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-100, 100)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.roleIcon.offsetY
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.roleIcon.offsetY = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("roleIconSettingsChanged")
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
			return profile[mode].widgets.indicators.roleIcon.size
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.roleIcon.size = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("roleIconSettingsChanged")
		end,
	})

	return subpage
end
