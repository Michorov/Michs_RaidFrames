local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local Preview = OptionsUILib.PanelSections.Preview or {}
OptionsUILib.PanelSections.Preview = Preview

local Methods = Preview.Methods or {}
Preview.Methods = Methods

function Preview:Create(panel)
	local frame = panel.frame
	local preview = CreateFrame("Frame", nil, frame)
	preview.panel = panel

	preview:SetPoint("TOPLEFT", frame.content, "TOPRIGHT", 0, 0)
	preview:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMRIGHT", 0, 0)

	preview.leftBorder = preview:CreateTexture(nil, "OVERLAY")
	preview.leftBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))

	preview.canvas = CreateFrame("Frame", nil, preview)
	preview.canvas:SetAllPoints(preview)

	return Mixin(preview, Methods)
end

function Methods:GetCanvas()
	return self.canvas
end

function Methods:SetLayoutUpdater(callback)
	self.layoutUpdater = callback
end

function Methods:SetPageUpdater(callback)
	self.pageUpdater = callback
end

function Methods:UpdateActivePage(pageKey, page)
	if self.pageUpdater then
		self.pageUpdater(pageKey, page)
	end
end

function Methods:UpdateLayout()
	local panel = self.panel
	local PP = panel.instance.PP
	local outerInset = PP:ToUIScaled(8)

	self:SetShown(panel.previewEnabled)
	self:SetWidth(PP:ToUIScaled(panel.layout.previewWidth))
	self.leftBorder:ClearAllPoints()
	self.leftBorder:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -outerInset)
	self.leftBorder:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, outerInset)
	self.leftBorder:SetWidth(PP:ToUIScaled(1))

	if self.layoutUpdater then
		self.layoutUpdater()
	end
end
