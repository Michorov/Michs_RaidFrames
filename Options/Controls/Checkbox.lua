local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.Checkbox = addon.Options.Controls.Checkbox or {}

local Checkbox = addon.Options.Controls.Checkbox
local theme = addon.Options.Theme
local hoverAccentColor = { 1.0, 0.74, 0.42, 1 }

local function UpdateVisual(checkbox)
	if checkbox.checked then
		if checkbox.isHovered then
			checkbox.check:SetColorTexture(
				hoverAccentColor[1],
				hoverAccentColor[2],
				hoverAccentColor[3],
				hoverAccentColor[4]
			)
		else
			checkbox.check:SetColorTexture(theme:GetColor("brand"))
		end

		checkbox.check:Show()
	else
		checkbox.check:Hide()
	end
end

function Checkbox:Create(parent, text)
	local checkbox = CreateFrame("Button", nil, parent, "BackdropTemplate")

	checkbox.layoutValues = {
		width = 220,
		height = 16,
		boxSize = 16,
		borderThickness = 1,
		textInset = 8,
		checkInset = 3,
	}
	checkbox.checked = false
	checkbox.isHovered = false

	checkbox.box = CreateFrame("Frame", nil, checkbox, "BackdropTemplate")
	checkbox.box:SetPoint("LEFT", checkbox, "LEFT", 0, 0)
	checkbox.box:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	checkbox.box:SetBackdropColor(theme:GetColor("controlBackground"))

	checkbox.boxHover = checkbox.box:CreateTexture(nil, "ARTWORK")
	checkbox.boxHover:SetColorTexture(theme:GetColor("controlHoverOverlay"))
	checkbox.boxHover:SetPoint("TOPLEFT", checkbox.box, "TOPLEFT", 0, 0)
	checkbox.boxHover:SetPoint("BOTTOMRIGHT", checkbox.box, "BOTTOMRIGHT", 0, 0)
	checkbox.boxHover:Hide()

	checkbox.boxTopBorder = checkbox.box:CreateTexture(nil, "OVERLAY")
	checkbox.boxTopBorder:SetColorTexture(theme:GetColor("border"))
	checkbox.boxTopBorder:SetPoint("TOPLEFT", checkbox.box, "TOPLEFT", 0, 0)
	checkbox.boxTopBorder:SetPoint("TOPRIGHT", checkbox.box, "TOPRIGHT", 0, 0)

	checkbox.boxBottomBorder = checkbox.box:CreateTexture(nil, "OVERLAY")
	checkbox.boxBottomBorder:SetColorTexture(theme:GetColor("border"))
	checkbox.boxBottomBorder:SetPoint("BOTTOMLEFT", checkbox.box, "BOTTOMLEFT", 0, 0)
	checkbox.boxBottomBorder:SetPoint("BOTTOMRIGHT", checkbox.box, "BOTTOMRIGHT", 0, 0)

	checkbox.boxLeftBorder = checkbox.box:CreateTexture(nil, "OVERLAY")
	checkbox.boxLeftBorder:SetColorTexture(theme:GetColor("border"))
	checkbox.boxLeftBorder:SetPoint("TOPLEFT", checkbox.box, "TOPLEFT", 0, 0)
	checkbox.boxLeftBorder:SetPoint("BOTTOMLEFT", checkbox.box, "BOTTOMLEFT", 0, 0)

	checkbox.boxRightBorder = checkbox.box:CreateTexture(nil, "OVERLAY")
	checkbox.boxRightBorder:SetColorTexture(theme:GetColor("border"))
	checkbox.boxRightBorder:SetPoint("TOPRIGHT", checkbox.box, "TOPRIGHT", 0, 0)
	checkbox.boxRightBorder:SetPoint("BOTTOMRIGHT", checkbox.box, "BOTTOMRIGHT", 0, 0)

	checkbox.check = checkbox.box:CreateTexture(nil, "ARTWORK")
	checkbox.check:SetColorTexture(theme:GetColor("brand"))
	checkbox.check:Hide()

	checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	checkbox.text:SetJustifyH("LEFT")
	theme:ApplyFont(checkbox.text, "arialNarrow", 12, "")
	checkbox.text:SetTextColor(theme:GetTextColor("primary"))
	checkbox.text:SetText(text or "Checkbox")

	function checkbox:SetChecked(checked)
		self.checked = checked and true or false
		UpdateVisual(self)
	end

	function checkbox:GetChecked()
		return self.checked
	end

	function checkbox:SetText(value)
		self.text:SetText(value or "")
	end

	function checkbox:SetOnValueChanged(callback)
		self.onValueChanged = callback
	end

	function checkbox:SetLayoutWidth(width)
		self.layoutValues.width = width
		self:UpdateLayout()
	end

	function checkbox:SetLayoutHeight(height)
		self.layoutValues.height = height
		self:UpdateLayout()
	end

	function checkbox:SetLayoutSize(width, height)
		self.layoutValues.width = width
		self.layoutValues.height = height
		self:UpdateLayout()
	end

	function checkbox:UpdateLayout()
		local widthPx = addon.Utilities:ToPixels(self.layoutValues.width)
		local heightPx = addon.Utilities:ToPixels(self.layoutValues.height)
		local boxSizePx = addon.Utilities:ToPixels(self.layoutValues.boxSize)
		local borderThicknessPx = addon.Utilities:ToPixels(self.layoutValues.borderThickness)
		local textInsetPx = addon.Utilities:ToPixels(self.layoutValues.textInset)
		local checkInsetPx = addon.Utilities:ToPixels(self.layoutValues.checkInset)
		local boxTopInsetPx = addon.Utilities:RoundToNearestInt((heightPx - boxSizePx) / 2)

		local width = addon.Utilities:ToUI(widthPx)
		local height = addon.Utilities:ToUI(heightPx)
		local boxSize = addon.Utilities:ToUI(boxSizePx)
		local borderThickness = addon.Utilities:ToUI(borderThicknessPx)
		local checkInset = addon.Utilities:ToUI(checkInsetPx)
		local boxTopInset = addon.Utilities:ToUI(boxTopInsetPx)
		local textLeftOffset = addon.Utilities:ToUI(boxSizePx + textInsetPx)

		self:SetSize(width, height)

		self.box:ClearAllPoints()
		self.box:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -boxTopInset)
		self.box:SetSize(boxSize, boxSize)

		self.boxTopBorder:SetHeight(borderThickness)
		self.boxBottomBorder:SetHeight(borderThickness)
		self.boxLeftBorder:SetWidth(borderThickness)
		self.boxRightBorder:SetWidth(borderThickness)

		self.check:ClearAllPoints()
		self.check:SetPoint("TOPLEFT", self.box, "TOPLEFT", checkInset, -checkInset)
		self.check:SetPoint("BOTTOMRIGHT", self.box, "BOTTOMRIGHT", -checkInset, checkInset)

		self.text:ClearAllPoints()
		self.text:SetPoint("LEFT", self, "LEFT", textLeftOffset, 0)
		self.text:SetPoint("RIGHT", self, "RIGHT", 0, 0)
	end

	checkbox:SetScript("OnEnter", function(self)
		self.isHovered = true
		self.boxHover:Show()
		UpdateVisual(self)
	end)

	checkbox:SetScript("OnLeave", function(self)
		self.isHovered = false
		self.boxHover:Hide()
		UpdateVisual(self)
	end)

	checkbox:SetScript("OnClick", function(self)
		self:SetChecked(not self:GetChecked())

		if self.onValueChanged then
			self.onValueChanged(self, self:GetChecked())
		end
	end)

	checkbox:UpdateLayout()

	return checkbox
end
