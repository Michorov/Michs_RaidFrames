local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

OptionsUILib.Controls = OptionsUILib.Controls or {}
OptionsUILib.Controls.SegmentedToggle = OptionsUILib.Controls.SegmentedToggle or {}

local SegmentedToggle = OptionsUILib.Controls.SegmentedToggle

local function ApplyVisualState(control)
	local PP = control.PP
	local activeBg = { OptionsUILib.Theme:GetColor("brand") }
	local activeHoverBg = { 1.0, 0.74, 0.42, 1 }
	local inactiveTextColor = { 0.82, 0.83, 0.87, 1 }
	local inactiveHoverTextColor = { 0.94, 0.95, 0.98, 1 }
	local activeTextColor = { OptionsUILib.Theme:GetColor("background", 1) }
	local plateInset = PP:ToUIScaled(2)

	local leftActive = control.value == control.leftOption.value
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

	control.activePlate.bg:SetColorTexture(activePlateColor[1], activePlateColor[2], activePlateColor[3], activePlateColor[4])
	control.activePlate.topHighlight:SetColorTexture(1, 1, 1, control.hoveredSegment and 0.12 or 0.08)

	if leftActive then
		control.leftSegment.text:SetTextColor(activeTextColor[1], activeTextColor[2], activeTextColor[3], activeTextColor[4])
	else
		control.leftSegment.text:SetTextColor(
			control.hoveredSegment == control.leftSegment and inactiveHoverTextColor[1] or inactiveTextColor[1],
			control.hoveredSegment == control.leftSegment and inactiveHoverTextColor[2] or inactiveTextColor[2],
			control.hoveredSegment == control.leftSegment and inactiveHoverTextColor[3] or inactiveTextColor[3],
			control.hoveredSegment == control.leftSegment and inactiveHoverTextColor[4] or inactiveTextColor[4]
		)
	end

	local rightActive = control.value == control.rightOption.value
	if rightActive then
		control.rightSegment.text:SetTextColor(activeTextColor[1], activeTextColor[2], activeTextColor[3], activeTextColor[4])
	else
		control.rightSegment.text:SetTextColor(
			control.hoveredSegment == control.rightSegment and inactiveHoverTextColor[1] or inactiveTextColor[1],
			control.hoveredSegment == control.rightSegment and inactiveHoverTextColor[2] or inactiveTextColor[2],
			control.hoveredSegment == control.rightSegment and inactiveHoverTextColor[3] or inactiveTextColor[3],
			control.hoveredSegment == control.rightSegment and inactiveHoverTextColor[4] or inactiveTextColor[4]
		)
	end

	control.leftSegment.hoverTexture:SetShown(control.hoveredSegment == control.leftSegment and not leftActive)
	control.rightSegment.hoverTexture:SetShown(control.hoveredSegment == control.rightSegment and not rightActive)
end

local function CreateSegment(control, option)
	local segment = CreateFrame("Button", nil, control)
	segment.option = option

	segment.hoverTexture = segment:CreateTexture(nil, "ARTWORK")
	segment.hoverTexture:SetColorTexture(OptionsUILib.Theme:GetColor("controlHoverOverlay"))
	segment.hoverTexture:SetAllPoints(segment)
	segment.hoverTexture:Hide()

	segment.text = segment:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	segment.text:SetPoint("CENTER", segment, "CENTER", 0, 0)
	segment.text:SetShadowOffset(0, 0)
	segment.text:SetShadowColor(0, 0, 0, 0)
	OptionsUILib.Theme:ApplyFont(segment.text, control.PP:ScaleFont(control.layout.fontSize), "")
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
		OptionsUILib.Controls.Dropdown:CloseOpenDropdown()

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

function SegmentedToggle:Create(parent, PP, leftOption, rightOption)
	if not parent or not PP then
		return nil
	end

	local control = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	control.PP = PP
	control.layout = {
		width = 152,
		height = 24,
		borderThickness = 1,
		fontSize = 12,
	}

	control.leftOption = leftOption or { value = "left", text = "Left" }
	control.rightOption = rightOption or { value = "right", text = "Right" }
	control.value = control.leftOption.value

	control:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	control:SetBackdropColor(OptionsUILib.Theme:GetColor("controlBackground"))

	control.activePlate = CreateFrame("Frame", nil, control)
	control.activePlate:SetFrameLevel(control:GetFrameLevel() + 1)

	control.activePlate.bg = control.activePlate:CreateTexture(nil, "BACKGROUND")
	control.activePlate.bg:SetAllPoints(control.activePlate)

	control.activePlate.topHighlight = control.activePlate:CreateTexture(nil, "ARTWORK")
	control.activePlate.topHighlight:SetPoint("TOPLEFT", control.activePlate, "TOPLEFT", 0, 0)
	control.activePlate.topHighlight:SetPoint("TOPRIGHT", control.activePlate, "TOPRIGHT", 0, 0)

	control.topBorder = control:CreateTexture(nil, "OVERLAY")
	control.topBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.topBorder:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
	control.topBorder:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, 0)

	control.bottomBorder = control:CreateTexture(nil, "OVERLAY")
	control.bottomBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.bottomBorder:SetPoint("BOTTOMLEFT", control, "BOTTOMLEFT", 0, 0)
	control.bottomBorder:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", 0, 0)

	control.leftBorder = control:CreateTexture(nil, "OVERLAY")
	control.leftBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.leftBorder:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
	control.leftBorder:SetPoint("BOTTOMLEFT", control, "BOTTOMLEFT", 0, 0)

	control.rightBorder = control:CreateTexture(nil, "OVERLAY")
	control.rightBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	control.rightBorder:SetPoint("TOPRIGHT", control, "TOPRIGHT", 0, 0)
	control.rightBorder:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", 0, 0)

	control.leftSegment = CreateSegment(control, control.leftOption)
	control.leftSegment:SetPoint("TOPLEFT", control, "TOPLEFT", 0, 0)
	control.leftSegment:SetPoint("BOTTOMLEFT", control, "BOTTOMLEFT", 0, 0)
	control.leftSegment:SetPoint("RIGHT", control, "CENTER", 0, 0)

	control.rightSegment = CreateSegment(control, control.rightOption)
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

	function control:SetLayoutSize(width, height)
		self.layout.width = width
		self.layout.height = height
		self:UpdateLayout()
	end

	function control:SetFontSize(fontSize)
		self.layout.fontSize = fontSize
		self:UpdateLayout()
	end

	function control:UpdateLayout()
		local PP = self.PP
		local borderThickness = PP:ToUIScaled(self.layout.borderThickness)

		self:SetSize(PP:ToUIScaled(self.layout.width), PP:ToUIScaled(self.layout.height))
		OptionsUILib.Theme:ApplyFont(self.leftSegment.text, PP:ScaleFont(self.layout.fontSize), "")
		OptionsUILib.Theme:ApplyFont(self.rightSegment.text, PP:ScaleFont(self.layout.fontSize), "")

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
