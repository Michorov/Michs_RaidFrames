local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}
addon.Options.Pages.Bars.Power = addon.Options.Pages.Bars.Power or {}

local Power = addon.Options.Pages.Bars.Power

local visibilityOptions = {
	{ value = 1, textKey = "Show" },
	{ value = 0, textKey = "Hide" },
}

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

	local textureRow = subpage:CreateRow(4)
	textureRow:SetLayoutPoint("TOPLEFT", checkboxRow.frame, "BOTTOMLEFT", 0, -16)

	local textureDropdown = textureRow:CreateControl("Dropdown", { labelKey = "Texture" })
	textureDropdown:SetOptions(addon.Styles.Textures:GetOptions(nil, true))
	textureDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].power.lsmTexture
		end,
		set = function(profile, mode, value)
			profile[mode].power.lsmTexture = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerSettingsChanged")
		end,
	})

	local borderRow = subpage:CreateRow(4)
	borderRow:SetLayoutPoint("TOPLEFT", textureRow.frame, "BOTTOMLEFT", 0, -16)

	local borderDropdown = borderRow:CreateControl("Dropdown", { labelKey = "Border" })
	borderDropdown:SetOptions(visibilityOptions)
	borderDropdown:BindValue({
		get = function(profile, mode)
			return (profile[mode].power.borderThicknessPx or 1) > 0 and 1 or 0
		end,
		set = function(profile, mode, value)
			profile[mode].power.borderThicknessPx = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("powerSettingsChanged")
		end,
	})

	local heightRow = subpage:CreateRow(4)
	heightRow:SetLayoutPoint("TOPLEFT", borderRow.frame, "BOTTOMLEFT", 0, -16)

	local heightSlider = heightRow:CreateControl("Slider", { labelKey = "Height" })
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

	subpage:SetStateUpdater(function(profile, mode)
		local settings = profile[mode].power
		textureDropdown:SetOptions(addon.Styles.Textures:GetOptions(settings.lsmTexture, true))
	end)

	return subpage
end
