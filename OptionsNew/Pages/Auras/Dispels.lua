local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Auras = addon.OptionsNew.Pages.Auras or {}
addon.OptionsNew.Pages.Auras.Dispels = addon.OptionsNew.Pages.Auras.Dispels or {}

local Dispels = addon.OptionsNew.Pages.Auras.Dispels

local gradientDirectionOptions = {
	{ value = 0, textKey = "Top" },
	{ value = 1, textKey = "Bottom" },
}

function Dispels:Create(page)
	local subpage = page:RegisterSubPage("dispels", { titleKey = "Dispels" })

	local settingsRow = subpage:CreateRow(2)
	settingsRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local checkboxSlot = settingsRow:CreateCheckboxSlot("top")
	local enabledCheckbox = checkboxSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.dispels.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.dispels.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("dispelsSettingsChanged")
			addon.UpdateScheduler:Notify("aurasStateChanged")
		end,
	})

	local showOnlyPlayerDispellableCheckbox =
		checkboxSlot:CreateControl("Checkbox", { labelKey = "Only Dispellable By Me" })
	showOnlyPlayerDispellableCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.dispels.showOnlyPlayerDispellable
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.dispels.showOnlyPlayerDispellable = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("dispelsSettingsChanged")
		end,
	})

	local gradientDirectionRow = subpage:CreateRow(4)
	gradientDirectionRow:SetLayoutPoint("TOPLEFT", settingsRow.frame, "BOTTOMLEFT", 0, -16)

	local gradientDirectionDropdown = gradientDirectionRow:CreateControl("Dropdown", { labelKey = "Start Gradient From" })
	gradientDirectionDropdown:SetOptions(gradientDirectionOptions)
	gradientDirectionDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.dispels.gradientDirection
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.dispels.gradientDirection = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("dispelsSettingsChanged")
		end,
	})

	return subpage
end
