local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local Panel = OptionsUILib.Panel
Panel.__index = Panel

local defaultLayout = {
	height = 576,
	headerHeight = 40,
	footerHeight = 32,
	sidebarWidth = 160,
	mainWidth = 640,
	previewWidth = 224,
	pagePadding = 32,
	pageHeaderHeight = 32,
	pageHeaderBodyGap = 32,
	pageHeaderControlHeight = 24,
	pageHeaderControlGap = 8,
	pageHeaderModeWidth = 152,
	pageHeaderButtonWidth = 116,
}

local function SavePosition(panel)
	local frame = panel.frame
	if not frame then
		return
	end

	local panelCenterX, panelCenterY = frame:GetCenter()
	local parentCenterX, parentCenterY = UIParent:GetCenter()
	if not panelCenterX or not panelCenterY or not parentCenterX or not parentCenterY then
		return
	end

	local globalScale = panel.instance.PP.globalScale or 1
	panel.offsetX = (panelCenterX - parentCenterX) / globalScale
	panel.offsetY = (panelCenterY - parentCenterY) / globalScale
end

function OptionsUILib.Instance:CreatePanel(config)
	config = config or {}
	local modes = config.modes or {}
	local activeMode = config.activeMode or modes[1]
	OptionsUILib.Theme:SetActiveLocale(config.localeGetter and config.localeGetter() or GetLocale())

	local panel = setmetatable({
		instance = self,
		name = config.name or self.addonName,
		titleKey = config.titleKey,
		title = config.title or (config.titleKey and (config.localize and config.localize(config.titleKey) or config.titleKey)) or self.title,
		config = config,
		layout = {
			height = defaultLayout.height,
			headerHeight = defaultLayout.headerHeight,
			footerHeight = defaultLayout.footerHeight,
			sidebarWidth = defaultLayout.sidebarWidth,
			mainWidth = defaultLayout.mainWidth,
			previewWidth = defaultLayout.previewWidth,
			pagePadding = defaultLayout.pagePadding,
			pageHeaderHeight = defaultLayout.pageHeaderHeight,
			pageHeaderBodyGap = defaultLayout.pageHeaderBodyGap,
			pageHeaderControlHeight = defaultLayout.pageHeaderControlHeight,
			pageHeaderControlGap = defaultLayout.pageHeaderControlGap,
			pageHeaderModeWidth = defaultLayout.pageHeaderModeWidth,
			pageHeaderButtonWidth = defaultLayout.pageHeaderButtonWidth,
		},
		previewEnabled = config.previewEnabled == true,
		modes = modes,
		modeOptions = config.modeOptions or {},
		activeMode = activeMode,
		localize = config.localize,
		localeGetter = config.localeGetter,
		profileGetter = config.profileGetter,
		pages = {},
		stateUpdaters = {},
		defaultPageKey = nil,
		activePageKey = nil,
		offsetX = 0,
		offsetY = 0,
	}, Panel)

	self.panels[#self.panels + 1] = panel

	local frameName = panel.config.frameName or ((panel.name or "OptionsUI") .. "Panel")
	local frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
	panel.frame = frame
	if frame:GetName() and not tContains(UISpecialFrames, frame:GetName()) then
		table.insert(UISpecialFrames, frame:GetName())
	end

	frame:Hide()
	frame:SetFrameStrata(panel.config.frameStrata or "DIALOG")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	frame:SetBackdropColor(OptionsUILib.Theme:GetColor("background"))
	frame.topBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.topBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	frame.topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

	frame.bottomBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.bottomBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	frame.bottomBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	frame.bottomBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

	frame.leftBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.leftBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	frame.leftBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	frame.leftBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

	frame.rightBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.rightBorder:SetColorTexture(OptionsUILib.Theme:GetColor("border"))
	frame.rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	frame.rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

	frame.header = OptionsUILib.PanelSections.Header:Create(panel)
	frame.footer = OptionsUILib.PanelSections.Footer:Create(panel)
	frame.sidebar = OptionsUILib.PanelSections.Sidebar:Create(panel)
	frame.content = OptionsUILib.PanelSections.Content:Create(panel)
	frame.preview = OptionsUILib.PanelSections.Preview:Create(panel)

	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)

	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition(panel)
		panel:UpdateLayout()
	end)

	panel.instance.PP:RegisterForUpdate(function()
		panel:UpdateLayout()
	end)

	return panel
end

function Panel:UpdateLayout()
	if not self.frame then
		return
	end

	local PP = self.instance.PP
	local width = self.layout.sidebarWidth + self.layout.mainWidth

	if self.previewEnabled then
		width = width + self.layout.previewWidth
	end

	self.frame:SetSize(PP:ToUIScaled(width), PP:ToUIScaled(self.layout.height))
	PP:CenterElement(self.frame, UIParent, PP:ToUIScaled(self.offsetX), PP:ToUIScaled(self.offsetY))

	local borderThickness = PP:ToUIScaled(1)
	self.frame.topBorder:SetHeight(borderThickness)
	self.frame.bottomBorder:SetHeight(borderThickness)
	self.frame.leftBorder:SetWidth(borderThickness)
	self.frame.rightBorder:SetWidth(borderThickness)

	self.frame.header:UpdateLayout()
	self.frame.footer:UpdateLayout()
	self.frame.sidebar:UpdateLayout()
	self.frame.content:UpdateLayout()
	self.frame.preview:UpdateLayout()
end

function Panel:RegisterPage(key, config)
	if self.pages[key] then
		return self.pages[key]
	end

	local page = OptionsUILib.Page:Create(self, key, config)
	self.pages[key] = page

	if self.frame and self.frame.sidebar then
		self.frame.sidebar:AddPage(page)
	end

	if self.frame and self.frame.content then
		self.frame.content:AddPage(page)
	end

	return page
end

function Panel:GetPage(key)
	return self.pages[key]
end

function Panel:SetActivePage(key)
	if not self.pages[key] then
		return
	end

	self.activePageKey = key

	if self.frame and self.frame.sidebar then
		self.frame.sidebar:SetActivePage(key)
	end

	if self.frame and self.frame.content then
		self.frame.content:SetActivePage(key)
	end

	if self.frame and self.frame.preview then
		self.frame.preview:UpdateActivePage(key, self.pages[key])
	end
end

function Panel:SetDefaultPage(key)
	if not self.pages[key] then
		return
	end

	self.defaultPageKey = key

	if not self.activePageKey then
		self:SetActivePage(key)
	end
end

function Panel:GetActivePage()
	return self.pages[self.activePageKey]
end

function Panel:GetActiveMode()
	return self.activeMode
end

function Panel:Localize(key, args)
	if not key then
		return nil
	end

	local text = self.localize and self.localize(key) or key
	if args then
		return text:format(unpack(args))
	end

	return text
end

function Panel:SetModeOptions(modeOptions)
	self.modeOptions = modeOptions or {}

	for _, page in pairs(self.pages) do
		if page.UpdateModeOptions then
			page:UpdateModeOptions()
		end
	end
end

function Panel:SetActiveMode(mode)
	if self.activeMode == mode then
		return self.activeMode
	end

	self.activeMode = mode
	for _, page in pairs(self.pages) do
		if page.UpdateModeSwitch then
			page:UpdateModeSwitch()
		end
	end

	self:UpdateState()

	return self.activeMode
end

function Panel:SetFooterText(text)
	self.frame.footer:SetText(text)
end

function Panel:SetTitle(title)
	self.title = title

	if self.frame and self.frame.header then
		self.frame.header.title:SetText(title or "")
	end
end

function Panel:UpdateLocale()
	if OptionsUILib.Controls.Dropdown then
		OptionsUILib.Controls.Dropdown:CloseOpenDropdown()
	end

	OptionsUILib.Theme:SetActiveLocale(self.localeGetter and self.localeGetter() or GetLocale())
	OptionsUILib.Theme:RefreshFonts()

	if self.titleKey then
		self:SetTitle(self:Localize(self.titleKey))
	end

	for _, page in pairs(self.pages) do
		if page.UpdateLocale then
			page:UpdateLocale()
		end
	end

	self:UpdateState()
	self:UpdateLayout()
end

function Panel:Show()
	if self.defaultPageKey and not self.activePageKey then
		self:SetActivePage(self.defaultPageKey)
	end

	self:UpdateState()
	self.frame:Show()
end

function Panel:Hide()
	self.frame:Hide()
end

function Panel:IsShown()
	return self.frame:IsShown()
end
