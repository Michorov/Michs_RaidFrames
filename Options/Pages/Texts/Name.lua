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

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Name Anchor")
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

	subpage.sizeSlider = addon.Options.Controls.Slider:Create(subpage, "Name Size")
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

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, "Name Offset X")
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

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, "Name Offset Y")
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

	subpage.classColorCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Name Class Color")
	subpage.classColorCheckbox:SetLayoutWidth(174)
	subpage.classColorCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.name = section.widgets.texts.name or {}
			section.widgets.texts.name.classColor = checked == true
		end, "nameSettingsChanged")
	end)

	subpage.colorPicker = addon.Options.Controls.ColorPicker:Create(subpage, "Name Color")
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

	subpage.outlineDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Name Outline")
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

	subpage.controls = {
		anchorDropdown = subpage.anchorDropdown,
		sizeSlider = subpage.sizeSlider,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		classColorCheckbox = subpage.classColorCheckbox,
		colorPicker = subpage.colorPicker,
		outlineDropdown = subpage.outlineDropdown,
	}

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(50)
		local sectionGapPx = addon.Utilities:ToPixels(16)
		local thirdRowOffsetPx = (rowStepPx * 2) + sectionGapPx
		local columnGapPx = addon.Utilities:ToPixels(30)
		local threeColumnSlotWidthPx = addon.Utilities:ToPixels(174)
		local threeColumnSecondOffsetPx = threeColumnSlotWidthPx + columnGapPx
		local sliderHeightPx = addon.Utilities:ToPixels(34)
		local colorPickerSizePx = addon.Utilities:ToPixels(controls.colorPicker.layoutValues.pickerSize)
		local colorPickerOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - colorPickerSizePx) / 2))
		local checkboxHeightPx = addon.Utilities:ToPixels(controls.classColorCheckbox.layoutValues.height)
		local checkboxOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - checkboxHeightPx) / 2))

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.anchorDropdown:ClearAllPoints()
		controls.anchorDropdown:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)

		controls.sizeSlider:ClearAllPoints()
		controls.sizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			0
		)

		controls.offsetXSlider:ClearAllPoints()
		controls.offsetXSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(rowStepPx)
		)

		controls.offsetYSlider:ClearAllPoints()
		controls.offsetYSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(rowStepPx)
		)

		controls.classColorCheckbox:ClearAllPoints()
		controls.classColorCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(thirdRowOffsetPx + checkboxOffsetPx)
		)

		controls.colorPicker:ClearAllPoints()
		controls.colorPicker:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(thirdRowOffsetPx + colorPickerOffsetPx)
		)

		controls.outlineDropdown:ClearAllPoints()
		controls.outlineDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(thirdRowOffsetPx + rowStepPx)
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

		if classColor == nil then
			classColor = defaults.classColor
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
	end

	return subpage
end
