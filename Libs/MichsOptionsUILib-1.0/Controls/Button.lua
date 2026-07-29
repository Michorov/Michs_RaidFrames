local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

OptionsUILib.Controls = OptionsUILib.Controls or {}
OptionsUILib.Controls.Button = OptionsUILib.Controls.Button or {}

local Button = OptionsUILib.Controls.Button

function Button:Create(parent, PP, text)
	if not parent or not PP then
		return nil
	end

	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")

	button.PP = PP
	button.layout = {
		width = 116,
		height = 24,
		borderThickness = 1,
		fontSize = 12,
		textAlignment = "CENTER",
		textInset = 0,
		point = nil,
		relativeTo = parent,
		relativePoint = nil,
		offsetX = 0,
		offsetY = 0,
	}

	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	button:SetBackdropColor(OptionsUILib.Theme:GetColor("buttonBackground"))

	button.borderTop = button:CreateTexture(nil, "OVERLAY")
	button.borderTop:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	button.borderTop:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	button.borderTop:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

	button.borderBottom = button:CreateTexture(nil, "OVERLAY")
	button.borderBottom:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	button.borderBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
	button.borderBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)

	button.borderLeft = button:CreateTexture(nil, "OVERLAY")
	button.borderLeft:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	button.borderLeft:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	button.borderLeft:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)

	button.borderRight = button:CreateTexture(nil, "OVERLAY")
	button.borderRight:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	button.borderRight:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
	button.borderRight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.text:SetTextColor(OptionsUILib.Theme:GetTextColor("primary"))

	function button:SetOnClick(callback)
		self.onClickCallback = callback
	end

	function button:SetText(value)
		self.text:SetText(value or "")
	end

	function button:SetLayoutWidth(width)
		self.layout.width = width
		self:UpdateLayout()
	end

	function button:SetLayoutHeight(height)
		self.layout.height = height
		self:UpdateLayout()
	end

	function button:SetLayoutSize(width, height)
		self.layout.width = width
		self.layout.height = height
		self:UpdateLayout()
	end

	function button:SetBorderSize(borderThickness)
		self.layout.borderThickness = borderThickness
		self:UpdateLayout()
	end

	function button:SetFontSize(fontSize)
		self.layout.fontSize = fontSize
		self:UpdateLayout()
	end

	function button:SetTextAlignment(alignment, inset)
		self.layout.textAlignment = alignment or "CENTER"
		self.layout.textInset = inset or 0
		self:UpdateLayout()
	end

	function button:SetLayoutPoint(point, relativeTo, relativePoint, offsetX, offsetY)
		self.layout.point = point
		self.layout.relativeTo = relativeTo or parent
		self.layout.relativePoint = relativePoint or point
		self.layout.offsetX = offsetX or 0
		self.layout.offsetY = offsetY or 0
		self:UpdateLayout()
	end

	function button:UpdateLayout()
		local PP = self.PP
		local borderThickness = PP:ToUIScaled(self.layout.borderThickness)
		local textInset = PP:ToUIScaled(self.layout.textInset)

		self:SetSize(PP:ToUIScaled(self.layout.width), PP:ToUIScaled(self.layout.height))

		OptionsUILib.Theme:ApplyFont(self.text, PP:ScaleFont(self.layout.fontSize), "")
		self.text:SetJustifyH(self.layout.textAlignment)
		self.text:ClearAllPoints()

		if self.layout.textAlignment == "LEFT" then
			self.text:SetPoint("LEFT", self, "LEFT", textInset, 0)
		elseif self.layout.textAlignment == "RIGHT" then
			self.text:SetPoint("RIGHT", self, "RIGHT", -textInset, 0)
		else
			self.text:SetPoint("CENTER", self, "CENTER", 0, 0)
		end

		self.borderTop:SetHeight(borderThickness)
		self.borderBottom:SetHeight(borderThickness)
		self.borderLeft:SetWidth(borderThickness)
		self.borderRight:SetWidth(borderThickness)

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

	button:SetScript("OnEnter", function(self)
		self:SetBackdropColor(OptionsUILib.Theme:GetColor("buttonBackgroundHover"))
		self.text:SetTextColor(OptionsUILib.Theme:GetColor("brand"))
	end)

	button:SetScript("OnLeave", function(self)
		self:SetBackdropColor(OptionsUILib.Theme:GetColor("buttonBackground"))
		self.text:SetTextColor(OptionsUILib.Theme:GetTextColor("primary"))
	end)

	button:SetScript("OnClick", function(self)
		if OptionsUILib.Controls.Dropdown and OptionsUILib.Controls.Dropdown.CloseOpenDropdown then
			OptionsUILib.Controls.Dropdown:CloseOpenDropdown()
		end

		if self.onClickCallback then
			self.onClickCallback(self)
		end
	end)

	button:UpdateLayout()
	button:SetText(text or "Button")

	return button
end
