local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Texts = addon.Options.Pages.Texts or {}
addon.Options.Pages.Texts.Away = addon.Options.Pages.Texts.Away or {}

local Away = addon.Options.Pages.Texts.Away

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

local outlineOptions = {
	{ value = "", textKey = "None" },
	{ value = "OUTLINE", textKey = "Outline" },
	{ value = "THICKOUTLINE", textKey = "Thick Outline" },
	{ value = "MONOCHROME", textKey = "Monochrome" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

function Away:Create(page)
	local subpage = page:RegisterSubPage("away", { titleKey = "Away" })

	local enabledRow = subpage:CreateRow(4)
	enabledRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local checkboxSlot = enabledRow:CreateCheckboxSlot("top")

	local enabledCheckbox = checkboxSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.away.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.away.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("awayTextSettingsChanged")
		end,
	})

	local positionRow = subpage:CreateRow(4)
	positionRow:SetLayoutPoint("TOPLEFT", enabledRow.frame, "BOTTOMLEFT", 0, 0)

	local anchorDropdown = positionRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.away.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.away.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("awayTextSettingsChanged")
		end,
	})

	local offsetXSlider = positionRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-100, 100)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.away.position.x
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.away.position.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("awayTextSettingsChanged")
		end,
	})

	local offsetYSlider = positionRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-100, 100)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.away.position.y
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.away.position.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("awayTextSettingsChanged")
		end,
	})

	local sizeRow = subpage:CreateRow(4)
	sizeRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -16)

	local sizeSlider = sizeRow:CreateControl("Slider", { labelKey = "Font Size" })
	sizeSlider:SetMinMaxValues(6, 32)
	sizeSlider:SetStep(1)
	sizeSlider:SetValueFormatter(FormatInteger)
	sizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.away.size
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.away.size = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("awayTextSettingsChanged")
		end,
	})

	local styleRow = subpage:CreateRow(4)
	styleRow:SetLayoutPoint("TOPLEFT", sizeRow.frame, "BOTTOMLEFT", 0, -16)

	local outlineDropdown = styleRow:CreateControl("Dropdown", { labelKey = "Style" })
	outlineDropdown:SetOptions(outlineOptions)
	outlineDropdown:BindValue({
		get = function(profile, mode)
			return addon.Utilities:NormalizeFontOutline(profile[mode].widgets.texts.away.outline, "")
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.away.outline = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("awayTextSettingsChanged")
		end,
	})

	local colorPicker = styleRow:CreateControl("ColorPicker", { labelKey = "Color" })
	colorPicker:SetHasOpacity(false)
	colorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.away.color
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.away.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("awayTextSettingsChanged")
		end,
	})

	return subpage
end
