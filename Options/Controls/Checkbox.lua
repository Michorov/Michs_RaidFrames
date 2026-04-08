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
			checkbox.check:SetColorTexture(
				theme.colors.brand[1],
				theme.colors.brand[2],
				theme.colors.brand[3],
				theme.colors.brand[4]
			)
		end

		checkbox.check:Show()
	else
		checkbox.check:Hide()
	end
end

function Checkbox:Create(parent, text)
	local checkbox = CreateFrame("Button", nil, parent, "BackdropTemplate")
	local boxSize = addon.Utilities:ToUI(addon.Utilities:ToPixels(16))
	local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(1))
	local textInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(8))

	checkbox:SetSize(
		addon.Utilities:ToUI(addon.Utilities:ToPixels(200)),
		addon.Utilities:ToUI(addon.Utilities:ToPixels(20))
	)
	checkbox.checked = false
	checkbox.isHovered = false

	checkbox.box = CreateFrame("Frame", nil, checkbox, "BackdropTemplate")
	checkbox.box:SetSize(boxSize, boxSize)
	checkbox.box:SetPoint("LEFT", checkbox, "LEFT", 0, 0)
	checkbox.box:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	checkbox.box:SetBackdropColor(0.04, 0.05, 0.07, 1)

	checkbox.boxHover = checkbox.box:CreateTexture(nil, "ARTWORK")
	checkbox.boxHover:SetColorTexture(1, 1, 1, 0.04)
	checkbox.boxHover:SetPoint("TOPLEFT", checkbox.box, "TOPLEFT", 0, 0)
	checkbox.boxHover:SetPoint("BOTTOMRIGHT", checkbox.box, "BOTTOMRIGHT", 0, 0)
	checkbox.boxHover:Hide()

	checkbox.boxTopBorder = checkbox.box:CreateTexture(nil, "OVERLAY")
	checkbox.boxTopBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	checkbox.boxTopBorder:SetPoint("TOPLEFT", checkbox.box, "TOPLEFT", 0, 0)
	checkbox.boxTopBorder:SetPoint("TOPRIGHT", checkbox.box, "TOPRIGHT", 0, 0)
	checkbox.boxTopBorder:SetHeight(borderThickness)

	checkbox.boxBottomBorder = checkbox.box:CreateTexture(nil, "OVERLAY")
	checkbox.boxBottomBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	checkbox.boxBottomBorder:SetPoint("BOTTOMLEFT", checkbox.box, "BOTTOMLEFT", 0, 0)
	checkbox.boxBottomBorder:SetPoint("BOTTOMRIGHT", checkbox.box, "BOTTOMRIGHT", 0, 0)
	checkbox.boxBottomBorder:SetHeight(borderThickness)

	checkbox.boxLeftBorder = checkbox.box:CreateTexture(nil, "OVERLAY")
	checkbox.boxLeftBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	checkbox.boxLeftBorder:SetPoint("TOPLEFT", checkbox.box, "TOPLEFT", 0, 0)
	checkbox.boxLeftBorder:SetPoint("BOTTOMLEFT", checkbox.box, "BOTTOMLEFT", 0, 0)
	checkbox.boxLeftBorder:SetWidth(borderThickness)

	checkbox.boxRightBorder = checkbox.box:CreateTexture(nil, "OVERLAY")
	checkbox.boxRightBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	checkbox.boxRightBorder:SetPoint("TOPRIGHT", checkbox.box, "TOPRIGHT", 0, 0)
	checkbox.boxRightBorder:SetPoint("BOTTOMRIGHT", checkbox.box, "BOTTOMRIGHT", 0, 0)
	checkbox.boxRightBorder:SetWidth(borderThickness)

	checkbox.check = checkbox.box:CreateTexture(nil, "ARTWORK")
	checkbox.check:SetColorTexture(
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4]
	)
	checkbox.check:SetPoint("TOPLEFT", checkbox.box, "TOPLEFT", borderThickness * 3, -borderThickness * 3)
	checkbox.check:SetPoint("BOTTOMRIGHT", checkbox.box, "BOTTOMRIGHT", -borderThickness * 3, borderThickness * 3)
	checkbox.check:Hide()

	checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	checkbox.text:SetPoint("LEFT", checkbox.box, "RIGHT", textInset, 0)
	checkbox.text:SetPoint("RIGHT", checkbox, "RIGHT", 0, 0)
	checkbox.text:SetJustifyH("LEFT")
	checkbox.text:SetFont(theme.fonts.arialNarrow, 12, "")
	checkbox.text:SetTextColor(0.85, 0.85, 0.88, 1)
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

	return checkbox
end
