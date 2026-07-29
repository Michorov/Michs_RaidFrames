local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

OptionsUILib.Controls = OptionsUILib.Controls or {}
OptionsUILib.Controls.Label = OptionsUILib.Controls.Label or {}

local Label = OptionsUILib.Controls.Label

function Label:Create(parent, PP, text)
	if not parent or not PP then
		return nil
	end

	local control = CreateFrame("Frame", nil, parent)
	control.PP = PP
	control.layout = {
		parent = parent,
		width = 220,
		height = 16,
		fontSize = 14,
		point = nil,
		relativeTo = parent,
		relativePoint = nil,
		offsetX = 0,
		offsetY = 0,
	}

	control.text = control:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	control.text:SetJustifyH("LEFT")
	control.text:SetTextColor(OptionsUILib.Theme:GetTextColor("primary"))
	control.text:SetText(text or "")

	function control:SetText(value)
		self.text:SetText(value or "")
	end

	function control:SetTextColor(r, g, b, a)
		self.text:SetTextColor(r or 1, g or 1, b or 1, a or 1)
	end

	function control:SetFontSize(fontSize)
		self.layout.fontSize = fontSize
		self:UpdateLayout()
	end

	function control:SetLayoutWidth(width)
		self.layout.width = width
		self:UpdateLayout()
	end

	function control:SetLayoutHeight(height)
		self.layout.height = height
		self:UpdateLayout()
	end

	function control:SetLayoutSize(width, height)
		self.layout.width = width
		self.layout.height = height
		self:UpdateLayout()
	end

	function control:SetLayoutPoint(point, relativeTo, relativePoint, offsetX, offsetY)
		self.layout.point = point
		self.layout.relativeTo = relativeTo or self.layout.parent
		self.layout.relativePoint = relativePoint or point
		self.layout.offsetX = offsetX or 0
		self.layout.offsetY = offsetY or 0
		self:UpdateLayout()
	end

	function control:UpdateLayout()
		local PP = self.PP

		self:SetSize(PP:ToUIScaled(self.layout.width), PP:ToUIScaled(self.layout.height))
		OptionsUILib.Theme:ApplyFont(self.text, PP:ScaleFont(self.layout.fontSize), "")

		self.text:ClearAllPoints()
		self.text:SetPoint("LEFT", self, "LEFT", 0, 0)
		self.text:SetPoint("RIGHT", self, "RIGHT", 0, 0)

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

	control:UpdateLayout()

	return control
end
