local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}
addon.Options.Pages.Indicators.HealPrediction = addon.Options.Pages.Indicators.HealPrediction or {}

local HealPrediction = addon.Options.Pages.Indicators.HealPrediction

function HealPrediction:Create(page)
	local subpage = page:RegisterSubPage("healPrediction", { titleKey = "Heal Prediction" })
	local row = subpage:CreateRow(4)
	row:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local checkboxSlot = row:CreateCheckboxSlot()
	local enabled = checkboxSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabled:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.healPrediction.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.healPrediction.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healPredictionSettingsChanged")
		end,
	})

	local color = row:CreateControl("ColorPicker", { labelKey = "Color" })
	color:SetHasOpacity(true)
	color:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.indicators.healPrediction.color
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.indicators.healPrediction.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healPredictionSettingsChanged")
		end,
	})

	return subpage
end
