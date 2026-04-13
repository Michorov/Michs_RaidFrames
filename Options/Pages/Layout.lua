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

	addon.Options.ControllerState = addon.Options.ControllerState
		or {
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
			backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 1.0 },
			borderColor = { r = 0, g = 0, b = 0, a = 1 },
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
		backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 1.0 },
		borderColor = { r = 0, g = 0, b = 0, a = 1 },
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
		if page and page.UpdateState then
			page:UpdateState(addon.Database:GetProfile())
		else
			Layout:UpdateState(addon.Database:GetProfile())
		end
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

local function CreateControlSlot(parent)
	return CreateFrame("Frame", nil, parent)
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
		if page and page.UpdateState then
			page:UpdateState(addon.Database:GetProfile())
		else
			Layout:UpdateState(addon.Database:GetProfile())
		end
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

	page.backgroundColorPicker = addon.Options.Controls.ColorPicker:Create(page, "Background Color")
	page.backgroundColorPicker:SetHasOpacity(true)
	page.backgroundColorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.background = section.background or {}
			section.background.color = { r = r, g = g, b = b, a = a }
		end, "backgroundSettingsChanged")
	end)

	page.borderColorPicker = addon.Options.Controls.ColorPicker:Create(page, "Border Color")
	page.borderColorPicker:SetHasOpacity(true)
	page.borderColorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.border = section.border or {}
			section.border.color = { r = r, g = g, b = b, a = a }
		end, "borderSettingsChanged")
	end)

	page.horizontalPositionSlot = CreateControlSlot(page.body)
	page.verticalPositionSlot = CreateControlSlot(page.body)
	page.horizontalSpacingSlot = CreateControlSlot(page.body)
	page.verticalSpacingSlot = CreateControlSlot(page.body)
	page.frameWidthSlot = CreateControlSlot(page.body)
	page.frameHeightSlot = CreateControlSlot(page.body)
	page.frameBorderThicknessSlot = CreateControlSlot(page.body)
	page.backgroundColorSlot = CreateControlSlot(page.body)
	page.borderColorSlot = CreateControlSlot(page.body)

	page.horizontalPositionSlider:SetParent(page.horizontalPositionSlot)
	page.verticalPositionSlider:SetParent(page.verticalPositionSlot)
	page.horizontalSpacingSlider:SetParent(page.horizontalSpacingSlot)
	page.verticalSpacingSlider:SetParent(page.verticalSpacingSlot)
	page.frameWidthSlider:SetParent(page.frameWidthSlot)
	page.frameHeightSlider:SetParent(page.frameHeightSlot)
	page.frameBorderThicknessSlider:SetParent(page.frameBorderThicknessSlot)
	page.backgroundColorPicker:SetParent(page.backgroundColorSlot)
	page.borderColorPicker:SetParent(page.borderColorSlot)

	function page:UpdateLayout()
		--Layout:UpdateLayout()
	end

	function page:UpdateState(profile)
		Layout:UpdateState(profile)
	end

	addon.Options.Data:RegisterForUpdates(page, function(profile)
		page:UpdateState(profile)
	end)

	--page:UpdateLayout()
	page:UpdateState(addon.Database:GetProfile())

	return page
end

function Layout:UpdateLayout()
	if not page then
		return
	end

	local layout = addon.Options.Sections.Content:GetLayout()
	local pagePaddingPx = layout.paddingPx
	local toggleWidthPx = addon.Utilities:ToPixels(112)
	local headerRowHeightPx = addon.Utilities:ToPixels(24)
	local firstControlOffsetPx = addon.Utilities:ToPixels(24)
	local controlSlotHeightPx = addon.Utilities:ToPixels(56)
	local sliderControlHeightPx = addon.Utilities:ToPixels(34)
	local colorPickerControlHeightPx = addon.Utilities:ToPixels(24)
	local rowStepPx = controlSlotHeightPx
	local sectionGapPx = addon.Utilities:ToPixels(18)
	local thirdRowOffsetPx = (rowStepPx * 2) + sectionGapPx
	local fourthRowOffsetPx = thirdRowOffsetPx + rowStepPx
	local sliderTopInsetPx = (controlSlotHeightPx - sliderControlHeightPx) / 2
	local colorPickerTopInsetPx = (controlSlotHeightPx - colorPickerControlHeightPx) / 2
	local threeColumnSecondOffsetPx = layout.threeColumn.startXPx[2] - layout.threeColumn.startXPx[1]
	local threeColumnThirdOffsetPx = layout.threeColumn.startXPx[3] - layout.threeColumn.startXPx[1]
	local threeColumnSlotWidthPx = layout.threeColumn.slotWidthPx

	page.headerRow:ClearAllPoints()
	page.headerRow:SetPoint(
		"TOPLEFT",
		page,
		"TOPLEFT",
		addon.Utilities:ToUI(pagePaddingPx),
		-addon.Utilities:ToUI(pagePaddingPx)
	)
	page.headerRow:SetPoint(
		"TOPRIGHT",
		page,
		"TOPRIGHT",
		-addon.Utilities:ToUI(pagePaddingPx),
		-addon.Utilities:ToUI(pagePaddingPx)
	)
	page.headerRow:SetHeight(addon.Utilities:ToUI(headerRowHeightPx))

	page.title:ClearAllPoints()
	page.title:SetPoint("LEFT", page.headerRow, "LEFT", 0, 0)

	page.modeToggle:SetWidth(addon.Utilities:ToUI(toggleWidthPx))
	page.modeToggle:ClearAllPoints()
	page.modeToggle:SetPoint("RIGHT", page.headerRow, "RIGHT", 0, 0)

	page.body:ClearAllPoints()
	page.body:SetPoint("TOPLEFT", page.headerRow, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))
	page.body:SetPoint("TOPRIGHT", page.headerRow, "BOTTOMRIGHT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))
	page.body:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", addon.Utilities:ToUI(pagePaddingPx), 0)
	page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -addon.Utilities:ToUI(pagePaddingPx), 0)

	page.horizontalPositionSlot:ClearAllPoints()
	page.horizontalPositionSlot:SetSize(
		addon.Utilities:ToUI(threeColumnSlotWidthPx),
		addon.Utilities:ToUI(controlSlotHeightPx)
	)
	page.horizontalPositionSlot:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)

	page.verticalPositionSlot:ClearAllPoints()
	page.verticalPositionSlot:SetSize(
		addon.Utilities:ToUI(threeColumnSlotWidthPx),
		addon.Utilities:ToUI(controlSlotHeightPx)
	)
	page.verticalPositionSlot:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		addon.Utilities:ToUI(threeColumnSecondOffsetPx),
		0
	)

	page.horizontalSpacingSlot:ClearAllPoints()
	page.horizontalSpacingSlot:SetSize(
		addon.Utilities:ToUI(threeColumnSlotWidthPx),
		addon.Utilities:ToUI(controlSlotHeightPx)
	)
	page.horizontalSpacingSlot:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, -addon.Utilities:ToUI(rowStepPx))

	page.verticalSpacingSlot:ClearAllPoints()
	page.verticalSpacingSlot:SetSize(
		addon.Utilities:ToUI(threeColumnSlotWidthPx),
		addon.Utilities:ToUI(controlSlotHeightPx)
	)
	page.verticalSpacingSlot:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		addon.Utilities:ToUI(threeColumnSecondOffsetPx),
		-addon.Utilities:ToUI(rowStepPx)
	)

	page.frameWidthSlot:ClearAllPoints()
	page.frameWidthSlot:SetSize(addon.Utilities:ToUI(threeColumnSlotWidthPx), addon.Utilities:ToUI(controlSlotHeightPx))
	page.frameWidthSlot:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, -addon.Utilities:ToUI(thirdRowOffsetPx))

	page.frameHeightSlot:ClearAllPoints()
	page.frameHeightSlot:SetSize(
		addon.Utilities:ToUI(threeColumnSlotWidthPx),
		addon.Utilities:ToUI(controlSlotHeightPx)
	)
	page.frameHeightSlot:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		addon.Utilities:ToUI(threeColumnSecondOffsetPx),
		-addon.Utilities:ToUI(thirdRowOffsetPx)
	)

	page.frameBorderThicknessSlot:ClearAllPoints()
	page.frameBorderThicknessSlot:SetSize(
		addon.Utilities:ToUI(threeColumnSlotWidthPx),
		addon.Utilities:ToUI(controlSlotHeightPx)
	)
	page.frameBorderThicknessSlot:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, -addon.Utilities:ToUI(fourthRowOffsetPx))

	page.backgroundColorSlot:ClearAllPoints()
	page.backgroundColorSlot:SetSize(
		addon.Utilities:ToUI(threeColumnSlotWidthPx),
		addon.Utilities:ToUI(controlSlotHeightPx)
	)
	page.backgroundColorSlot:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		addon.Utilities:ToUI(threeColumnThirdOffsetPx),
		-addon.Utilities:ToUI(thirdRowOffsetPx)
	)

	page.borderColorSlot:ClearAllPoints()
	page.borderColorSlot:SetSize(
		addon.Utilities:ToUI(threeColumnSlotWidthPx),
		addon.Utilities:ToUI(controlSlotHeightPx)
	)
	page.borderColorSlot:SetPoint(
		"TOPLEFT",
		page.body,
		"TOPLEFT",
		addon.Utilities:ToUI(threeColumnSecondOffsetPx),
		-addon.Utilities:ToUI(fourthRowOffsetPx)
	)

	page.horizontalPositionSlider:SetControlWidthPx(threeColumnSlotWidthPx)
	page.horizontalPositionSlider:ClearAllPoints()
	page.horizontalPositionSlider:SetPoint(
		"TOPLEFT",
		page.horizontalPositionSlot,
		"TOPLEFT",
		0,
		-addon.Utilities:ToUI(sliderTopInsetPx)
	)

	page.verticalPositionSlider:SetControlWidthPx(threeColumnSlotWidthPx)
	page.verticalPositionSlider:ClearAllPoints()
	page.verticalPositionSlider:SetPoint(
		"TOPLEFT",
		page.verticalPositionSlot,
		"TOPLEFT",
		0,
		-addon.Utilities:ToUI(sliderTopInsetPx)
	)

	page.horizontalSpacingSlider:SetControlWidthPx(threeColumnSlotWidthPx)
	page.horizontalSpacingSlider:ClearAllPoints()
	page.horizontalSpacingSlider:SetPoint(
		"TOPLEFT",
		page.horizontalSpacingSlot,
		"TOPLEFT",
		0,
		-addon.Utilities:ToUI(sliderTopInsetPx)
	)

	page.verticalSpacingSlider:SetControlWidthPx(threeColumnSlotWidthPx)
	page.verticalSpacingSlider:ClearAllPoints()
	page.verticalSpacingSlider:SetPoint(
		"TOPLEFT",
		page.verticalSpacingSlot,
		"TOPLEFT",
		0,
		-addon.Utilities:ToUI(sliderTopInsetPx)
	)

	page.frameWidthSlider:SetControlWidthPx(threeColumnSlotWidthPx)
	page.frameWidthSlider:ClearAllPoints()
	page.frameWidthSlider:SetPoint(
		"TOPLEFT",
		page.frameWidthSlot,
		"TOPLEFT",
		0,
		-addon.Utilities:ToUI(sliderTopInsetPx)
	)

	page.frameHeightSlider:SetControlWidthPx(threeColumnSlotWidthPx)
	page.frameHeightSlider:ClearAllPoints()
	page.frameHeightSlider:SetPoint(
		"TOPLEFT",
		page.frameHeightSlot,
		"TOPLEFT",
		0,
		-addon.Utilities:ToUI(sliderTopInsetPx)
	)

	page.frameBorderThicknessSlider:SetControlWidthPx(threeColumnSlotWidthPx)
	page.frameBorderThicknessSlider:ClearAllPoints()
	page.frameBorderThicknessSlider:SetPoint(
		"TOPLEFT",
		page.frameBorderThicknessSlot,
		"TOPLEFT",
		0,
		-addon.Utilities:ToUI(sliderTopInsetPx)
	)

	page.backgroundColorPicker:SetWidth(addon.Utilities:ToUI(threeColumnSlotWidthPx))
	page.backgroundColorPicker:ClearAllPoints()
	page.backgroundColorPicker:SetPoint(
		"TOPLEFT",
		page.backgroundColorSlot,
		"TOPLEFT",
		0,
		-addon.Utilities:ToUI(colorPickerTopInsetPx)
	)

	page.borderColorPicker:SetWidth(addon.Utilities:ToUI(threeColumnSlotWidthPx))
	page.borderColorPicker:ClearAllPoints()
	page.borderColorPicker:SetPoint(
		"TOPLEFT",
		page.borderColorSlot,
		"TOPLEFT",
		0,
		-addon.Utilities:ToUI(colorPickerTopInsetPx)
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
	local background = section.background or {}
	local border = section.border or {}
	local backgroundColor = background.color or defaults.backgroundColor
	local borderColor = border.color or defaults.borderColor

	page.modeToggle:SetValue(mode)
	page.horizontalPositionSlider:SetValueSilently(position.x or defaults.positionX)
	page.verticalPositionSlider:SetValueSilently(position.y or defaults.positionY)
	page.horizontalSpacingSlider:SetValueSilently(spacing.x or defaults.spacingX)
	page.verticalSpacingSlider:SetValueSilently(spacing.y or defaults.spacingY)
	page.frameWidthSlider:SetValueSilently(size.width or defaults.frameWidth)
	page.frameHeightSlider:SetValueSilently(size.height or defaults.frameHeight)
	page.frameBorderThicknessSlider:SetValueSilently(border.thicknessPx or defaults.borderThickness)
	page.backgroundColorPicker:SetColor(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)
	page.borderColorPicker:SetColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
end
