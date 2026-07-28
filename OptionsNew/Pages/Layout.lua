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
	spacingRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -8)

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

	local orientationRow = subpage:CreateRow(3)
	orientationRow:SetLayoutPoint("TOPLEFT", spacingRow.frame, "BOTTOMLEFT", 0, -16)

	local orientationDropdown = orientationRow:CreateControl("Dropdown", L["Orientation"])
	orientationDropdown:SetOptions({
		{ value = "HORIZONTAL", text = L["Horizontal"] },
		{ value = "VERTICAL", text = L["Vertical"] },
	})
	orientationDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].direction
		end,
		set = function(profile, mode, value)
			profile[mode].direction = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local reverseSlot = orientationRow:CreateCheckboxSlot()
	local reverseGroupOrderCheckbox = reverseSlot:CreateControl("Checkbox", L["Reverse Group Order"])
	reverseGroupOrderCheckbox:BindValue({
		get = function(profile)
			return profile.raid.reverse
		end,
		set = function(profile, _, value)
			profile.raid.reverse = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local raidGroupCheckboxes = {}
	for groupIndex = 1, 8 do
		local checkbox = subpage:CreateControl("Checkbox", (L["Group %d"]):format(groupIndex))
		local rowIndex = math.floor((groupIndex - 1) / 4)
		local rowColumnIndex = (groupIndex - 1) % 4
		local columnIndex = math.floor(rowColumnIndex / 2)
		local subColumnIndex = rowColumnIndex % 2
		local columnStartX = columnIndex == 0 and 0 or 200
		local offsetX = columnStartX + (subColumnIndex * 100)
		local offsetY = -16 - (rowIndex * 32)

		checkbox:SetLayoutWidth(87)
		checkbox:SetLayoutPoint("TOPLEFT", orientationRow.frame, "BOTTOMLEFT", offsetX, offsetY)
		checkbox:BindValue({
			get = function(profile)
				return profile.raid.groups[groupIndex]
			end,
			set = function(profile, _, value)
				profile.raid.groups[groupIndex] = value
			end,
			onChange = function()
				addon.UpdateScheduler:Notify("layoutChanged")
			end,
		})

		raidGroupCheckboxes[groupIndex] = checkbox
	end

	subpage:SetStateUpdater(function(_, mode)
		local isRaidMode = mode == "raid"

		reverseGroupOrderCheckbox:SetShown(isRaidMode)
		for _, checkbox in ipairs(raidGroupCheckboxes) do
			checkbox:SetShown(isRaidMode)
		end
	end)

	return page
end
