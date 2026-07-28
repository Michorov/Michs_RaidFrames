local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Layout = addon.OptionsNew.Pages.Layout or {}

local Layout = addon.OptionsNew.Pages.Layout
local L = addon.L

local function FormatInteger(value)
	return string.format("%d", value)
end

function Layout:Create(panel, config)
	config = config or {}

	local page = panel:RegisterPage("layout", {
		title = L["Layout"],
		showHeader = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
		showHeaderButton = true,
		headerButtonText = config.headerButtonText,
		headerButtonCallback = config.headerButtonCallback,
	})
	local subpage = page:RegisterSubPage("layout", { title = L["Layout"] })

	local positionRow = subpage:CreateRow(3)
	positionRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local horizontalPositionSlider = positionRow:CreateControl("Slider", L["Horizontal Position"])
	horizontalPositionSlider:SetMinMaxValues(-2000, 2000)
	horizontalPositionSlider:SetStep(1)
	horizontalPositionSlider:SetValueFormatter(FormatInteger)
	horizontalPositionSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].position.x
		end,
		set = function(profile, mode, value)
			profile[mode].position.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local verticalPositionSlider = positionRow:CreateControl("Slider", L["Vertical Position"])
	verticalPositionSlider:SetMinMaxValues(-2000, 2000)
	verticalPositionSlider:SetStep(1)
	verticalPositionSlider:SetValueFormatter(FormatInteger)
	verticalPositionSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].position.y
		end,
		set = function(profile, mode, value)
			profile[mode].position.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local spacingRow = subpage:CreateRow(3)
	spacingRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -6)

	local horizontalSpacingSlider = spacingRow:CreateControl("Slider", L["Horizontal Spacing"])
	horizontalSpacingSlider:SetMinMaxValues(-25, 25)
	horizontalSpacingSlider:SetStep(1)
	horizontalSpacingSlider:SetValueFormatter(FormatInteger)
	horizontalSpacingSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].spacing.x
		end,
		set = function(profile, mode, value)
			profile[mode].spacing.x = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local verticalSpacingSlider = spacingRow:CreateControl("Slider", L["Vertical Spacing"])
	verticalSpacingSlider:SetMinMaxValues(-25, 25)
	verticalSpacingSlider:SetStep(1)
	verticalSpacingSlider:SetValueFormatter(FormatInteger)
	verticalSpacingSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].spacing.y
		end,
		set = function(profile, mode, value)
			profile[mode].spacing.y = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	return page
end
