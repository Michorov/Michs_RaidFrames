local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local Header = OptionsUILib.PanelSections.Header or {}
OptionsUILib.PanelSections.Header = Header

local Methods = Header.Methods or {}
Header.Methods = Methods

function Header:Create(panel)
	local frame = panel.frame
	local header = CreateFrame("Frame", nil, frame)
	header.panel = panel

	header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

	header.title = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	header.title:SetJustifyH("LEFT")
	header.title:SetText(panel.title)
	header.title:SetTextColor(OptionsUILib.Theme:GetColor("brand"))

	header.closeButton = CreateFrame("Button", nil, header)
	header.closeButton.text = header.closeButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	header.closeButton.text:SetJustifyH("CENTER")
	header.closeButton.text:SetJustifyV("MIDDLE")
	header.closeButton.text:SetText("X")
	header.closeButton.text:SetTextColor(OptionsUILib.Theme:GetTextColor("secondary"))
	header.closeButton.text:SetPoint("TOPLEFT", header.closeButton, "TOPLEFT", 0, 0)
	header.closeButton.text:SetPoint("BOTTOMRIGHT", header.closeButton, "BOTTOMRIGHT", 0, 0)

	header.closeButton:SetScript("OnClick", function()
		panel:Hide()
	end)
	header.closeButton:SetScript("OnEnter", function(self)
		self.text:SetTextColor(OptionsUILib.Theme:GetColor("brand"))
	end)
	header.closeButton:SetScript("OnLeave", function(self)
		self.text:SetTextColor(OptionsUILib.Theme:GetTextColor("secondary"))
	end)

	return Mixin(header, Methods)
end

function Methods:UpdateLayout()
	local panel = self.panel
	local PP = panel.instance.PP

	self:SetHeight(PP:ToUIScaled(panel.layout.headerHeight))

	self.title:ClearAllPoints()
	self.title:SetPoint("TOPLEFT", self, "TOPLEFT", PP:ToUIScaled(8), PP:ToUIScaled(-8))
	OptionsUILib.Theme:ApplyFont(self.title, PP:ScaleFont(22), "", "title")

	self.closeButton:ClearAllPoints()
	self.closeButton:SetPoint("TOPRIGHT", self, "TOPRIGHT", PP:ToUIScaled(-8), PP:ToUIScaled(-8))
	self.closeButton:SetSize(PP:ToUIScaled(24), PP:ToUIScaled(24))

	OptionsUILib.Theme:ApplyFont(self.closeButton.text, PP:ScaleFont(16), "")
end
