local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Texts = addon.Options.Pages.Texts or {}
addon.Options.Pages.Texts.Name = addon.Options.Pages.Texts.Name or {}

local Name = addon.Options.Pages.Texts.Name
local subpage

local anchorOptions = {
	{ value = "TOPLEFT", text = "Top Left" },
	{ value = "TOP", text = "Top Center" },
	{ value = "TOPRIGHT", text = "Top Right" },
	{ value = "LEFT", text = "Left" },
	{ value = "CENTER", text = "Center" },
	{ value = "RIGHT", text = "Right" },
	{ value = "BOTTOMLEFT", text = "Bottom Left" },
	{ value = "BOTTOM", text = "Bottom Center" },
	{ value = "BOTTOMRIGHT", text = "Bottom Right" },
}

local outlineOptions = {
	{ value = "NONE", text = "None" },
	{ value = "OUTLINE", text = "Outline" },
	{ value = "THICKOUTLINE", text = "Thick Outline" },
	{ value = "MONOCHROME", text = "Monochrome" },
}

local function GetControllerState()
	local content = addon.Options.Sections.Content
	if content and content.GetControllerState then
		return content:GetControllerState()
	end

	addon.Options.ControllerState = addon.Options.ControllerState
		or {
			mode = "party",
			subpages = {
				auras = "buffs",
				texts = "name",
				indicators = "readyCheck",
				bars = "health",
			},
		}

	return addon.Options.ControllerState
end

local function GetModeKey()
	local state = GetControllerState()
	return state.mode == "raid" and "raid" or "party"
end

local function GetModeDefaults(mode)
	if mode == "raid" then
		return {
			anchor = "TOPLEFT",
			size = 10,
			offsetX = 2,
			offsetY = -2,
			classColor = false,
			color = { r = 0, g = 0, b = 0, a = 1 },
			outline = "NONE",
			truncate = false,
			maxLength = 12,
		}
	end

	return {
		anchor = "TOPLEFT",
		size = 12,
		offsetX = 2,
		offsetY = -2,
		classColor = false,
		color = { r = 0, g = 0, b = 0, a = 1 },
		outline = "NONE",
		truncate = false,
		maxLength = 12,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r Name text settings are disabled during combat.")
end

local function ApplyModeSetting(updateFn, notifyEvent)
	if InCombatLockdown() then
		ShowCombatLockMessage()
		if subpage and subpage.UpdateState then
			subpage:UpdateState(addon.Database:GetProfile())
		end
		return
	end

	local profile = addon.Database:GetProfile()
	local mode = GetModeKey()

	profile[mode] = profile[mode] or {}
	updateFn(profile[mode], mode)

	addon.UpdateScheduler:Notify(notifyEvent)
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

function Name:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Anchor")
	subpage.anchorDropdown:SetLayoutWidth(174)
	subpage.anchorDropdown:SetOptions(anchorOptions)
	subpage.anchorDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.anchor = value
		end, "nameSettingsChanged")
	end)

	subpage.sizeSlider = addon.Options.Controls.Slider:Create(subpage, "Font Size")
	subpage.sizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.sizeSlider, 6, 32, 1)
	subpage.sizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.size = value
		end, "nameSettingsChanged")
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, "Offset X")
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -100, 100, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.position = section.widgets.texts.name.position or {}
			section.widgets.texts.name.position.x = value
		end, "nameSettingsChanged")
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, "Offset Y")
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -100, 100, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.position = section.widgets.texts.name.position or {}
			section.widgets.texts.name.position.y = value
		end, "nameSettingsChanged")
	end)

	subpage.classColorCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Use Class Color")
	subpage.classColorCheckbox:SetLayoutWidth(174)
	subpage.classColorCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.classColor = checked == true
		end, "nameSettingsChanged")
	end)

	subpage.colorPicker = addon.Options.Controls.ColorPicker:Create(subpage, "Color")
	subpage.colorPicker:SetLayoutWidth(174)
	subpage.colorPicker:SetHasOpacity(true)
	subpage.colorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.color = { r = r, g = g, b = b, a = a }
		end, "nameSettingsChanged")
	end)

	subpage.outlineDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Style")
	subpage.outlineDropdown:SetLayoutWidth(174)
	subpage.outlineDropdown:SetOptions(outlineOptions)
	subpage.outlineDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.outline = value
		end, "nameSettingsChanged")
	end)

	subpage.truncateCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Truncate")
	subpage.truncateCheckbox:SetLayoutWidth(174)
	subpage.truncateCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.truncate = checked == true
		end, "nameSettingsChanged")
	end)

	subpage.maxLengthSlider = addon.Options.Controls.Slider:Create(subpage, "Max Length")
	subpage.maxLengthSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.maxLengthSlider, 1, 32, 1)
	subpage.maxLengthSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.maxLength = value
		end, "nameSettingsChanged")
	end)

	subpage.controls = {
		anchorDropdown = subpage.anchorDropdown,
		sizeSlider = subpage.sizeSlider,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		classColorCheckbox = subpage.classColorCheckbox,
		colorPicker = subpage.colorPicker,
		outlineDropdown = subpage.outlineDropdown,
		truncateCheckbox = subpage.truncateCheckbox,
		maxLengthSlider = subpage.maxLengthSlider,
	}

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(50)
		local firstSectionRowGapPx = addon.Utilities:ToPixels(8)
		local sectionGapPx = addon.Utilities:ToPixels(16)
		local columnGapPx = addon.Utilities:ToPixels(30)
		local columnWidthPx = addon.Utilities:ToPixels(174)
		local secondColumnOffsetPx = columnWidthPx + columnGapPx
		local thirdColumnOffsetPx = (columnWidthPx * 2) + (columnGapPx * 2)
		local dropdownSliderOffsetPx = addon.Utilities:ToPixels(5)
		local sliderHeightPx = addon.Utilities:ToPixels(34)
		local colorPickerSizePx = addon.Utilities:ToPixels(controls.colorPicker.layoutValues.pickerSize)
		local checkboxHeightPx = addon.Utilities:ToPixels(controls.classColorCheckbox.layoutValues.height)
		local dropdownFieldTopOffsetPx =
			addon.Utilities:ToPixels(
				controls.outlineDropdown.layoutValues.labelHeight + controls.outlineDropdown.layoutValues.labelSpacing
			)
		local dropdownFieldHeightPx = addon.Utilities:ToPixels(controls.outlineDropdown.layoutValues.fieldHeight)
		local colorPickerOffsetPx = dropdownFieldTopOffsetPx
			+ addon.Utilities:RoundToNearestInt(math.max(0, (dropdownFieldHeightPx - colorPickerSizePx) / 2))
		local checkboxOffsetPx = dropdownFieldTopOffsetPx
			+ addon.Utilities:RoundToNearestInt(math.max(0, (dropdownFieldHeightPx - checkboxHeightPx) / 2))
		local checkboxCenterOffsetPx = checkboxOffsetPx + addon.Utilities:RoundToNearestInt(checkboxHeightPx / 2)
		local maxLengthControlCenterOffsetPx = addon.Utilities:RoundToNearestInt(
			(
				addon.Utilities:ToPixels(controls.maxLengthSlider.layoutValues.topRowHeight)
				+ addon.Utilities:ToPixels(controls.maxLengthSlider.layoutValues.labelSpacing)
				+ addon.Utilities:ToPixels(controls.maxLengthSlider.layoutValues.thumbSize)
			) / 2
		)
		local maxLengthSliderOffsetPx =
			addon.Utilities:RoundToNearestInt(
				math.max(0, checkboxCenterOffsetPx - maxLengthControlCenterOffsetPx)
			)
		local positionControlsOffsetPx = 0
		local positionSecondRowOffsetPx = positionControlsOffsetPx + rowStepPx + firstSectionRowGapPx
		local styleControlsOffsetPx = positionSecondRowOffsetPx + rowStepPx + sectionGapPx
		local truncateControlsOffsetPx = styleControlsOffsetPx + rowStepPx + sectionGapPx
		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.anchorDropdown:ClearAllPoints()
		controls.anchorDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(positionControlsOffsetPx)
		)

		controls.sizeSlider:ClearAllPoints()
		controls.sizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(positionControlsOffsetPx + dropdownSliderOffsetPx)
		)

		controls.offsetXSlider:ClearAllPoints()
		controls.offsetXSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(positionSecondRowOffsetPx)
		)

		controls.offsetYSlider:ClearAllPoints()
		controls.offsetYSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(positionSecondRowOffsetPx)
		)

		controls.outlineDropdown:ClearAllPoints()
		controls.outlineDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(styleControlsOffsetPx)
		)

		controls.colorPicker:ClearAllPoints()
		controls.colorPicker:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(styleControlsOffsetPx + colorPickerOffsetPx)
		)

		controls.classColorCheckbox:ClearAllPoints()
		controls.classColorCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(thirdColumnOffsetPx),
			-addon.Utilities:ToUI(styleControlsOffsetPx + checkboxOffsetPx)
		)

		controls.truncateCheckbox:ClearAllPoints()
		controls.truncateCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(truncateControlsOffsetPx + checkboxOffsetPx)
		)

		controls.maxLengthSlider:ClearAllPoints()
		controls.maxLengthSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(truncateControlsOffsetPx + maxLengthSliderOffsetPx)
		)
	end

	function subpage:UpdateState(profile)
		if not profile then
			return
		end

		local controls = self.controls
		local mode = GetModeKey()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults(mode)
		local texts = (section.widgets or {}).texts or {}
		local name = texts.name or {}
		local position = name.position or {}
		local classColor = name.classColor
		local truncate = name.truncate

		if classColor == nil then
			classColor = defaults.classColor
		end

		if truncate == nil then
			truncate = defaults.truncate
		end

		controls.anchorDropdown:SetOptions(anchorOptions)
		controls.anchorDropdown:SetValue(name.anchor or defaults.anchor)
		controls.sizeSlider:SetValueSilently(name.size or defaults.size)
		controls.offsetXSlider:SetValueSilently(position.x or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(position.y or defaults.offsetY)
		controls.classColorCheckbox:SetChecked(classColor == true)
		controls.colorPicker:SetColor(
			(name.color or defaults.color).r,
			(name.color or defaults.color).g,
			(name.color or defaults.color).b,
			(name.color or defaults.color).a
		)
		controls.outlineDropdown:SetOptions(outlineOptions)
		controls.outlineDropdown:SetValue(name.outline or defaults.outline)
		controls.truncateCheckbox:SetChecked(truncate == true)
		controls.maxLengthSlider:SetValueSilently(name.maxLength or defaults.maxLength)
	end

	return subpage
end
