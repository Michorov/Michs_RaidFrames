local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Frames = addon.Options.Pages.Frames or {}

local FramesPage = addon.Options.Pages.Frames

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
				bars = "health",
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
			frameWidth = 110,
			frameHeight = 56,
			borderThickness = 1,
			backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 1.0 },
			borderColor = { r = 0, g = 0, b = 0, a = 1 },
		}
	end

	return {
		frameWidth = 128,
		frameHeight = 64,
		borderThickness = 1,
		backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 1.0 },
		borderColor = { r = 0, g = 0, b = 0, a = 1 },
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r Frame changes are disabled during combat.")
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

function FramesPage:Ensure(parent)
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
	page.header.title:SetText("Frames")

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
		if page and page.UpdateLayout then
			page:UpdateLayout()
		end
		if page and page.UpdateState then
			page:UpdateState(addon.Database:GetProfile())
		end
	end)

	page.frameWidthSlider = addon.Options.Controls.Slider:Create(page.body, "Frame Width")
	page.frameWidthSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.frameWidthSlider, 25, 300, 1)
	page.frameWidthSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.size = section.size or {}
			section.size.width = value
		end, "layoutChanged")
	end)

	page.frameHeightSlider = addon.Options.Controls.Slider:Create(page.body, "Frame Height")
	page.frameHeightSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.frameHeightSlider, 25, 300, 1)
	page.frameHeightSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.size = section.size or {}
			section.size.height = value
		end, "layoutChanged")
	end)

	page.frameBorderThicknessSlider = addon.Options.Controls.Slider:Create(page.body, "Border Thickness")
	page.frameBorderThicknessSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(page.frameBorderThicknessSlider, 0, 6, 1)
	page.frameBorderThicknessSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.border = section.border or {}
			section.border.thicknessPx = value
		end, "borderSettingsChanged")
	end)

	page.backgroundColorPicker = addon.Options.Controls.ColorPicker:Create(page.body, "Background Color")
	page.backgroundColorPicker:SetLayoutWidth(174)
	page.backgroundColorPicker:SetHasOpacity(true)
	page.backgroundColorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.background = section.background or {}
			section.background.color = { r = r, g = g, b = b, a = a }
		end, "backgroundSettingsChanged")
	end)

	page.borderColorPicker = addon.Options.Controls.ColorPicker:Create(page.body, "Border Color")
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
		frameWidthSlider = page.frameWidthSlider,
		frameHeightSlider = page.frameHeightSlider,
		frameBorderThicknessSlider = page.frameBorderThicknessSlider,
		backgroundColorPicker = page.backgroundColorPicker,
		borderColorPicker = page.borderColorPicker,
	}

	function page:UpdateLayout()
		local controls = self.controls
		local headerHeightPx = addon.Utilities:ToPixels(32)
		local firstControlOffsetPx = addon.Utilities:ToPixels(16)
		local rowStepPx = addon.Utilities:ToPixels(50)
		local columnGapPx = addon.Utilities:ToPixels(30)
		local threeColumnSlotWidthPx = addon.Utilities:ToPixels(174)
		local threeColumnSecondOffsetPx = threeColumnSlotWidthPx + columnGapPx
		local threeColumnThirdOffsetPx = (threeColumnSlotWidthPx * 2) + (columnGapPx * 2)
		local sliderHeightPx = addon.Utilities:ToPixels(34)
		local colorPickerSizePx = addon.Utilities:ToPixels(controls.backgroundColorPicker.layoutValues.pickerSize)
		local colorPickerOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - colorPickerSizePx) / 2))

		self.header:SetHeight(addon.Utilities:ToUI(headerHeightPx))

		self.body:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))
		self.body:SetPoint(
			"TOPRIGHT",
			self.header,
			"BOTTOMRIGHT",
			0,
			-addon.Utilities:ToUI(firstControlOffsetPx)
		)

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.frameWidthSlider:ClearAllPoints()
		controls.frameWidthSlider:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, 0)

		controls.frameHeightSlider:ClearAllPoints()
		controls.frameHeightSlider:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			0
		)

		controls.backgroundColorPicker:ClearAllPoints()
		controls.backgroundColorPicker:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnThirdOffsetPx),
			-addon.Utilities:ToUI(colorPickerOffsetPx)
		)

		controls.frameBorderThicknessSlider:ClearAllPoints()
		controls.frameBorderThicknessSlider:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(rowStepPx)
		)

		controls.borderColorPicker:ClearAllPoints()
		controls.borderColorPicker:SetPoint(
			"TOPLEFT",
			self.body,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(rowStepPx + colorPickerOffsetPx)
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
		local size = section.size or {}
		local background = section.background or {}
		local border = section.border or {}
		local backgroundColor = background.color or defaults.backgroundColor
		local borderColor = border.color or defaults.borderColor

		controls.modeToggle:SetValue(mode)
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
