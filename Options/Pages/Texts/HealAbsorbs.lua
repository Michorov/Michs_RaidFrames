local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Texts = addon.Options.Pages.Texts or {}
addon.Options.Pages.Texts.HealAbsorbs = addon.Options.Pages.Texts.HealAbsorbs or {}

local HealAbsorbs = addon.Options.Pages.Texts.HealAbsorbs

local subpage

local anchorOptions = {
	{ value = "TOPLEFT", text = "Top Left" },
	{ value = "TOP", text = "Top" },
	{ value = "TOPRIGHT", text = "Top Right" },
	{ value = "LEFT", text = "Left" },
	{ value = "CENTER", text = "Center" },
	{ value = "RIGHT", text = "Right" },
	{ value = "BOTTOMLEFT", text = "Bottom Left" },
	{ value = "BOTTOM", text = "Bottom" },
	{ value = "BOTTOMRIGHT", text = "Bottom Right" },
}

local outlineOptions = {
	{ value = "", text = "None" },
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

local function GetModeDefaults()
	return {
		enabled = false,
		abbreviate = true,
		anchor = "CENTER",
		offsetX = 0,
		offsetY = 0,
		size = 10,
		outline = "OUTLINE",
		color = { r = 1, g = 1, b = 1, a = 1 },
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r Heal Absorbs text settings are disabled during combat.")
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

function HealAbsorbs:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Enabled")
	subpage.enabledCheckbox:SetLayoutWidth(174)
	subpage.enabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.healAbsorbs = section.widgets.texts.healAbsorbs or {}
			section.widgets.texts.healAbsorbs.enabled = checked == true
		end, "healAbsorbsTextSettingsChanged")
	end)

	subpage.abbreviateCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Abbreviate Numbers")
	subpage.abbreviateCheckbox:SetLayoutWidth(174)
	subpage.abbreviateCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.healAbsorbs = section.widgets.texts.healAbsorbs or {}
			section.widgets.texts.healAbsorbs.abbreviate = checked == true
		end, "healAbsorbsTextSettingsChanged")
	end)

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Anchor")
	subpage.anchorDropdown:SetLayoutWidth(174)
	subpage.anchorDropdown:SetOptions(anchorOptions)
	subpage.anchorDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.healAbsorbs = section.widgets.texts.healAbsorbs or {}
			section.widgets.texts.healAbsorbs.anchor = value
		end, "healAbsorbsTextSettingsChanged")
	end)

	subpage.sizeSlider = addon.Options.Controls.Slider:Create(subpage, "Font Size")
	subpage.sizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.sizeSlider, 6, 32, 1)
	subpage.sizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.healAbsorbs = section.widgets.texts.healAbsorbs or {}
			section.widgets.texts.healAbsorbs.size = value
		end, "healAbsorbsTextSettingsChanged")
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, "Offset X")
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -100, 100, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.healAbsorbs = section.widgets.texts.healAbsorbs or {}
			section.widgets.texts.healAbsorbs.position = section.widgets.texts.healAbsorbs.position or {}
			section.widgets.texts.healAbsorbs.position.x = value
		end, "healAbsorbsTextSettingsChanged")
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, "Offset Y")
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -100, 100, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.healAbsorbs = section.widgets.texts.healAbsorbs or {}
			section.widgets.texts.healAbsorbs.position = section.widgets.texts.healAbsorbs.position or {}
			section.widgets.texts.healAbsorbs.position.y = value
		end, "healAbsorbsTextSettingsChanged")
	end)

	subpage.outlineDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Style")
	subpage.outlineDropdown:SetLayoutWidth(174)
	subpage.outlineDropdown:SetOptions(outlineOptions)
	subpage.outlineDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.healAbsorbs = section.widgets.texts.healAbsorbs or {}
			section.widgets.texts.healAbsorbs.outline = value
		end, "healAbsorbsTextSettingsChanged")
	end)

	subpage.colorPicker = addon.Options.Controls.ColorPicker:Create(subpage, "Color")
	subpage.colorPicker:SetLayoutWidth(174)
	subpage.colorPicker:SetHasOpacity(false)
	subpage.colorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.healAbsorbs = section.widgets.texts.healAbsorbs or {}
			section.widgets.texts.healAbsorbs.color = { r = r, g = g, b = b, a = a }
		end, "healAbsorbsTextSettingsChanged")
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		abbreviateCheckbox = subpage.abbreviateCheckbox,
		anchorDropdown = subpage.anchorDropdown,
		sizeSlider = subpage.sizeSlider,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		outlineDropdown = subpage.outlineDropdown,
		colorPicker = subpage.colorPicker,
	}

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(50)
		local anchorRowGapPx = addon.Utilities:ToPixels(8)
		local sectionGapPx = addon.Utilities:ToPixels(16)
		local thirdRowOffsetPx = (rowStepPx * 2) + anchorRowGapPx
		local fourthRowOffsetPx = thirdRowOffsetPx + rowStepPx + sectionGapPx
		local columnGapPx = addon.Utilities:ToPixels(30)
		local threeColumnSlotWidthPx = addon.Utilities:ToPixels(174)
		local threeColumnSecondOffsetPx = threeColumnSlotWidthPx + columnGapPx
		local sliderHeightPx = addon.Utilities:ToPixels(34)
		local checkboxHeightPx = addon.Utilities:ToPixels(controls.enabledCheckbox.layoutValues.height)
		local checkboxOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - checkboxHeightPx) / 2))
		local colorPickerSizePx = addon.Utilities:ToPixels(controls.colorPicker.layoutValues.pickerSize)
		local dropdownFieldTopOffsetPx =
			addon.Utilities:ToPixels(
				controls.outlineDropdown.layoutValues.labelHeight + controls.outlineDropdown.layoutValues.labelSpacing
			)
		local dropdownFieldHeightPx = addon.Utilities:ToPixels(controls.outlineDropdown.layoutValues.fieldHeight)
		local colorPickerOffsetPx = dropdownFieldTopOffsetPx
			+ addon.Utilities:RoundToNearestInt(math.max(0, (dropdownFieldHeightPx - colorPickerSizePx) / 2))

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.enabledCheckbox:ClearAllPoints()
		controls.enabledCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(checkboxOffsetPx)
		)

		controls.abbreviateCheckbox:ClearAllPoints()
		controls.abbreviateCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(checkboxOffsetPx)
		)

		controls.anchorDropdown:ClearAllPoints()
		controls.anchorDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(rowStepPx)
		)

		controls.sizeSlider:ClearAllPoints()
		controls.sizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(rowStepPx)
		)

		controls.offsetXSlider:ClearAllPoints()
		controls.offsetXSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(thirdRowOffsetPx)
		)

		controls.offsetYSlider:ClearAllPoints()
		controls.offsetYSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(thirdRowOffsetPx)
		)

		controls.outlineDropdown:ClearAllPoints()
		controls.outlineDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(fourthRowOffsetPx)
		)

		controls.colorPicker:ClearAllPoints()
		controls.colorPicker:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(fourthRowOffsetPx + colorPickerOffsetPx)
		)
	end

	function subpage:UpdateState(profile)
		if not profile then
			return
		end

		local controls = self.controls
		local mode = GetModeKey()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults()
		local texts = (section.widgets or {}).texts or {}
		local healAbsorbs = texts.healAbsorbs or {}
		local position = healAbsorbs.position or {}
		local color = healAbsorbs.color or defaults.color

		local enabled = healAbsorbs.enabled
		if enabled == nil then
			enabled = defaults.enabled
		end

		local abbreviate = healAbsorbs.abbreviate
		if abbreviate == nil then
			abbreviate = defaults.abbreviate
		end

		controls.enabledCheckbox:SetChecked(enabled == true)
		controls.abbreviateCheckbox:SetChecked(abbreviate == true)
		controls.anchorDropdown:SetOptions(anchorOptions)
		controls.anchorDropdown:SetValue(healAbsorbs.anchor or defaults.anchor)
		controls.sizeSlider:SetValueSilently(healAbsorbs.size or defaults.size)
		controls.offsetXSlider:SetValueSilently(position.x or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(position.y or defaults.offsetY)
		local outline = addon.Utilities:NormalizeFontOutline(healAbsorbs.outline, defaults.outline)
		controls.outlineDropdown:SetOptions(outlineOptions)
		controls.outlineDropdown:SetValue(outline)
		controls.colorPicker:SetColor(color.r, color.g, color.b, color.a)
	end

	return subpage
end
