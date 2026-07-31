local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}
addon.Options.Pages.Bars.Power = addon.Options.Pages.Bars.Power or {}

local Power = addon.Options.Pages.Bars.Power

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

	local sliderRow = subpage:CreateRow(4)
	sliderRow:SetLayoutPoint("TOPLEFT", textureRow.frame, "BOTTOMLEFT", 0, -16)

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

	subpage:SetStateUpdater(function(profile, mode)
		local settings = profile[mode].power
		textureDropdown:SetOptions(addon.Styles.Textures:GetOptions(settings.lsmTexture, true))
	end)

	return subpage
end
