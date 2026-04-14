local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.RaidBuffReminder = addon.Options.Pages.Auras.RaidBuffReminder or {}

local RaidBuffReminder = addon.Options.Pages.Auras.RaidBuffReminder

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

local function ResolveBoolean(value, defaultValue)
	if value == nil then
		return defaultValue
	end

	return value == true
end

local function GetModeDefaults(mode)
	if mode == "raid" then
		return {
			enabled = true,
			showInCombat = false,
			anchor = "CENTER",
			offsetX = 0,
			offsetY = 0,
			iconSize = 28,
			borderSizePx = 1,
			borderColor = { r = 1, g = 0, b = 0, a = 1 },
		}
	end

	return {
		enabled = true,
		showInCombat = false,
		anchor = "CENTER",
		offsetX = 0,
		offsetY = 0,
		iconSize = 32,
		borderSizePx = 1,
		borderColor = { r = 1, g = 0, b = 0, a = 1 },
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r Raid Buff Reminder settings are disabled during combat.")
end

local function ApplyModeSetting(updateFn)
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

	addon.UpdateScheduler:Notify("raidBuffReminderSettingsChanged")
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

function RaidBuffReminder:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Enabled")
	subpage.enabledCheckbox:SetLayoutWidth(174)
	subpage.enabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.raidBuffReminder = section.widgets.icons.raidBuffReminder or {}
			section.widgets.icons.raidBuffReminder.enabled = checked == true
		end)
	end)

	subpage.showInCombatCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Show in Combat")
	subpage.showInCombatCheckbox:SetLayoutWidth(174)
	subpage.showInCombatCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.raidBuffReminder = section.widgets.icons.raidBuffReminder or {}
			section.widgets.icons.raidBuffReminder.showInCombat = checked == true
		end)
	end)

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Anchor")
	subpage.anchorDropdown:SetLayoutWidth(174)
	subpage.anchorDropdown:SetOptions(anchorOptions)
	subpage.anchorDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.raidBuffReminder = section.widgets.icons.raidBuffReminder or {}
			section.widgets.icons.raidBuffReminder.anchor = value
		end)
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, "Offset X")
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -300, 300, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.raidBuffReminder = section.widgets.icons.raidBuffReminder or {}
			section.widgets.icons.raidBuffReminder.offsetX = value
		end)
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, "Offset Y")
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -300, 300, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.raidBuffReminder = section.widgets.icons.raidBuffReminder or {}
			section.widgets.icons.raidBuffReminder.offsetY = value
		end)
	end)

	subpage.iconSizeSlider = addon.Options.Controls.Slider:Create(subpage, "Icon Size")
	subpage.iconSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.iconSizeSlider, 8, 128, 1)
	subpage.iconSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.raidBuffReminder = section.widgets.icons.raidBuffReminder or {}
			section.widgets.icons.raidBuffReminder.iconSize = value
		end)
	end)

	subpage.borderSizeSlider = addon.Options.Controls.Slider:Create(subpage, "Border Size")
	subpage.borderSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.borderSizeSlider, 0, 6, 1)
	subpage.borderSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.raidBuffReminder = section.widgets.icons.raidBuffReminder or {}
			section.widgets.icons.raidBuffReminder.borderSizePx = value
		end)
	end)

	subpage.borderColorPicker = addon.Options.Controls.ColorPicker:Create(subpage, "Border Color")
	subpage.borderColorPicker:SetLayoutWidth(174)
	subpage.borderColorPicker:SetHasOpacity(false)
	subpage.borderColorPicker:SetOnValueChanged(function(_, r, g, b)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.raidBuffReminder = section.widgets.icons.raidBuffReminder or {}
			section.widgets.icons.raidBuffReminder.borderColor = { r = r, g = g, b = b, a = 1 }
		end)
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		showInCombatCheckbox = subpage.showInCombatCheckbox,
		anchorDropdown = subpage.anchorDropdown,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		iconSizeSlider = subpage.iconSizeSlider,
		borderSizeSlider = subpage.borderSizeSlider,
		borderColorPicker = subpage.borderColorPicker,
	}

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(50)
		local topRowAdjustmentPx = addon.Utilities:ToPixels(8)
		local sectionGapPx = addon.Utilities:ToPixels(16)
		local columnGapPx = addon.Utilities:ToPixels(30)
		local columnWidthPx = addon.Utilities:ToPixels(174)
		local secondColumnOffsetPx = columnWidthPx + columnGapPx
		local thirdColumnOffsetPx = (columnWidthPx * 2) + (columnGapPx * 2)
		local sliderHeightPx = addon.Utilities:ToPixels(34)
		local colorPickerSizePx = addon.Utilities:ToPixels(controls.borderColorPicker.layoutValues.pickerSize)
		local colorPickerOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - colorPickerSizePx) / 2))
		local firstRowOffsetPx = 0
		local secondRowOffsetPx = rowStepPx - topRowAdjustmentPx
		local thirdRowOffsetPx = secondRowOffsetPx + rowStepPx + sectionGapPx
		local fourthRowOffsetPx = thirdRowOffsetPx + rowStepPx
		local fifthRowOffsetPx = fourthRowOffsetPx + rowStepPx

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.enabledCheckbox:ClearAllPoints()
		controls.enabledCheckbox:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(firstRowOffsetPx))

		controls.showInCombatCheckbox:ClearAllPoints()
		controls.showInCombatCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(firstRowOffsetPx)
		)

		controls.anchorDropdown:ClearAllPoints()
		controls.anchorDropdown:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(secondRowOffsetPx))

		controls.offsetXSlider:ClearAllPoints()
		controls.offsetXSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(thirdRowOffsetPx))

		controls.offsetYSlider:ClearAllPoints()
		controls.offsetYSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(thirdRowOffsetPx)
		)

		controls.iconSizeSlider:ClearAllPoints()
		controls.iconSizeSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(fourthRowOffsetPx))

		controls.borderSizeSlider:ClearAllPoints()
		controls.borderSizeSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(fifthRowOffsetPx))

		controls.borderColorPicker:ClearAllPoints()
		controls.borderColorPicker:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(fifthRowOffsetPx + colorPickerOffsetPx)
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
		local widgets = section.widgets or {}
		local icons = widgets.icons or {}
		local raidBuffReminder = icons.raidBuffReminder or {}
		local borderColor = raidBuffReminder.borderColor or defaults.borderColor

		controls.enabledCheckbox:SetChecked(ResolveBoolean(raidBuffReminder.enabled, defaults.enabled))
		controls.showInCombatCheckbox:SetChecked(
			ResolveBoolean(raidBuffReminder.showInCombat, defaults.showInCombat)
		)
		controls.anchorDropdown:SetValue(raidBuffReminder.anchor or defaults.anchor)
		controls.offsetXSlider:SetValue(raidBuffReminder.offsetX or defaults.offsetX)
		controls.offsetYSlider:SetValue(raidBuffReminder.offsetY or defaults.offsetY)
		controls.iconSizeSlider:SetValue(raidBuffReminder.iconSize or defaults.iconSize)
		controls.borderSizeSlider:SetValue(raidBuffReminder.borderSizePx or defaults.borderSizePx)
		controls.borderColorPicker:SetColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
	end

	return subpage
end
