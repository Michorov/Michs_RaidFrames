local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.Debuffs = addon.Options.Pages.Auras.Debuffs or {}

local Debuffs = addon.Options.Pages.Auras.Debuffs
local _, _, _, interfaceVersion = GetBuildInfo()
local isRestrictedAuraAPI = (tonumber(interfaceVersion) or 0) >= 120100

local anchorOptions = {
	{ value = "TOPLEFT", textKey = "Top Left" },
	{ value = "TOPRIGHT", textKey = "Top Right" },
	{ value = "BOTTOMLEFT", textKey = "Bottom Left" },
	{ value = "BOTTOMRIGHT", textKey = "Bottom Right" },
}

local visibilityOptions = {
	{ value = true, textKey = "Show" },
	{ value = false, textKey = "Hide" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

function Debuffs:Create(page)
	local subpage = page:RegisterSubPage("debuffs", { titleKey = "Debuffs" })

	local topRow = subpage:CreateRow(2)
	topRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local topSlot = topRow:CreateCheckboxSlot("top")
	local enabledCheckbox = topSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
			addon.UpdateScheduler:Notify("aurasStateChanged")
		end,
	})

	local secondaryCheckbox = topSlot:CreateControl("Checkbox", {
		labelKey = isRestrictedAuraAPI and "Show Tooltips" or "Color By Debuff Type",
	})
	secondaryCheckbox:BindValue({
		get = function(profile, mode)
			if isRestrictedAuraAPI then
				return profile[mode].widgets.icons.debuffs.showTooltips
			end

			return profile[mode].widgets.icons.debuffs.borderColorByDebuffType
		end,
		set = function(profile, mode, value)
			if isRestrictedAuraAPI then
				profile[mode].widgets.icons.debuffs.showTooltips = value
			else
				profile[mode].widgets.icons.debuffs.borderColorByDebuffType = value
			end
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local positionRow = subpage:CreateRow(4)
	positionRow:SetLayoutPoint("TOPLEFT", topRow.frame, "BOTTOMLEFT", 0, -16)

	local anchorDropdown = positionRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local offsetXSlider = positionRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-300, 300)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.offsetX
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.offsetX = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local offsetYSlider = positionRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-300, 300)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.offsetY
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.offsetY = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local spacingSlider = positionRow:CreateControl("Slider", { labelKey = "Spacing" })
	spacingSlider:SetMinMaxValues(-10, 20)
	spacingSlider:SetStep(1)
	spacingSlider:SetValueFormatter(FormatInteger)
	spacingSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.spacing
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.spacing = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local iconRow = subpage:CreateRow(4)
	iconRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -16)

	local maxIconsSlider = iconRow:CreateControl("Slider", { labelKey = "Max Icons" })
	maxIconsSlider:SetMinMaxValues(1, 10)
	maxIconsSlider:SetStep(1)
	maxIconsSlider:SetValueFormatter(FormatInteger)
	maxIconsSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.maxIcons
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.maxIcons = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local iconsPerRowSlider = iconRow:CreateControl("Slider", { labelKey = "Icons Per Row" })
	iconsPerRowSlider:SetMinMaxValues(1, 10)
	iconsPerRowSlider:SetStep(1)
	iconsPerRowSlider:SetValueFormatter(FormatInteger)
	iconsPerRowSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.iconsPerRow
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.iconsPerRow = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local iconSizeSlider = iconRow:CreateControl("Slider", { labelKey = "Icon Size" })
	iconSizeSlider:SetMinMaxValues(8, 64)
	iconSizeSlider:SetStep(1)
	iconSizeSlider:SetValueFormatter(FormatInteger)
	iconSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.iconSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.iconSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local borderSizeSlider = iconRow:CreateControl("Slider", { labelKey = "Border Size" })
	borderSizeSlider:SetMinMaxValues(0, 4)
	borderSizeSlider:SetStep(1)
	borderSizeSlider:SetValueFormatter(FormatInteger)
	borderSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.borderSizePx
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.borderSizePx = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local stacksRow = subpage:CreateRow(4)
	stacksRow:SetLayoutPoint("TOPLEFT", iconRow.frame, "BOTTOMLEFT", 0, -16)

	local showStacksDropdown = stacksRow:CreateControl("Dropdown", { labelKey = "Show Stacks" })
	showStacksDropdown:SetOptions(visibilityOptions)
	showStacksDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.showStacks
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.showStacks = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local stacksFontSizeSlider = stacksRow:CreateControl("Slider", { labelKey = "Stacks Size" })
	stacksFontSizeSlider:SetMinMaxValues(6, 32)
	stacksFontSizeSlider:SetStep(1)
	stacksFontSizeSlider:SetValueFormatter(FormatInteger)
	stacksFontSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.stacksFontSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.stacksFontSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local cooldownRow = subpage:CreateRow(4)
	cooldownRow:SetLayoutPoint("TOPLEFT", stacksRow.frame, "BOTTOMLEFT", 0, -16)

	local showCooldownDropdown = cooldownRow:CreateControl("Dropdown", { labelKey = "Show Duration" })
	showCooldownDropdown:SetOptions(visibilityOptions)
	showCooldownDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.showCooldown
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.showCooldown = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	local cooldownFontSizeSlider = cooldownRow:CreateControl("Slider", { labelKey = "Duration Size" })
	cooldownFontSizeSlider:SetMinMaxValues(6, 32)
	cooldownFontSizeSlider:SetStep(1)
	cooldownFontSizeSlider:SetValueFormatter(FormatInteger)
	cooldownFontSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.debuffs.cooldownFontSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.debuffs.cooldownFontSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("debuffAurasSettingsChanged")
		end,
	})

	return subpage
end
