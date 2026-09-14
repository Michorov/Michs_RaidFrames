local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}
addon.Options.Pages.Indicators.Mouseover = addon.Options.Pages.Indicators.Mouseover or {}

local Mouseover = addon.Options.Pages.Indicators.Mouseover

function Mouseover:Create(page)
	local subpage = page:RegisterSubPage("mouseover", { titleKey = "Mouseover" })

	local settingsRow = subpage:CreateRow(4)
	settingsRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local enabledSlot = settingsRow:CreateCheckboxSlot("top")
	local enabledCheckbox = enabledSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.mouseover.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.mouseover.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("mouseoverSettingsChanged")
		end,
	})

	local colorRow = subpage:CreateRow(4)
	colorRow:SetLayoutPoint("TOPLEFT", settingsRow.frame, "BOTTOMLEFT", 0, 0)

	local colorPicker = colorRow:CreateControl("ColorPicker", { labelKey = "Color" })
	colorPicker:SetHasOpacity(false)
	colorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.mouseover.color
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.mouseover.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("mouseoverSettingsChanged")
		end,
	})

	return subpage
end
