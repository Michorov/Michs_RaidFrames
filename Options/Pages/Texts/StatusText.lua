local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Texts = addon.Options.Pages.Texts or {}
addon.Options.Pages.Texts.StatusText = addon.Options.Pages.Texts.StatusText or {}

local StatusText = addon.Options.Pages.Texts.StatusText

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

function StatusText:Create(page)
	local subpage = page:RegisterSubPage("statusText", { titleKey = "Status" })

	local positionRow = subpage:CreateRow(4)
	positionRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local anchorDropdown = positionRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.statusText.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.statusText.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("statusTextSettingsChanged")
		end,
	})

	local offsetXSlider = positionRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-100, 100)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.statusText.position.x
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.statusText.position.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("statusTextSettingsChanged")
		end,
	})

	local offsetYSlider = positionRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-100, 100)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.statusText.position.y
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.statusText.position.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("statusTextSettingsChanged")
		end,
	})

	local fontRow = subpage:CreateRow(4)
	fontRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -16)

	local fontDropdown = fontRow:CreateControl("Dropdown", { labelKey = "Font" })
	fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions(nil, true))
	fontDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.statusText.lsmFont
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.statusText.lsmFont = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("statusTextSettingsChanged")
		end,
	})

	local sizeSlider = fontRow:CreateControl("Slider", { labelKey = "Font Size" })
	sizeSlider:SetMinMaxValues(6, 32)
	sizeSlider:SetStep(1)
	sizeSlider:SetValueFormatter(FormatInteger)
	sizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.statusText.size
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.statusText.size = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("statusTextSettingsChanged")
		end,
	})

	local styleRow = subpage:CreateRow(4)
	styleRow:SetLayoutPoint("TOPLEFT", fontRow.frame, "BOTTOMLEFT", 0, -16)

	local outlineDropdown = styleRow:CreateControl("Dropdown", { labelKey = "Style" })
	outlineDropdown:SetOptions(outlineOptions)
	outlineDropdown:BindValue({
		get = function(profile, mode)
			return addon.Utilities:NormalizeFontOutline(profile[mode].widgets.texts.statusText.outline, "")
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.statusText.outline = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("statusTextSettingsChanged")
		end,
	})

	local colorPicker = styleRow:CreateControl("ColorPicker", { labelKey = "Color" })
	colorPicker:SetHasOpacity(false)
	colorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.statusText.color
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.statusText.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("statusTextSettingsChanged")
		end,
	})

	subpage:SetStateUpdater(function(profile, mode)
		local settings = profile[mode].widgets.texts.statusText
		fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions(settings.lsmFont, true))
	end)

	return subpage
end
