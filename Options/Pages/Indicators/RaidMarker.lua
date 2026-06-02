local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}
addon.Options.Pages.Indicators.RaidMarker = addon.Options.Pages.Indicators.RaidMarker or {}

local RaidMarker = addon.Options.Pages.Indicators.RaidMarker

local subpage
local L = addon.L

local anchorOptions = {
	{ value = "TOPLEFT", text = L["Top Left"] },
	{ value = "TOP", text = L["Top Center"] },
	{ value = "TOPRIGHT", text = L["Top Right"] },
	{ value = "LEFT", text = L["Left"] },
	{ value = "CENTER", text = L["Center"] },
	{ value = "RIGHT", text = L["Right"] },
	{ value = "BOTTOMLEFT", text = L["Bottom Left"] },
	{ value = "BOTTOM", text = L["Bottom Center"] },
	{ value = "BOTTOMRIGHT", text = L["Bottom Right"] },
}

local function UpdateAnchorOptions()
	anchorOptions[1].text = L["Top Left"]
	anchorOptions[2].text = L["Top Center"]
	anchorOptions[3].text = L["Top Right"]
	anchorOptions[4].text = L["Left"]
	anchorOptions[5].text = L["Center"]
	anchorOptions[6].text = L["Right"]
	anchorOptions[7].text = L["Bottom Left"]
	anchorOptions[8].text = L["Bottom Center"]
	anchorOptions[9].text = L["Bottom Right"]
end

local function GetModeDefaults()
	return {
		enabled = true,
		anchor = "TOP",
		offsetX = 0,
		offsetY = 0,
		size = 18,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Raid Marker settings are disabled during combat."])
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
	local mode = addon.Options.State:GetMode()

	profile[mode] = profile[mode] or {}
	updateFn(profile[mode], mode)

	addon.UpdateScheduler:Notify("raidMarkerSettingsChanged")
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

function RaidMarker:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Enabled"])
	subpage.enabledCheckbox:SetLayoutWidth(174)
	subpage.enabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.raidMarker = section.widgets.indicators.raidMarker or {}
			section.widgets.indicators.raidMarker.enabled = checked == true
		end)
	end)

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, L["Anchor"])
	subpage.anchorDropdown:SetLayoutWidth(174)
	subpage.anchorDropdown:SetOptions(anchorOptions)
	subpage.anchorDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.raidMarker = section.widgets.indicators.raidMarker or {}
			section.widgets.indicators.raidMarker.anchor = value
		end)
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset X"])
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -100, 100, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.raidMarker = section.widgets.indicators.raidMarker or {}
			section.widgets.indicators.raidMarker.offsetX = value
		end)
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset Y"])
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -100, 100, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.raidMarker = section.widgets.indicators.raidMarker or {}
			section.widgets.indicators.raidMarker.offsetY = value
		end)
	end)

	subpage.sizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Size"])
	subpage.sizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.sizeSlider, 8, 64, 1)
	subpage.sizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.indicators = section.widgets.indicators or {}
			section.widgets.indicators.raidMarker = section.widgets.indicators.raidMarker or {}
			section.widgets.indicators.raidMarker.size = value
		end)
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		anchorDropdown = subpage.anchorDropdown,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		sizeSlider = subpage.sizeSlider,
	}

	function subpage:UpdateLocale()
		UpdateAnchorOptions()
		self.enabledCheckbox:SetText(L["Enabled"])
		self.anchorDropdown:SetLabel(L["Anchor"])
		self.anchorDropdown:SetOptions(anchorOptions)
		self.offsetXSlider:SetLabel(L["Offset X"])
		self.offsetYSlider:SetLabel(L["Offset Y"])
		self.sizeSlider:SetLabel(L["Size"])
	end

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
		local mode = addon.Options.State:GetMode()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults()
		local widgets = section.widgets or {}
		local indicators = widgets.indicators or {}
		local raidMarker = indicators.raidMarker or {}
		local enabled = raidMarker.enabled
		if enabled == nil then
			enabled = defaults.enabled
		end

		controls.enabledCheckbox:SetChecked(enabled == true)
		controls.anchorDropdown:SetValue(raidMarker.anchor or defaults.anchor)
		controls.offsetXSlider:SetValueSilently(raidMarker.offsetX or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(raidMarker.offsetY or defaults.offsetY)
		controls.sizeSlider:SetValueSilently(raidMarker.size or defaults.size)
	end

	subpage:UpdateLocale()

	return subpage
end
