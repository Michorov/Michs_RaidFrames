local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.Button = addon.Options.Controls.Button or {}

local Button = addon.Options.Controls.Button
local theme = addon.Options.Theme

function Button:Create(parent, text)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")

	button:SetSize(48, 24)

	button:ClearAllPoints()
	button:SetPoint("CENTER", parent, "CENTER", 0, 0)

	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	button:SetBackdropColor(0.12, 0.12, 0.14, 1)

	local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(1))

	local top = button:CreateTexture(nil, "OVERLAY")
	top:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	top:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	top:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
	top:SetHeight(borderThickness)

	local bottom = button:CreateTexture(nil, "OVERLAY")
	bottom:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
	bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	bottom:SetHeight(borderThickness)

	local left = button:CreateTexture(nil, "OVERLAY")
	left:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	left:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
	left:SetWidth(borderThickness)

	local right = button:CreateTexture(nil, "OVERLAY")
	right:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	right:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
	right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	right:SetWidth(borderThickness)

	button.borderTop = top
	button.borderBottom = bottom
	button.borderLeft = left
	button.borderRight = right

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
	button.text:SetFont(theme.fonts.arialNarrow, 14, "")
	button.text:SetText(text or "Button")

	local normalBg = { 0.12, 0.12, 0.14, 1 }
	local hoverBg = { 0.18, 0.18, 0.22, 1 }
	button.normalTextColor = { 0.85, 0.85, 0.88, 1 }
	button.hoverTextColor = {
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4],
	}

	button.text:SetTextColor(
		button.normalTextColor[1],
		button.normalTextColor[2],
		button.normalTextColor[3],
		button.normalTextColor[4]
	)

	button:SetBackdropColor(normalBg[1], normalBg[2], normalBg[3], normalBg[4])

	button:SetScript("OnEnter", function(self)
		self:SetBackdropColor(hoverBg[1], hoverBg[2], hoverBg[3], hoverBg[4])
		self.text:SetTextColor(
			self.hoverTextColor[1],
			self.hoverTextColor[2],
			self.hoverTextColor[3],
			self.hoverTextColor[4]
		)
	end)

	button:SetScript("OnLeave", function(self)
		self:SetBackdropColor(normalBg[1], normalBg[2], normalBg[3], normalBg[4])
		self.text:SetTextColor(
			self.normalTextColor[1],
			self.normalTextColor[2],
			self.normalTextColor[3],
			self.normalTextColor[4]
		)
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

	return button
end
