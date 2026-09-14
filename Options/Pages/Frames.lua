local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Frames = addon.Options.Pages.Frames or {}

local Frames = addon.Options.Pages.Frames

local visibilityOptions = {
	{ value = 1, textKey = "Show" },
	{ value = 0, textKey = "Hide" },
}

local function FormatInteger(value)
	return string.format("%d", value)
end

function Frames:Create(panel, config)
	config = config or {}

	local page = panel:RegisterPage("frames", {
		titleKey = "Frames",
		showHeader = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
		showHeaderButton = true,
		headerButtonText = config.headerButtonText,
		headerButtonCallback = config.headerButtonCallback,
	})
	local subpage = page:RegisterSubPage("frames", { titleKey = "Frames" })

	local frameRow = subpage:CreateRow(4)
	frameRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local frameWidthSlider = frameRow:CreateControl("Slider", { labelKey = "Frame Width" })
	frameWidthSlider:SetMinMaxValues(25, 200)
	frameWidthSlider:SetStep(1)
	frameWidthSlider:SetValueFormatter(FormatInteger)
	frameWidthSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].size.width
		end,
		set = function(profile, mode, value)
			profile[mode].size.width = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local frameHeightSlider = frameRow:CreateControl("Slider", { labelKey = "Frame Height" })
	frameHeightSlider:SetMinMaxValues(25, 200)
	frameHeightSlider:SetStep(1)
	frameHeightSlider:SetValueFormatter(FormatInteger)
	frameHeightSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].size.height
		end,
		set = function(profile, mode, value)
			profile[mode].size.height = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local backgroundColorPicker = frameRow:CreateControl("ColorPicker", { labelKey = "Background Color" })
	backgroundColorPicker:SetHasOpacity(true)
	backgroundColorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].background.color
		end,
		set = function(profile, mode, value)
			profile[mode].background.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("backgroundSettingsChanged")
		end,
	})

	local borderRow = subpage:CreateRow(4)
	borderRow:SetLayoutPoint("TOPLEFT", frameRow.frame, "BOTTOMLEFT", 0, -8)

	local borderDropdown = borderRow:CreateControl("Dropdown", { labelKey = "Border" })
	borderDropdown:SetOptions(visibilityOptions)
	borderDropdown:BindValue({
		get = function(profile, mode)
			return (profile[mode].border.thicknessPx or 1) > 0 and 1 or 0
		end,
		set = function(profile, mode, value)
			profile[mode].border.thicknessPx = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("borderSettingsChanged")
		end,
	})

	local borderColorPicker = borderRow:CreateControl("ColorPicker", { labelKey = "Border Color" })
	borderColorPicker:SetHasOpacity(true)
	borderColorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].border.color
		end,
		set = function(profile, mode, value)
			profile[mode].border.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("borderSettingsChanged")
		end,
	})

	return page
end
