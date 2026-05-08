local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}
addon.Options.Pages.Bars.Power = addon.Options.Pages.Bars.Power or {}

local Power = addon.Options.Pages.Bars.Power

local subpage
local L = addon.L

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
			enabled = true,
			healerOnly = false,
			height = 6,
			borderThickness = 1,
		}
	end

	return {
		enabled = true,
		healerOnly = false,
		height = 8,
		borderThickness = 1,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Power settings are disabled during combat."])
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

function Power:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Enabled"])
	subpage.enabledCheckbox:SetLayoutWidth(174)
	subpage.enabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.power = section.power or {}
			section.power.enabled = checked == true
		end, "powerSettingsChanged")
	end)

	subpage.healerOnlyCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Healers Only"])
	subpage.healerOnlyCheckbox:SetLayoutWidth(174)
	subpage.healerOnlyCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.power = section.power or {}
			section.power.healerOnly = checked == true
		end, "powerSettingsChanged")
	end)

	subpage.heightSlider = addon.Options.Controls.Slider:Create(subpage, L["Height"])
	subpage.heightSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.heightSlider, 1, 20, 1)
	subpage.heightSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.power = section.power or {}
			section.power.height = value
		end, "powerSettingsChanged")
	end)

	subpage.borderThicknessSlider = addon.Options.Controls.Slider:Create(subpage, L["Border Size"])
	subpage.borderThicknessSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.borderThicknessSlider, 0, 6, 1)
	subpage.borderThicknessSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.power = section.power or {}
			section.power.borderThicknessPx = value
		end, "powerSettingsChanged")
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		healerOnlyCheckbox = subpage.healerOnlyCheckbox,
		heightSlider = subpage.heightSlider,
		borderThicknessSlider = subpage.borderThicknessSlider,
	}

	function subpage:UpdateLocale()
		self.enabledCheckbox:SetText(L["Enabled"])
		self.healerOnlyCheckbox:SetText(L["Healers Only"])
		self.heightSlider:SetLabel(L["Height"])
		self.borderThicknessSlider:SetLabel(L["Border Size"])
	end

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(50)
		local columnGapPx = addon.Utilities:ToPixels(30)
		local threeColumnSlotWidthPx = addon.Utilities:ToPixels(174)
		local threeColumnSecondOffsetPx = threeColumnSlotWidthPx + columnGapPx
		local sliderHeightPx = addon.Utilities:ToPixels(34)
		local checkboxHeightPx = addon.Utilities:ToPixels(controls.enabledCheckbox.layoutValues.height)
		local checkboxOffsetPx = addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - checkboxHeightPx) / 2))

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.enabledCheckbox:ClearAllPoints()
		controls.enabledCheckbox:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(checkboxOffsetPx))

		controls.healerOnlyCheckbox:ClearAllPoints()
		controls.healerOnlyCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(checkboxOffsetPx)
		)

		controls.heightSlider:ClearAllPoints()
		controls.heightSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(rowStepPx))

		controls.borderThicknessSlider:ClearAllPoints()
		controls.borderThicknessSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(rowStepPx)
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
		local power = section.power or {}
		local enabled = power.enabled
		local healerOnly = power.healerOnly

		if enabled == nil then
			enabled = defaults.enabled
		end

		if healerOnly == nil then
			healerOnly = defaults.healerOnly
		end

		controls.enabledCheckbox:SetChecked(enabled == true)
		controls.healerOnlyCheckbox:SetChecked(healerOnly == true)
		controls.heightSlider:SetValueSilently(power.height or defaults.height)
		controls.borderThicknessSlider:SetValueSilently(power.borderThicknessPx or defaults.borderThickness)
	end

	subpage:UpdateLocale()

	return subpage
end
