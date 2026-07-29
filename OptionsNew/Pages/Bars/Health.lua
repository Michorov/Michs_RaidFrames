local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Bars = addon.OptionsNew.Pages.Bars or {}
addon.OptionsNew.Pages.Bars.Health = addon.OptionsNew.Pages.Bars.Health or {}

local Health = addon.OptionsNew.Pages.Bars.Health

function Health:Create(page)
	local subpage = page:RegisterSubPage("health", { titleKey = "Health" })

	local row = subpage:CreateRow(4)
	row:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local useClassColorCheckbox = row:CreateControl("Checkbox", { labelKey = "Use Class Color" })
	useClassColorCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].health.classColor
		end,
		set = function(profile, mode, value)
			profile[mode].health.classColor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthSettingsChanged")
		end,
	})

	local healthColorPicker = row:CreateControl("ColorPicker", { labelKey = "Health Color" })
	healthColorPicker:SetHasOpacity(true)
	healthColorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].health.color
		end,
		set = function(profile, mode, value)
			profile[mode].health.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthSettingsChanged")
		end,
	})

	return subpage
end
