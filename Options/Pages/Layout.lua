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

	page.header = CreateFrame("Frame", nil, page)
	page.header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
	page.header:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)

	page.body = CreateFrame("Frame", nil, page)
	page.body:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
	page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

	page.header.title = page.header:CreateFontString(nil, "OVERLAY")
	page.header.title:SetPoint("LEFT", page.header, "LEFT", 0, 0)
	page.header.title:SetJustifyH("LEFT")
	page.header.title:SetFont(theme.fonts.arialNarrow, 20, "")
	page.header.title:SetTextColor(theme:GetTextColor("highlight"))
	page.header.title:SetText("Layout")

	page.modeToggle = addon.Options.Controls.SegmentedToggle:Create(
		page.header,
		{ value = "party", text = "Party" },
		{ value = "raid", text = "Raid" }
	)
	page.modeToggle:SetLayoutSize(112, 24)
	page.modeToggle:SetPoint("RIGHT", page.header, "RIGHT", 0, 0)
	page.modeToggle:SetOnValueChanged(function(_, value)
		local state = GetControllerState()
		state.mode = value
		if page and page.UpdateState then
			page:UpdateState(addon.Database:GetProfile())
		end
	end)

	page.horizontalPositionSlider = addon.Options.Controls.Slider:Create(page, "Horizontal Position")
	page.horizontalPositionSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.horizontalPositionSlider, -2000, 2000, 1)
	page.horizontalPositionSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.position = section.position or {}
			section.position.x = value
		end, "layoutChanged")
	end)

	page.verticalPositionSlider = addon.Options.Controls.Slider:Create(page, "Vertical Position")
	page.verticalPositionSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.verticalPositionSlider, -2000, 2000, 1)
	page.verticalPositionSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.position = section.position or {}
			section.position.y = value
		end, "layoutChanged")
	end)

	page.horizontalSpacingSlider = addon.Options.Controls.Slider:Create(page, "Horizontal Spacing")
	page.horizontalSpacingSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.horizontalSpacingSlider, -25, 25, 1)
	page.horizontalSpacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.spacing = section.spacing or {}
			section.spacing.x = value
		end, "layoutChanged")
	end)

	page.verticalSpacingSlider = addon.Options.Controls.Slider:Create(page, "Vertical Spacing")
	page.verticalSpacingSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.verticalSpacingSlider, -25, 25, 1)
	page.verticalSpacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.spacing = section.spacing or {}
			section.spacing.y = value
		end, "layoutChanged")
	end)

	page.frameWidthSlider = addon.Options.Controls.Slider:Create(page, "Frame Width")
	page.frameWidthSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.frameWidthSlider, 25, 300, 1)
	page.frameWidthSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.size = section.size or {}
			section.size.width = value
		end, "layoutChanged")
	end)

	page.frameHeightSlider = addon.Options.Controls.Slider:Create(page, "Frame Height")
	page.frameHeightSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.frameHeightSlider, 25, 300, 1)
	page.frameHeightSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.size = section.size or {}
			section.size.height = value
		end, "layoutChanged")
	end)

	page.frameBorderThicknessSlider = addon.Options.Controls.Slider:Create(page, "Border Thickness")
	page.frameBorderThicknessSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.frameBorderThicknessSlider, 0, 6, 1)
	page.frameBorderThicknessSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.border = section.border or {}
			section.border.thicknessPx = value
		end, "borderSettingsChanged")
	end)

	page.backgroundColorPicker = addon.Options.Controls.ColorPicker:Create(page, "Background Color")
	page.backgroundColorPicker:SetLayoutWidth(174)
	page.backgroundColorPicker:SetHasOpacity(true)
	page.backgroundColorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.background = section.background or {}
			section.background.color = { r = r, g = g, b = b, a = a }
		end, "backgroundSettingsChanged")
	end)

	page.borderColorPicker = addon.Options.Controls.ColorPicker:Create(page, "Border Color")
	page.borderColorPicker:SetLayoutWidth(174)
	page.borderColorPicker:SetHasOpacity(true)
	page.borderColorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.border = section.border or {}
			section.border.color = { r = r, g = g, b = b, a = a }
		end, "borderSettingsChanged")
	end)

	page.controls = {
		modeToggle = page.modeToggle,
		horizontalPositionSlider = page.horizontalPositionSlider,
		verticalPositionSlider = page.verticalPositionSlider,
		horizontalSpacingSlider = page.horizontalSpacingSlider,
		verticalSpacingSlider = page.verticalSpacingSlider,
		frameWidthSlider = page.frameWidthSlider,
		frameHeightSlider = page.frameHeightSlider,
		frameBorderThicknessSlider = page.frameBorderThicknessSlider,
		backgroundColorPicker = page.backgroundColorPicker,
		borderColorPicker = page.borderColorPicker,
	}

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
		local controls = self.controls
		local headerHeightPx = addon.Utilities:ToPixels(32)
		local firstControlOffsetPx = addon.Utilities:ToPixels(16)
		local controlSlotHeightPx = addon.Utilities:ToPixels(56)
		local rowStepPx = controlSlotHeightPx
		local sectionGapPx = addon.Utilities:ToPixels(18)
		local thirdRowOffsetPx = (rowStepPx * 2) + sectionGapPx
		local fourthRowOffsetPx = thirdRowOffsetPx + rowStepPx
		local columnGapPx = addon.Utilities:ToPixels(30)
		local threeColumnSlotWidthPx = addon.Utilities:ToPixels(174)
		local threeColumnSecondOffsetPx = threeColumnSlotWidthPx + columnGapPx
		local threeColumnThirdOffsetPx = (threeColumnSlotWidthPx * 2) + (columnGapPx * 2)

		self.header:SetHeight(addon.Utilities:ToUI(headerHeightPx))

		self.body:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(addon.Utilities:ToPixels(16)))
		self.body:SetPoint(
			"TOPRIGHT",
			self.header,
			"BOTTOMRIGHT",
			0,
			-addon.Utilities:ToUI(addon.Utilities:ToPixels(16))
		)

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		self.horizontalPositionSlot:ClearAllPoints()
		self.horizontalPositionSlot:SetSize(
			addon.Utilities:ToUI(threeColumnSlotWidthPx),
			addon.Utilities:ToUI(controlSlotHeightPx)
		)
		self.horizontalPositionSlot:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, 0)

		self.verticalPositionSlot:ClearAllPoints()
		self.verticalPositionSlot:SetSize(
			addon.Utilities:ToUI(threeColumnSlotWidthPx),
			addon.Utilities:ToUI(controlSlotHeightPx)
		)
		self.verticalPositionSlot:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			0
		)

		self.horizontalSpacingSlot:ClearAllPoints()
		self.horizontalSpacingSlot:SetSize(
			addon.Utilities:ToUI(threeColumnSlotWidthPx),
			addon.Utilities:ToUI(controlSlotHeightPx)
		)
		self.horizontalSpacingSlot:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -addon.Utilities:ToUI(rowStepPx))

		self.verticalSpacingSlot:ClearAllPoints()
		self.verticalSpacingSlot:SetSize(
			addon.Utilities:ToUI(threeColumnSlotWidthPx),
			addon.Utilities:ToUI(controlSlotHeightPx)
		)
		self.verticalSpacingSlot:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(rowStepPx)
		)

		self.frameWidthSlot:ClearAllPoints()
		self.frameWidthSlot:SetSize(
			addon.Utilities:ToUI(threeColumnSlotWidthPx),
			addon.Utilities:ToUI(controlSlotHeightPx)
		)
		self.frameWidthSlot:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -addon.Utilities:ToUI(thirdRowOffsetPx))

		self.frameHeightSlot:ClearAllPoints()
		self.frameHeightSlot:SetSize(
			addon.Utilities:ToUI(threeColumnSlotWidthPx),
			addon.Utilities:ToUI(controlSlotHeightPx)
		)
		self.frameHeightSlot:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(thirdRowOffsetPx)
		)

		self.frameBorderThicknessSlot:ClearAllPoints()
		self.frameBorderThicknessSlot:SetSize(
			addon.Utilities:ToUI(threeColumnSlotWidthPx),
			addon.Utilities:ToUI(controlSlotHeightPx)
		)
		self.frameBorderThicknessSlot:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(fourthRowOffsetPx)
		)

		self.backgroundColorSlot:ClearAllPoints()
		self.backgroundColorSlot:SetSize(
			addon.Utilities:ToUI(threeColumnSlotWidthPx),
			addon.Utilities:ToUI(controlSlotHeightPx)
		)
		self.backgroundColorSlot:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnThirdOffsetPx),
			-addon.Utilities:ToUI(thirdRowOffsetPx)
		)

		self.borderColorSlot:ClearAllPoints()
		self.borderColorSlot:SetSize(
			addon.Utilities:ToUI(threeColumnSlotWidthPx),
			addon.Utilities:ToUI(controlSlotHeightPx)
		)
		self.borderColorSlot:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(fourthRowOffsetPx)
		)

		controls.horizontalPositionSlider:ClearAllPoints()
		controls.horizontalPositionSlider:SetPoint(
			"TOPLEFT",
			self.horizontalPositionSlot,
			"TOPLEFT",
			0,
			0
		)

		controls.verticalPositionSlider:ClearAllPoints()
		controls.verticalPositionSlider:SetPoint(
			"TOPLEFT",
			self.verticalPositionSlot,
			"TOPLEFT",
			0,
			0
		)

		controls.horizontalSpacingSlider:ClearAllPoints()
		controls.horizontalSpacingSlider:SetPoint(
			"TOPLEFT",
			self.horizontalSpacingSlot,
			"TOPLEFT",
			0,
			0
		)

		controls.verticalSpacingSlider:ClearAllPoints()
		controls.verticalSpacingSlider:SetPoint(
			"TOPLEFT",
			self.verticalSpacingSlot,
			"TOPLEFT",
			0,
			0
		)

		controls.frameWidthSlider:ClearAllPoints()
		controls.frameWidthSlider:SetPoint(
			"TOPLEFT",
			self.frameWidthSlot,
			"TOPLEFT",
			0,
			0
		)

		controls.frameHeightSlider:ClearAllPoints()
		controls.frameHeightSlider:SetPoint(
			"TOPLEFT",
			self.frameHeightSlot,
			"TOPLEFT",
			0,
			0
		)

		controls.frameBorderThicknessSlider:ClearAllPoints()
		controls.frameBorderThicknessSlider:SetPoint(
			"TOPLEFT",
			self.frameBorderThicknessSlot,
			"TOPLEFT",
			0,
			0
		)

		controls.backgroundColorPicker:ClearAllPoints()
		controls.backgroundColorPicker:SetPoint(
			"TOPLEFT",
			self.backgroundColorSlot,
			"TOPLEFT",
			0,
			0
		)

		controls.borderColorPicker:ClearAllPoints()
		controls.borderColorPicker:SetPoint(
			"TOPLEFT",
			self.borderColorSlot,
			"TOPLEFT",
			0,
			0
		)
	end

	function page:UpdateState(profile)
		if not profile then
			return
		end

		local controls = self.controls

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

		controls.modeToggle:SetValue(mode)
		controls.horizontalPositionSlider:SetValueSilently(position.x or defaults.positionX)
		controls.verticalPositionSlider:SetValueSilently(position.y or defaults.positionY)
		controls.horizontalSpacingSlider:SetValueSilently(spacing.x or defaults.spacingX)
		controls.verticalSpacingSlider:SetValueSilently(spacing.y or defaults.spacingY)
		controls.frameWidthSlider:SetValueSilently(size.width or defaults.frameWidth)
		controls.frameHeightSlider:SetValueSilently(size.height or defaults.frameHeight)
		controls.frameBorderThicknessSlider:SetValueSilently(border.thicknessPx or defaults.borderThickness)
		controls.backgroundColorPicker:SetColor(
			backgroundColor.r,
			backgroundColor.g,
			backgroundColor.b,
			backgroundColor.a
		)
		controls.borderColorPicker:SetColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
	end

	addon.Options.Data:RegisterForUpdates(page, function(profile)
		page:UpdateState(profile)
	end)

	page:UpdateLayout()
	page:UpdateState(addon.Database:GetProfile())

	return page
end
