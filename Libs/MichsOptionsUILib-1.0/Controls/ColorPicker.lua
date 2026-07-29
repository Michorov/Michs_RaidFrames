local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

OptionsUILib.Controls = OptionsUILib.Controls or {}
OptionsUILib.Controls.ColorPicker = OptionsUILib.Controls.ColorPicker or {}

local ColorPicker = OptionsUILib.Controls.ColorPicker

local function ClampChannel(value, fallback)
	value = tonumber(value)
	if value == nil then
		return fallback
	end

	return math.max(0, math.min(1, value))
end

local function UpdateVisual(control)
	control.swatchFill:SetColorTexture(control.r, control.g, control.b, control.a)
	control.field.hoverTexture:SetShown(control.isHovered == true)
end

local function NotifyValueChanged(control)
	local value = {
		r = control.r,
		g = control.g,
		b = control.b,
		a = control.a,
	}

	if control.HandleValueChanged then
		control:HandleValueChanged(value)
	elseif control.onValueChanged then
		control.onValueChanged(control, value)
	end
end

local function OpenPicker(control)
	if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then
		return
	end

	if OptionsUILib.Controls.Dropdown then
		OptionsUILib.Controls.Dropdown:CloseOpenDropdown()
	end

	local initialR, initialG, initialB, initialA = control:GetColor()

	local function ApplyFromPicker()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		local a = control.hasOpacity and (ColorPickerFrame:GetColorAlpha() or 1) or 1

		control:SetColor(r, g, b, a)
		NotifyValueChanged(control)
	end

	ColorPickerFrame:SetupColorPickerAndShow({
		swatchFunc = ApplyFromPicker,
		opacityFunc = ApplyFromPicker,
		cancelFunc = function(previousValues)
			if type(previousValues) == "table" then
				control:SetColor(
					previousValues.r or initialR,
					previousValues.g or initialG,
					previousValues.b or initialB,
					previousValues.a or previousValues.opacity or initialA
				)
			else
				control:SetColor(initialR, initialG, initialB, initialA)
			end

			NotifyValueChanged(control)
		end,
		hasOpacity = control.hasOpacity,
		opacity = initialA,
		r = initialR,
		g = initialG,
		b = initialB,
	})
end

function ColorPicker:Create(parent, PP, labelText)
	local control = CreateFrame("Frame", nil, parent)

	control.PP = PP
	control.layout = {
		parent = parent,
		width = 220,
		height = 44,
		pickerSize = 24,
		labelInset = 8,
		borderThickness = 1,
		swatchInnerInset = 2,
		fontSize = 12,
		point = nil,
		relativeTo = parent,
		relativePoint = nil,
		offsetX = 0,
		offsetY = 0,
	}
	control.labelVisible = true
	control.hasOpacity = false
	control.isHovered = false
	control.r = 1
	control.g = 1
	control.b = 1
	control.a = 1

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.label:SetTextColor(OptionsUILib.Theme:GetTextColor("primary"))
	control.label:SetJustifyH("LEFT")
	control.label:SetJustifyV("MIDDLE")
	control.label:SetText(labelText or "Color")

	control.field = CreateFrame("Button", nil, control, "BackdropTemplate")
	control.field:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	control.field:SetBackdropColor(0.02, 0.03, 0.04, 1)

	control.field.topBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.topBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.field.topBorder:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.topBorder:SetPoint("TOPRIGHT", control.field, "TOPRIGHT", 0, 0)

	control.field.bottomBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.bottomBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.field.bottomBorder:SetPoint("BOTTOMLEFT", control.field, "BOTTOMLEFT", 0, 0)
	control.field.bottomBorder:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)

	control.field.leftBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.leftBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.field.leftBorder:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.leftBorder:SetPoint("BOTTOMLEFT", control.field, "BOTTOMLEFT", 0, 0)

	control.field.rightBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.rightBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.field.rightBorder:SetPoint("TOPRIGHT", control.field, "TOPRIGHT", 0, 0)
	control.field.rightBorder:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)

	control.field.hoverTexture = control.field:CreateTexture(nil, "OVERLAY", nil, 1)
	control.field.hoverTexture:SetColorTexture(OptionsUILib.Theme:GetColor("controlHoverOverlay"))
	control.field.hoverTexture:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.hoverTexture:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)
	control.field.hoverTexture:Hide()

	control.swatchFill = control.field:CreateTexture(nil, "ARTWORK")

	function control:SetLabel(text)
		self.label:SetText(text or "")
	end

	function control:SetLayoutWidth(width)
		self.layout.width = width
		self:UpdateLayout()
	end

	function control:SetLayoutHeight(height)
		self.layout.height = height
		self:UpdateLayout()
	end

	function control:SetLayoutSize(width, height)
		self.layout.width = width
		self.layout.height = height
		self:UpdateLayout()
	end

	function control:SetPickerSize(size)
		self.layout.pickerSize = size
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

	function control:SetLabelVisible(isVisible)
		self.labelVisible = isVisible ~= false
		self:UpdateLayout()
	end

	function control:SetHasOpacity(hasOpacity)
		self.hasOpacity = hasOpacity == true
		self.a = self.hasOpacity and self.a or 1
		UpdateVisual(self)
	end

	function control:SetColor(r, g, b, a)
		if type(r) == "table" then
			a = r.a
			b = r.b
			g = r.g
			r = r.r
		end

		self.r = ClampChannel(r, self.r)
		self.g = ClampChannel(g, self.g)
		self.b = ClampChannel(b, self.b)
		self.a = self.hasOpacity and ClampChannel(a, self.a) or 1

		UpdateVisual(self)
	end

	function control:SetBoundValue(value)
		self:SetColor(value)
	end

	function control:GetColor()
		return self.r, self.g, self.b, self.a
	end

	function control:SetOnValueChanged(callback)
		self.onValueChanged = function(_, value)
			if type(value) == "table" then
				callback(self, value.r, value.g, value.b, value.a)
			else
				callback(self, self.r, self.g, self.b, self.a)
			end
		end
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
		local pickerSize = PP:ToUIScaled(self.layout.pickerSize)
		local borderThickness = PP:ToUIScaled(self.layout.borderThickness)
		local swatchInnerInset = PP:ToUIScaled(self.layout.swatchInnerInset)
		local pickerTopInset = PP:ToUIScaled(math.max(0, self.layout.height - self.layout.pickerSize))

		self:SetSize(PP:ToUIScaled(self.layout.width), PP:ToUIScaled(self.layout.height))
		OptionsUILib.Theme:ApplyFont(self.label, PP:ScaleFont(self.layout.fontSize), "")

		self.field:ClearAllPoints()
		self.field:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -pickerTopInset)
		self.field:SetSize(pickerSize, pickerSize)

		self.field.topBorder:SetHeight(borderThickness)
		self.field.bottomBorder:SetHeight(borderThickness)
		self.field.leftBorder:SetWidth(borderThickness)
		self.field.rightBorder:SetWidth(borderThickness)

		self.swatchFill:ClearAllPoints()
		self.swatchFill:SetPoint("TOPLEFT", self.field, "TOPLEFT", swatchInnerInset, -swatchInnerInset)
		self.swatchFill:SetPoint("BOTTOMRIGHT", self.field, "BOTTOMRIGHT", -swatchInnerInset, swatchInnerInset)

		self.label:ClearAllPoints()
		if self.labelVisible then
			self.label:Show()
			self.label:SetPoint("LEFT", self.field, "RIGHT", PP:ToUIScaled(self.layout.labelInset), 0)
			self.label:SetPoint("RIGHT", self, "RIGHT", 0, 0)
			self.label:SetPoint("TOP", self.field, "TOP", 0, 0)
			self.label:SetPoint("BOTTOM", self.field, "BOTTOM", 0, 0)
		else
			self.label:Hide()
		end

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
	end

	control.field:SetScript("OnEnter", function()
		control.isHovered = true
		UpdateVisual(control)
	end)

	control.field:SetScript("OnLeave", function()
		control.isHovered = false
		UpdateVisual(control)
	end)

	control.field:SetScript("OnClick", function()
		OpenPicker(control)
	end)

	control:UpdateLayout()
	UpdateVisual(control)

	return control
end
