local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.Buffs = addon.Options.Pages.Auras.Buffs or {}

local Buffs = addon.Options.Pages.Auras.Buffs

local subpage
local L = addon.L
local _, _, _, interfaceVersion = GetBuildInfo()
local isRestrictedAuraAPI = (tonumber(interfaceVersion) or 0) >= 120100

local anchorOptions = {
	{ value = "TOPLEFT", text = L["Top Left"] },
	{ value = "TOPRIGHT", text = L["Top Right"] },
	{ value = "BOTTOMLEFT", text = L["Bottom Left"] },
	{ value = "BOTTOMRIGHT", text = L["Bottom Right"] },
}

local function UpdateAnchorOptions()
	anchorOptions[1].text = L["Top Left"]
	anchorOptions[2].text = L["Top Right"]
	anchorOptions[3].text = L["Bottom Left"]
	anchorOptions[4].text = L["Bottom Right"]
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
		anchor = "BOTTOMRIGHT",
		offsetX = -2,
		offsetY = 2,
		iconSize = 16,
		spacing = -1,
		maxIcons = 6,
		iconsPerRow = 3,
		borderSizePx = 1,
		showStacks = true,
		stacksFontSize = 10,
		showCooldown = false,
		cooldownFontSize = 10,
		showExternals = false,
		showTooltips = false,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Buff settings are disabled during combat."])
end

local function ApplyModeSetting(updateFn, notifyState)
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

	addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
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

function Buffs:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Enabled"])
	subpage.enabledCheckbox:SetLayoutWidth(174)
	subpage.enabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.enabled = checked == true
		end, true)
	end)

	subpage.showTooltipsCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Show Tooltips"])
	subpage.showTooltipsCheckbox:SetLayoutWidth(174)
	subpage.showTooltipsCheckbox:SetShown(isRestrictedAuraAPI)
	subpage.showTooltipsCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.showTooltips = checked == true
		end)
	end)

	subpage.showExternalsCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Show External Buffs"])
	subpage.showExternalsCheckbox:SetLayoutWidth(174)
	subpage.showExternalsCheckbox:SetShown(not isRestrictedAuraAPI)
	subpage.showExternalsCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.showExternals = checked == true
		end)
	end)

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, L["Position"])
	subpage.anchorDropdown:SetLayoutWidth(174)
	subpage.anchorDropdown:SetOptions(anchorOptions)
	subpage.anchorDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.anchor = value
		end)
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset X"])
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -300, 300, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.offsetX = value
		end)
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset Y"])
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -300, 300, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.offsetY = value
		end)
	end)

	subpage.iconSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Icon Size"])
	subpage.iconSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.iconSizeSlider, 8, 64, 1)
	subpage.iconSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.iconSize = value
		end)
	end)

	subpage.spacingSlider = addon.Options.Controls.Slider:Create(subpage, L["Spacing"])
	subpage.spacingSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.spacingSlider, -10, 20, 1)
	subpage.spacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.spacing = value
		end)
	end)

	subpage.maxIconsSlider = addon.Options.Controls.Slider:Create(subpage, L["Max Icons"])
	subpage.maxIconsSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.maxIconsSlider, 1, 10, 1)
	subpage.maxIconsSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.maxIcons = value
		end)
	end)

	subpage.iconsPerRowSlider = addon.Options.Controls.Slider:Create(subpage, L["Icons Per Row"])
	subpage.iconsPerRowSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.iconsPerRowSlider, 1, 10, 1)
	subpage.iconsPerRowSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.iconsPerRow = value
		end)
	end)

	subpage.borderSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Border Size"])
	subpage.borderSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.borderSizeSlider, 0, 4, 1)
	subpage.borderSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.borderSizePx = value
		end)
	end)

	subpage.showStacksCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Show Stacks"])
	subpage.showStacksCheckbox:SetLayoutWidth(174)
	subpage.showStacksCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.showStacks = checked == true
		end)
	end)

	subpage.stacksFontSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Stacks Size"])
	subpage.stacksFontSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.stacksFontSizeSlider, 6, 32, 1)
	subpage.stacksFontSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.stacksFontSize = value
		end)
	end)

	subpage.showCooldownCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Show Duration"])
	subpage.showCooldownCheckbox:SetLayoutWidth(174)
	subpage.showCooldownCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.showCooldown = checked == true
		end)
	end)

	subpage.cooldownFontSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Duration Size"])
	subpage.cooldownFontSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.cooldownFontSizeSlider, 6, 32, 1)
	subpage.cooldownFontSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.buffs = section.widgets.icons.buffs or {}
			section.widgets.icons.buffs.cooldownFontSize = value
		end)
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		showTooltipsCheckbox = subpage.showTooltipsCheckbox,
		showExternalsCheckbox = subpage.showExternalsCheckbox,
		anchorDropdown = subpage.anchorDropdown,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		iconSizeSlider = subpage.iconSizeSlider,
		spacingSlider = subpage.spacingSlider,
		maxIconsSlider = subpage.maxIconsSlider,
		iconsPerRowSlider = subpage.iconsPerRowSlider,
		borderSizeSlider = subpage.borderSizeSlider,
		showStacksCheckbox = subpage.showStacksCheckbox,
		stacksFontSizeSlider = subpage.stacksFontSizeSlider,
		showCooldownCheckbox = subpage.showCooldownCheckbox,
		cooldownFontSizeSlider = subpage.cooldownFontSizeSlider,
	}

	function subpage:UpdateLocale()
		UpdateAnchorOptions()
		self.enabledCheckbox:SetText(L["Enabled"])
		self.showTooltipsCheckbox:SetText(L["Show Tooltips"])
		self.showExternalsCheckbox:SetText(L["Show External Buffs"])
		self.anchorDropdown:SetLabel(L["Position"])
		self.anchorDropdown:SetOptions(anchorOptions)
		self.offsetXSlider:SetLabel(L["Offset X"])
		self.offsetYSlider:SetLabel(L["Offset Y"])
		self.iconSizeSlider:SetLabel(L["Icon Size"])
		self.spacingSlider:SetLabel(L["Spacing"])
		self.maxIconsSlider:SetLabel(L["Max Icons"])
		self.iconsPerRowSlider:SetLabel(L["Icons Per Row"])
		self.borderSizeSlider:SetLabel(L["Border Size"])
		self.showStacksCheckbox:SetText(L["Show Stacks"])
		self.stacksFontSizeSlider:SetLabel(L["Stacks Size"])
		self.showCooldownCheckbox:SetText(L["Show Duration"])
		self.cooldownFontSizeSlider:SetLabel(L["Duration Size"])
	end

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(50)
		local sectionGapPx = addon.Utilities:ToPixels(16)
		local columnGapPx = addon.Utilities:ToPixels(30)
		local columnWidthPx = addon.Utilities:ToPixels(174)
		local secondColumnOffsetPx = columnWidthPx + columnGapPx
		local thirdColumnOffsetPx = (columnWidthPx * 2) + (columnGapPx * 2)
		local sliderHeightPx = addon.Utilities:ToPixels(34)
		local checkboxHeightPx = addon.Utilities:ToPixels(controls.enabledCheckbox.layoutValues.height)
		local checkboxStackGapPx = addon.Utilities:ToPixels(12)
		local topControlsGapPx = addon.Utilities:ToPixels(28)
		local anchorDropdownHeightPx = addon.Utilities:ToPixels(
			controls.anchorDropdown.layoutValues.labelHeight
				+ controls.anchorDropdown.layoutValues.labelSpacing
				+ controls.anchorDropdown.layoutValues.fieldHeight
		)
		local stackedCheckboxHeightPx = (checkboxHeightPx * 2) + checkboxStackGapPx
		local checkboxOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - checkboxHeightPx) / 2))
		local firstRowOffsetPx = 0
		local secondRowOffsetPx = math.max(stackedCheckboxHeightPx, anchorDropdownHeightPx) + topControlsGapPx
		local thirdRowOffsetPx = secondRowOffsetPx + rowStepPx
		local fourthRowOffsetPx = thirdRowOffsetPx + rowStepPx
		local fifthRowOffsetPx = fourthRowOffsetPx + rowStepPx + sectionGapPx
		local sixthRowOffsetPx = fifthRowOffsetPx + rowStepPx

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.enabledCheckbox:ClearAllPoints()
		controls.enabledCheckbox:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(firstRowOffsetPx))

		controls.showTooltipsCheckbox:ClearAllPoints()
		controls.showTooltipsCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(firstRowOffsetPx + checkboxHeightPx + checkboxStackGapPx)
		)

		controls.showExternalsCheckbox:ClearAllPoints()
		controls.showExternalsCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(firstRowOffsetPx + checkboxHeightPx + checkboxStackGapPx)
		)

		controls.anchorDropdown:ClearAllPoints()
		controls.anchorDropdown:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(firstRowOffsetPx)
		)

		controls.offsetXSlider:ClearAllPoints()
		controls.offsetXSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(secondRowOffsetPx))

		controls.offsetYSlider:ClearAllPoints()
		controls.offsetYSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(secondRowOffsetPx)
		)

		controls.spacingSlider:ClearAllPoints()
		controls.spacingSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(thirdColumnOffsetPx),
			-addon.Utilities:ToUI(secondRowOffsetPx)
		)

		controls.iconSizeSlider:ClearAllPoints()
		controls.iconSizeSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(thirdRowOffsetPx))

		controls.maxIconsSlider:ClearAllPoints()
		controls.maxIconsSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(thirdRowOffsetPx)
		)

		controls.iconsPerRowSlider:ClearAllPoints()
		controls.iconsPerRowSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(thirdColumnOffsetPx),
			-addon.Utilities:ToUI(thirdRowOffsetPx)
		)

		controls.borderSizeSlider:ClearAllPoints()
		controls.borderSizeSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(fourthRowOffsetPx))

		controls.showStacksCheckbox:ClearAllPoints()
		controls.showStacksCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(fifthRowOffsetPx + checkboxOffsetPx)
		)

		controls.stacksFontSizeSlider:ClearAllPoints()
		controls.stacksFontSizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(fifthRowOffsetPx)
		)

		controls.showCooldownCheckbox:ClearAllPoints()
		controls.showCooldownCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(sixthRowOffsetPx + checkboxOffsetPx)
		)

		controls.cooldownFontSizeSlider:ClearAllPoints()
		controls.cooldownFontSizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(sixthRowOffsetPx)
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
		local icons = widgets.icons or {}
		local buffs = icons.buffs or {}

		controls.enabledCheckbox:SetChecked(ResolveBoolean(buffs.enabled, defaults.enabled))
		controls.showTooltipsCheckbox:SetShown(isRestrictedAuraAPI)
		controls.showExternalsCheckbox:SetShown(not isRestrictedAuraAPI)
		controls.showTooltipsCheckbox:SetChecked(ResolveBoolean(buffs.showTooltips, defaults.showTooltips))
		controls.showExternalsCheckbox:SetChecked(ResolveBoolean(buffs.showExternals, defaults.showExternals))
		controls.anchorDropdown:SetOptions(anchorOptions)
		controls.anchorDropdown:SetValue(buffs.anchor or defaults.anchor)
		controls.offsetXSlider:SetValueSilently(buffs.offsetX or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(buffs.offsetY or defaults.offsetY)
		controls.iconSizeSlider:SetValueSilently(buffs.iconSize or defaults.iconSize)
		controls.spacingSlider:SetValueSilently(buffs.spacing or defaults.spacing)
		controls.maxIconsSlider:SetValueSilently(buffs.maxIcons or defaults.maxIcons)
		controls.iconsPerRowSlider:SetValueSilently(buffs.iconsPerRow or defaults.iconsPerRow)
		controls.borderSizeSlider:SetValueSilently(buffs.borderSizePx or defaults.borderSizePx)
		controls.showStacksCheckbox:SetChecked(ResolveBoolean(buffs.showStacks, defaults.showStacks))
		controls.stacksFontSizeSlider:SetValueSilently(buffs.stacksFontSize or defaults.stacksFontSize)
		controls.showCooldownCheckbox:SetChecked(ResolveBoolean(buffs.showCooldown, defaults.showCooldown))
		controls.cooldownFontSizeSlider:SetValueSilently(buffs.cooldownFontSize or defaults.cooldownFontSize)
	end

	subpage:UpdateLocale()

	return subpage
end
