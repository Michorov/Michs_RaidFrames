local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.Dropdown = addon.Options.Controls.Dropdown or {}

local Dropdown = addon.Options.Controls.Dropdown
local theme = addon.Options.Theme

local openDropdown
local defaultArrowColor = { 0.72, 0.74, 0.78, 1 }

local function ToUI(value)
	return addon.Utilities:ToUI(addon.Utilities:ToPixels(value))
end

local function ToPixels(value)
	return addon.Utilities:ToPixels(value)
end

local function HideOpenDropdown()
	if not openDropdown then
		return
	end

	openDropdown:SetArrowColor(defaultArrowColor)
	openDropdown.list:Hide()
	openDropdown = nil
end

local function GetOption(options, value)
	for _, option in ipairs(options or {}) do
		if option.value == value then
			return option
		end
	end

	return nil
end

local function ApplyOptionTexture(texture, option)
	if option and option.texture then
		texture:SetTexture(option.texture)
		texture:Show()
	else
		texture:SetTexture(nil)
		texture:Hide()
	end
end

local function ApplyOptionTextStyle(control, fontString, option, isPlaceholder)
	if not fontString then
		return
	end

	local fontSize = control.layoutValues.fontSize or 12
	local customFontApplied = false

	if option and option.font then
		customFontApplied = fontString:SetFont(option.font, fontSize, "") == true
	end

	if not customFontApplied then
		theme:ApplyFont(fontString, "arialNarrow", fontSize, "")
	end

	if option and option.texture then
		fontString:SetShadowColor(0, 0, 0, 1)
		fontString:SetShadowOffset(1, -1)
	else
		fontString:SetShadowColor(0, 0, 0, 0)
		fontString:SetShadowOffset(0, 0)
	end

	if option and option.textColor then
		fontString:SetTextColor(
			option.textColor[1] or 1,
			option.textColor[2] or 1,
			option.textColor[3] or 1,
			option.textColor[4] or 1
		)
	elseif isPlaceholder then
		fontString:SetTextColor(theme:GetTextColor("placeholder"))
	else
		fontString:SetTextColor(theme:GetTextColor("primary"))
	end
end

local function UpdateSelectionText(control)
	local selectedOption = GetOption(control.options, control.value)
	local selectedText = selectedOption and selectedOption.text or nil
	local isPlaceholder = not selectedText

	control.selectionText:SetText(selectedText or control.placeholder or "")
	ApplyOptionTexture(control.selectionTexture, selectedOption)
	ApplyOptionTextStyle(control, control.selectionText, selectedOption, isPlaceholder)
end

local function SetArrowColor(control, color)
	control.arrow.leftStroke:SetColorTexture(color[1], color[2], color[3], color[4])
	control.arrow.rightStroke:SetColorTexture(color[1], color[2], color[3], color[4])
end

local function ScrollList(control, delta)
	if not control.list.scrollBar:IsShown() then
		return
	end

	local step = ToUI(control.layoutValues.listRowHeight + control.layoutValues.listRowSpacing)
	local value = control.list.scrollBar:GetValue() - (delta * step)
	control.list.scrollBar:SetValue(math.max(0, math.min(control.list.scrollRange, value)))
end

local function StopScrollBarDrag(control)
	control.list.scrollHitArea:SetScript("OnUpdate", nil)
	control.list.scrollDragOffset = nil
end

local function UpdateScrollBarDrag(control)
	if not IsMouseButtonDown("LeftButton") then
		StopScrollBarDrag(control)
		return
	end

	local scrollBar = control.list.scrollBar
	local scrollRange = control.list.scrollRange
	local thumbHeight = scrollBar.thumb:GetHeight()
	local thumbTravel = scrollBar:GetHeight() - thumbHeight

	if scrollRange <= 0 or thumbTravel <= 0 then
		return
	end

	local _, cursorY = GetCursorPosition()
	cursorY = cursorY / scrollBar:GetEffectiveScale()

	local thumbTop = cursorY + control.list.scrollDragOffset
	local topOffset = math.max(0, math.min(thumbTravel, scrollBar:GetTop() - thumbTop))
	scrollBar:SetValue((topOffset / thumbTravel) * scrollRange)
end

local function StartScrollBarDrag(control)
	local scrollBar = control.list.scrollBar
	local scrollRange = control.list.scrollRange
	local thumbHeight = scrollBar.thumb:GetHeight()
	local thumbTravel = scrollBar:GetHeight() - thumbHeight

	if scrollRange <= 0 or thumbTravel <= 0 then
		return
	end

	local _, cursorY = GetCursorPosition()
	cursorY = cursorY / scrollBar:GetEffectiveScale()

	local thumbTop = scrollBar:GetTop() - ((scrollBar:GetValue() / scrollRange) * thumbTravel)
	local thumbBottom = thumbTop - thumbHeight

	if cursorY <= thumbTop and cursorY >= thumbBottom then
		control.list.scrollDragOffset = thumbTop - cursorY
	else
		control.list.scrollDragOffset = thumbHeight / 2
	end

	control.list.scrollHitArea:SetScript("OnUpdate", function()
		UpdateScrollBarDrag(control)
	end)
	UpdateScrollBarDrag(control)
end

local function EnsureListRows(control)
	control.list.buttons = control.list.buttons or {}

	for index, option in ipairs(control.options or {}) do
		local button = control.list.buttons[index]

		if not button then
			button = CreateFrame("Button", nil, control.list.scrollChild, "BackdropTemplate")
			button:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8x8",
			})
			button:SetBackdropColor(0, 0, 0, 0)

			button.previewTexture = button:CreateTexture(nil, "ARTWORK", nil, -1)
			button.previewTexture:SetAllPoints(button)
			button.previewTexture:SetAlpha(0.4)
			button.previewTexture:Hide()

			button.hoverTexture = button:CreateTexture(nil, "ARTWORK")
			button.hoverTexture:SetColorTexture(theme:GetColor("controlHoverOverlay"))
			button.hoverTexture:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
			button.hoverTexture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
			button.hoverTexture:Hide()

			button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			button.text:SetJustifyH("LEFT")
			button.text:SetWordWrap(false)
			button.text:SetMaxLines(1)

			button:SetScript("OnEnter", function(self)
				self.hoverTexture:Show()
			end)

			button:SetScript("OnLeave", function(self)
				self.hoverTexture:Hide()
			end)

			button:EnableMouseWheel(true)
			button:SetScript("OnMouseWheel", function(_, delta)
				ScrollList(control, delta)
			end)

			button:SetScript("OnClick", function(self)
				control:SetValue(self.value)
				HideOpenDropdown()

				if control.onValueChanged then
					control.onValueChanged(control, self.value)
				end
			end)

			control.list.buttons[index] = button
		end

		button:SetFrameLevel(control.list.scrollFrame:GetFrameLevel() + 1)
		button.value = option.value
		ApplyOptionTexture(button.previewTexture, option)
		ApplyOptionTextStyle(control, button.text, option, false)
		button.text:SetText(option.text or "")
		button.text:ClearAllPoints()
		button.text:SetPoint("LEFT", button, "LEFT", ToUI(control.layoutValues.textInset), 0)
		button.text:SetPoint("RIGHT", button, "RIGHT", -ToUI(control.layoutValues.textInset), 0)
		button:Show()
	end

	for index = #(control.options or {}) + 1, #control.list.buttons do
		control.list.buttons[index]:Hide()
	end
end

local function UpdateListLayout(control)
	local borderThicknessPx = ToPixels(control.layoutValues.borderThickness)
	local rowHeightPx = ToPixels(control.layoutValues.listRowHeight)
	local rowSpacingPx = ToPixels(control.layoutValues.listRowSpacing)
	local listPaddingPx = ToPixels(control.layoutValues.listPadding)
	local scrollBarWidthPx = ToPixels(control.layoutValues.scrollBarWidth)
	local scrollBarSpacingPx = ToPixels(control.layoutValues.scrollBarSpacing)
	local borderThickness = addon.Utilities:ToUI(borderThicknessPx)
	local rowHeight = addon.Utilities:ToUI(rowHeightPx)
	local rowSpacing = addon.Utilities:ToUI(rowSpacingPx)
	local listPadding = addon.Utilities:ToUI(listPaddingPx)
	local optionCount = #(control.options or {})
	local visibleCount = math.min(optionCount, control.layoutValues.maxVisibleRows)
	local contentHeightPx = (optionCount * rowHeightPx) + (math.max(0, optionCount - 1) * rowSpacingPx)
	local visibleHeightPx = (visibleCount * rowHeightPx) + (math.max(0, visibleCount - 1) * rowSpacingPx)
	local contentHeight = addon.Utilities:ToUI(contentHeightPx)
	local visibleHeight = addon.Utilities:ToUI(visibleHeightPx)
	local listHeight = visibleHeight + (listPadding * 2)
	local isScrollable = optionCount > control.layoutValues.maxVisibleRows
	local contentWidth = control:GetWidth() - (listPadding * 2)

	if isScrollable then
		contentWidth = contentWidth - addon.Utilities:ToUI(scrollBarWidthPx + scrollBarSpacingPx)
	end

	control.list:ClearAllPoints()
	control.list:SetPoint("TOPLEFT", control.field, "BOTTOMLEFT", 0, -borderThickness)
	control.list:SetWidth(control:GetWidth())
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

	control.list.scrollFrame:ClearAllPoints()
	control.list.scrollFrame:SetPoint("TOPLEFT", control.list, "TOPLEFT", listPadding, -listPadding)
	control.list.scrollFrame:SetSize(contentWidth, visibleHeight)
	control.list.scrollChild:SetSize(contentWidth, math.max(contentHeight, ToUI(1)))

	EnsureListRows(control)

	local previousButton
	for _, button in ipairs(control.list.buttons or {}) do
		if button:IsShown() then
			button:ClearAllPoints()
			button:SetHeight(rowHeight)

			if not previousButton then
				button:SetPoint("TOPLEFT", control.list.scrollChild, "TOPLEFT", 0, 0)
				button:SetPoint("TOPRIGHT", control.list.scrollChild, "TOPRIGHT", 0, 0)
			else
				button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -rowSpacing)
				button:SetPoint("TOPRIGHT", previousButton, "BOTTOMRIGHT", 0, -rowSpacing)
			end

			previousButton = button
		end
	end

	control.list.scrollRange = math.max(0, contentHeight - visibleHeight)

	if isScrollable then
		local scrollTrackWidth = ToUI(control.layoutValues.scrollTrackWidth)
		local scrollThumbWidth = ToUI(control.layoutValues.scrollThumbWidth)
		local scrollThumbMinHeight = ToUI(control.layoutValues.scrollThumbMinHeight)
		local scrollThumbHeight = math.max(scrollThumbMinHeight, visibleHeight * (visibleHeight / contentHeight))

		control.list.scrollBar:ClearAllPoints()
		control.list.scrollBar:SetPoint("TOPRIGHT", control.list, "TOPRIGHT", -listPadding, -listPadding)
		control.list.scrollBar:SetSize(addon.Utilities:ToUI(scrollBarWidthPx), visibleHeight)
		control.list.scrollBar.track:SetWidth(scrollTrackWidth)
		control.list.scrollBar.thumb:SetSize(scrollThumbWidth, scrollThumbHeight)
		control.list.scrollBar:SetMinMaxValues(0, control.list.scrollRange)
		control.list.scrollBar:SetValue(0)
		control.list.scrollFrame:SetVerticalScroll(0)
		control.list.scrollBar:Show()

		control.list.scrollHitArea:ClearAllPoints()
		control.list.scrollHitArea:SetPoint("TOPLEFT", control.list.scrollFrame, "TOPRIGHT", 0, listPadding)
		control.list.scrollHitArea:SetPoint("BOTTOMRIGHT", control.list, "BOTTOMRIGHT", 0, 0)
		control.list.scrollHitArea:Show()
	else
		StopScrollBarDrag(control)
		control.list.scrollBar:Hide()
		control.list.scrollHitArea:Hide()
		control.list.scrollBar:SetMinMaxValues(0, 0)
		control.list.scrollBar:SetValue(0)
		control.list.scrollFrame:SetVerticalScroll(0)
	end
end

local function ToggleDropdown(control)
	if openDropdown == control then
		HideOpenDropdown()
		return
	end

	HideOpenDropdown()
	control.list:SetFrameLevel(control:GetFrameLevel() + 50)
	control.list.scrollFrame:SetFrameLevel(control.list:GetFrameLevel() + 1)
	control.list.scrollBar:SetFrameLevel(control.list:GetFrameLevel() + 2)
	control.list.scrollHitArea:SetFrameLevel(control.list.scrollBar:GetFrameLevel() + 1)
	UpdateListLayout(control)
	control.list:Show()
	control:SetArrowColor({ theme:GetColor("brand") })
	openDropdown = control
end

function Dropdown:Create(parent, labelText)
	local control = CreateFrame("Frame", nil, parent)
	control.layoutValues = {
		width = 220,
		fieldHeight = 24,
		labelHeight = 16,
		labelSpacing = 4,
		borderThickness = 1,
		fontSize = 12,
		textInset = 10,
		arrowInset = 12,
		arrowWidth = 10,
		arrowHeight = 8,
		arrowStrokeThickness = 2,
		selectionRightInset = 30,
		listRowHeight = 24,
		listRowSpacing = 2,
		listPadding = 4,
		maxVisibleRows = 10,
		scrollBarWidth = 8,
		scrollBarSpacing = 4,
		scrollTrackWidth = 2,
		scrollThumbWidth = 6,
		scrollThumbMinHeight = 16,
	}

	control.options = {}
	control.value = nil
	control.placeholder = "Select..."
	control.labelVisible = true

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	theme:ApplyFont(control.label, "arialNarrow", control.layoutValues.fontSize, "")
	control.label:SetTextColor(theme:GetTextColor("primary"))
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

	control.selectionTexture = control.field:CreateTexture(nil, "ARTWORK", nil, -1)
	control.selectionTexture:SetAllPoints(control.field)
	control.selectionTexture:SetAlpha(0.4)
	control.selectionTexture:Hide()

	control.selectionText = control.field:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	theme:ApplyFont(control.selectionText, "arialNarrow", control.layoutValues.fontSize, "")
	control.selectionText:SetTextColor(theme:GetTextColor("primary"))
	control.selectionText:SetJustifyH("LEFT")
	control.selectionText:SetWordWrap(false)
	control.selectionText:SetMaxLines(1)
	control.selectionText:SetText(control.placeholder)

	control.arrow = CreateFrame("Frame", nil, control.field)
	control.arrow.leftStroke = control.arrow:CreateTexture(nil, "OVERLAY")
	control.arrow.rightStroke = control.arrow:CreateTexture(nil, "OVERLAY")

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
	control.list.buttons = {}
	control.list.scrollRange = 0

	control.list.scrollFrame = CreateFrame("ScrollFrame", nil, control.list)
	control.list.scrollFrame:SetFrameLevel(control.list:GetFrameLevel() + 1)
	control.list.scrollFrame:EnableMouseWheel(true)
	control.list.scrollFrame:SetScript("OnMouseWheel", function(_, delta)
		ScrollList(control, delta)
	end)

	control.list.scrollChild = CreateFrame("Frame", nil, control.list.scrollFrame)
	control.list.scrollChild:SetPoint("TOPLEFT", control.list.scrollFrame, "TOPLEFT", 0, 0)
	control.list.scrollFrame:SetScrollChild(control.list.scrollChild)

	control.list.scrollBar = CreateFrame("Slider", nil, control.list)
	control.list.scrollBar:EnableMouse(false)
	control.list.scrollBar:SetOrientation("VERTICAL")
	control.list.scrollBar:SetFrameLevel(control.list:GetFrameLevel() + 2)
	control.list.scrollBar:SetScript("OnValueChanged", function(_, value)
		control.list.scrollFrame:SetVerticalScroll(value)
	end)

	control.list.scrollBar.track = control.list.scrollBar:CreateTexture(nil, "ARTWORK")
	control.list.scrollBar.track:SetColorTexture(theme:GetColor("border"))
	control.list.scrollBar.track:SetPoint("TOP", control.list.scrollBar, "TOP", 0, 0)
	control.list.scrollBar.track:SetPoint("BOTTOM", control.list.scrollBar, "BOTTOM", 0, 0)

	control.list.scrollBar.thumb = control.list.scrollBar:CreateTexture(nil, "OVERLAY")
	control.list.scrollBar.thumb:SetColorTexture(theme:GetTextColor("secondary"))
	control.list.scrollBar:SetThumbTexture(control.list.scrollBar.thumb)

	control.list.scrollHitArea = CreateFrame("Button", nil, control.list)
	control.list.scrollHitArea:SetFrameLevel(control.list.scrollBar:GetFrameLevel() + 1)
	control.list.scrollHitArea:EnableMouse(true)
	control.list.scrollHitArea:EnableMouseWheel(true)
	control.list.scrollHitArea:SetScript("OnMouseWheel", function(_, delta)
		ScrollList(control, delta)
	end)
	control.list.scrollHitArea:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" then
			StartScrollBarDrag(control)
		end
	end)
	control.list.scrollHitArea:SetScript("OnMouseUp", function(_, button)
		if button == "LeftButton" then
			StopScrollBarDrag(control)
		end
	end)
	control.list.scrollHitArea:Hide()

	control.list:SetScript("OnHide", function()
		StopScrollBarDrag(control)
	end)

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

	function control:SetBorderSize(borderThickness)
		self.layoutValues.borderThickness = borderThickness
		self:UpdateLayout()
	end

	function control:SetFontSize(fontSize)
		self.layoutValues.fontSize = fontSize
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
		local labelSpacingPx = ToPixels(self.layoutValues.labelSpacing)
		local fieldHeightPx = ToPixels(self.layoutValues.fieldHeight)
		local labelHeightPx = ToPixels(self.layoutValues.labelHeight)
		local borderThicknessPx = ToPixels(self.layoutValues.borderThickness)
		local textInsetPx = ToPixels(self.layoutValues.textInset)
		local arrowInsetPx = ToPixels(self.layoutValues.arrowInset)
		local arrowWidthPx = ToPixels(self.layoutValues.arrowWidth)
		local arrowHeightPx = ToPixels(self.layoutValues.arrowHeight)
		local arrowStrokeThicknessPx = ToPixels(self.layoutValues.arrowStrokeThickness)
		local selectionRightInsetPx = ToPixels(self.layoutValues.selectionRightInset)
		local arrowSideInsetPx = math.max(1, addon.Utilities:RoundToNearestInt(arrowStrokeThicknessPx / 2))
		local arrowTopInsetPx = 1
		local arrowBottomInsetPx = 1
		local usableArrowWidthPx = math.max(2, arrowWidthPx - (arrowSideInsetPx * 2))
		local usableArrowHeightPx = math.max(2, arrowHeightPx - arrowTopInsetPx - arrowBottomInsetPx)
		local arrowHalfRunPx = usableArrowWidthPx / 2
		local arrowStrokeLengthPx = addon.Utilities:RoundToNearestInt(
			math.sqrt((arrowHalfRunPx * arrowHalfRunPx) + (usableArrowHeightPx * usableArrowHeightPx))
		)
		local arrowStrokeCenterOffsetXPx = addon.Utilities:RoundToNearestInt(usableArrowWidthPx / 4)
		local arrowStrokeRotation = math.atan2(usableArrowHeightPx, arrowHalfRunPx)

		local labelSpacing = addon.Utilities:ToUI(labelSpacingPx)
		local fieldHeight = addon.Utilities:ToUI(fieldHeightPx)
		local labelHeight = addon.Utilities:ToUI(labelHeightPx)
		local borderThickness = addon.Utilities:ToUI(borderThicknessPx)
		local textInset = addon.Utilities:ToUI(textInsetPx)
		local widthPx = ToPixels(self.layoutValues.width)

		self:SetWidth(addon.Utilities:ToUI(widthPx))
		theme:ApplyFont(self.label, "arialNarrow", self.layoutValues.fontSize, "")
		UpdateSelectionText(self)

		self.label:ClearAllPoints()
		self.field:ClearAllPoints()

		if self.labelVisible then
			self:SetHeight(addon.Utilities:ToUI(labelHeightPx + labelSpacingPx + fieldHeightPx))
			self.label:Show()
			self.label:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.label:SetHeight(labelHeight)
			self.field:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(labelHeightPx + labelSpacingPx))
			self.field:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -addon.Utilities:ToUI(labelHeightPx + labelSpacingPx))
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
		self.selectionText:SetPoint("RIGHT", self.field, "RIGHT", -addon.Utilities:ToUI(selectionRightInsetPx), 0)

		self.arrow:SetSize(addon.Utilities:ToUI(arrowWidthPx), addon.Utilities:ToUI(arrowHeightPx))
		self.arrow:ClearAllPoints()
		self.arrow:SetPoint(
			"CENTER",
			self.field,
			"RIGHT",
			-addon.Utilities:ToUI(arrowInsetPx + addon.Utilities:RoundToNearestInt(arrowWidthPx / 2)),
			0
		)
		self.arrow.leftStroke:ClearAllPoints()
		self.arrow.leftStroke:SetPoint("CENTER", self.arrow, "CENTER", -addon.Utilities:ToUI(arrowStrokeCenterOffsetXPx), 0)
		self.arrow.leftStroke:SetSize(addon.Utilities:ToUI(arrowStrokeLengthPx), addon.Utilities:ToUI(arrowStrokeThicknessPx))
		self.arrow.leftStroke:SetRotation(-arrowStrokeRotation)

		self.arrow.rightStroke:ClearAllPoints()
		self.arrow.rightStroke:SetPoint("CENTER", self.arrow, "CENTER", addon.Utilities:ToUI(arrowStrokeCenterOffsetXPx), 0)
		self.arrow.rightStroke:SetSize(addon.Utilities:ToUI(arrowStrokeLengthPx), addon.Utilities:ToUI(arrowStrokeThicknessPx))
		self.arrow.rightStroke:SetRotation(arrowStrokeRotation)

		if openDropdown == self then
			UpdateListLayout(self)
		end
	end

	control.field:SetScript("OnClick", function()
		ToggleDropdown(control)
	end)

	control:SetScript("OnHide", function(self)
		if openDropdown == self then
			HideOpenDropdown()
		end
	end)

	control:UpdateLayout()
	UpdateSelectionText(control)

	return control
end

function Dropdown:CloseOpenDropdown()
	HideOpenDropdown()
end
