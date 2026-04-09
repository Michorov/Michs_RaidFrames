local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.Dropdown = addon.Options.Controls.Dropdown or {}

local Dropdown = addon.Options.Controls.Dropdown
local theme = addon.Options.Theme

local openDropdown
local defaultArrowColor = { 0.72, 0.74, 0.78, 1 }

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
end

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
			button.hoverTexture:SetColorTexture(1, 1, 1, 0.03)
			button.hoverTexture:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
			button.hoverTexture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
			button.hoverTexture:Hide()

			button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			button.text:SetFont(theme.fonts.arialNarrow, 12, "")
			button.text:SetJustifyH("LEFT")
			button.text:SetPoint("LEFT", button, "LEFT", addon.Utilities:ToUI(addon.Utilities:ToPixels(10)), 0)
			button.text:SetPoint("RIGHT", button, "RIGHT", addon.Utilities:ToUI(addon.Utilities:ToPixels(-10)), 0)

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
	local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(1))
	local rowHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(24))
	local rowSpacing = addon.Utilities:ToUI(addon.Utilities:ToPixels(2))
	local listPadding = addon.Utilities:ToUI(addon.Utilities:ToPixels(4))
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
	local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(1))
	local textInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(10))
	local arrowInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(10))
	local width = addon.Utilities:ToUI(addon.Utilities:ToPixels(220))

	control:SetSize(width, addon.Utilities:ToUI(addon.Utilities:ToPixels(46)))
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

	control.selectionText = control.field:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.selectionText:SetFont(theme.fonts.arialNarrow, 12, "")
	control.selectionText:SetTextColor(0.85, 0.85, 0.88, 1)
	control.selectionText:SetJustifyH("LEFT")
	control.selectionText:SetPoint("LEFT", control.field, "LEFT", textInset, 0)
	control.selectionText:SetPoint(
		"RIGHT",
		control.field,
		"RIGHT",
		-addon.Utilities:ToUI(addon.Utilities:ToPixels(24)),
		0
	)
	control.selectionText:SetText(control.placeholder)

	control.arrow = CreateFrame("Frame", nil, control.field)
	control.arrow:SetSize(
		addon.Utilities:ToUI(addon.Utilities:ToPixels(8)),
		addon.Utilities:ToUI(addon.Utilities:ToPixels(6))
	)
	control.arrow:SetPoint("CENTER", control.field, "CENTER", 0, 0)
	control.arrow:SetPoint("RIGHT", control.field, "RIGHT", -arrowInset, 0)

	control.arrow.leftStroke = control.arrow:CreateLine(nil, "OVERLAY")
	control.arrow.leftStroke:SetThickness(addon.Utilities:ToUI(addon.Utilities:ToPixels(1)))
	control.arrow.leftStroke:SetStartPoint("TOPLEFT", control.arrow, "TOPLEFT", 0, 0)
	control.arrow.leftStroke:SetEndPoint("BOTTOM", control.arrow, "BOTTOM", 0, 0)

	control.arrow.rightStroke = control.arrow:CreateLine(nil, "OVERLAY")
	control.arrow.rightStroke:SetThickness(addon.Utilities:ToUI(addon.Utilities:ToPixels(1)))
	control.arrow.rightStroke:SetStartPoint("TOPRIGHT", control.arrow, "TOPRIGHT", 0, 0)
	control.arrow.rightStroke:SetEndPoint("BOTTOM", control.arrow, "BOTTOM", 0, 0)

	function control:SetArrowColor(color)
		SetArrowColor(self, color)
	end

	control:SetArrowColor(defaultArrowColor)

	control.field.hoverTexture = control.field:CreateTexture(nil, "ARTWORK")
	control.field.hoverTexture:SetColorTexture(1, 1, 1, 0.03)
	control.field.hoverTexture:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.hoverTexture:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)
	control.field.hoverTexture:Hide()

	control.field:SetScript("OnEnter", function(self)
		self.hoverTexture:Show()
		control:SetArrowColor(theme.colors.brand)
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
	control.list:SetBackdropColor(0.04, 0.05, 0.07, 1)
	control.list:Hide()

	control.list.topBorder = control.list:CreateTexture(nil, "OVERLAY")
	control.list.topBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)

	control.list.bottomBorder = control.list:CreateTexture(nil, "OVERLAY")
	control.list.bottomBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)

	control.list.leftBorder = control.list:CreateTexture(nil, "OVERLAY")
	control.list.leftBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)

	control.list.rightBorder = control.list:CreateTexture(nil, "OVERLAY")
	control.list.rightBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)

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

	function control:SetLabelVisible(isVisible)
		self.labelVisible = isVisible ~= false
		UpdateLayout(self)
	end

	function control:SetOnValueChanged(callback)
		self.onValueChanged = callback
	end

	control.field:SetScript("OnClick", function()
		ToggleDropdown(control)
		if openDropdown == control then
			control:SetArrowColor(theme.colors.brand)
		else
			control:SetArrowColor(defaultArrowColor)
		end
	end)

	UpdateLayout(control)
	UpdateSelectionText(control)

	return control
end

function Dropdown:CloseOpenDropdown()
	HideOpenDropdown()
end
