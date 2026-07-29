local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Auras = addon.OptionsNew.Pages.Auras or {}
addon.OptionsNew.Pages.Auras.Buffs = addon.OptionsNew.Pages.Auras.Buffs or {}

local Buffs = addon.OptionsNew.Pages.Auras.Buffs
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

function Buffs:Create(page)
	local subpage = page:RegisterSubPage("buffs", { titleKey = "Buffs" })

	local topRow = subpage:CreateRow(2)
	topRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local topSlot = topRow:CreateCheckboxSlot("top")
	local enabledCheckbox = topSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
	enabledCheckbox:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.enabled
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.enabled = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
			addon.UpdateScheduler:Notify("aurasStateChanged")
		end,
	})

	local secondaryCheckbox = topSlot:CreateControl("Checkbox", {
		labelKey = isRestrictedAuraAPI and "Show Tooltips" or "Show External Buffs",
	})
	secondaryCheckbox:BindValue({
		get = function(profile, mode)
			if isRestrictedAuraAPI then
				return profile[mode].widgets.icons.buffs.showTooltips
			end

			return profile[mode].widgets.icons.buffs.showExternals
		end,
		set = function(profile, mode, value)
			if isRestrictedAuraAPI then
				profile[mode].widgets.icons.buffs.showTooltips = value
			else
				profile[mode].widgets.icons.buffs.showExternals = value
			end
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local positionRow = subpage:CreateRow(4)
	positionRow:SetLayoutPoint("TOPLEFT", topRow.frame, "BOTTOMLEFT", 0, -16)

	local anchorDropdown = positionRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local offsetXSlider = positionRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-300, 300)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.offsetX
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.offsetX = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local offsetYSlider = positionRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-300, 300)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.offsetY
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.offsetY = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local spacingSlider = positionRow:CreateControl("Slider", { labelKey = "Spacing" })
	spacingSlider:SetMinMaxValues(-10, 20)
	spacingSlider:SetStep(1)
	spacingSlider:SetValueFormatter(FormatInteger)
	spacingSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.spacing
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.spacing = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
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
			return profile[mode].widgets.icons.buffs.maxIcons
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.maxIcons = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local iconsPerRowSlider = iconRow:CreateControl("Slider", { labelKey = "Icons Per Row" })
	iconsPerRowSlider:SetMinMaxValues(1, 10)
	iconsPerRowSlider:SetStep(1)
	iconsPerRowSlider:SetValueFormatter(FormatInteger)
	iconsPerRowSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.iconsPerRow
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.iconsPerRow = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local iconSizeSlider = iconRow:CreateControl("Slider", { labelKey = "Icon Size" })
	iconSizeSlider:SetMinMaxValues(8, 64)
	iconSizeSlider:SetStep(1)
	iconSizeSlider:SetValueFormatter(FormatInteger)
	iconSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.iconSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.iconSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local borderSizeSlider = iconRow:CreateControl("Slider", { labelKey = "Border Size" })
	borderSizeSlider:SetMinMaxValues(0, 4)
	borderSizeSlider:SetStep(1)
	borderSizeSlider:SetValueFormatter(FormatInteger)
	borderSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.borderSizePx
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.borderSizePx = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local stacksRow = subpage:CreateRow(4)
	stacksRow:SetLayoutPoint("TOPLEFT", iconRow.frame, "BOTTOMLEFT", 0, -16)

	local showStacksDropdown = stacksRow:CreateControl("Dropdown", { labelKey = "Show Stacks" })
	showStacksDropdown:SetOptions(visibilityOptions)
	showStacksDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.showStacks
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.showStacks = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local stacksFontSizeSlider = stacksRow:CreateControl("Slider", { labelKey = "Stacks Size" })
	stacksFontSizeSlider:SetMinMaxValues(6, 32)
	stacksFontSizeSlider:SetStep(1)
	stacksFontSizeSlider:SetValueFormatter(FormatInteger)
	stacksFontSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.stacksFontSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.stacksFontSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local cooldownRow = subpage:CreateRow(4)
	cooldownRow:SetLayoutPoint("TOPLEFT", stacksRow.frame, "BOTTOMLEFT", 0, -16)

	local showCooldownDropdown = cooldownRow:CreateControl("Dropdown", { labelKey = "Show Duration" })
	showCooldownDropdown:SetOptions(visibilityOptions)
	showCooldownDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.showCooldown
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.showCooldown = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	local cooldownFontSizeSlider = cooldownRow:CreateControl("Slider", { labelKey = "Duration Size" })
	cooldownFontSizeSlider:SetMinMaxValues(6, 32)
	cooldownFontSizeSlider:SetStep(1)
	cooldownFontSizeSlider:SetValueFormatter(FormatInteger)
	cooldownFontSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.buffs.cooldownFontSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.buffs.cooldownFontSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
		end,
	})

	return subpage
end
