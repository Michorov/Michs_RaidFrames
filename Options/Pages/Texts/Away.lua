local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Texts = addon.Options.Pages.Texts or {}
addon.Options.Pages.Texts.Away = addon.Options.Pages.Texts.Away or {}

local Away = addon.Options.Pages.Texts.Away

local subpage
local L = addon.L

local anchorOptions = {
	{ value = "TOPLEFT", text = L["Top Left"] },
	{ value = "TOP", text = L["Top"] },
	{ value = "TOPRIGHT", text = L["Top Right"] },
	{ value = "LEFT", text = L["Left"] },
	{ value = "CENTER", text = L["Center"] },
	{ value = "RIGHT", text = L["Right"] },
	{ value = "BOTTOMLEFT", text = L["Bottom Left"] },
	{ value = "BOTTOM", text = L["Bottom"] },
	{ value = "BOTTOMRIGHT", text = L["Bottom Right"] },
}

local outlineOptions = {
	{ value = "", text = L["None"] },
	{ value = "OUTLINE", text = L["Outline"] },
	{ value = "THICKOUTLINE", text = L["Thick Outline"] },
	{ value = "MONOCHROME", text = L["Monochrome"] },
}

local function UpdateAnchorOptions()
	anchorOptions[1].text = L["Top Left"]
	anchorOptions[2].text = L["Top"]
	anchorOptions[3].text = L["Top Right"]
	anchorOptions[4].text = L["Left"]
	anchorOptions[5].text = L["Center"]
	anchorOptions[6].text = L["Right"]
	anchorOptions[7].text = L["Bottom Left"]
	anchorOptions[8].text = L["Bottom"]
	anchorOptions[9].text = L["Bottom Right"]
end

local function UpdateOutlineOptions()
	outlineOptions[1].text = L["None"]
	outlineOptions[2].text = L["Outline"]
	outlineOptions[3].text = L["Thick Outline"]
	outlineOptions[4].text = L["Monochrome"]
end

local function GetModeDefaults()
	return {
		enabled = true,
		anchor = "CENTER",
		offsetX = 0,
		offsetY = -18,
		size = 10,
		outline = "",
		color = { r = 1, g = 1, b = 1, a = 1 },
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Away text settings are disabled during combat."])
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
	local mode = addon.Options.State:GetMode()

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

local function ForEachControl(controls, methodName)
	for _, control in pairs(controls or {}) do
		local method = control and control[methodName]
		if type(method) == "function" then
			method(control)
		end
	end
end

function Away:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Enabled"])
	subpage.enabledCheckbox:SetLayoutWidth(174)
	subpage.enabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.away = section.widgets.texts.away or {}
			section.widgets.texts.away.enabled = checked == true
		end, "awayTextSettingsChanged")
	end)

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, L["Anchor"])
	subpage.anchorDropdown:SetLayoutWidth(174)
	subpage.anchorDropdown:SetOptions(anchorOptions)
	subpage.anchorDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.away = section.widgets.texts.away or {}
			section.widgets.texts.away.anchor = value
		end, "awayTextSettingsChanged")
	end)

	subpage.sizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Font Size"])
	subpage.sizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.sizeSlider, 6, 32, 1)
	subpage.sizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.away = section.widgets.texts.away or {}
			section.widgets.texts.away.size = value
		end, "awayTextSettingsChanged")
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset X"])
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -100, 100, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.away = section.widgets.texts.away or {}
			section.widgets.texts.away.position = section.widgets.texts.away.position or {}
			section.widgets.texts.away.position.x = value
		end, "awayTextSettingsChanged")
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset Y"])
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -100, 100, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.away = section.widgets.texts.away or {}
			section.widgets.texts.away.position = section.widgets.texts.away.position or {}
			section.widgets.texts.away.position.y = value
		end, "awayTextSettingsChanged")
	end)

	subpage.outlineDropdown = addon.Options.Controls.Dropdown:Create(subpage, L["Style"])
	subpage.outlineDropdown:SetLayoutWidth(174)
	subpage.outlineDropdown:SetOptions(outlineOptions)
	subpage.outlineDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.away = section.widgets.texts.away or {}
			section.widgets.texts.away.outline = value
		end, "awayTextSettingsChanged")
	end)

	subpage.colorPicker = addon.Options.Controls.ColorPicker:Create(subpage, L["Color"])
	subpage.colorPicker:SetLayoutWidth(174)
	subpage.colorPicker:SetHasOpacity(false)
	subpage.colorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.texts = section.widgets.texts or {}
			section.widgets.texts.away = section.widgets.texts.away or {}
			section.widgets.texts.away.color = { r = r, g = g, b = b, a = a }
		end, "awayTextSettingsChanged")
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		anchorDropdown = subpage.anchorDropdown,
		sizeSlider = subpage.sizeSlider,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		outlineDropdown = subpage.outlineDropdown,
		colorPicker = subpage.colorPicker,
	}

	function subpage:UpdateLocale()
		UpdateAnchorOptions()
		UpdateOutlineOptions()
		ForEachControl(self.controls, "UpdateLocale")
		self.enabledCheckbox:SetText(L["Enabled"])
		self.anchorDropdown:SetLabel(L["Anchor"])
		self.anchorDropdown:SetOptions(anchorOptions)
		self.sizeSlider:SetLabel(L["Font Size"])
		self.offsetXSlider:SetLabel(L["Offset X"])
		self.offsetYSlider:SetLabel(L["Offset Y"])
		self.outlineDropdown:SetLabel(L["Style"])
		self.outlineDropdown:SetOptions(outlineOptions)
		self.colorPicker:SetLabel(L["Color"])
	end

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(50)
		local anchorRowGapPx = addon.Utilities:ToPixels(8)
		local sectionGapPx = addon.Utilities:ToPixels(16)
		local secondRowOffsetPx = rowStepPx
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

		ForEachControl(controls, "UpdateLayout")

		controls.enabledCheckbox:ClearAllPoints()
		controls.enabledCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(checkboxOffsetPx)
		)

		controls.anchorDropdown:ClearAllPoints()
		controls.anchorDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(secondRowOffsetPx)
		)

		controls.sizeSlider:ClearAllPoints()
		controls.sizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(secondRowOffsetPx)
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
		local mode = addon.Options.State:GetMode()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults()
		local texts = (section.widgets or {}).texts or {}
		local away = texts.away or {}
		local position = away.position or {}
		local color = away.color or defaults.color

		local enabled = away.enabled
		if enabled == nil then
			enabled = defaults.enabled
		end

		controls.enabledCheckbox:SetChecked(enabled == true)
		controls.anchorDropdown:SetOptions(anchorOptions)
		controls.anchorDropdown:SetValue(away.anchor or defaults.anchor)
		controls.sizeSlider:SetValueSilently(away.size or defaults.size)
		controls.offsetXSlider:SetValueSilently(position.x or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(position.y or defaults.offsetY)
		local outline = addon.Utilities:NormalizeFontOutline(away.outline, defaults.outline)
		controls.outlineDropdown:SetOptions(outlineOptions)
		controls.outlineDropdown:SetValue(outline)
		controls.colorPicker:SetColor(color.r, color.g, color.b, color.a)
	end

	subpage:UpdateLocale()

	return subpage
end
