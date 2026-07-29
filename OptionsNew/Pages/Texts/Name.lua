local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Texts = addon.OptionsNew.Pages.Texts or {}
addon.OptionsNew.Pages.Texts.Name = addon.OptionsNew.Pages.Texts.Name or {}

local Name = addon.OptionsNew.Pages.Texts.Name

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

local outlineOptions = {
	{ value = "", textKey = "None" },
	{ value = "OUTLINE", textKey = "Outline" },
	{ value = "THICKOUTLINE", textKey = "Thick Outline" },
	{ value = "MONOCHROME", textKey = "Monochrome" },
}

local colorModeOptions = {
	{ value = true, textKey = "Class Color" },
	{ value = false, textKey = "Static" },
}

local truncateOptions = {
	{ value = true, textKey = "Truncated" },
	{ value = false, textKey = "Full Name" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

function Name:Create(page)
	local subpage = page:RegisterSubPage("name", { titleKey = "Name" })

	local fontRow = subpage:CreateRow(4)
	fontRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local sizeSlider = fontRow:CreateControl("Slider", { labelKey = "Font Size" })
	sizeSlider:SetMinMaxValues(6, 32)
	sizeSlider:SetStep(1)
	sizeSlider:SetValueFormatter(FormatInteger)
	sizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.name.size
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.name.size = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

	local positionRow = subpage:CreateRow(4)
	positionRow:SetLayoutPoint("TOPLEFT", fontRow.frame, "BOTTOMLEFT", 0, -16)

	local anchorDropdown = positionRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.name.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.name.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

	local offsetXSlider = positionRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-100, 100)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.name.position.x
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.name.position.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

	local offsetYSlider = positionRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-100, 100)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.name.position.y
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.name.position.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

	local styleRow = subpage:CreateRow(4)
	styleRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -16)

	local outlineDropdown = styleRow:CreateControl("Dropdown", { labelKey = "Style" })
	outlineDropdown:SetOptions(outlineOptions)
	outlineDropdown:BindValue({
		get = function(profile, mode)
			return addon.Utilities:NormalizeFontOutline(profile[mode].widgets.texts.name.outline, "")
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.name.outline = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

	local classColorDropdown = styleRow:CreateControl("Dropdown", { labelKey = "Color" })
	classColorDropdown:SetOptions(colorModeOptions)
	classColorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.name.classColor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.name.classColor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

	local colorPicker = styleRow:CreateControl("ColorPicker", { labelKey = "Color" })
	colorPicker:SetHasOpacity(true)
	colorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.name.color
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.name.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

	local truncateRow = subpage:CreateRow(4)
	truncateRow:SetLayoutPoint("TOPLEFT", styleRow.frame, "BOTTOMLEFT", 0, -16)

	local truncateDropdown = truncateRow:CreateControl("Dropdown", { labelKey = "Name Length" })
	truncateDropdown:SetOptions(truncateOptions)
	truncateDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.name.truncate
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.name.truncate = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

	local maxLengthSlider = truncateRow:CreateControl("Slider", { labelKey = "Max Length" })
	maxLengthSlider:SetMinMaxValues(1, 32)
	maxLengthSlider:SetStep(1)
	maxLengthSlider:SetValueFormatter(FormatInteger)
	maxLengthSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.name.maxLength
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.name.maxLength = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

	return subpage
end
