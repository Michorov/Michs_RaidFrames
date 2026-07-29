local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

OptionsUILib.Controls = OptionsUILib.Controls or {}
OptionsUILib.Controls.Slider = OptionsUILib.Controls.Slider or {}

local Slider = OptionsUILib.Controls.Slider

local function UpdateVisuals(control)
	local minValue, maxValue = control.slider:GetMinMaxValues()
	local value = control.slider:GetValue()
	local valueRange = maxValue - minValue
	local progress = 0

	if valueRange > 0 then
		progress = (value - minValue) / valueRange
	end

	control.fill:SetWidth(control.trackWidth * progress)

	local handleWidth = control.handle:GetWidth() or 0
	local handleTravelWidth = math.max(0, control.trackWidth - handleWidth)
	local handleOffset = (handleWidth / 2) + (handleTravelWidth * progress)

	control.handle:ClearAllPoints()
	control.handle:SetPoint("CENTER", control.track, "LEFT", handleOffset, 0)
end

local function UpdateValueText(control, value)
	if control.valueFormatter then
		control.valueInput:SetText(control.valueFormatter(value))
	elseif math.floor(value) == value then
		control.valueInput:SetText(tostring(value))
	else
		control.valueInput:SetText(string.format("%.2f", value))
	end
end

local function ParsePercentOrRaw(control, text)
	local sanitizedText = (text or ""):gsub("%s+", ""):gsub(",", ".")
	local hasPercent = sanitizedText:find("%%") ~= nil
	local numericText = sanitizedText:gsub("%%", "")
	local number = tonumber(numericText)

	if not number then
		return nil
	end

	local _, maxValue = control.slider:GetMinMaxValues()

	if hasPercent or number > maxValue then
		return number / 100
	end

	return number
end

local function CommitValueInput(control)
	if control.isCommittingValueInput then
		return
	end

	control.isCommittingValueInput = true

	local text = control.valueInput:GetText() or ""
	local parsedValue

	if control.valueParser == "percent" then
		parsedValue = ParsePercentOrRaw(control, text)
	elseif control.valueParser then
		parsedValue = control.valueParser(control, text)
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

function Slider:Create(parent, PP, text)
	if not parent or not PP then
		return nil
	end

	local control = CreateFrame("Frame", nil, parent)

	control.PP = PP
	control.layout = {
		parent = parent,
		width = 220,
		fieldHeight = 24,
		trackHeight = 4,
		thumbSize = 12,
		topRowHeight = 16,
		labelSpacing = 4,
		borderThickness = 1,
		fontSize = 12,
		valueInputWidth = 34,
		valueInputGap = 6,
		point = nil,
		relativeTo = parent,
		relativePoint = nil,
		offsetX = 0,
		offsetY = 0,
	}

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.label:SetTextColor(OptionsUILib.Theme:GetTextColor("primary"))
	control.label:SetJustifyH("LEFT")
	control.label:SetJustifyV("MIDDLE")
	control.label:SetText(text or "Slider")

	control.valueInput = CreateFrame("EditBox", nil, control)
	control.valueInput:SetAutoFocus(false)
	control.valueInput:SetTextColor(0.65, 0.65, 0.68, 1)
	control.valueInput:SetJustifyH("RIGHT")
	control.valueInput:SetTextInsets(0, 0, 0, 0)
	control.valueInput:SetText("0")

	control.slider = CreateFrame("Slider", nil, control)
	control.slider:SetOrientation("HORIZONTAL")
	control.slider:SetMinMaxValues(0, 100)
	control.slider:SetValueStep(1)
	control.slider:SetObeyStepOnDrag(true)

	control.track = control.slider:CreateTexture(nil, "BACKGROUND")
	control.track:SetColorTexture(OptionsUILib.Theme:GetColor("controlBackground"))

	control.trackTopBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackTopBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.trackTopBorder:SetPoint("TOPLEFT", control.track, "TOPLEFT", 0, 0)
	control.trackTopBorder:SetPoint("TOPRIGHT", control.track, "TOPRIGHT", 0, 0)

	control.trackBottomBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackBottomBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.trackBottomBorder:SetPoint("BOTTOMLEFT", control.track, "BOTTOMLEFT", 0, 0)
	control.trackBottomBorder:SetPoint("BOTTOMRIGHT", control.track, "BOTTOMRIGHT", 0, 0)

	control.trackLeftBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackLeftBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.trackLeftBorder:SetPoint("TOPLEFT", control.track, "TOPLEFT", 0, 0)
	control.trackLeftBorder:SetPoint("BOTTOMLEFT", control.track, "BOTTOMLEFT", 0, 0)

	control.trackRightBorder = control.slider:CreateTexture(nil, "OVERLAY")
	control.trackRightBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.trackRightBorder:SetPoint("TOPRIGHT", control.track, "TOPRIGHT", 0, 0)
	control.trackRightBorder:SetPoint("BOTTOMRIGHT", control.track, "BOTTOMRIGHT", 0, 0)

	control.fill = control.slider:CreateTexture(nil, "ARTWORK", nil, 1)
	control.fill:SetColorTexture(OptionsUILib.Theme:GetColor("brand"))
	control.fill:SetPoint("LEFT", control.track, "LEFT", 0, 0)

	control.slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
	control.thumb = control.slider:GetThumbTexture()
	control.thumb:SetVertexColor(0, 0, 0, 0)

	control.handle = control.slider:CreateTexture(nil, "OVERLAY", nil, 2)
	control.handle:SetColorTexture(OptionsUILib.Theme:GetColor("brand"))

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

	function control:SetValueSilently(value)
		self.suppressValueChanged = true
		self.slider:SetValue(value)
		self.suppressValueChanged = false
	end

	function control:SetBoundValue(value)
		self:SetValueSilently(value)
	end

	function control:GetValue()
		return self.slider:GetValue()
	end

	function control:SetLayoutWidth(width)
		self.layout.width = width
		self:UpdateLayout()
	end

	function control:SetBorderSize(borderThickness)
		self.layout.borderThickness = borderThickness
		self:UpdateLayout()
	end

	function control:SetFontSize(fontSize)
		self.layout.fontSize = fontSize
		self:UpdateLayout()
	end

	function control:SetLayoutPoint(point, relativeTo, relativePoint, offsetX, offsetY)
		self.layout.point = point
		self.layout.relativeTo = relativeTo or self.layout.parent
		self.layout.relativePoint = relativePoint or point
		self.layout.offsetX = offsetX or 0
		self.layout.offsetY = offsetY or 0
		self:UpdateLayout()
	end

	function control:UpdateLayout()
		local PP = self.PP
		local width = PP:ToUIScaled(self.layout.width)
		local topRowHeight = PP:ToUIScaled(self.layout.topRowHeight)
		local labelSpacing = PP:ToUIScaled(self.layout.labelSpacing)
		local fieldHeight = PP:ToUIScaled(self.layout.fieldHeight)
		local thumbSize = PP:ToUIScaled(self.layout.thumbSize)
		local trackHeight = PP:ToUIScaled(self.layout.trackHeight)
		local borderThickness = PP:ToUIScaled(self.layout.borderThickness)
		local sliderTopOffset = topRowHeight + labelSpacing

		self.trackWidth = width
		self:SetSize(width, topRowHeight + labelSpacing + fieldHeight)
		OptionsUILib.Theme:ApplyFont(self.label, PP:ScaleFont(self.layout.fontSize), "")
		OptionsUILib.Theme:ApplyFont(self.valueInput, PP:ScaleFont(self.layout.fontSize), "")

		self.valueInput:ClearAllPoints()
		self.valueInput:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
		self.valueInput:SetSize(PP:ToUIScaled(self.layout.valueInputWidth), topRowHeight)

		self.label:ClearAllPoints()
		self.label:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
		self.label:SetPoint("TOPRIGHT", self.valueInput, "TOPLEFT", PP:ToUIScaled(-self.layout.valueInputGap), 0)
		self.label:SetHeight(topRowHeight)

		self.slider:ClearAllPoints()
		self.slider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -sliderTopOffset)
		self.slider:SetSize(width, fieldHeight)

		self.track:SetSize(width, trackHeight)
		PP:CenterElement(self.track, self.slider, 0, 0)

		self.trackTopBorder:SetHeight(borderThickness)
		self.trackBottomBorder:SetHeight(borderThickness)
		self.trackLeftBorder:SetWidth(borderThickness)
		self.trackRightBorder:SetWidth(borderThickness)

		self.fill:SetHeight(trackHeight)
		self.thumb:SetSize(thumbSize, thumbSize)
		self.handle:SetSize(thumbSize, thumbSize)

		if self.layout.point then
			self:ClearAllPoints()
			self:SetPoint(
				self.layout.point,
				self.layout.relativeTo,
				self.layout.relativePoint,
				PP:ToUIScaled(self.layout.offsetX),
				PP:ToUIScaled(self.layout.offsetY)
			)
		end

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
		control.handle:SetColorTexture(1, 0.74, 0.42, 1)
		control.fill:SetColorTexture(1, 0.74, 0.42, 1)
	end)

	control.slider:SetScript("OnLeave", function()
		control.handle:SetColorTexture(OptionsUILib.Theme:GetColor("brand"))
		control.fill:SetColorTexture(OptionsUILib.Theme:GetColor("brand"))
	end)

	control.slider:SetScript("OnValueChanged", function(_, value)
		UpdateVisuals(control)
		UpdateValueText(control, value)

		if not control.suppressValueChanged then
			if control.HandleValueChanged then
				control:HandleValueChanged(value)
			elseif control.onValueChanged then
				control.onValueChanged(control, value)
			end
		end
	end)

	control:UpdateLayout()
	control:SetValue(0)
	UpdateValueText(control, control.slider:GetValue())

	return control
end
