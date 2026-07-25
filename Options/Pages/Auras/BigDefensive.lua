local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.BigDefensive = addon.Options.Pages.Auras.BigDefensive or {}

local BigDefensive = addon.Options.Pages.Auras.BigDefensive

local subpage
local L = addon.L

local function ResolveBoolean(value, defaultValue)
	if value == nil then
		return defaultValue
	end

	return value == true
end

local function GetModeDefaults(mode)
	if mode == "raid" then
		return {
			offsetX = 0,
			offsetY = 0,
			iconSize = 28,
			borderSizePx = 1,
			showStacks = true,
			stacksFontSize = 16,
			showCooldown = false,
			cooldownFontSize = 16,
		}
	end

	return {
		offsetX = 0,
		offsetY = 0,
		iconSize = 32,
		borderSizePx = 1,
		showStacks = true,
		stacksFontSize = 10,
		showCooldown = false,
		cooldownFontSize = 16,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Big Defensive settings are disabled during combat."])
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

	addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

function BigDefensive:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset X"])
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -300, 300, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.bigDefensive = section.widgets.icons.bigDefensive or {}
			section.widgets.icons.bigDefensive.offsetX = value
		end)
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset Y"])
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -300, 300, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.bigDefensive = section.widgets.icons.bigDefensive or {}
			section.widgets.icons.bigDefensive.offsetY = value
		end)
	end)

	subpage.iconSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Icon Size"])
	subpage.iconSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.iconSizeSlider, 8, 128, 1)
	subpage.iconSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.bigDefensive = section.widgets.icons.bigDefensive or {}
			section.widgets.icons.bigDefensive.iconSize = value
		end)
	end)

	subpage.borderSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Border Size"])
	subpage.borderSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.borderSizeSlider, 0, 6, 1)
	subpage.borderSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.bigDefensive = section.widgets.icons.bigDefensive or {}
			section.widgets.icons.bigDefensive.borderSizePx = value
		end)
	end)

	subpage.showStacksCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Show Stacks"])
	subpage.showStacksCheckbox:SetLayoutWidth(174)
	subpage.showStacksCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.bigDefensive = section.widgets.icons.bigDefensive or {}
			section.widgets.icons.bigDefensive.showStacks = checked == true
		end)
	end)

	subpage.stacksFontSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Stacks Size"])
	subpage.stacksFontSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.stacksFontSizeSlider, 6, 32, 1)
	subpage.stacksFontSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.bigDefensive = section.widgets.icons.bigDefensive or {}
			section.widgets.icons.bigDefensive.stacksFontSize = value
		end)
	end)

	subpage.showCooldownCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Show Duration"])
	subpage.showCooldownCheckbox:SetLayoutWidth(174)
	subpage.showCooldownCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.bigDefensive = section.widgets.icons.bigDefensive or {}
			section.widgets.icons.bigDefensive.showCooldown = checked == true
		end)
	end)

	subpage.cooldownFontSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Duration Size"])
	subpage.cooldownFontSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.cooldownFontSizeSlider, 6, 32, 1)
	subpage.cooldownFontSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.bigDefensive = section.widgets.icons.bigDefensive or {}
			section.widgets.icons.bigDefensive.cooldownFontSize = value
		end)
	end)

	subpage.controls = {
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		iconSizeSlider = subpage.iconSizeSlider,
		borderSizeSlider = subpage.borderSizeSlider,
		showStacksCheckbox = subpage.showStacksCheckbox,
		stacksFontSizeSlider = subpage.stacksFontSizeSlider,
		showCooldownCheckbox = subpage.showCooldownCheckbox,
		cooldownFontSizeSlider = subpage.cooldownFontSizeSlider,
	}

	function subpage:UpdateLocale()
		self.offsetXSlider:SetLabel(L["Offset X"])
		self.offsetYSlider:SetLabel(L["Offset Y"])
		self.iconSizeSlider:SetLabel(L["Icon Size"])
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
		local sliderHeightPx = addon.Utilities:ToPixels(addon.Options.Controls.Slider.defaultHeight)
		local checkboxHeightPx = addon.Utilities:ToPixels(controls.showStacksCheckbox.layoutValues.height)
		local checkboxOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - checkboxHeightPx) / 2))
		local firstRowOffsetPx = 0
		local secondRowOffsetPx = rowStepPx
		local thirdRowOffsetPx = secondRowOffsetPx + rowStepPx
		local fourthRowOffsetPx = thirdRowOffsetPx + rowStepPx + sectionGapPx
		local fifthRowOffsetPx = fourthRowOffsetPx + rowStepPx

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.offsetXSlider:ClearAllPoints()
		controls.offsetXSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(firstRowOffsetPx))

		controls.offsetYSlider:ClearAllPoints()
		controls.offsetYSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(firstRowOffsetPx)
		)

		controls.iconSizeSlider:ClearAllPoints()
		controls.iconSizeSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(secondRowOffsetPx))

		controls.borderSizeSlider:ClearAllPoints()
		controls.borderSizeSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(thirdRowOffsetPx))

		controls.showStacksCheckbox:ClearAllPoints()
		controls.showStacksCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(fourthRowOffsetPx + checkboxOffsetPx)
		)

		controls.stacksFontSizeSlider:ClearAllPoints()
		controls.stacksFontSizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(fourthRowOffsetPx)
		)

		controls.showCooldownCheckbox:ClearAllPoints()
		controls.showCooldownCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(fifthRowOffsetPx + checkboxOffsetPx)
		)

		controls.cooldownFontSizeSlider:ClearAllPoints()
		controls.cooldownFontSizeSlider:SetPoint(
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
		local mode = addon.Options.State:GetMode()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults(mode)
		local widgets = section.widgets or {}
		local icons = widgets.icons or {}
		local bigDefensive = icons.bigDefensive or {}

		controls.offsetXSlider:SetValueSilently(bigDefensive.offsetX or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(bigDefensive.offsetY or defaults.offsetY)
		controls.iconSizeSlider:SetValueSilently(bigDefensive.iconSize or defaults.iconSize)
		controls.borderSizeSlider:SetValueSilently(bigDefensive.borderSizePx or defaults.borderSizePx)
		controls.showStacksCheckbox:SetChecked(ResolveBoolean(bigDefensive.showStacks, defaults.showStacks))
		controls.stacksFontSizeSlider:SetValueSilently(bigDefensive.stacksFontSize or defaults.stacksFontSize)
		controls.showCooldownCheckbox:SetChecked(ResolveBoolean(bigDefensive.showCooldown, defaults.showCooldown))
		controls.cooldownFontSizeSlider:SetValueSilently(bigDefensive.cooldownFontSize or defaults.cooldownFontSize)
	end

	subpage:UpdateLocale()

	return subpage
end
