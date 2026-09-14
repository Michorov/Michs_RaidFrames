local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}
addon.Options.Pages.Indicators.Threat = addon.Options.Pages.Indicators.Threat or {}

local Threat = addon.Options.Pages.Indicators.Threat

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

	return subpage
end
