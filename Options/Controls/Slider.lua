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
	control.layoutValues = {
		width = 200,
		trackHeight = 4,
		thumbSize = 12,
		trackVerticalOffset = 4,
		topRowHeight = 16,
		labelSpacing = 6,
		borderThickness = 1,
		valueInputWidth = 40,
		valueInputGap = 6,
	}

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	theme:ApplyFont(control.label, "arialNarrow", 12, "")
	control.label:SetTextColor(theme:GetTextColor("primary"))
	control.label:SetJustifyH("LEFT")
	control.label:SetJustifyV("MIDDLE")
	control.label:SetText(text or "Slider")

	control.valueInput = CreateFrame("EditBox", nil, control)
	control.valueInput:SetAutoFocus(false)
	control.valueInput:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, 0)
	theme:ApplyFont(control.valueInput, "arialNarrow", 12, "")
	control.valueInput:SetTextColor(0.65, 0.65, 0.68, 1)
	control.valueInput:SetJustifyH("RIGHT")
	control.valueInput:SetTextInsets(0, 0, 0, 0)
	control.valueInput:SetText("0")
	control.valueInput:SetCursorPosition(0)

	control.slider = CreateFrame("Slider", nil, control)
	control.slider:SetOrientation("HORIZONTAL")
	control.slider:SetMinMaxValues(0, 100)
	control.slider:SetValueStep(1)
	control.slider:SetObeyStepOnDrag(true)

	control.track = control.slider:CreateTexture(nil, "BACKGROUND")
	control.track:SetColorTexture(theme:GetColor("controlBackground"))

	control.trackTopBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackTopBorder:SetColorTexture(theme:GetColor("border"))
	control.trackTopBorder:SetPoint("TOPLEFT", control.track, "TOPLEFT", 0, 0)
	control.trackTopBorder:SetPoint("TOPRIGHT", control.track, "TOPRIGHT", 0, 0)

	control.trackBottomBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackBottomBorder:SetColorTexture(theme:GetColor("border"))
	control.trackBottomBorder:SetPoint("BOTTOMLEFT", control.track, "BOTTOMLEFT", 0, 0)
	control.trackBottomBorder:SetPoint("BOTTOMRIGHT", control.track, "BOTTOMRIGHT", 0, 0)

	control.trackLeftBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackLeftBorder:SetColorTexture(theme:GetColor("border"))
	control.trackLeftBorder:SetPoint("TOPLEFT", control.track, "TOPLEFT", 0, 0)
	control.trackLeftBorder:SetPoint("BOTTOMLEFT", control.track, "BOTTOMLEFT", 0, 0)

	control.trackRightBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackRightBorder:SetColorTexture(theme:GetColor("border"))
	control.trackRightBorder:SetPoint("TOPRIGHT", control.track, "TOPRIGHT", 0, 0)
	control.trackRightBorder:SetPoint("BOTTOMRIGHT", control.track, "BOTTOMRIGHT", 0, 0)

	control.fill = control.slider:CreateTexture(nil, "ARTWORK")
	control.fill:SetDrawLayer("ARTWORK", 1)
	control.fill:SetColorTexture(theme:GetColor("brand"))
	control.fill:SetPoint("LEFT", control.track, "LEFT", 0, 0)
	control.fill:SetWidth(0)

	control.slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
	control.thumb = control.slider:GetThumbTexture()
	control.thumb:SetVertexColor(0, 0, 0, 0)

	control.handle = control.slider:CreateTexture(nil, "OVERLAY")
	control.handle:SetDrawLayer("OVERLAY", 2)
	control.handle:SetColorTexture(theme:GetColor("brand"))

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

	function control:SetLayoutWidth(width)
		self.layoutValues.width = width
		self:UpdateLayout()
	end

	function control:SetValueSilently(value)
		self.suppressValueChanged = true
		self.slider:SetValue(value)
		self.suppressValueChanged = false
	end

	function control:GetValue()
		return self.slider:GetValue()
	end

	function control:UpdateLayout()
		local controlWidthPx = addon.Utilities:ToPixels(self.layoutValues.width)
		local trackHeightPx = addon.Utilities:ToPixels(self.layoutValues.trackHeight)
		local thumbSizePx = addon.Utilities:ToPixels(self.layoutValues.thumbSize)
		local trackVerticalOffsetPx = addon.Utilities:ToPixels(self.layoutValues.trackVerticalOffset)
		local topRowHeightPx = addon.Utilities:ToPixels(self.layoutValues.topRowHeight)
		local labelSpacingPx = addon.Utilities:ToPixels(self.layoutValues.labelSpacing)
		local borderThicknessPx = addon.Utilities:ToPixels(self.layoutValues.borderThickness)
		local valueInputWidthPx = addon.Utilities:ToPixels(self.layoutValues.valueInputWidth)
		local valueInputGapPx = addon.Utilities:ToPixels(self.layoutValues.valueInputGap)
		local sliderTopOffsetPx = topRowHeightPx + labelSpacingPx
		local controlHeightPx = topRowHeightPx + labelSpacingPx + thumbSizePx

		self.trackWidth = addon.Utilities:ToUI(controlWidthPx)

		self:SetSize(addon.Utilities:ToUI(controlWidthPx), addon.Utilities:ToUI(controlHeightPx))
		self.valueInput:SetSize(addon.Utilities:ToUI(valueInputWidthPx), addon.Utilities:ToUI(topRowHeightPx))

		self.label:ClearAllPoints()
		self.label:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.label:SetPoint("TOPRIGHT", self.valueInput, "TOPLEFT", -addon.Utilities:ToUI(valueInputGapPx), 0)
		self.label:SetHeight(addon.Utilities:ToUI(topRowHeightPx))

		self.slider:ClearAllPoints()
		self.slider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(sliderTopOffsetPx))
		self.slider:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -addon.Utilities:ToUI(sliderTopOffsetPx))
		self.slider:SetHeight(addon.Utilities:ToUI(thumbSizePx))

		self.track:SetSize(addon.Utilities:ToUI(controlWidthPx), addon.Utilities:ToUI(trackHeightPx))
		self.track:ClearAllPoints()
		self.track:SetPoint("TOPLEFT", self.slider, "TOPLEFT", 0, -addon.Utilities:ToUI(trackVerticalOffsetPx))

		local borderThickness = addon.Utilities:ToUI(borderThicknessPx)
		self.trackTopBorder:SetHeight(borderThickness)
		self.trackBottomBorder:SetHeight(borderThickness)
		self.trackLeftBorder:SetWidth(borderThickness)
		self.trackRightBorder:SetWidth(borderThickness)

		self.fill:SetHeight(addon.Utilities:ToUI(trackHeightPx))
		self.thumb:SetSize(addon.Utilities:ToUI(thumbSizePx), addon.Utilities:ToUI(thumbSizePx))
		self.handle:SetSize(addon.Utilities:ToUI(thumbSizePx), addon.Utilities:ToUI(thumbSizePx))

		UpdateVisuals(self)
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
		control.handle:SetColorTexture(theme:GetColor("brand"))
		control.fill:SetColorTexture(theme:GetColor("brand"))
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

	control:UpdateLayout()
	control:SetValue(0)
	UpdateValueText(control, control.slider:GetValue())

	return control
end
