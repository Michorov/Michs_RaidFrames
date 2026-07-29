local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Bars = addon.OptionsNew.Pages.Bars or {}
addon.OptionsNew.Pages.Bars.Power = addon.OptionsNew.Pages.Bars.Power or {}

local Power = addon.OptionsNew.Pages.Bars.Power

local function FormatInteger(value)
	return string.format("%d", value)
end

function Power:Create(page)
	local subpage = page:RegisterSubPage("power", { titleKey = "Power" })

	local checkboxRow = subpage:CreateRow(2)
	checkboxRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local checkboxSlot = checkboxRow:CreateCheckboxSlot()

	local enabledCheckbox = checkboxSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].power.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].power.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerSettingsChanged")
		end,
	})

	local healerOnlyCheckbox = checkboxSlot:CreateControl("Checkbox", { labelKey = "Healers Only" })
	healerOnlyCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].power.healerOnly
		end,
		set = function(profile, mode, value)
			profile[mode].power.healerOnly = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerSettingsChanged")
		end,
	})

	local sliderRow = subpage:CreateRow(4)
	sliderRow:SetLayoutPoint("TOPLEFT", checkboxRow.frame, "BOTTOMLEFT", 0, -24)

	local heightSlider = sliderRow:CreateControl("Slider", { labelKey = "Height" })
	heightSlider:SetMinMaxValues(1, 20)
	heightSlider:SetStep(1)
	heightSlider:SetValueFormatter(FormatInteger)
	heightSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].power.height
		end,
		set = function(profile, mode, value)
			profile[mode].power.height = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerSettingsChanged")
		end,
	})

	local borderThicknessSlider = sliderRow:CreateControl("Slider", { labelKey = "Border Size" })
	borderThicknessSlider:SetMinMaxValues(0, 6)
	borderThicknessSlider:SetStep(1)
	borderThicknessSlider:SetValueFormatter(FormatInteger)
	borderThicknessSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].power.borderThicknessPx
		end,
		set = function(profile, mode, value)
			profile[mode].power.borderThicknessPx = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerSettingsChanged")
		end,
	})

	return subpage
end
