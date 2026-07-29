local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local Content = OptionsUILib.PanelSections.Content or {}
OptionsUILib.PanelSections.Content = Content

local Methods = Content.Methods or {}
Content.Methods = Methods

function Content:Create(panel)
	local frame = panel.frame
	local content = CreateFrame("Frame", nil, frame)
	content.panel = panel
	content.pages = {}

	content:SetPoint("TOPLEFT", frame.sidebar, "TOPRIGHT", 0, 0)
	content:SetPoint("BOTTOMLEFT", frame.sidebar, "BOTTOMRIGHT", 0, 0)

	return Mixin(content, Methods)
end

function Methods:AddPage(page)
	if self.pages[page.key] then
		return self.pages[page.key]
	end

	self.pages[page.key] = page
	page:UpdateLayout()

	return page
end

function Methods:SetActivePage(pageKey)
	for key, page in pairs(self.pages) do
		page.frame:SetShown(key == pageKey)
	end
end

function Methods:UpdateLayout()
	local panel = self.panel
	local PP = panel.instance.PP

	self:SetWidth(PP:ToUIScaled(panel.layout.mainWidth))

	for _, page in pairs(self.pages) do
		page:UpdateLayout()
	end
end
