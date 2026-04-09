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

local function UpdateLayout(control)
	local labelSpacing = addon.Utilities:ToUI(addon.Utilities:ToPixels(6))
	local fieldHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(24))

	control.label:ClearAllPoints()
	control.field:ClearAllPoints()

	if control.labelVisible then
		control:SetHeight(addon.Utilities:ToUI(addon.Utilities:ToPixels(46)))
		control.label:Show()
		control.label:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
		control.field:SetPoint("TOPLEFT", control.label, "BOTTOMLEFT", 0, -labelSpacing)
		control.field:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, -labelSpacing)
	else
		control:SetHeight(fieldHeight)
		control.label:Hide()
		control.field:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
		control.field:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, 0)
	end

	control.field:SetHeight(fieldHeight)
	UpdatePlaceholder(control)
end

function Input:Create(parent, labelText)
	local control = CreateFrame("Frame", nil, parent)
	local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(1))
	local fieldHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(24))
	local textInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(10))
	local width = addon.Utilities:ToUI(addon.Utilities:ToPixels(220))

	control:SetSize(width, addon.Utilities:ToUI(addon.Utilities:ToPixels(46)))
	control.placeholder = ""
	control.labelVisible = true

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.label:SetFont(theme.fonts.arialNarrow, 12, "")
	control.label:SetTextColor(0.85, 0.85, 0.88, 1)
	control.label:SetJustifyH("LEFT")
	control.label:SetText(labelText or "Input")

	control.field = CreateFrame("EditBox", nil, control, "BackdropTemplate")
	control.field:SetAutoFocus(false)
	control.field:SetFont(theme.fonts.arialNarrow, 12, "")
	control.field:SetTextColor(0.85, 0.85, 0.88, 1)
	control.field:SetJustifyH("LEFT")
	control.field:SetTextInsets(textInset, textInset, 0, 0)

	control.field:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	control.field:SetBackdropColor(0.04, 0.05, 0.07, 1)

	control.field.topBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.topBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	control.field.topBorder:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.topBorder:SetPoint("TOPRIGHT", control.field, "TOPRIGHT", 0, 0)
	control.field.topBorder:SetHeight(borderThickness)

	control.field.bottomBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.bottomBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	control.field.bottomBorder:SetPoint("BOTTOMLEFT", control.field, "BOTTOMLEFT", 0, 0)
	control.field.bottomBorder:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)
	control.field.bottomBorder:SetHeight(borderThickness)

	control.field.leftBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.leftBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	control.field.leftBorder:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.leftBorder:SetPoint("BOTTOMLEFT", control.field, "BOTTOMLEFT", 0, 0)
	control.field.leftBorder:SetWidth(borderThickness)

	control.field.rightBorder = control.field:CreateTexture(nil, "OVERLAY")
	control.field.rightBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	control.field.rightBorder:SetPoint("TOPRIGHT", control.field, "TOPRIGHT", 0, 0)
	control.field.rightBorder:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)
	control.field.rightBorder:SetWidth(borderThickness)

	control.field.hoverTexture = control.field:CreateTexture(nil, "ARTWORK")
	control.field.hoverTexture:SetColorTexture(1, 1, 1, 0.03)
	control.field.hoverTexture:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.hoverTexture:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)
	control.field.hoverTexture:Hide()

	control.placeholderText = control.field:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	control.placeholderText:SetFont(theme.fonts.arialNarrow, 12, "")
	control.placeholderText:SetTextColor(0.50, 0.52, 0.56, 1)
	control.placeholderText:SetJustifyH("LEFT")
	control.placeholderText:SetPoint("LEFT", control.field, "LEFT", textInset, 0)
	control.placeholderText:SetPoint("RIGHT", control.field, "RIGHT", -textInset, 0)
	control.placeholderText:Hide()

	control.field:SetScript("OnEnter", function(self)
		self.hoverTexture:Show()
	end)

	control.field:SetScript("OnLeave", function(self)
		self.hoverTexture:Hide()
	end)

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
		UpdateLayout(self)
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

	control.field:SetScript("OnEditFocusLost", function(self)
		UpdatePlaceholder(control)

		if control.onEditFocusLost then
			control.onEditFocusLost(control, self:GetText())
		end
	end)

	control.field:SetScript("OnEditFocusGained", function()
		UpdatePlaceholder(control)
	end)

	UpdateLayout(control)

	return control
end
