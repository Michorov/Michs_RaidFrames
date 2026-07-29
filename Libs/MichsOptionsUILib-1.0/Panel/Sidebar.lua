local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local Sidebar = OptionsUILib.PanelSections.Sidebar or {}
OptionsUILib.PanelSections.Sidebar = Sidebar

local Methods = Sidebar.Methods or {}
Sidebar.Methods = Methods

local function UpdateButtonState(button)
	local isActive = button.sidebar.panel.activePageKey == button.page.key

	if isActive then
		button.text:SetTextColor(OptionsUILib.Theme:GetColor("brand"))
	else
		button.text:SetTextColor(OptionsUILib.Theme:GetTextColor("primary"))
	end
end

local function CreateButton(sidebar, page)
	local button = CreateFrame("Button", nil, sidebar)
	button.sidebar = sidebar
	button.page = page

	button.hoverTexture = button:CreateTexture(nil, "BACKGROUND")
	button.hoverTexture:SetColorTexture(OptionsUILib.Theme:GetColor("controlHoverOverlay"))
	button.hoverTexture:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	button.hoverTexture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	button.hoverTexture:Hide()

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.text:SetJustifyH("LEFT")
	button.text:SetText(page.title)

	button:SetScript("OnClick", function(self)
		self.sidebar.panel:SetActivePage(self.page.key)
	end)

	button:SetScript("OnEnter", function(self)
		self.hoverTexture:Show()
		self.text:SetTextColor(OptionsUILib.Theme:GetColor("brand"))
	end)

	button:SetScript("OnLeave", function(self)
		self.hoverTexture:Hide()
		UpdateButtonState(self)
	end)

	return button
end

function Sidebar:Create(panel)
	local frame = panel.frame
	local sidebar = CreateFrame("Frame", nil, frame)
	sidebar.panel = panel
	sidebar.buttons = {}
	sidebar.topPages = {}
	sidebar.bottomPages = {}

	sidebar:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT", 0, 0)
	sidebar:SetPoint("BOTTOMLEFT", frame.footer, "TOPLEFT", 0, 0)

	sidebar.rightBorder = sidebar:CreateTexture(nil, "OVERLAY")
	sidebar.rightBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))

	return Mixin(sidebar, Methods)
end

function Methods:AddPage(page)
	if self.buttons[page.key] then
		return self.buttons[page.key]
	end

	local button = CreateButton(self, page)
	self.buttons[page.key] = button

	if page.sidebarPlacement == "bottom" then
		self.bottomPages[#self.bottomPages + 1] = page
	else
		self.topPages[#self.topPages + 1] = page
	end

	self:UpdateLayout()

	return button
end

function Methods:SetActivePage(pageKey)
	for _, button in pairs(self.buttons) do
		UpdateButtonState(button)
	end
end

function Methods:UpdateLayout()
	local panel = self.panel
	local PP = panel.instance.PP
	local outerInset = PP:ToUIScaled(8)
	local spacing = PP:ToUIScaled(4)
	local textInset = PP:ToUIScaled(10)
	local buttonHeight = PP:ToUIScaled(32)

	self:SetWidth(PP:ToUIScaled(panel.layout.sidebarWidth))

	local previousTopButton
	for _, page in ipairs(self.topPages) do
		local button = self.buttons[page.key]
		if button then
			button:ClearAllPoints()
			button:SetHeight(buttonHeight)

			if previousTopButton then
				button:SetPoint("TOPLEFT", previousTopButton, "BOTTOMLEFT", 0, -spacing)
				button:SetPoint("TOPRIGHT", previousTopButton, "BOTTOMRIGHT", 0, -spacing)
			else
				button:SetPoint("TOPLEFT", self, "TOPLEFT", outerInset, -outerInset)
				button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -outerInset, -outerInset)
			end

			button.text:ClearAllPoints()
			button.text:SetPoint("LEFT", button, "LEFT", textInset, 0)
			button.text:SetPoint("RIGHT", button, "RIGHT", -textInset, 0)
			OptionsUILib.Theme:ApplyFont(button.text, PP:ScaleFont(14), "")
			UpdateButtonState(button)

			previousTopButton = button
		end
	end

	local previousBottomButton
	for _, page in ipairs(self.bottomPages) do
		local button = self.buttons[page.key]
		if button then
			button:ClearAllPoints()
			button:SetHeight(buttonHeight)

			if previousBottomButton then
				button:SetPoint("BOTTOMLEFT", previousBottomButton, "TOPLEFT", 0, spacing)
				button:SetPoint("BOTTOMRIGHT", previousBottomButton, "TOPRIGHT", 0, spacing)
			else
				button:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", outerInset, outerInset)
				button:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -outerInset, outerInset)
			end

			button.text:ClearAllPoints()
			button.text:SetPoint("LEFT", button, "LEFT", textInset, 0)
			button.text:SetPoint("RIGHT", button, "RIGHT", -textInset, 0)
			OptionsUILib.Theme:ApplyFont(button.text, PP:ScaleFont(14), "")
			UpdateButtonState(button)

			previousBottomButton = button
		end
	end

	self.rightBorder:ClearAllPoints()
	self.rightBorder:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -outerInset)
	self.rightBorder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, outerInset)
	self.rightBorder:SetWidth(PP:ToUIScaled(1))
end
