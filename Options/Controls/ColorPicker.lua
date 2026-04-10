local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Controls = addon.Options.Controls or {}
addon.Options.Controls.ColorPicker = addon.Options.Controls.ColorPicker or {}

local ColorPicker = addon.Options.Controls.ColorPicker
local theme = addon.Options.Theme

local function ClampChannel(value, fallback)
	value = tonumber(value)
	if value == nil then
		return fallback
	end

	return math.max(0, math.min(1, value))
end

local function CreateBorder(frame)
	local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(1))

	frame.topBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.topBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	frame.topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	frame.topBorder:SetHeight(borderThickness)

	frame.bottomBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.bottomBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	frame.bottomBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	frame.bottomBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	frame.bottomBorder:SetHeight(borderThickness)

	frame.leftBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.leftBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	frame.leftBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.leftBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	frame.leftBorder:SetWidth(borderThickness)

	frame.rightBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.rightBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	frame.rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	frame.rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	frame.rightBorder:SetWidth(borderThickness)
end

local function UpdateVisual(control)
	control.swatchFill:SetColorTexture(control.r, control.g, control.b, control.a)
	control.field.hoverTexture:SetShown(control.isHovered == true)
end

local function UpdateLayout(control)
	local swatchSize = addon.Utilities:ToUI(addon.Utilities:ToPixels(24))
	local labelInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(8))
	local controlHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(24))

	control:SetHeight(controlHeight)

	control.field:ClearAllPoints()
	control.field:SetPoint("LEFT", control, "LEFT", 0, 0)
	control.field:SetSize(swatchSize, swatchSize)

	control.label:ClearAllPoints()

	if control.labelVisible then
		control.label:Show()
		control.label:SetPoint("LEFT", control.field, "RIGHT", labelInset, 0)
		control.label:SetPoint("RIGHT", control, "RIGHT", 0, 0)
		control.label:SetPoint("TOP", control.field, "TOP", 0, 0)
		control.label:SetPoint("BOTTOM", control.field, "BOTTOM", 0, 0)
	else
		control.label:Hide()
	end
end

local function NotifyValueChanged(control)
	if control.onValueChanged then
		control.onValueChanged(control, control.r, control.g, control.b, control.a)
	end
end

local function OpenPicker(control)
	if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then
		return
	end

	addon.Options.Controls.Dropdown:CloseOpenDropdown()

	local initialR, initialG, initialB, initialA = control:GetColor()

	local function ApplyFromPicker()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		local a = control.hasOpacity and (ColorPickerFrame:GetColorAlpha() or 1) or 1

		control:SetColor(r, g, b, a)
		NotifyValueChanged(control)
	end

	ColorPickerFrame:SetupColorPickerAndShow({
		swatchFunc = ApplyFromPicker,
		opacityFunc = ApplyFromPicker,
		cancelFunc = function(previousValues)
			if type(previousValues) == "table" then
				control:SetColor(
					previousValues.r or initialR,
					previousValues.g or initialG,
					previousValues.b or initialB,
					previousValues.a or previousValues.opacity or initialA
				)
			else
				control:SetColor(initialR, initialG, initialB, initialA)
			end

			NotifyValueChanged(control)
		end,
		hasOpacity = control.hasOpacity,
		opacity = initialA,
		r = initialR,
		g = initialG,
		b = initialB,
	})
end

function ColorPicker:Create(parent, labelText)
	local control = CreateFrame("Frame", nil, parent)
	local width = addon.Utilities:ToUI(addon.Utilities:ToPixels(220))
	local swatchSize = addon.Utilities:ToUI(addon.Utilities:ToPixels(24))
	local swatchInnerInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(2))

	control:SetSize(width, addon.Utilities:ToUI(addon.Utilities:ToPixels(24)))
	control.labelVisible = true
	control.hasOpacity = false
	control.isHovered = false
	control.r = 1
	control.g = 1
	control.b = 1
	control.a = 1

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.label:SetFont(theme.fonts.arialNarrow, 12, "")
	control.label:SetTextColor(0.85, 0.85, 0.88, 1)
	control.label:SetJustifyH("LEFT")
	control.label:SetJustifyV("MIDDLE")
	control.label:SetText(labelText or "Color")

	control.field = CreateFrame("Button", nil, control, "BackdropTemplate")
	control.field:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	control.field:SetBackdropColor(0.02, 0.03, 0.04, 1)
	CreateBorder(control.field)

	control.field.hoverTexture = control.field:CreateTexture(nil, "ARTWORK")
	control.field.hoverTexture:SetColorTexture(1, 1, 1, 0.08)
	control.field.hoverTexture:SetDrawLayer("OVERLAY", 1)
	control.field.hoverTexture:SetPoint("TOPLEFT", control.field, "TOPLEFT", 0, 0)
	control.field.hoverTexture:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", 0, 0)
	control.field.hoverTexture:Hide()

	control.swatchFill = control.field:CreateTexture(nil, "ARTWORK")
	control.swatchFill:SetPoint("TOPLEFT", control.field, "TOPLEFT", swatchInnerInset, -swatchInnerInset)
	control.swatchFill:SetPoint("BOTTOMRIGHT", control.field, "BOTTOMRIGHT", -swatchInnerInset, swatchInnerInset)

	function control:SetLabel(text)
		self.label:SetText(text or "")
	end

	function control:SetLabelVisible(isVisible)
		self.labelVisible = isVisible ~= false
		UpdateLayout(self)
	end

	function control:SetHasOpacity(hasOpacity)
		self.hasOpacity = hasOpacity == true
		self.a = self.hasOpacity and self.a or 1
	end

	function control:SetColor(r, g, b, a)
		if type(r) == "table" then
			a = r.a
			b = r.b
			g = r.g
			r = r.r
		end

		self.r = ClampChannel(r, self.r)
		self.g = ClampChannel(g, self.g)
		self.b = ClampChannel(b, self.b)
		self.a = self.hasOpacity and ClampChannel(a, self.a) or 1

		UpdateVisual(self)
	end

	function control:GetColor()
		return self.r, self.g, self.b, self.a
	end

	function control:SetOnValueChanged(callback)
		self.onValueChanged = callback
	end

	control.field:SetScript("OnEnter", function()
		control.isHovered = true
		UpdateVisual(control)
	end)

	control.field:SetScript("OnLeave", function()
		control.isHovered = false
		UpdateVisual(control)
	end)

	control.field:SetScript("OnClick", function()
		OpenPicker(control)
	end)

	UpdateLayout(control)
	UpdateVisual(control)

	return control
end
