local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.BigDefensive = addon.Options.Pages.Auras.BigDefensive or {}

local BigDefensive = addon.Options.Pages.Auras.BigDefensive

local visibilityOptions = {
	{ value = true, textKey = "Show" },
	{ value = false, textKey = "Hide" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

function BigDefensive:Create(page)
	local subpage = page:RegisterSubPage("bigDefensive", { titleKey = "Big Defensive" })

	local positionRow = subpage:CreateRow(4)
	positionRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local offsetXSlider = positionRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-300, 300)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.bigDefensive.offsetX
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.bigDefensive.offsetX = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
		end,
	})

	local offsetYSlider = positionRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-300, 300)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.bigDefensive.offsetY
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.bigDefensive.offsetY = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
		end,
	})

	local iconRow = subpage:CreateRow(4)
	iconRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -16)

	local iconSizeSlider = iconRow:CreateControl("Slider", { labelKey = "Icon Size" })
	iconSizeSlider:SetMinMaxValues(8, 128)
	iconSizeSlider:SetStep(1)
	iconSizeSlider:SetValueFormatter(FormatInteger)
	iconSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.bigDefensive.iconSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.bigDefensive.iconSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
		end,
	})

	local borderRow = subpage:CreateRow(4)
	borderRow:SetLayoutPoint("TOPLEFT", iconRow.frame, "BOTTOMLEFT", 0, -16)

	local borderSizeSlider = borderRow:CreateControl("Slider", { labelKey = "Border Size" })
	borderSizeSlider:SetMinMaxValues(0, 6)
	borderSizeSlider:SetStep(1)
	borderSizeSlider:SetValueFormatter(FormatInteger)
	borderSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.bigDefensive.borderSizePx
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.bigDefensive.borderSizePx = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
		end,
	})

	local stacksRow = subpage:CreateRow(4)
	stacksRow:SetLayoutPoint("TOPLEFT", borderRow.frame, "BOTTOMLEFT", 0, -16)

	local showStacksDropdown = stacksRow:CreateControl("Dropdown", { labelKey = "Stacks" })
	showStacksDropdown:SetOptions(visibilityOptions)
	showStacksDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.bigDefensive.showStacks
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.bigDefensive.showStacks = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
		end,
	})

	local stacksFontSizeSlider = stacksRow:CreateControl("Slider", { labelKey = "Stacks Size" })
	stacksFontSizeSlider:SetMinMaxValues(6, 32)
	stacksFontSizeSlider:SetStep(1)
	stacksFontSizeSlider:SetValueFormatter(FormatInteger)
	stacksFontSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.bigDefensive.stacksFontSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.bigDefensive.stacksFontSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
		end,
	})

	local cooldownRow = subpage:CreateRow(4)
	cooldownRow:SetLayoutPoint("TOPLEFT", stacksRow.frame, "BOTTOMLEFT", 0, -16)

	local showCooldownDropdown = cooldownRow:CreateControl("Dropdown", { labelKey = "Duration" })
	showCooldownDropdown:SetOptions(visibilityOptions)
	showCooldownDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.bigDefensive.showCooldown
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.bigDefensive.showCooldown = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
		end,
	})

	local cooldownFontSizeSlider = cooldownRow:CreateControl("Slider", { labelKey = "Duration Size" })
	cooldownFontSizeSlider:SetMinMaxValues(6, 32)
	cooldownFontSizeSlider:SetStep(1)
	cooldownFontSizeSlider:SetValueFormatter(FormatInteger)
	cooldownFontSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.bigDefensive.cooldownFontSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.bigDefensive.cooldownFontSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("bigDefensiveAurasSettingsChanged")
		end,
	})

	return subpage
end
