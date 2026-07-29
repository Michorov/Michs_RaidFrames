local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}
addon.Options.Pages.Indicators.RaidMarker = addon.Options.Pages.Indicators.RaidMarker or {}

local RaidMarker = addon.Options.Pages.Indicators.RaidMarker

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

function RaidMarker:Create(page)
	local subpage = page:RegisterSubPage("raidMarker", { titleKey = "Raid Marker" })

	local enabledRow = subpage:CreateRow(4)
	enabledRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local enabledSlot = enabledRow:CreateCheckboxSlot("top")
	local enabledCheckbox = enabledSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.raidMarker.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.raidMarker.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidMarkerSettingsChanged")
		end,
	})

	local anchorRow = subpage:CreateRow(4)
	anchorRow:SetLayoutPoint("TOPLEFT", enabledRow.frame, "BOTTOMLEFT", 0, 0)

	local anchorDropdown = anchorRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.raidMarker.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.raidMarker.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidMarkerSettingsChanged")
		end,
	})

	local offsetXSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-100, 100)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.raidMarker.offsetX
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.raidMarker.offsetX = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidMarkerSettingsChanged")
		end,
	})

	local offsetYSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-100, 100)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.raidMarker.offsetY
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.raidMarker.offsetY = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidMarkerSettingsChanged")
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
			return profile[mode].widgets.indicators.raidMarker.size
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.raidMarker.size = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("raidMarkerSettingsChanged")
		end,
	})

	return subpage
end
