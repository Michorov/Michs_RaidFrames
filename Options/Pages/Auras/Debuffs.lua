local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.Debuffs = addon.Options.Pages.Auras.Debuffs or {}

local Debuffs = addon.Options.Pages.Auras.Debuffs

local subpage

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
		offsetX = 2,
		offsetY = 2,
		iconSize = 16,
		spacing = -1,
		maxIcons = 6,
		iconsPerRow = 3,
		borderSizePx = 1,
		borderColorByDebuffType = false,
		showStacks = true,
		stacksFontSize = 10,
		showCooldown = false,
		cooldownFontSize = 10,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r Debuff settings are disabled during combat.")
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
	local mode = GetModeKey()

	profile[mode] = profile[mode] or {}
	updateFn(profile[mode], mode)

	addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
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

function Debuffs:Ensure(parent)
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
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.enabled = checked == true
		end, true)
	end)

	subpage.borderColorByDebuffTypeCheckbox =
		addon.Options.Controls.Checkbox:Create(subpage, "Color By Debuff Type")
	subpage.borderColorByDebuffTypeCheckbox:SetLayoutWidth(174)
	subpage.borderColorByDebuffTypeCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.borderColorByDebuffType = checked == true
		end, true)
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, "Offset X")
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -300, 300, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.offsetX = value
		end)
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, "Offset Y")
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -300, 300, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.offsetY = value
		end)
	end)

	subpage.iconSizeSlider = addon.Options.Controls.Slider:Create(subpage, "Icon Size")
	subpage.iconSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.iconSizeSlider, 8, 64, 1)
	subpage.iconSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.iconSize = value
		end)
	end)

	subpage.spacingSlider = addon.Options.Controls.Slider:Create(subpage, "Spacing")
	subpage.spacingSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.spacingSlider, -10, 20, 1)
	subpage.spacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.spacing = value
		end)
	end)

	subpage.maxIconsSlider = addon.Options.Controls.Slider:Create(subpage, "Max Icons")
	subpage.maxIconsSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.maxIconsSlider, 1, 10, 1)
	subpage.maxIconsSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.maxIcons = value
		end)
	end)

	subpage.iconsPerRowSlider = addon.Options.Controls.Slider:Create(subpage, "Icons Per Row")
	subpage.iconsPerRowSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.iconsPerRowSlider, 1, 10, 1)
	subpage.iconsPerRowSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.iconsPerRow = value
		end)
	end)

	subpage.borderSizeSlider = addon.Options.Controls.Slider:Create(subpage, "Border Size")
	subpage.borderSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.borderSizeSlider, 1, 4, 1)
	subpage.borderSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.borderSizePx = value
		end)
	end)

	subpage.showStacksCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Show Stacks")
	subpage.showStacksCheckbox:SetLayoutWidth(174)
	subpage.showStacksCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.showStacks = checked == true
		end)
	end)

	subpage.stacksFontSizeSlider = addon.Options.Controls.Slider:Create(subpage, "Stacks Size")
	subpage.stacksFontSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.stacksFontSizeSlider, 6, 32, 1)
	subpage.stacksFontSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.stacksFontSize = value
		end)
	end)

	subpage.showCooldownCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Show Duration")
	subpage.showCooldownCheckbox:SetLayoutWidth(174)
	subpage.showCooldownCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.showCooldown = checked == true
		end)
	end)

	subpage.cooldownFontSizeSlider = addon.Options.Controls.Slider:Create(subpage, "Duration Size")
	subpage.cooldownFontSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.cooldownFontSizeSlider, 6, 32, 1)
	subpage.cooldownFontSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.debuffs = section.widgets.icons.debuffs or {}
			section.widgets.icons.debuffs.cooldownFontSize = value
		end)
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		borderColorByDebuffTypeCheckbox = subpage.borderColorByDebuffTypeCheckbox,
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
		local checkboxOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - checkboxHeightPx) / 2))
		local firstRowOffsetPx = 0
		local secondRowOffsetPx = rowStepPx
		local thirdRowOffsetPx = rowStepPx * 2
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

		controls.borderColorByDebuffTypeCheckbox:ClearAllPoints()
		controls.borderColorByDebuffTypeCheckbox:SetPoint(
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
		local mode = GetModeKey()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults()
		local widgets = section.widgets or {}
		local icons = widgets.icons or {}
		local debuffs = icons.debuffs or {}

		controls.enabledCheckbox:SetChecked(ResolveBoolean(debuffs.enabled, defaults.enabled))
		controls.borderColorByDebuffTypeCheckbox:SetChecked(
			ResolveBoolean(debuffs.borderColorByDebuffType, defaults.borderColorByDebuffType)
		)
		controls.offsetXSlider:SetValue(debuffs.offsetX or defaults.offsetX)
		controls.offsetYSlider:SetValue(debuffs.offsetY or defaults.offsetY)
		controls.iconSizeSlider:SetValue(debuffs.iconSize or defaults.iconSize)
		controls.spacingSlider:SetValue(debuffs.spacing or defaults.spacing)
		controls.maxIconsSlider:SetValue(debuffs.maxIcons or defaults.maxIcons)
		controls.iconsPerRowSlider:SetValue(debuffs.iconsPerRow or defaults.iconsPerRow)
		controls.borderSizeSlider:SetValue(debuffs.borderSizePx or defaults.borderSizePx)
		controls.showStacksCheckbox:SetChecked(ResolveBoolean(debuffs.showStacks, defaults.showStacks))
		controls.stacksFontSizeSlider:SetValue(debuffs.stacksFontSize or defaults.stacksFontSize)
		controls.showCooldownCheckbox:SetChecked(ResolveBoolean(debuffs.showCooldown, defaults.showCooldown))
		controls.cooldownFontSizeSlider:SetValue(debuffs.cooldownFontSize or defaults.cooldownFontSize)
	end

	return subpage
end
