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
	frame.topBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.topBorder:SetColorTexture(theme:GetColor("border"))
	frame.topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

	frame.bottomBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.bottomBorder:SetColorTexture(theme:GetColor("border"))
	frame.bottomBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	frame.bottomBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

	frame.leftBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.leftBorder:SetColorTexture(theme:GetColor("border"))
	frame.leftBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.leftBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

	frame.rightBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.rightBorder:SetColorTexture(theme:GetColor("border"))
	frame.rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	frame.rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
end

local function UpdateVisual(control)
	control.swatchFill:SetColorTexture(control.r, control.g, control.b, control.a)
	control.field.hoverTexture:SetShown(control.isHovered == true)
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
	control.layoutValues = {
		width = 220,
		pickerSize = 24,
		labelInset = 8,
		borderThickness = 1,
		swatchInnerInset = 2,
	}
	control.labelVisible = true
	control.hasOpacity = false
	control.isHovered = false
	control.r = 1
	control.g = 1
	control.b = 1
	control.a = 1

	control.label = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.label:SetFont(theme.fonts.arialNarrow, 12, "")
	control.label:SetTextColor(theme:GetTextColor("primary"))
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

	function control:SetLabel(text)
		self.label:SetText(text or "")
	end

	function control:SetLayoutWidth(width)
		self.layoutValues.width = width
		self:UpdateLayout()
	end

	function control:SetPickerSize(size)
		self.layoutValues.pickerSize = size
		self:UpdateLayout()
	end

	function control:SetLabelVisible(isVisible)
		self.labelVisible = isVisible ~= false
		self:UpdateLayout()
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

	function control:UpdateLayout()
		local widthPx = addon.Utilities:ToPixels(self.layoutValues.width)
		local pickerSizePx = addon.Utilities:ToPixels(self.layoutValues.pickerSize)
		local labelInsetPx = addon.Utilities:ToPixels(self.layoutValues.labelInset)
		local borderThicknessPx = addon.Utilities:ToPixels(self.layoutValues.borderThickness)
		local swatchInnerInsetPx = addon.Utilities:ToPixels(self.layoutValues.swatchInnerInset)

		local width = addon.Utilities:ToUI(widthPx)
		local pickerSize = addon.Utilities:ToUI(pickerSizePx)
		local labelInset = addon.Utilities:ToUI(labelInsetPx)
		local borderThickness = addon.Utilities:ToUI(borderThicknessPx)
		local swatchInnerInset = addon.Utilities:ToUI(swatchInnerInsetPx)

		self:SetSize(width, pickerSize)

		self.field:ClearAllPoints()
		self.field:SetPoint("LEFT", self, "LEFT", 0, 0)
		self.field:SetSize(pickerSize, pickerSize)

		self.field.topBorder:SetHeight(borderThickness)
		self.field.bottomBorder:SetHeight(borderThickness)
		self.field.leftBorder:SetWidth(borderThickness)
		self.field.rightBorder:SetWidth(borderThickness)

		self.swatchFill:ClearAllPoints()
		self.swatchFill:SetPoint("TOPLEFT", self.field, "TOPLEFT", swatchInnerInset, -swatchInnerInset)
		self.swatchFill:SetPoint("BOTTOMRIGHT", self.field, "BOTTOMRIGHT", -swatchInnerInset, swatchInnerInset)

		self.label:ClearAllPoints()

		if self.labelVisible then
			self.label:Show()
			self.label:SetPoint("LEFT", self.field, "RIGHT", labelInset, 0)
			self.label:SetPoint("RIGHT", self, "RIGHT", 0, 0)
			self.label:SetPoint("TOP", self.field, "TOP", 0, 0)
			self.label:SetPoint("BOTTOM", self.field, "BOTTOM", 0, 0)
		else
			self.label:Hide()
		end
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

	control:UpdateLayout()
	UpdateVisual(control)

	return control
end
