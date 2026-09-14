local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Texts = addon.Options.Pages.Texts or {}
addon.Options.Pages.Texts.Health = addon.Options.Pages.Texts.Health or {}

local Health = addon.Options.Pages.Texts.Health

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
	{ value = "class", textKey = "Class Color" },
}

local healthFormatOptions = {
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

function Health:Create(page)
	local subpage = page:RegisterSubPage("healthText", { titleKey = "Health" })

	local checkboxRow = subpage:CreateRow(4)
	checkboxRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local checkboxSlot = checkboxRow:CreateCheckboxSlot("top")

	local enabledCheckbox = checkboxSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	local fontRow = subpage:CreateRow(4)
	fontRow:SetLayoutPoint("TOPLEFT", checkboxRow.frame, "BOTTOMLEFT", 0, 0)

	local fontDropdown = fontRow:CreateControl("Dropdown", { labelKey = "Font" })
	fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions(nil, true))
	fontDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.lsmFont
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.lsmFont = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	local outlineDropdown = fontRow:CreateControl("Dropdown", { labelKey = "Style" })
	outlineDropdown:SetOptions(outlineOptions)
	outlineDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.outline
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.outline = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	local sizeSlider = fontRow:CreateControl("Slider", { labelKey = "Font Size" })
	sizeSlider:SetMinMaxValues(6, 32)
	sizeSlider:SetStep(1)
	sizeSlider:SetValueFormatter(FormatInteger)
	sizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.size
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.size = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	local positionRow = subpage:CreateRow(4)
	positionRow:SetLayoutPoint("TOPLEFT", fontRow.frame, "BOTTOMLEFT", 0, -16)

	local anchorDropdown = positionRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	local offsetXSlider = positionRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-100, 100)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.position.x
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.position.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	local offsetYSlider = positionRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-100, 100)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.position.y
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.position.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	local colorRow = subpage:CreateRow(4)
	colorRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -16)

	local colorStyleDropdown = colorRow:CreateControl("Dropdown", { labelKey = "Color Style" })
	colorStyleDropdown:SetOptions(colorStyleOptions)
	colorStyleDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.classColor and "class" or "static"
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.classColor = value == "class"
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	local colorPicker = colorRow:CreateControl("ColorPicker", { labelKey = "Color" })
	colorPicker:SetHasOpacity(false)
	colorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.color
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	local formatRow = subpage:CreateRow(4)
	formatRow:SetLayoutPoint("TOPLEFT", colorRow.frame, "BOTTOMLEFT", 0, -16)

	local formatDropdown = formatRow:CreateControl("Dropdown", { labelKey = "Health Format" })
	formatDropdown:SetOptions(healthFormatOptions)
	formatDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.healthText.format
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.healthText.format = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthTextSettingsChanged")
		end,
	})

	subpage:SetStateUpdater(function(profile, mode)
		local settings = profile[mode].widgets.texts.healthText
		fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions(settings.lsmFont, true))
	end)

	return subpage
end
