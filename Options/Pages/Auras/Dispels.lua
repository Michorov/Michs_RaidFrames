local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.Dispels = addon.Options.Pages.Auras.Dispels or {}

local Dispels = addon.Options.Pages.Auras.Dispels

local anchorOptions = {
	{ value = "TOPLEFT", textKey = "Top Left" },
	{ value = "TOPRIGHT", textKey = "Top Right" },
	{ value = "BOTTOMLEFT", textKey = "Bottom Left" },
	{ value = "BOTTOMRIGHT", textKey = "Bottom Right" },
}

local gradientDirectionOptions = {
	{ value = 0, textKey = "Top" },
	{ value = 1, textKey = "Bottom" },
}

local textureOptions = {
	{ value = "Gradient", textKey = "Gradient" },
	{ value = "Flat", textKey = "Flat" },
}

local visibilityOptions = {
	{ value = true, textKey = "Show" },
	{ value = false, textKey = "Hide" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

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

	local overlayRow = subpage:CreateRow(4)
	overlayRow:SetLayoutPoint("TOPLEFT", settingsRow.frame, "BOTTOMLEFT", 0, -16)

	local overlayDropdown = overlayRow:CreateControl("Dropdown", { labelKey = "Dispel Overlay" })
	overlayDropdown:SetOptions(visibilityOptions)
	overlayDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.dispels.showOverlay ~= false
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.dispels.showOverlay = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("dispelsSettingsChanged")
		end,
	})

	local gradientDirectionRow = subpage:CreateRow(4)
	gradientDirectionRow:SetLayoutPoint("TOPLEFT", overlayRow.frame, "BOTTOMLEFT", 0, -16)

	local textureDropdown = gradientDirectionRow:CreateControl("Dropdown", { labelKey = "Texture" })
	textureDropdown:SetOptions(textureOptions)
	textureDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.dispels.texture or "Gradient"
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.dispels.texture = value
		end,
		onChange = function()
			page.panel:UpdateState()
			addon.UpdateScheduler:Notify("dispelsSettingsChanged")
		end,
	})

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

	local borderDropdown = gradientDirectionRow:CreateControl("Dropdown", { labelKey = "Border" })
	borderDropdown:SetOptions(visibilityOptions)
	borderDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.dispels.showBorder ~= false
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.dispels.showBorder = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("dispelsSettingsChanged")
		end,
	})

	local iconsRow = subpage:CreateRow(4)
	iconsRow:SetLayoutPoint("TOPLEFT", gradientDirectionRow.frame, "BOTTOMLEFT", 0, -16)

	local iconsDropdown = iconsRow:CreateControl("Dropdown", { labelKey = "Dispel Icons" })
	iconsDropdown:SetOptions(visibilityOptions)
	iconsDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.dispels.showIcons ~= false
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.dispels.showIcons = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("dispelsSettingsChanged")
		end,
	})

	local iconsPositionDropdown = iconsRow:CreateControl("Dropdown", { labelKey = "Icons position" })
	iconsPositionDropdown:SetOptions(anchorOptions)
	iconsPositionDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.dispels.anchor or "TOPRIGHT"
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.dispels.anchor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("dispelsSettingsChanged")
		end,
	})

	local iconSizeSlider = iconsRow:CreateControl("Slider", { labelKey = "Icon Size" })
	iconSizeSlider:SetMinMaxValues(8, 128)
	iconSizeSlider:SetStep(1)
	iconSizeSlider:SetValueFormatter(FormatInteger)
	iconSizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.icons.dispels.iconSize or 14
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.icons.dispels.iconSize = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("dispelsSettingsChanged")
		end,
	})

	subpage:SetStateUpdater(function(profile, mode)
		local showGradientSettings = (profile[mode].widgets.icons.dispels.texture or "Gradient") == "Gradient"
		gradientDirectionDropdown:SetShown(showGradientSettings)
		borderDropdown:SetShown(showGradientSettings)
	end)

	return subpage
end
