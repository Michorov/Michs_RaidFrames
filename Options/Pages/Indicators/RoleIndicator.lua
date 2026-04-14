local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}
addon.Options.Pages.Indicators.RoleIndicator = addon.Options.Pages.Indicators.RoleIndicator or {}

local RoleIndicator = addon.Options.Pages.Indicators.RoleIndicator

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
		anchor = "TOPLEFT",
		offsetX = 0,
		offsetY = 0,
		size = 16,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r Role Indicator settings are disabled during combat.")
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

	addon.UpdateScheduler:Notify("roleIconSettingsChanged")
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

function RoleIndicator:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Enabled")
	subpage.enabledCheckbox:SetLayoutWidth(174)
	subpage.enabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.roleIcon = section.widgets.indicators.roleIcon or {}
			section.widgets.indicators.roleIcon.enabled = checked == true
		end)
	end)

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Anchor")
	subpage.anchorDropdown:SetLayoutWidth(174)
	subpage.anchorDropdown:SetOptions(anchorOptions)
	subpage.anchorDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.roleIcon = section.widgets.indicators.roleIcon or {}
			section.widgets.indicators.roleIcon.anchor = value
		end)
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, "Offset X")
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -100, 100, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.roleIcon = section.widgets.indicators.roleIcon or {}
			section.widgets.indicators.roleIcon.offsetX = value
		end)
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, "Offset Y")
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -100, 100, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.roleIcon = section.widgets.indicators.roleIcon or {}
			section.widgets.indicators.roleIcon.offsetY = value
		end)
	end)

	subpage.sizeSlider = addon.Options.Controls.Slider:Create(subpage, "Size")
	subpage.sizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.sizeSlider, 8, 64, 1)
	subpage.sizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.roleIcon = section.widgets.indicators.roleIcon or {}
			section.widgets.indicators.roleIcon.size = value
		end)
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		anchorDropdown = subpage.anchorDropdown,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		sizeSlider = subpage.sizeSlider,
	}

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(50)
		local anchorRowGapPx = addon.Utilities:ToPixels(16)
		local columnGapPx = addon.Utilities:ToPixels(30)
		local columnWidthPx = addon.Utilities:ToPixels(174)
		local secondColumnOffsetPx = columnWidthPx + columnGapPx
		local sliderHeightPx = addon.Utilities:ToPixels(34)
		local checkboxHeightPx = addon.Utilities:ToPixels(controls.enabledCheckbox.layoutValues.height)
		local checkboxOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - checkboxHeightPx) / 2))
		local enabledControlsOffsetPx = 0
		local anchorControlsOffsetPx = rowStepPx
		local offsetControlsOffsetPx = anchorControlsOffsetPx + rowStepPx + anchorRowGapPx
		local sizeControlsOffsetPx = offsetControlsOffsetPx + rowStepPx

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
			-addon.Utilities:ToUI(enabledControlsOffsetPx + checkboxOffsetPx)
		)

		controls.anchorDropdown:ClearAllPoints()
		controls.anchorDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(anchorControlsOffsetPx)
		)

		controls.offsetXSlider:ClearAllPoints()
		controls.offsetXSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(offsetControlsOffsetPx)
		)

		controls.offsetYSlider:ClearAllPoints()
		controls.offsetYSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(offsetControlsOffsetPx)
		)

		controls.sizeSlider:ClearAllPoints()
		controls.sizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(sizeControlsOffsetPx)
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
		local widgets = section.widgets or {}
		local indicators = widgets.indicators or {}
		local roleIcon = indicators.roleIcon or {}
		local enabled = roleIcon.enabled
		if enabled == nil then
			enabled = defaults.enabled
		end

		controls.enabledCheckbox:SetChecked(enabled == true)
		controls.anchorDropdown:SetValue(roleIcon.anchor or defaults.anchor)
		controls.offsetXSlider:SetValueSilently(roleIcon.offsetX or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(roleIcon.offsetY or defaults.offsetY)
		controls.sizeSlider:SetValueSilently(roleIcon.size or defaults.size)
	end

	return subpage
end
