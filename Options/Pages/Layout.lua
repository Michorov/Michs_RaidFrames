local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Layout = addon.Options.Pages.Layout or {}

local Layout = addon.Options.Pages.Layout

local page
local theme = addon.Options.Theme

local function GetControllerState()
	local content = addon.Options.Sections.Content
	if content and content.GetControllerState then
		return content:GetControllerState()
	end

	addon.Options.ControllerState = addon.Options.ControllerState or {
		mode = "party",
		subpages = {
			auras = "buffs",
			texts = "name",
			indicators = "readyCheck",
			bars = "absorbs",
		},
	}

	return addon.Options.ControllerState
end

local function GetModeKey()
	local state = GetControllerState()
	return state.mode == "raid" and "raid" or "party"
end

local function GetModeDefaults(mode)
	if mode == "raid" then
		return {
			positionX = 0,
			positionY = 0,
			spacingX = -1,
			spacingY = -1,
			frameWidth = 110,
			frameHeight = 56,
			borderThickness = 1,
		}
	end

	return {
		positionX = 0,
		positionY = 0,
		spacingX = -1,
		spacingY = -1,
		frameWidth = 128,
		frameHeight = 64,
		borderThickness = 1,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r Layout changes are disabled during combat.")
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ApplyModeSetting(updateFn, notifyEvent)
	if InCombatLockdown() then
		ShowCombatLockMessage()
		Layout:UpdateState(addon.Database:GetProfile())
		return
	end

	local profile = addon.Database:GetProfile()
	local mode = GetModeKey()

	profile[mode] = profile[mode] or {}
	updateFn(profile[mode], mode)

	addon.UpdateScheduler:Notify(notifyEvent)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

function Layout:Ensure(parent)
	if page then
		return page
	end

	page = CreateFrame("Frame", nil, parent)

	page.headerRow = CreateFrame("Frame", nil, page)
	page.body = CreateFrame("Frame", nil, page)

	page.title = page:CreateFontString(nil, "OVERLAY")
	page.title:SetJustifyH("LEFT")
	page.title:SetFont(theme.fonts.arialNarrow, 20, "")
	page.title:SetTextColor(0.88, 0.89, 0.92, 1)
	page.title:SetText("Layout")

	page.modeToggle = addon.Options.Controls.SegmentedToggle:Create(
		page,
		{ value = "party", text = "Party" },
		{ value = "raid", text = "Raid" }
	)
	page.modeToggle:SetOnValueChanged(function(_, value)
		local state = GetControllerState()
		state.mode = value
		Layout:UpdateState(addon.Database:GetProfile())
	end)

	page.horizontalPositionSlider = addon.Options.Controls.Slider:Create(page, "Horizontal Position")
	ConfigureIntegerSlider(page.horizontalPositionSlider, -2000, 2000, 1)
	page.horizontalPositionSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.position = section.position or {}
			section.position.x = value
		end, "layoutChanged")
	end)

	page.verticalPositionSlider = addon.Options.Controls.Slider:Create(page, "Vertical Position")
	ConfigureIntegerSlider(page.verticalPositionSlider, -2000, 2000, 1)
	page.verticalPositionSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.position = section.position or {}
			section.position.y = value
		end, "layoutChanged")
	end)

	page.horizontalSpacingSlider = addon.Options.Controls.Slider:Create(page, "Horizontal Spacing")
	ConfigureIntegerSlider(page.horizontalSpacingSlider, -25, 25, 1)
	page.horizontalSpacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.spacing = section.spacing or {}
			section.spacing.x = value
		end, "layoutChanged")
	end)

	page.verticalSpacingSlider = addon.Options.Controls.Slider:Create(page, "Vertical Spacing")
	ConfigureIntegerSlider(page.verticalSpacingSlider, -25, 25, 1)
	page.verticalSpacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.spacing = section.spacing or {}
			section.spacing.y = value
		end, "layoutChanged")
	end)

	page.frameWidthSlider = addon.Options.Controls.Slider:Create(page, "Frame Width")
	ConfigureIntegerSlider(page.frameWidthSlider, 25, 300, 1)
	page.frameWidthSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.size = section.size or {}
			section.size.width = value
		end, "layoutChanged")
	end)

	page.frameHeightSlider = addon.Options.Controls.Slider:Create(page, "Frame Height")
	ConfigureIntegerSlider(page.frameHeightSlider, 25, 300, 1)
	page.frameHeightSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.size = section.size or {}
			section.size.height = value
		end, "layoutChanged")
	end)

	page.frameBorderThicknessSlider = addon.Options.Controls.Slider:Create(page, "Border Thickness")
	ConfigureIntegerSlider(page.frameBorderThicknessSlider, 0, 6, 1)
	page.frameBorderThicknessSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.border = section.border or {}
			section.border.thicknessPx = value
		end, "borderSettingsChanged")
	end)

	addon.Options.Data:RegisterForUpdates(Layout, function(profile)
		Layout:UpdateState(profile)
	end)

	self:UpdateLayout()
	self:UpdateState(addon.Database:GetProfile())

	return page
end

function Layout:UpdateLayout()
	if not page then
		return
	end

	local layout = addon.Options.Sections.Content:GetLayout()
	local pagePadding = layout.padding
	local toggleWidth = addon.Utilities:ToUI(addon.Utilities:ToPixels(112))
	local headerRowHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(24))
	local firstControlOffset = addon.Utilities:ToUI(addon.Utilities:ToPixels(24))
	local sliderRowHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(34))
	local rowSpacing = addon.Utilities:ToUI(addon.Utilities:ToPixels(18))
	local rowStep = sliderRowHeight + rowSpacing
	local threeColumnSecondOffset = layout.threeColumn.startX[2] - layout.threeColumn.startX[1]
	local threeColumnThirdOffset = layout.threeColumn.startX[3] - layout.threeColumn.startX[1]
	local threeColumnControlWidth = layout.threeColumn.slotWidth

	page.headerRow:ClearAllPoints()
	page.headerRow:SetPoint("TOPLEFT", page, "TOPLEFT", pagePadding, -pagePadding)
	page.headerRow:SetPoint("TOPRIGHT", page, "TOPRIGHT", -pagePadding, -pagePadding)
	page.headerRow:SetHeight(headerRowHeight)

	page.title:ClearAllPoints()
	page.title:SetPoint("LEFT", page.headerRow, "LEFT", 0, 0)

	page.modeToggle:SetWidth(toggleWidth)
	page.modeToggle:ClearAllPoints()
	page.modeToggle:SetPoint("RIGHT", page.headerRow, "RIGHT", 0, 0)

	page.body:ClearAllPoints()
	page.body:SetPoint("TOPLEFT", page.headerRow, "BOTTOMLEFT", 0, -firstControlOffset)
	page.body:SetPoint("TOPRIGHT", page.headerRow, "BOTTOMRIGHT", 0, -firstControlOffset)
	page.body:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", pagePadding, 0)
	page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -pagePadding, 0)

	page.horizontalPositionSlider:SetControlWidth(threeColumnControlWidth)
	page.horizontalPositionSlider:ClearAllPoints()
	page.horizontalPositionSlider:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)

	page.verticalPositionSlider:SetControlWidth(threeColumnControlWidth)
	page.verticalPositionSlider:ClearAllPoints()
	page.verticalPositionSlider:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		threeColumnSecondOffset,
		0
	)

	page.horizontalSpacingSlider:SetControlWidth(threeColumnControlWidth)
	page.horizontalSpacingSlider:ClearAllPoints()
	page.horizontalSpacingSlider:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		0,
		-rowStep
	)

	page.verticalSpacingSlider:SetControlWidth(threeColumnControlWidth)
	page.verticalSpacingSlider:ClearAllPoints()
	page.verticalSpacingSlider:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		threeColumnSecondOffset,
		-rowStep
	)

	page.frameWidthSlider:SetControlWidth(threeColumnControlWidth)
	page.frameWidthSlider:ClearAllPoints()
	page.frameWidthSlider:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, -(rowStep * 2))

	page.frameHeightSlider:SetControlWidth(threeColumnControlWidth)
	page.frameHeightSlider:ClearAllPoints()
	page.frameHeightSlider:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		threeColumnSecondOffset,
		-(rowStep * 2)
	)

	page.frameBorderThicknessSlider:SetControlWidth(threeColumnControlWidth)
	page.frameBorderThicknessSlider:ClearAllPoints()
	page.frameBorderThicknessSlider:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		threeColumnThirdOffset,
		-(rowStep * 2)
	)
end

function Layout:UpdateState(profile)
	if not page or not profile then
		return
	end

	local mode = GetModeKey()
	local section = profile[mode] or {}
	local defaults = GetModeDefaults(mode)
	local position = section.position or {}
	local spacing = section.spacing or {}
	local size = section.size or {}
	local border = section.border or {}

	page.modeToggle:SetValue(mode)
	page.horizontalPositionSlider:SetValueSilently(position.x or defaults.positionX)
	page.verticalPositionSlider:SetValueSilently(position.y or defaults.positionY)
	page.horizontalSpacingSlider:SetValueSilently(spacing.x or defaults.spacingX)
	page.verticalSpacingSlider:SetValueSilently(spacing.y or defaults.spacingY)
	page.frameWidthSlider:SetValueSilently(size.width or defaults.frameWidth)
	page.frameHeightSlider:SetValueSilently(size.height or defaults.frameHeight)
	page.frameBorderThicknessSlider:SetValueSilently(border.thicknessPx or defaults.borderThickness)
end
