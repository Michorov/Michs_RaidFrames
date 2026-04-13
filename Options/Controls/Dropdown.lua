local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.Dropdown = addon.Options.Controls.Dropdown or {}

local Dropdown = addon.Options.Controls.Dropdown
local theme = addon.Options.Theme

local openDropdown
local defaultArrowColor = { 0.72, 0.74, 0.78, 1 }

local function HideOpenDropdown()
	if not openDropdown then
		return
	end

	openDropdown:SetArrowColor(defaultArrowColor)
	openDropdown.list:Hide()
	openDropdown = nil
end

local function GetOptionText(options, value)
	for _, option in ipairs(options or {}) do
		if option.value == value then
			return option.text
		end
	end

	return nil
end

local function UpdateSelectionText(control)
	local selectedText = GetOptionText(control.options, control.value)
	local isPlaceholder = not selectedText

	control.selectionText:SetText(selectedText or control.placeholder or "")

	if isPlaceholder then
		control.selectionText:SetTextColor(0.50, 0.52, 0.56, 1)
	else
		control.selectionText:SetTextColor(0.85, 0.85, 0.88, 1)
	end
end

local function SetArrowColor(control, color)
	control.arrow.leftStroke:SetColorTexture(color[1], color[2], color[3], color[4])
	control.arrow.rightStroke:SetColorTexture(color[1], color[2], color[3], color[4])
end

local function EnsureListRows(control)
	control.list.buttons = control.list.buttons or {}

	for index, option in ipairs(control.options or {}) do
		local button = control.list.buttons[index]

		if not button then
			button = CreateFrame("Button", nil, control.list, "BackdropTemplate")
			button:SetFrameLevel(control.list:GetFrameLevel() + 1)
			button:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8x8",
			})
			button:SetBackdropColor(0, 0, 0, 0)

			button.hoverTexture = button:CreateTexture(nil, "ARTWORK")
			button.hoverTexture:SetColorTexture(theme:GetColor("controlHoverOverlay"))
			button.hoverTexture:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
			button.hoverTexture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
			button.hoverTexture:Hide()

			button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			button.text:SetFont(theme.fonts.arialNarrow, 12, "")
			button.text:SetJustifyH("LEFT")

			button:SetScript("OnEnter", function(self)
				self.hoverTexture:Show()
			end)

			button:SetScript("OnLeave", function(self)
				self.hoverTexture:Hide()
			end)

			control.list.buttons[index] = button
		end

		button.value = option.value
		button.text:SetText(option.text or "")
		button.text:SetTextColor(0.85, 0.85, 0.88, 1)
		button.text:ClearAllPoints()
		button.text:SetPoint(
			"LEFT",
			button,
			"LEFT",
			addon.Utilities:ToUI(addon.Utilities:ToPixels(control.layoutValues.textInset)),
			0
		)
		button.text:SetPoint(
			"RIGHT",
			button,
			"RIGHT",
			-addon.Utilities:ToUI(addon.Utilities:ToPixels(control.layoutValues.textInset)),
			0
		)
		button:Show()

		button:SetScript("OnClick", function(self)
			control:SetValue(self.value)
			HideOpenDropdown()

			if control.onValueChanged then
				control.onValueChanged(control, self.value)
			end
		end)
	end

	for index = #control.options + 1, #control.list.buttons do
		control.list.buttons[index]:Hide()
	end
end

local function UpdateListLayout(control)
	local borderThicknessPx = addon.Utilities:ToPixels(control.layoutValues.borderThickness)
	local rowHeightPx = addon.Utilities:ToPixels(control.layoutValues.listRowHeight)
	local rowSpacingPx = addon.Utilities:ToPixels(control.layoutValues.listRowSpacing)
	local listPaddingPx = addon.Utilities:ToPixels(control.layoutValues.listPadding)
	local borderThickness = addon.Utilities:ToUI(borderThicknessPx)
	local rowHeight = addon.Utilities:ToUI(rowHeightPx)
	local rowSpacing = addon.Utilities:ToUI(rowSpacingPx)
	local listPadding = addon.Utilities:ToUI(listPaddingPx)
	local listWidth = control:GetWidth()
	local optionCount = #(control.options or {})
	local listHeight = (optionCount * rowHeight) + math.max(0, optionCount - 1) * rowSpacing + (listPadding * 2)

	control.list:ClearAllPoints()
	control.list:SetPoint("TOPLEFT", control.field, "BOTTOMLEFT", 0, -borderThickness)
	control.list:SetWidth(listWidth)
	control.list:SetHeight(listHeight)

	control.list.topBorder:ClearAllPoints()
	control.list.topBorder:SetPoint("TOPLEFT", control.list, "TOPLEFT", 0, 0)
	control.list.topBorder:SetPoint("TOPRIGHT", control.list, "TOPRIGHT", 0, 0)
	control.list.topBorder:SetHeight(borderThickness)

	control.list.bottomBorder:ClearAllPoints()
	control.list.bottomBorder:SetPoint("BOTTOMLEFT", control.list, "BOTTOMLEFT", 0, 0)
	control.list.bottomBorder:SetPoint("BOTTOMRIGHT", control.list, "BOTTOMRIGHT", 0, 0)
	control.list.bottomBorder:SetHeight(borderThickness)

	control.list.leftBorder:ClearAllPoints()
	control.list.leftBorder:SetPoint("TOPLEFT", control.list, "TOPLEFT", 0, 0)
	control.list.leftBorder:SetPoint("BOTTOMLEFT", control.list, "BOTTOMLEFT", 0, 0)
	control.list.leftBorder:SetWidth(borderThickness)

	control.list.rightBorder:ClearAllPoints()
	control.list.rightBorder:SetPoint("TOPRIGHT", control.list, "TOPRIGHT", 0, 0)
	control.list.rightBorder:SetPoint("BOTTOMRIGHT", control.list, "BOTTOMRIGHT", 0, 0)
	control.list.rightBorder:SetWidth(borderThickness)

	EnsureListRows(control)

	local previousButton
	for _, button in ipairs(control.list.buttons or {}) do
		if button:IsShown() then
			button:ClearAllPoints()
			button:SetHeight(rowHeight)

			if not previousButton then
				button:SetPoint("TOPLEFT", control.list, "TOPLEFT", listPadding, -listPadding)
				button:SetPoint("TOPRIGHT", control.list, "TOPRIGHT", -listPadding, -listPadding)
			else
				button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -rowSpacing)
				button:SetPoint("TOPRIGHT", previousButton, "BOTTOMRIGHT", 0, -rowSpacing)
			end
			previousButton = button
		end
	end
end

local function ToggleDropdown(control)
	if openDropdown == control then
		HideOpenDropdown()
		return
	end

	HideOpenDropdown()
	UpdateListLayout(control)
	control.list:SetFrameLevel(control:GetFrameLevel() + 50)
	control.list:Raise()
	control.list:Show()
	openDropdown = control
end

function Dropdown:Create(parent, labelText)
	local control = CreateFrame("Frame", nil, parent)
	control.layoutValues = {
		width = 220,
		fieldHeight = 24,
		labelHeight = 16,
		labelSpacing = 4,
		labelInset = 2,
		borderThickness = 1,
		textInset = 10,
		arrowInset = 10,
		arrowWidth = 8,
		arrowHeight = 6,
		arrowStrokeThickness = 1,
		selectionRightInset = 24,
		listRowHeight = 24,
		listRowSpacing = 2,
		listPadding = 4,
	}

	control:SetSize(
		addon.Utilities:ToUI(addon.Utilities:ToPixels(control.layoutValues.width)),
		addon.Utilities:ToUI(
			addon.Utilities:ToPixels(
				control.layoutValues.labelHeight + control.layoutValues.labelSpacing + control.layoutValues.fieldHeight
			)
		)
	)
	control.options = {}
	control.value = nil
	control.placeholder = "Select..."
	control.labelVisible = true

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.label:SetFont(theme.fonts.arialNarrow, 12, "")
	control.label:SetTextColor(0.85, 0.85, 0.88, 1)
	control.label:SetJustifyH("LEFT")
	control.label:SetText(labelText or "Dropdown")

	control.field = CreateFrame("Button", nil, control, "BackdropTemplate")
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

	control.selectionText = control.field:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.selectionText:SetFont(theme.fonts.arialNarrow, 12, "")
	control.selectionText:SetTextColor(0.85, 0.85, 0.88, 1)
	control.selectionText:SetJustifyH("LEFT")
	control.selectionText:SetText(control.placeholder)

	control.arrow = CreateFrame("Frame", nil, control.field)

	control.arrow.leftStroke = control.arrow:CreateLine(nil, "OVERLAY")
	control.arrow.leftStroke:SetStartPoint("TOPLEFT", control.arrow, 0, 0)
	control.arrow.leftStroke:SetEndPoint("BOTTOM", control.arrow, 0, 0)

	control.arrow.rightStroke = control.arrow:CreateLine(nil, "OVERLAY")
	control.arrow.rightStroke:SetStartPoint("TOPRIGHT", control.arrow, 0, 0)
	control.arrow.rightStroke:SetEndPoint("BOTTOM", control.arrow, 0, 0)

	function control:SetArrowColor(color)
		SetArrowColor(self, color)
	end

	control:SetArrowColor(defaultArrowColor)

	control.field.hoverTexture = control.field:CreateTexture(nil, "ARTWORK")
	control.field.hoverTexture:SetColorTexture(theme:GetColor("controlHoverOverlay"))
	control.field.hoverTexture:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.hoverTexture:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)
	control.field.hoverTexture:Hide()

	control.field:SetScript("OnEnter", function(self)
		self.hoverTexture:Show()
		control:SetArrowColor({ theme:GetColor("brand") })
	end)

	control.field:SetScript("OnLeave", function(self)
		self.hoverTexture:Hide()
		if openDropdown ~= control then
			control:SetArrowColor(defaultArrowColor)
		end
	end)

	control.list = CreateFrame("Frame", nil, control, "BackdropTemplate")
	control.list:SetFrameStrata("DIALOG")
	control.list:SetFrameLevel(control:GetFrameLevel() + 50)
	control.list:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	control.list:SetBackdropColor(theme:GetColor("controlBackground"))
	control.list:Hide()

	control.list.topBorder = control.list:CreateTexture(nil, "OVERLAY")
	control.list.topBorder:SetColorTexture(theme:GetColor("border"))

	control.list.bottomBorder = control.list:CreateTexture(nil, "OVERLAY")
	control.list.bottomBorder:SetColorTexture(theme:GetColor("border"))

	control.list.leftBorder = control.list:CreateTexture(nil, "OVERLAY")
	control.list.leftBorder:SetColorTexture(theme:GetColor("border"))

	control.list.rightBorder = control.list:CreateTexture(nil, "OVERLAY")
	control.list.rightBorder:SetColorTexture(theme:GetColor("border"))

	function control:SetOptions(options)
		self.options = options or {}
		UpdateSelectionText(self)
		UpdateListLayout(self)
	end

	function control:SetValue(value)
		self.value = value
		UpdateSelectionText(self)
	end

	function control:GetValue()
		return self.value
	end

	function control:SetPlaceholder(text)
		self.placeholder = text or ""
		UpdateSelectionText(self)
	end

	function control:SetLabel(text)
		self.label:SetText(text or "")
	end

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

	function control:SetLabelVisible(isVisible)
		self.labelVisible = isVisible ~= false
		self:UpdateLayout()
	end

	function control:SetOnValueChanged(callback)
		self.onValueChanged = callback
	end

	function control:UpdateLayout()
		local labelSpacingPx = addon.Utilities:ToPixels(self.layoutValues.labelSpacing)
		local fieldHeightPx = addon.Utilities:ToPixels(self.layoutValues.fieldHeight)
		local labelHeightPx = addon.Utilities:ToPixels(self.layoutValues.labelHeight)
		local labelInsetPx = addon.Utilities:ToPixels(self.layoutValues.labelInset)
		local borderThicknessPx = addon.Utilities:ToPixels(self.layoutValues.borderThickness)
		local textInsetPx = addon.Utilities:ToPixels(self.layoutValues.textInset)
		local arrowInsetPx = addon.Utilities:ToPixels(self.layoutValues.arrowInset)
		local arrowWidthPx = addon.Utilities:ToPixels(self.layoutValues.arrowWidth)
		local arrowHeightPx = addon.Utilities:ToPixels(self.layoutValues.arrowHeight)
		local arrowStrokeThicknessPx = addon.Utilities:ToPixels(self.layoutValues.arrowStrokeThickness)
		local selectionRightInsetPx = addon.Utilities:ToPixels(self.layoutValues.selectionRightInset)

		local labelSpacing = addon.Utilities:ToUI(labelSpacingPx)
		local fieldHeight = addon.Utilities:ToUI(fieldHeightPx)
		local labelHeight = addon.Utilities:ToUI(labelHeightPx)
		local labelInset = addon.Utilities:ToUI(labelInsetPx)
		local borderThickness = addon.Utilities:ToUI(borderThicknessPx)
		local textInset = addon.Utilities:ToUI(textInsetPx)
		local arrowInset = addon.Utilities:ToUI(arrowInsetPx)
		local widthPx = addon.Utilities:ToPixels(self.layoutValues.width)

		self:SetWidth(addon.Utilities:ToUI(widthPx))

		self.label:ClearAllPoints()
		self.field:ClearAllPoints()

		if self.labelVisible then
			self:SetHeight(addon.Utilities:ToUI(labelHeightPx + labelSpacingPx + fieldHeightPx))
			self.label:Show()
			self.label:SetPoint("TOPLEFT", self, "TOPLEFT", labelInset, 0)
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

		self.field.topBorder:SetHeight(borderThickness)
		self.field.bottomBorder:SetHeight(borderThickness)
		self.field.leftBorder:SetWidth(borderThickness)
		self.field.rightBorder:SetWidth(borderThickness)

		self.selectionText:ClearAllPoints()
		self.selectionText:SetPoint("LEFT", self.field, "LEFT", textInset, 0)
		self.selectionText:SetPoint(
			"RIGHT",
			self.field,
			"RIGHT",
			-addon.Utilities:ToUI(selectionRightInsetPx),
			0
		)

		self.arrow:SetSize(addon.Utilities:ToUI(arrowWidthPx), addon.Utilities:ToUI(arrowHeightPx))
		self.arrow:ClearAllPoints()
		self.arrow:SetPoint("CENTER", self.field, "CENTER", 0, 0)
		self.arrow:SetPoint("RIGHT", self.field, "RIGHT", -arrowInset, 0)
		self.arrow.leftStroke:SetThickness(addon.Utilities:ToUI(arrowStrokeThicknessPx))
		self.arrow.rightStroke:SetThickness(addon.Utilities:ToUI(arrowStrokeThicknessPx))

		if openDropdown == self then
			UpdateListLayout(self)
		end
	end

	control.field:SetScript("OnClick", function()
		ToggleDropdown(control)
		if openDropdown == control then
			control:SetArrowColor({ theme:GetColor("brand") })
		else
			control:SetArrowColor(defaultArrowColor)
		end
	end)

	control:UpdateLayout()
	UpdateSelectionText(control)

	return control
end

function Dropdown:CloseOpenDropdown()
	HideOpenDropdown()
end
