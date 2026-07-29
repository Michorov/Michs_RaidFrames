local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}
addon.Options.Pages.Indicators.Threat = addon.Options.Pages.Indicators.Threat or {}

local Threat = addon.Options.Pages.Indicators.Threat

local function FormatInteger(value)
	return string.format("%d", value)
end

function Threat:Create(page)
	local subpage = page:RegisterSubPage("threat", { titleKey = "Threat" })

	local settingsRow = subpage:CreateRow(4)
	settingsRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local enabledSlot = settingsRow:CreateCheckboxSlot("top")
	local enabledCheckbox = enabledSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.threat.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.threat.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("threatSettingsChanged")
		end,
	})

	local sizeRow = subpage:CreateRow(4)
	sizeRow:SetLayoutPoint("TOPLEFT", settingsRow.frame, "BOTTOMLEFT", 0, 0)

	local borderSizeSlider = sizeRow:CreateControl("Slider", { labelKey = "Size" })
	borderSizeSlider:SetMinMaxValues(1, 8)
	borderSizeSlider:SetStep(1)
	borderSizeSlider:SetValueFormatter(FormatInteger)
	borderSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.threat.borderSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.threat.borderSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("threatSettingsChanged")
		end,
	})

	return subpage
end
