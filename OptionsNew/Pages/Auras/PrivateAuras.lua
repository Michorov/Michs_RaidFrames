local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Auras = addon.OptionsNew.Pages.Auras or {}
addon.OptionsNew.Pages.Auras.PrivateAuras = addon.OptionsNew.Pages.Auras.PrivateAuras or {}

local PrivateAuras = addon.OptionsNew.Pages.Auras.PrivateAuras

local anchorOptions = {
	{ value = "LEFT", textKey = "Left" },
	{ value = "RIGHT", textKey = "Right" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

function PrivateAuras:Create(page)
	local subpage = page:RegisterSubPage("privateAuras", { titleKey = "Private Auras" })

	local anchorRow = subpage:CreateRow(4)
	anchorRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local anchorDropdown = anchorRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)
	anchorDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.privateAuras.anchor
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.privateAuras.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
		end,
	})

	local offsetXSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-200, 200)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)
	offsetXSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.privateAuras.offsetX
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.privateAuras.offsetX = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
		end,
	})

	local offsetYSlider = anchorRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-200, 200)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)
	offsetYSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.privateAuras.offsetY
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.privateAuras.offsetY = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
		end,
	})

	local iconRow = subpage:CreateRow(4)
	iconRow:SetLayoutPoint("TOPLEFT", anchorRow.frame, "BOTTOMLEFT", 0, -16)

	local maxIconsSlider = iconRow:CreateControl("Slider", { labelKey = "Max Icons" })
	maxIconsSlider:SetMinMaxValues(1, 10)
	maxIconsSlider:SetStep(1)
	maxIconsSlider:SetValueFormatter(FormatInteger)
	maxIconsSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.privateAuras.maxIcons
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.privateAuras.maxIcons = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
		end,
	})

	local iconSizeSlider = iconRow:CreateControl("Slider", { labelKey = "Icon Size" })
	iconSizeSlider:SetMinMaxValues(8, 64)
	iconSizeSlider:SetStep(1)
	iconSizeSlider:SetValueFormatter(FormatInteger)
	iconSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.privateAuras.iconSize
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.privateAuras.iconSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
		end,
	})

	local spacingSlider = iconRow:CreateControl("Slider", { labelKey = "Spacing" })
	spacingSlider:SetMinMaxValues(0, 20)
	spacingSlider:SetStep(1)
	spacingSlider:SetValueFormatter(FormatInteger)
	spacingSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.privateAuras.spacing
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.privateAuras.spacing = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
		end,
	})

	return subpage
end
