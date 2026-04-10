local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.Slider = addon.Options.Controls.Slider or {}

local Slider = addon.Options.Controls.Slider

local theme = addon.Options.Theme
local hoverAccentColor = { 1.0, 0.74, 0.42, 1 }

local function UpdateVisuals(control)
	local minValue, maxValue = control.slider:GetMinMaxValues()
	local value = control.slider:GetValue()
	local valueRange = maxValue - minValue
	local progress = 0

	if valueRange > 0 then
		progress = (value - minValue) / valueRange
	end

	control.fill:SetWidth(control.trackWidth * progress)

	if control.handle then
		local handleWidth = control.handle:GetWidth() or 0
		local handleHalfWidth = handleWidth / 2
		local handleTravelWidth = math.max(0, control.trackWidth - handleWidth)
		local handleOffset = handleHalfWidth + (handleTravelWidth * progress)

		control.handle:ClearAllPoints()
		control.handle:SetPoint("CENTER", control.track, "LEFT", handleOffset, 0)
	end
end

local function UpdateValueText(control, value)
	local formatter = control.valueFormatter
	if formatter then
		control.valueInput:SetText(formatter(value))
		return
	end

	if math.floor(value) == value then
		control.valueInput:SetText(tostring(value))
		return
	end

	control.valueInput:SetText(string.format("%.2f", value))
end

local function CommitValueInput(control)
	if control.isCommittingValueInput then
		return
	end

	control.isCommittingValueInput = true

	local parser = control.valueParser
	local text = control.valueInput:GetText() or ""
	local parsedValue

	if parser then
		parsedValue = parser(control, text)
	else
		parsedValue = tonumber(text)
	end

	if parsedValue == nil then
		UpdateValueText(control, control.slider:GetValue())
		control.valueInput:ClearFocus()
		control.isCommittingValueInput = false
		return
	end

	local minValue, maxValue = control.slider:GetMinMaxValues()
	local clampedValue = math.max(minValue, math.min(maxValue, parsedValue))
	local step = control.slider:GetValueStep()

	if step and step > 0 then
		local stepCount = math.floor(((clampedValue - minValue) / step) + 0.5)
		clampedValue = minValue + (stepCount * step)
		clampedValue = math.max(minValue, math.min(maxValue, clampedValue))
	end

	control:SetValue(clampedValue)
	UpdateValueText(control, control.slider:GetValue())
	control.valueInput:ClearFocus()
	control.isCommittingValueInput = false
end

function Slider:Create(parent, text)
	local control = CreateFrame("Frame", nil, parent)
	local trackHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(4))
	local trackWidth = addon.Utilities:ToUI(addon.Utilities:ToPixels(200))
	local thumbSize = addon.Utilities:ToUI(addon.Utilities:ToPixels(12))
	local trackVerticalOffset = addon.Utilities:ToUI(addon.Utilities:ToPixels(4))
	local topRowHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(16))
	local labelSpacing = addon.Utilities:ToUI(addon.Utilities:ToPixels(6))
	local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(1))
	local valueInputWidth = addon.Utilities:ToUI(addon.Utilities:ToPixels(48))
	local valueInputGap = addon.Utilities:ToUI(addon.Utilities:ToPixels(8))

	control:SetSize(trackWidth, topRowHeight + labelSpacing + thumbSize)
	control.trackWidth = trackWidth

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.label:SetFont(theme.fonts.arialNarrow, 12, "")
	control.label:SetTextColor(0.85, 0.85, 0.88, 1)
	control.label:SetJustifyH("LEFT")
	control.label:SetJustifyV("MIDDLE")
	control.label:SetText(text or "Slider")

	control.valueInput = CreateFrame("EditBox", nil, control)
	control.valueInput:SetAutoFocus(false)
	control.valueInput:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, 0)
	control.valueInput:SetSize(valueInputWidth, topRowHeight)
	control.valueInput:SetFont(theme.fonts.arialNarrow, 12, "")
	control.valueInput:SetTextColor(0.65, 0.65, 0.68, 1)
	control.valueInput:SetJustifyH("RIGHT")
	control.valueInput:SetTextInsets(0, 0, 0, 0)
	control.valueInput:SetText("0")
	control.valueInput:SetCursorPosition(0)

	control.label:ClearAllPoints()
	control.label:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
	control.label:SetPoint("TOPRIGHT", control.valueInput, "TOPLEFT", -valueInputGap, 0)
	control.label:SetHeight(topRowHeight)

	control.slider = CreateFrame("Slider", nil, control)
	control.slider:SetOrientation("HORIZONTAL")
	control.slider:SetPoint("TOPLEFT", control, "TOPLEFT", 0, -(topRowHeight + labelSpacing))
	control.slider:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, -(topRowHeight + labelSpacing))
	control.slider:SetHeight(thumbSize)
	control.slider:SetMinMaxValues(0, 100)
	control.slider:SetValueStep(1)
	control.slider:SetObeyStepOnDrag(true)

	control.track = control.slider:CreateTexture(nil, "BACKGROUND")
	control.track:SetColorTexture(theme:GetColor("controlBackground"))
	control.track:SetSize(trackWidth, trackHeight)
	control.track:SetPoint("TOPLEFT", control.slider, "TOPLEFT", 0, -trackVerticalOffset)

	control.trackTopBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackTopBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	control.trackTopBorder:SetPoint("TOPLEFT", control.track, "TOPLEFT", 0, 0)
	control.trackTopBorder:SetPoint("TOPRIGHT", control.track, "TOPRIGHT", 0, 0)
	control.trackTopBorder:SetHeight(borderThickness)

	control.trackBottomBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackBottomBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	control.trackBottomBorder:SetPoint("BOTTOMLEFT", control.track, "BOTTOMLEFT", 0, 0)
	control.trackBottomBorder:SetPoint("BOTTOMRIGHT", control.track, "BOTTOMRIGHT", 0, 0)
	control.trackBottomBorder:SetHeight(borderThickness)

	control.trackLeftBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackLeftBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	control.trackLeftBorder:SetPoint("TOPLEFT", control.track, "TOPLEFT", 0, 0)
	control.trackLeftBorder:SetPoint("BOTTOMLEFT", control.track, "BOTTOMLEFT", 0, 0)
	control.trackLeftBorder:SetWidth(borderThickness)

	control.trackRightBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackRightBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	control.trackRightBorder:SetPoint("TOPRIGHT", control.track, "TOPRIGHT", 0, 0)
	control.trackRightBorder:SetPoint("BOTTOMRIGHT", control.track, "BOTTOMRIGHT", 0, 0)
	control.trackRightBorder:SetWidth(borderThickness)

	control.fill = control.slider:CreateTexture(nil, "ARTWORK")
	control.fill:SetDrawLayer("ARTWORK", 1)
	control.fill:SetColorTexture(
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4]
	)
	control.fill:SetPoint("LEFT", control.track, "LEFT", 0, 0)
	control.fill:SetHeight(trackHeight)
	control.fill:SetWidth(0)

	control.slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
	control.thumb = control.slider:GetThumbTexture()
	control.thumb:SetSize(thumbSize, thumbSize)
	control.thumb:SetVertexColor(0, 0, 0, 0)

	control.handle = control.slider:CreateTexture(nil, "OVERLAY")
	control.handle:SetDrawLayer("OVERLAY", 2)
	control.handle:SetColorTexture(
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4]
	)
	control.handle:SetSize(thumbSize, thumbSize)

	function control:SetLabel(value)
		self.label:SetText(value or "")
	end

	function control:SetValueFormatter(formatter)
		self.valueFormatter = formatter
		UpdateValueText(self, self.slider:GetValue())
	end

	function control:SetValueParser(parser)
		self.valueParser = parser
	end

	function control:SetOnValueChanged(callback)
		self.onValueChanged = callback
	end

	function control:SetMinMaxValues(minValue, maxValue)
		self.slider:SetMinMaxValues(minValue, maxValue)
		UpdateVisuals(self)
		UpdateValueText(self, self.slider:GetValue())
	end

	function control:SetStep(step)
		self.slider:SetValueStep(step)
		self.slider:SetObeyStepOnDrag(true)
	end

	function control:SetValue(value)
		self.slider:SetValue(value)
	end

	function control:SetControlWidth(width)
		local snappedWidth = addon.Utilities:ToUI(addon.Utilities:ToPixels(width))
		self:SetWidth(snappedWidth)
		self.trackWidth = snappedWidth
		self.track:SetWidth(snappedWidth)
		UpdateVisuals(self)
	end

	function control:SetValueSilently(value)
		self.suppressValueChanged = true
		self.slider:SetValue(value)
		self.suppressValueChanged = false
	end

	function control:GetValue()
		return self.slider:GetValue()
	end

	control.valueInput:SetScript("OnEnterPressed", function()
		CommitValueInput(control)
	end)

	control.valueInput:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
	end)

	control.valueInput:SetScript("OnMouseUp", function(self)
		if self:HasFocus() then
			self:HighlightText()
		end
	end)

	control.valueInput:SetScript("OnEscapePressed", function()
		UpdateValueText(control, control.slider:GetValue())
		control.valueInput:ClearFocus()
	end)

	control.valueInput:SetScript("OnEditFocusLost", function()
		CommitValueInput(control)
	end)

	control.slider:SetScript("OnEnter", function()
		control.handle:SetColorTexture(
			hoverAccentColor[1],
			hoverAccentColor[2],
			hoverAccentColor[3],
			hoverAccentColor[4]
		)
		control.fill:SetColorTexture(
			hoverAccentColor[1],
			hoverAccentColor[2],
			hoverAccentColor[3],
			hoverAccentColor[4]
		)
	end)

	control.slider:SetScript("OnLeave", function()
		control.handle:SetColorTexture(
			theme.colors.brand[1],
			theme.colors.brand[2],
			theme.colors.brand[3],
			theme.colors.brand[4]
		)
		control.fill:SetColorTexture(
			theme.colors.brand[1],
			theme.colors.brand[2],
			theme.colors.brand[3],
			theme.colors.brand[4]
		)
	end)

	control.slider:SetScript("OnValueChanged", function(_, value)
		UpdateVisuals(control)
		UpdateValueText(control, value)

		if control.suppressValueChanged then
			return
		end

		if control.onValueChanged then
			control.onValueChanged(control, value)
		end
	end)

	control:SetValue(0)
	UpdateValueText(control, control.slider:GetValue())

	return control
end
