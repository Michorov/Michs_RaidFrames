local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.Dispels = addon.Options.Pages.Auras.Dispels or {}

local Dispels = addon.Options.Pages.Auras.Dispels

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

local growDirectionOptions = {
	{ value = "LEFT", text = "Left" },
	{ value = "RIGHT", text = "Right" },
}

local overlayStyleOptions = {
	{ value = "FULL", text = "Full Bar" },
	{ value = "GRADIENT", text = "Gradient" },
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

local function GetModeDefaults()
	return {
		enabled = true,
		overlayEnabled = true,
		overlayStyle = "FULL",
		anchor = "TOPRIGHT",
		relativeAnchor = "TOPRIGHT",
		growDirection = "LEFT",
		spacing = 1,
		offsetX = -2,
		offsetY = -2,
		iconSize = 12,
		maxIcons = 4,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r Dispel settings are disabled during combat.")
end

local function ApplyModeSetting(updateFn, settingsReason, notifyState)
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

	addon.UpdateScheduler:Notify(settingsReason or "dispelsSettingsChanged")
	if notifyState then
		addon.UpdateScheduler:Notify("aurasStateChanged")
	end
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

function Dispels:Ensure(parent)
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
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.enabled = checked == true
		end, "dispelsSettingsChanged", true)
	end)

	subpage.overlayEnabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Enabled")
	subpage.overlayEnabledCheckbox:SetLayoutWidth(174)
	subpage.overlayEnabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispelOverlay = section.widgets.icons.dispelOverlay or {}
			section.widgets.icons.dispelOverlay.enabled = checked == true
		end, "dispelOverlaySettingsChanged")
	end)

	subpage.overlayStyleDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Style")
	subpage.overlayStyleDropdown:SetLayoutWidth(174)
	subpage.overlayStyleDropdown:SetOptions(overlayStyleOptions)
	subpage.overlayStyleDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispelOverlay = section.widgets.icons.dispelOverlay or {}
			section.widgets.icons.dispelOverlay.style = value
		end, "dispelOverlaySettingsChanged")
	end)

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Anchor")
	subpage.anchorDropdown:SetLayoutWidth(174)
	subpage.anchorDropdown:SetOptions(anchorOptions)
	subpage.anchorDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.anchor = value
		end, "dispelsSettingsChanged")
	end)

	subpage.relativeAnchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, "To Frame")
	subpage.relativeAnchorDropdown:SetLayoutWidth(174)
	subpage.relativeAnchorDropdown:SetOptions(anchorOptions)
	subpage.relativeAnchorDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.relativeAnchor = value
		end, "dispelsSettingsChanged")
	end)

	subpage.growDirectionDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Grow Direction")
	subpage.growDirectionDropdown:SetLayoutWidth(174)
	subpage.growDirectionDropdown:SetOptions(growDirectionOptions)
	subpage.growDirectionDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.growDirection = value
		end, "dispelsSettingsChanged")
	end)

	subpage.spacingSlider = addon.Options.Controls.Slider:Create(subpage, "Spacing")
	subpage.spacingSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.spacingSlider, 0, 12, 1)
	subpage.spacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.spacing = value
		end, "dispelsSettingsChanged")
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, "Offset X")
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -100, 100, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.offsetX = value
		end, "dispelsSettingsChanged")
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, "Offset Y")
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -100, 100, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.offsetY = value
		end, "dispelsSettingsChanged")
	end)

	subpage.iconSizeSlider = addon.Options.Controls.Slider:Create(subpage, "Icon Size")
	subpage.iconSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.iconSizeSlider, 6, 32, 1)
	subpage.iconSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.iconSize = value
		end, "dispelsSettingsChanged")
	end)

	subpage.maxIconsSlider = addon.Options.Controls.Slider:Create(subpage, "Max Icons")
	subpage.maxIconsSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.maxIconsSlider, 1, 6, 1)
	subpage.maxIconsSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.maxIcons = value
		end, "dispelsSettingsChanged", true)
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		overlayEnabledCheckbox = subpage.overlayEnabledCheckbox,
		overlayStyleDropdown = subpage.overlayStyleDropdown,
		anchorDropdown = subpage.anchorDropdown,
		relativeAnchorDropdown = subpage.relativeAnchorDropdown,
		growDirectionDropdown = subpage.growDirectionDropdown,
		spacingSlider = subpage.spacingSlider,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		iconSizeSlider = subpage.iconSizeSlider,
		maxIconsSlider = subpage.maxIconsSlider,
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
		local firstRowOffsetPx = 0
		local secondRowOffsetPx = rowStepPx - topRowAdjustmentPx
		local thirdRowOffsetPx = secondRowOffsetPx + rowStepPx + sectionGapPx
		local fourthRowOffsetPx = thirdRowOffsetPx + rowStepPx
		local fifthRowOffsetPx = fourthRowOffsetPx + rowStepPx + sectionGapPx
		local overlayCheckboxOffsetPx = fifthRowOffsetPx
			+ addon.Utilities:ToPixels(
				controls.overlayStyleDropdown.layoutValues.labelHeight + controls.overlayStyleDropdown.layoutValues.labelSpacing
			)

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.enabledCheckbox:ClearAllPoints()
		controls.enabledCheckbox:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(firstRowOffsetPx))

		controls.anchorDropdown:ClearAllPoints()
		controls.anchorDropdown:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(secondRowOffsetPx))

		controls.relativeAnchorDropdown:ClearAllPoints()
		controls.relativeAnchorDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(secondRowOffsetPx)
		)

		controls.growDirectionDropdown:ClearAllPoints()
		controls.growDirectionDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(thirdColumnOffsetPx),
			-addon.Utilities:ToUI(secondRowOffsetPx)
		)

		controls.spacingSlider:ClearAllPoints()
		controls.spacingSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(thirdColumnOffsetPx),
			-addon.Utilities:ToUI(thirdRowOffsetPx)
		)

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

		controls.maxIconsSlider:ClearAllPoints()
		controls.maxIconsSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(fourthRowOffsetPx)
		)

		controls.overlayEnabledCheckbox:ClearAllPoints()
		controls.overlayEnabledCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(overlayCheckboxOffsetPx)
		)

		controls.overlayStyleDropdown:ClearAllPoints()
		controls.overlayStyleDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(fifthRowOffsetPx)
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
		local icons = widgets.icons or {}
		local dispels = icons.dispels or {}
		local dispelOverlay = icons.dispelOverlay or {}

		controls.enabledCheckbox:SetChecked(ResolveBoolean(dispels.enabled, defaults.enabled))
		controls.overlayEnabledCheckbox:SetChecked(ResolveBoolean(dispelOverlay.enabled, defaults.overlayEnabled))
		controls.overlayStyleDropdown:SetValue(dispelOverlay.style or defaults.overlayStyle)
		controls.anchorDropdown:SetValue(dispels.anchor or defaults.anchor)
		controls.relativeAnchorDropdown:SetValue(dispels.relativeAnchor or defaults.relativeAnchor)
		controls.growDirectionDropdown:SetValue(dispels.growDirection or defaults.growDirection)
		controls.spacingSlider:SetValueSilently(dispels.spacing or defaults.spacing)
		controls.offsetXSlider:SetValueSilently(dispels.offsetX or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(dispels.offsetY or defaults.offsetY)
		controls.iconSizeSlider:SetValueSilently(dispels.iconSize or defaults.iconSize)
		controls.maxIconsSlider:SetValueSilently(dispels.maxIcons or defaults.maxIcons)
	end

	return subpage
end
