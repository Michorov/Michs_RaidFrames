local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local Footer = OptionsUILib.PanelSections.Footer or {}
OptionsUILib.PanelSections.Footer = Footer

local Methods = Footer.Methods or {}
Footer.Methods = Methods

function Footer:Create(panel)
	local frame = panel.frame
	local footer = CreateFrame("Frame", nil, frame)
	footer.panel = panel

	footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

	footer.text = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	footer.text:SetJustifyH("LEFT")
	footer.text:SetTextColor(OptionsUILib.Theme:GetTextColor("secondary"))

	footer.topBorder = footer:CreateTexture(nil, "OVERLAY")
	footer.topBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))

	return Mixin(footer, Methods)
end

function Methods:SetText(text)
	self.text:SetText(text or "")
end

function Methods:UpdateLayout()
	local panel = self.panel
	local PP = panel.instance.PP
	local borderThickness = PP:ToUIScaled(1)

	self:SetHeight(PP:ToUIScaled(panel.layout.footerHeight))

	self.text:ClearAllPoints()
	self.text:SetPoint("LEFT", self, "LEFT", PP:ToUIScaled(10), 0)
	self.text:SetPoint("RIGHT", self, "RIGHT", PP:ToUIScaled(-8), 0)
	OptionsUILib.Theme:ApplyFont(self.text, PP:ScaleFont(12), "")

	self.topBorder:ClearAllPoints()
	self.topBorder:SetPoint("TOPLEFT", self, "TOPLEFT", PP:ToUIScaled(8), 0)
	self.topBorder:SetPoint("TOPRIGHT", self, "TOPRIGHT", PP:ToUIScaled(-8), 0)
	self.topBorder:SetHeight(borderThickness)
end
