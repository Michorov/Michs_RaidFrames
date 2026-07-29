local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

OptionsUILib.Controls = OptionsUILib.Controls or {}
OptionsUILib.Controls.Input = OptionsUILib.Controls.Input or {}

local Input = OptionsUILib.Controls.Input

local function UpdatePlaceholder(control)
	if not control.placeholderText then
		return
	end

	local text = control.field:GetText() or ""
	local hasFocus = control.field:HasFocus()
	local hasPlaceholder = type(control.placeholder) == "string" and control.placeholder ~= ""

	if hasPlaceholder and text == "" and not hasFocus then
		control.placeholderText:SetText(control.placeholder)
		control.placeholderText:Show()
	else
		control.placeholderText:Hide()
	end
end

function Input:Create(parent, PP, labelText)
	if not parent or not PP then
		return nil
	end

	local control = CreateFrame("Frame", nil, parent)
	control.PP = PP
	control.layout = {
		parent = parent,
		width = 220,
		fieldHeight = 24,
		labelHeight = 16,
		labelSpacing = 4,
		borderThickness = 1,
		textInset = 10,
		fontSize = 12,
		point = nil,
		relativeTo = parent,
		relativePoint = nil,
		offsetX = 0,
		offsetY = 0,
	}

	control.placeholder = ""
	control.labelVisible = true

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.label:SetTextColor(OptionsUILib.Theme:GetTextColor("primary"))
	control.label:SetJustifyH("LEFT")
	control.label:SetText(labelText or "Input")

	control.field = CreateFrame("EditBox", nil, control, "BackdropTemplate")
	control.field:SetAutoFocus(false)
	control.field:SetTextColor(OptionsUILib.Theme:GetTextColor("primary"))
	control.field:SetJustifyH("LEFT")
	control.field:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	control.field:SetBackdropColor(OptionsUILib.Theme:GetColor("controlBackground"))

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

	control.field.hoverTexture = control.field:CreateTexture(nil, "ARTWORK")
	control.field.hoverTexture:SetColorTexture(OptionsUILib.Theme:GetColor("controlHoverOverlay"))
	control.field.hoverTexture:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.hoverTexture:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)
	control.field.hoverTexture:Hide()

	control.placeholderText = control.field:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	control.placeholderText:SetTextColor(OptionsUILib.Theme:GetTextColor("placeholder"))
	control.placeholderText:SetJustifyH("LEFT")
	control.placeholderText:Hide()

	function control:SetLayoutWidth(width)
		self.layout.width = width
		self:UpdateLayout()
	end

	function control:SetLayoutHeight(height)
		self.layout.fieldHeight = height
		self:UpdateLayout()
	end

	function control:SetLayoutSize(width, height)
		self.layout.width = width
		self.layout.fieldHeight = height
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

	function control:SetText(value)
		self.field:SetText(value or "")
		UpdatePlaceholder(self)
	end

	function control:GetText()
		return self.field:GetText() or ""
	end

	function control:SetPlaceholder(text)
		self.placeholder = text or ""
		UpdatePlaceholder(self)
	end

	function control:SetOnTextChanged(callback)
		self.onTextChanged = callback
	end

	function control:SetOnEnterPressed(callback)
		self.onEnterPressed = callback
	end

	function control:SetOnEditFocusLost(callback)
		self.onEditFocusLost = callback
	end

	function control:SetLabel(text)
		self.label:SetText(text or "")
	end

	function control:SetLabelVisible(isVisible)
		self.labelVisible = isVisible ~= false
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
		local labelSpacing = PP:ToUIScaled(self.layout.labelSpacing)
		local fieldHeight = PP:ToUIScaled(self.layout.fieldHeight)
		local labelHeight = PP:ToUIScaled(self.layout.labelHeight)
		local borderThickness = PP:ToUIScaled(self.layout.borderThickness)
		local textInset = PP:ToUIScaled(self.layout.textInset)

		self:SetWidth(PP:ToUIScaled(self.layout.width))
		OptionsUILib.Theme:ApplyFont(self.label, PP:ScaleFont(self.layout.fontSize), "")
		OptionsUILib.Theme:ApplyFont(self.field, PP:ScaleFont(self.layout.fontSize), "")
		OptionsUILib.Theme:ApplyFont(self.placeholderText, PP:ScaleFont(self.layout.fontSize), "")

		self.label:ClearAllPoints()
		self.field:ClearAllPoints()

		if self.labelVisible then
			self:SetHeight(labelHeight + labelSpacing + fieldHeight)
			self.label:Show()
			self.label:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.label:SetHeight(labelHeight)
			self.field:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(labelHeight + labelSpacing))
			self.field:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -(labelHeight + labelSpacing))
		else
			self:SetHeight(fieldHeight)
			self.label:Hide()
			self.field:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.field:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
		end

		self.field:SetHeight(fieldHeight)
		self.field:SetTextInsets(textInset, textInset, 0, 0)
		self.field.topBorder:SetHeight(borderThickness)
		self.field.bottomBorder:SetHeight(borderThickness)
		self.field.leftBorder:SetWidth(borderThickness)
		self.field.rightBorder:SetWidth(borderThickness)

		self.placeholderText:ClearAllPoints()
		self.placeholderText:SetPoint("LEFT", self.field, "LEFT", textInset, 0)
		self.placeholderText:SetPoint("RIGHT", self.field, "RIGHT", -textInset, 0)

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

		UpdatePlaceholder(self)
	end

	control.field:SetScript("OnEnter", function(self)
		self.hoverTexture:Show()
	end)

	control.field:SetScript("OnLeave", function(self)
		self.hoverTexture:Hide()
	end)

	control.field:SetScript("OnTextChanged", function(self, userInput)
		UpdatePlaceholder(control)

		if userInput and control.onTextChanged then
			control.onTextChanged(control, self:GetText())
		end
	end)

	control.field:SetScript("OnEnterPressed", function(self)
		if control.onEnterPressed then
			control.onEnterPressed(control, self:GetText())
		end
		self:ClearFocus()
	end)

	control.field:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)

	control.field:SetScript("OnEditFocusLost", function(self)
		UpdatePlaceholder(control)

		if control.onEditFocusLost then
			control.onEditFocusLost(control, self:GetText())
		end
	end)

	control.field:SetScript("OnEditFocusGained", function()
		UpdatePlaceholder(control)
	end)

	control:UpdateLayout()

	return control
end
