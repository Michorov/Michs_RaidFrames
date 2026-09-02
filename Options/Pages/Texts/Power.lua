local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Texts = addon.Options.Pages.Texts or {}
addon.Options.Pages.Texts.Power = addon.Options.Pages.Texts.Power or {}

local Power = addon.Options.Pages.Texts.Power

local anchorOptions = {
	{ value = "TOPLEFT", textKey = "Top Left" },
	{ value = "TOP", textKey = "Top" },
	{ value = "TOPRIGHT", textKey = "Top Right" },
	{ value = "RIGHT", textKey = "Right" },
	{ value = "BOTTOMRIGHT", textKey = "Bottom Right" },
	{ value = "BOTTOM", textKey = "Bottom" },
	{ value = "BOTTOMLEFT", textKey = "Bottom Left" },
	{ value = "LEFT", textKey = "Left" },
	{ value = "CENTER", textKey = "Center" },
}

local outlineOptions = {
	{ value = "", textKey = "None" },
	{ value = "OUTLINE", textKey = "Outline" },
	{ value = "THICKOUTLINE", textKey = "Thick Outline" },
	{ value = "MONOCHROME", textKey = "Monochrome" },
}

local colorStyleOptions = {
	{ value = "static", textKey = "Static" },
	{ value = "powerType", textKey = "Power Type" },
}

local powerFormatOptions = {
	{ value = "abbreviated", text = "100k" },
	{ value = "percent", text = "100%" },
	{ value = "full", text = "100,000" },
	{ value = "abbreviatedPercent", text = "100k | 100%" },
	{ value = "percentAbbreviated", text = "100% | 100k" },
	{ value = "fullPercent", text = "100,000 | 100%" },
	{ value = "percentFull", text = "100% | 100,000" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

function Power:Create(page)
	local subpage = page:RegisterSubPage("powerText", { titleKey = "Power" })

	local checkboxRow = subpage:CreateRow(2)
	checkboxRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local checkboxSlot = checkboxRow:CreateCheckboxSlot()

	local enabledCheckbox = checkboxSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local healerOnlyCheckbox = checkboxSlot:CreateControl("Checkbox", { labelKey = "Healers Only" })
	healerOnlyCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.healerOnly
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.healerOnly = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local fontRow = subpage:CreateRow(4)
	fontRow:SetLayoutPoint("TOPLEFT", checkboxRow.frame, "BOTTOMLEFT", 0, -16)

	local fontDropdown = fontRow:CreateControl("Dropdown", { labelKey = "Font" })
	fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions(nil, true))
	fontDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.lsmFont
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.lsmFont = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local outlineDropdown = fontRow:CreateControl("Dropdown", { labelKey = "Style" })
	outlineDropdown:SetOptions(outlineOptions)
	outlineDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.outline
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.outline = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local sizeSlider = fontRow:CreateControl("Slider", { labelKey = "Font Size" })
	sizeSlider:SetMinMaxValues(6, 32)
	sizeSlider:SetStep(1)
	sizeSlider:SetValueFormatter(FormatInteger)
	sizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.size
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.size = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local positionRow = subpage:CreateRow(4)
	positionRow:SetLayoutPoint("TOPLEFT", fontRow.frame, "BOTTOMLEFT", 0, -16)

	local anchorDropdown = positionRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local offsetXSlider = positionRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-100, 100)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.position.x
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.position.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local offsetYSlider = positionRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-100, 100)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.position.y
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.position.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local colorRow = subpage:CreateRow(4)
	colorRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -16)

	local colorStyleDropdown = colorRow:CreateControl("Dropdown", { labelKey = "Color Style" })
	colorStyleDropdown:SetOptions(colorStyleOptions)
	colorStyleDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.colorByPowerType and "powerType" or "static"
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.colorByPowerType = value == "powerType"
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local colorPicker = colorRow:CreateControl("ColorPicker", { labelKey = "Color" })
	colorPicker:SetHasOpacity(false)
	colorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.color
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	local formatRow = subpage:CreateRow(4)
	formatRow:SetLayoutPoint("TOPLEFT", colorRow.frame, "BOTTOMLEFT", 0, -16)

	local formatDropdown = formatRow:CreateControl("Dropdown", { labelKey = "Power Format" })
	formatDropdown:SetOptions(powerFormatOptions)
	formatDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.powerText.format
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.powerText.format = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerTextSettingsChanged")
		end,
	})

	subpage:SetStateUpdater(function(profile, mode)
		local settings = profile[mode].widgets.texts.powerText
		fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions(settings.lsmFont, true))
	end)

	return subpage
end
