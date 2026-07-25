local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.SegmentedToggle = addon.Options.Controls.SegmentedToggle or {}

local SegmentedToggle = addon.Options.Controls.SegmentedToggle
local L = addon.L
local theme = addon.Options.Theme

SegmentedToggle.defaultWidth = 152
SegmentedToggle.defaultHeight = 24

local function ApplyVisualState(control)
	local activeBg = { theme:GetColor("brand") }
	local activeHoverBg = { 1.0, 0.74, 0.42, 1 }
	local inactiveTextColor = { 0.82, 0.83, 0.87, 1 }
	local inactiveHoverTextColor = { 0.94, 0.95, 0.98, 1 }
	local activeTextColor = { theme:GetColor("panelBackground", 1) }
	local plateInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(2))

	local leftActive = control.value == control.leftOption.value
	local rightActive = control.value == control.rightOption.value
	local activePlateColor = activeBg

	control.activePlate:ClearAllPoints()

	if leftActive then
		control.activePlate:SetPoint("TOPLEFT", control, "TOPLEFT", plateInset, -plateInset)
		control.activePlate:SetPoint("BOTTOMLEFT", control, "BOTTOMLEFT", plateInset, plateInset)
		control.activePlate:SetPoint("RIGHT", control, "CENTER", 0, 0)
		if control.hoveredSegment == control.leftSegment then
			activePlateColor = activeHoverBg
		end
	else
		control.activePlate:SetPoint("TOPRIGHT", control, "TOPRIGHT", -plateInset, -plateInset)
		control.activePlate:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", -plateInset, plateInset)
		control.activePlate:SetPoint("LEFT", control, "CENTER", 0, 0)
		if control.hoveredSegment == control.rightSegment then
			activePlateColor = activeHoverBg
		end
	end

	control.activePlate.bg:SetColorTexture(
		activePlateColor[1],
		activePlateColor[2],
		activePlateColor[3],
		activePlateColor[4]
	)
	control.activePlate.topHighlight:SetColorTexture(1, 1, 1, control.hoveredSegment and 0.12 or 0.08)

	if leftActive then
		control.leftSegment.text:SetTextColor(
			activeTextColor[1],
			activeTextColor[2],
			activeTextColor[3],
			activeTextColor[4]
		)
	else
		control.leftSegment.text:SetTextColor(
			control.hoveredSegment == control.leftSegment and inactiveHoverTextColor[1] or inactiveTextColor[1],
			control.hoveredSegment == control.leftSegment and inactiveHoverTextColor[2] or inactiveTextColor[2],
			control.hoveredSegment == control.leftSegment and inactiveHoverTextColor[3] or inactiveTextColor[3],
			control.hoveredSegment == control.leftSegment and inactiveHoverTextColor[4] or inactiveTextColor[4]
		)
	end

	control.leftSegment.hoverTexture:SetShown(control.hoveredSegment == control.leftSegment and not leftActive)
	control.leftSegment.hoverTexture:SetColorTexture(theme:GetColor("controlHoverOverlay"))

	if rightActive then
		control.rightSegment.text:SetTextColor(
			activeTextColor[1],
			activeTextColor[2],
			activeTextColor[3],
			activeTextColor[4]
		)
	else
		control.rightSegment.text:SetTextColor(
			control.hoveredSegment == control.rightSegment and inactiveHoverTextColor[1] or inactiveTextColor[1],
			control.hoveredSegment == control.rightSegment and inactiveHoverTextColor[2] or inactiveTextColor[2],
			control.hoveredSegment == control.rightSegment and inactiveHoverTextColor[3] or inactiveTextColor[3],
			control.hoveredSegment == control.rightSegment and inactiveHoverTextColor[4] or inactiveTextColor[4]
		)
	end

	control.rightSegment.hoverTexture:SetShown(control.hoveredSegment == control.rightSegment and not rightActive)
	control.rightSegment.hoverTexture:SetColorTexture(theme:GetColor("controlHoverOverlay"))
end

local function CreateSegment(control, option, side)
	local segment = CreateFrame("Button", nil, control)
	segment.option = option

	segment.hoverTexture = segment:CreateTexture(nil, "ARTWORK")
	segment.hoverTexture:SetPoint("TOPLEFT", segment, "TOPLEFT", 0, 0)
	segment.hoverTexture:SetPoint("BOTTOMRIGHT", segment, "BOTTOMRIGHT", 0, 0)
	segment.hoverTexture:Hide()

	segment.text = segment:CreateFontString(nil, "OVERLAY")
	segment.text:SetPoint("CENTER", segment, "CENTER", 0, 0)
	theme:ApplyFont(segment.text, "arialNarrow", 12, "")
	segment.text:SetShadowOffset(0, 0)
	segment.text:SetShadowColor(0, 0, 0, 0)
	segment.text:SetText(segment.option.text or "")

	segment:SetScript("OnEnter", function(self)
		control.hoveredSegment = self
		ApplyVisualState(control)
	end)

	segment:SetScript("OnLeave", function()
		control.hoveredSegment = nil
		ApplyVisualState(control)
	end)

	segment:SetScript("OnClick", function(self)
		addon.Options.Controls.Dropdown:CloseOpenDropdown()

		if control.value == self.option.value then
			return
		end

		control:SetValue(self.option.value)

		if control.onValueChanged then
			control.onValueChanged(control, self.option.value)
		end
	end)

	return segment
end

function SegmentedToggle:Create(parent, leftOption, rightOption)
	local control = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	control.layoutValues = {
		width = SegmentedToggle.defaultWidth,
		height = SegmentedToggle.defaultHeight,
		borderThickness = 1,
		fontSize = 12,
	}

	control.leftOption = leftOption or { value = "left", text = L["Left"] }
	control.rightOption = rightOption or { value = "right", text = L["Right"] }
	control.value = control.leftOption.value

	control:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	control:SetBackdropColor(theme:GetColor("controlBackground"))

	control.activePlate = CreateFrame("Frame", nil, control)
	control.activePlate:SetFrameLevel(control:GetFrameLevel() + 1)

	control.activePlate.bg = control.activePlate:CreateTexture(nil, "BACKGROUND")
	control.activePlate.bg:SetPoint("TOPLEFT", control.activePlate, "TOPLEFT", 0, 0)
	control.activePlate.bg:SetPoint("BOTTOMRIGHT", control.activePlate, "BOTTOMRIGHT", 0, 0)

	control.activePlate.topHighlight = control.activePlate:CreateTexture(nil, "ARTWORK")
	control.activePlate.topHighlight:SetPoint("TOPLEFT", control.activePlate, "TOPLEFT", 0, 0)
	control.activePlate.topHighlight:SetPoint("TOPRIGHT", control.activePlate, "TOPRIGHT", 0, 0)

	control.topBorder = control:CreateTexture(nil, "OVERLAY")
	control.topBorder:SetColorTexture(theme:GetColor("border"))
	control.topBorder:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
	control.topBorder:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, 0)

	control.bottomBorder = control:CreateTexture(nil, "OVERLAY")
	control.bottomBorder:SetColorTexture(theme:GetColor("border"))
	control.bottomBorder:SetPoint("BOTTOMLEFT", control, "BOTTOMLEFT", 0, 0)
	control.bottomBorder:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", 0, 0)

	control.leftBorder = control:CreateTexture(nil, "OVERLAY")
	control.leftBorder:SetColorTexture(theme:GetColor("border"))
	control.leftBorder:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
	control.leftBorder:SetPoint("BOTTOMLEFT", control, "BOTTOMLEFT", 0, 0)

	control.rightBorder = control:CreateTexture(nil, "OVERLAY")
	control.rightBorder:SetColorTexture(theme:GetColor("border"))
	control.rightBorder:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, 0)
	control.rightBorder:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", 0, 0)

	control.leftSegment = CreateSegment(control, control.leftOption, "left")
	control.leftSegment:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
	control.leftSegment:SetPoint("BOTTOMLEFT", control, "BOTTOMLEFT", 0, 0)
	control.leftSegment:SetPoint("RIGHT", control, "CENTER", 0, 0)

	control.rightSegment = CreateSegment(control, control.rightOption, "right")
	control.rightSegment:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, 0)
	control.rightSegment:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", 0, 0)
	control.rightSegment:SetPoint("LEFT", control, "CENTER", 0, 0)

	function control:SetValue(value)
		self.value = value
		ApplyVisualState(self)
	end

	function control:SetOptions(leftOption, rightOption)
		self.leftOption = leftOption or self.leftOption
		self.rightOption = rightOption or self.rightOption

		self.leftSegment.option = self.leftOption
		self.rightSegment.option = self.rightOption
		self.leftSegment.text:SetText(self.leftOption.text or "")
		self.rightSegment.text:SetText(self.rightOption.text or "")

		if self.value ~= self.leftOption.value and self.value ~= self.rightOption.value then
			self.value = self.leftOption.value
		end

		ApplyVisualState(self)
	end

	function control:GetValue()
		return self.value
	end

	function control:SetOnValueChanged(callback)
		self.onValueChanged = callback
	end

	function control:SetLayoutWidth(width)
		self.layoutValues.width = width
		self:UpdateLayout()
	end

	function control:SetLayoutHeight(height)
		self.layoutValues.height = height
		self:UpdateLayout()
	end

	function control:SetLayoutSize(width, height)
		self.layoutValues.width = width
		self.layoutValues.height = height
		self:UpdateLayout()
	end

	function control:SetFontSize(fontSize)
		self.layoutValues.fontSize = fontSize
		self:UpdateLayout()
	end

	function control:UpdateLayout()
		local widthPx = addon.Utilities:ToPixels(self.layoutValues.width)
		local heightPx = addon.Utilities:ToPixels(self.layoutValues.height)
		local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(self.layoutValues.borderThickness))

		self:SetSize(addon.Utilities:ToUI(widthPx), addon.Utilities:ToUI(heightPx))
		theme:ApplyFont(self.leftSegment.text, "arialNarrow", self.layoutValues.fontSize, "")
		theme:ApplyFont(self.rightSegment.text, "arialNarrow", self.layoutValues.fontSize, "")

		self.activePlate.topHighlight:SetHeight(borderThickness)
		self.topBorder:SetHeight(borderThickness)
		self.bottomBorder:SetHeight(borderThickness)
		self.leftBorder:SetWidth(borderThickness)
		self.rightBorder:SetWidth(borderThickness)

		ApplyVisualState(self)
	end

	control:UpdateLayout()

	return control
end
