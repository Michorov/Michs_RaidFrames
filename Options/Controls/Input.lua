local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.Input = addon.Options.Controls.Input or {}

local Input = addon.Options.Controls.Input
local theme = addon.Options.Theme

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

function Input:Create(parent, labelText)
	local control = CreateFrame("Frame", nil, parent)
	control.layoutValues = {
		width = 220,
		fieldHeight = 24,
		labelHeight = 16,
		labelSpacing = 4,
		borderThickness = 1,
		textInset = 10,
	}

	control.placeholder = ""
	control.labelVisible = true

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.label:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
	control.label:SetFont(theme.fonts.arialNarrow, 12, "")
	control.label:SetTextColor(0.85, 0.85, 0.88, 1)
	control.label:SetJustifyH("LEFT")
	control.label:SetText(labelText or "Input")

	control.field = CreateFrame("EditBox", nil, control, "BackdropTemplate")
	control.field:SetAutoFocus(false)
	control.field:SetFont(theme.fonts.arialNarrow, 12, "")
	control.field:SetTextColor(0.85, 0.85, 0.88, 1)
	control.field:SetJustifyH("LEFT")

	control.field:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	control.field:SetBackdropColor(theme:GetColor("controlBackground"))

	control.field.topBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.topBorder:SetColorTexture(theme:GetColor("border"))
	control.field.topBorder:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.topBorder:SetPoint("TOPRIGHT", control.field, "TOPRIGHT", 0, 0)

	control.field.bottomBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.bottomBorder:SetColorTexture(theme:GetColor("border"))
	control.field.bottomBorder:SetPoint("BOTTOMLEFT", control.field, "BOTTOMLEFT", 0, 0)
	control.field.bottomBorder:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)

	control.field.leftBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.leftBorder:SetColorTexture(theme:GetColor("border"))
	control.field.leftBorder:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.leftBorder:SetPoint("BOTTOMLEFT", control.field, "BOTTOMLEFT", 0, 0)

	control.field.rightBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.rightBorder:SetColorTexture(theme:GetColor("border"))
	control.field.rightBorder:SetPoint("TOPRIGHT", control.field, "TOPRIGHT", 0, 0)
	control.field.rightBorder:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)

	control.field.hoverTexture = control.field:CreateTexture(nil, "ARTWORK")
	control.field.hoverTexture:SetColorTexture(theme:GetColor("controlHoverOverlay"))
	control.field.hoverTexture:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.hoverTexture:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)
	control.field.hoverTexture:Hide()

	control.placeholderText = control.field:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	control.placeholderText:SetFont(theme.fonts.arialNarrow, 12, "")
	control.placeholderText:SetTextColor(0.50, 0.52, 0.56, 1)
	control.placeholderText:SetJustifyH("LEFT")
	control.placeholderText:Hide()

	control.field:SetScript("OnEnter", function(self)
		self.hoverTexture:Show()
	end)

	control.field:SetScript("OnLeave", function(self)
		self.hoverTexture:Hide()
	end)

	function control:SetLayoutWidth(width)
		self.layoutValues.width = width
		self:UpdateLayout()
	end

	function control:SetLayoutHeight(height)
		self.layoutValues.fieldHeight = height
		self:UpdateLayout()
	end

	function control:SetLayoutSize(width, height)
		self.layoutValues.width = width
		self.layoutValues.fieldHeight = height
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

	function control:UpdateLayout()
		local labelSpacingPx = addon.Utilities:ToPixels(self.layoutValues.labelSpacing)
		local fieldHeightPx = addon.Utilities:ToPixels(self.layoutValues.fieldHeight)
		local labelHeightPx = addon.Utilities:ToPixels(self.layoutValues.labelHeight)
		local borderThicknessPx = addon.Utilities:ToPixels(self.layoutValues.borderThickness)
		local textInsetPx = addon.Utilities:ToPixels(self.layoutValues.textInset)

		local labelSpacing = addon.Utilities:ToUI(labelSpacingPx)
		local fieldHeight = addon.Utilities:ToUI(fieldHeightPx)
		local labelHeight = addon.Utilities:ToUI(labelHeightPx)
		local borderThickness = addon.Utilities:ToUI(borderThicknessPx)
		local textInset = addon.Utilities:ToUI(textInsetPx)

		local widthPx = addon.Utilities:ToPixels(self.layoutValues.width)
		self:SetWidth(addon.Utilities:ToUI(widthPx))

		self.label:ClearAllPoints()
		self.field:ClearAllPoints()

		if self.labelVisible then
			self:SetHeight(addon.Utilities:ToUI(labelHeightPx + labelSpacingPx + fieldHeightPx))
			self.label:Show()
			self.label:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.label:SetHeight(labelHeight)
			self.field:SetPoint(
				"TOPLEFT",
				self,
				"TOPLEFT",
				0,
				-addon.Utilities:ToUI(labelHeightPx + labelSpacingPx)
			)
			self.field:SetPoint(
				"TOPRIGHT",
				self,
				"TOPRIGHT",
				0,
				-addon.Utilities:ToUI(labelHeightPx + labelSpacingPx)
			)
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

		UpdatePlaceholder(self)
	end

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
