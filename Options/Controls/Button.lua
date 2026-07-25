local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.Button = addon.Options.Controls.Button or {}

local Button = addon.Options.Controls.Button
local theme = addon.Options.Theme

Button.defaultHeight = 24

function Button:Create(parent, text)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")

	button.layoutValues = {
		width = 48,
		height = Button.defaultHeight,
		borderThickness = 1,
		fontSize = 14,
		textAlignment = "CENTER",
		textInset = 0,
	}

	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	button:SetBackdropColor(theme:GetColor("buttonBackground"))

	local borderTop = button:CreateTexture(nil, "OVERLAY")
	borderTop:SetColorTexture(theme:GetColor("border"))
	borderTop:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	borderTop:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)

	local borderBottom = button:CreateTexture(nil, "OVERLAY")
	borderBottom:SetColorTexture(theme:GetColor("border"))
	borderBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
	borderBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)

	local borderLeft = button:CreateTexture(nil, "OVERLAY")
	borderLeft:SetColorTexture(theme:GetColor("border"))
	borderLeft:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	borderLeft:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)

	local borderRight = button:CreateTexture(nil, "OVERLAY")
	borderRight:SetColorTexture(theme:GetColor("border"))
	borderRight:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
	borderRight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)

	button.borderTop = borderTop
	button.borderBottom = borderBottom
	button.borderLeft = borderLeft
	button.borderRight = borderRight

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
	theme:ApplyFont(button.text, "arialNarrow", button.layoutValues.fontSize, "")
	button.text:SetText(text or "Button")
	button.text:SetTextColor(theme:GetTextColor("primary"))

	button:SetScript("OnEnter", function(self)
		self:SetBackdropColor(theme:GetColor("buttonBackgroundHover"))
		self.text:SetTextColor(theme:GetColor("brand"))
	end)

	button:SetScript("OnLeave", function(self)
		self:SetBackdropColor(theme:GetColor("buttonBackground"))
		self.text:SetTextColor(theme:GetTextColor("primary"))
	end)

	function button:SetOnClick(callback)
		self.onClickCallback = callback

		self:SetScript("OnClick", function(self)
			addon.Options.Controls.Dropdown:CloseOpenDropdown()

			if self.onClickCallback then
				self.onClickCallback(self)
			end
		end)
	end

	function button:SetText(value)
		self.text:SetText(value or "")
	end

	function button:SetLayoutWidth(width)
		self.layoutValues.width = width

		self:UpdateLayout()
	end

	function button:SetLayoutHeight(height)
		self.layoutValues.height = height

		self:UpdateLayout()
	end

	function button:SetLayoutSize(width, height)
		self.layoutValues.width = width
		self.layoutValues.height = height

		self:UpdateLayout()
	end

	function button:SetLayoutBorderSize(borderThickness)
		self.layoutValues.borderThickness = borderThickness

		self:UpdateLayout()
	end

	function button:SetBorderSize(borderThickness)
		self:SetLayoutBorderSize(borderThickness)
	end

	function button:SetFontSize(fontSize)
		self.layoutValues.fontSize = fontSize

		self:UpdateLayout()
	end

	function button:SetTextAlignment(alignment, inset)
		self.layoutValues.textAlignment = alignment or "CENTER"
		self.layoutValues.textInset = inset or 0

		self:UpdateLayout()
	end

	function button:UpdateLayout()
		local textInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(self.layoutValues.textInset))

		self:SetSize(
			addon.Utilities:ToUI(addon.Utilities:ToPixels(self.layoutValues.width)),
			addon.Utilities:ToUI(addon.Utilities:ToPixels(self.layoutValues.height))
		)
		theme:ApplyFont(self.text, "arialNarrow", self.layoutValues.fontSize, "")
		self.text:SetJustifyH(self.layoutValues.textAlignment)
		self.text:ClearAllPoints()

		if self.layoutValues.textAlignment == "LEFT" then
			self.text:SetPoint("LEFT", self, "LEFT", textInset, 0)
		elseif self.layoutValues.textAlignment == "RIGHT" then
			self.text:SetPoint("RIGHT", self, "RIGHT", -textInset, 0)
		else
			self.text:SetPoint("CENTER", self, "CENTER", 0, 0)
		end

		if self.layoutValues.borderThickness == 0 then
			self.borderTop:Hide()
			self.borderBottom:Hide()
			self.borderLeft:Hide()
			self.borderRight:Hide()
		else
			local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(self.layoutValues.borderThickness))
			self.borderTop:SetHeight(borderThickness)
			self.borderBottom:SetHeight(borderThickness)
			self.borderLeft:SetWidth(borderThickness)
			self.borderRight:SetWidth(borderThickness)

			self.borderTop:Show()
			self.borderBottom:Show()
			self.borderLeft:Show()
			self.borderRight:Show()
		end
	end

	button:UpdateLayout()

	return button
end
