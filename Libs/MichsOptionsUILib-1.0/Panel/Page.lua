local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local Page = OptionsUILib.Page or {}
OptionsUILib.Page = Page

local Methods = Page.Methods or {}
Page.Methods = Methods

local function UpdateSubPageDropdown(page)
	if not page.subpageDropdown then
		return
	end

	local options = {}
	for _, subpage in ipairs(page.subpages) do
		options[#options + 1] = {
			text = subpage.title,
			value = subpage.key,
		}
	end

	page.subpageDropdown:SetOptions(options)
	page.subpageDropdown:SetValue(page.activeSubpageKey)
	page.subpageDropdown:SetShown(#options > 0)
end

local function GetModeText(panel, mode)
	for _, option in ipairs(panel.modeOptions or {}) do
		if option.value == mode then
			return option.textKey and panel:Localize(option.textKey, option.textArgs) or option.text
		end
	end

	if not mode or mode == "" then
		return ""
	end

	return mode:sub(1, 1):upper() .. mode:sub(2)
end

local function GetModeOptions(panel)
	local options = {}
	for _, mode in ipairs(panel.modes) do
		options[#options + 1] = {
			text = GetModeText(panel, mode),
			value = mode,
		}
	end

	return options
end

local function CreateModeSwitch(page)
	local panel = page.panel
	local PP = panel.instance.PP
	local modes = panel.modes

	if page.modeSwitchType == "dropdown" then
		local dropdown = OptionsUILib.Controls.Dropdown:Create(page.header.modeSlot, PP)
		dropdown:SetLabelVisible(false)
		dropdown:SetPlaceholder("")
		dropdown:SetOptions(GetModeOptions(panel))
		dropdown:SetOnValueChanged(function(_, value)
			panel:SetActiveMode(value)
		end)

		page.modeSwitch = dropdown
		return
	end

	if not modes[1] or not modes[2] then
		return
	end

	local toggle = OptionsUILib.Controls.SegmentedToggle:Create(
		page.header.modeSlot,
		PP,
		{ value = modes[1], text = GetModeText(panel, modes[1]) },
		{ value = modes[2], text = GetModeText(panel, modes[2]) }
	)
	toggle:SetOnValueChanged(function(_, value)
		panel:SetActiveMode(value)
	end)

	page.modeSwitch = toggle
end

local function PositionHeaderSlot(page, slot, width, previousSlot, headerHeight, controlGap)
	slot:ClearAllPoints()
	if previousSlot then
		slot:SetPoint("RIGHT", previousSlot, "LEFT", -controlGap, 0)
	else
		slot:SetPoint("RIGHT", page.header, "RIGHT", 0, 0)
	end
	slot:SetSize(width, headerHeight)
	slot:Show()

	return slot
end

function Page:Create(panel, key, config)
	config = config or {}

	local placement = config.sidebarPlacement or "top"
	local parent = panel.frame.content
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetAllPoints(parent)
	frame:Hide()

	local page = Mixin({
		panel = panel,
		frame = frame,
		key = key,
		titleKey = config.titleKey,
		title = config.title or (config.titleKey and panel:Localize(config.titleKey)) or key,
		showHeader = config.showHeader == true,
		showSubpageDropdown = config.showSubpageDropdown == true,
		showModeSwitch = config.showModeSwitch == true,
		modeSwitchType = config.modeSwitchType or "toggle",
		showHeaderButton = config.showHeaderButton == true,
		headerButtonTextKey = config.headerButtonTextKey,
		headerButtonText = config.headerButtonText or "",
		headerButtonCallback = config.headerButtonCallback,
		sidebarPlacement = placement,
		subpages = {},
		activeSubpageKey = nil,
	}, Methods)

	frame.page = page

	if page.showHeader then
		frame.header = CreateFrame("Frame", nil, frame)

		frame.header.title = frame.header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		frame.header.title:SetJustifyH("LEFT")
		frame.header.title:SetText(page.title)
		frame.header.title:SetTextColor(OptionsUILib.Theme:GetTextColor("highlight"))

		frame.header.controlSlot = CreateFrame("Frame", nil, frame.header)
		frame.header.subpageSlot = frame.header.controlSlot
		frame.header.modeSlot = CreateFrame("Frame", nil, frame.header)
		frame.header.buttonSlot = CreateFrame("Frame", nil, frame.header)

		page.header = frame.header
		page.headerControlSlot = frame.header.controlSlot

		if page.showModeSwitch then
			CreateModeSwitch(page)
		end

		if page.showSubpageDropdown then
			page.subpageDropdown = OptionsUILib.Controls.Dropdown:Create(page.headerControlSlot, panel.instance.PP)
			page.subpageDropdown:SetLabelVisible(false)
			page.subpageDropdown:SetPlaceholder("")
			page.subpageDropdown:SetOnValueChanged(function(_, value)
				page:SetActiveSubPage(value)
			end)
			page.subpageDropdown:Hide()
		end

		if page.showHeaderButton then
			local buttonText = page.headerButtonText
			if page.headerButtonTextKey then
				buttonText = panel:Localize(page.headerButtonTextKey)
			end

			page.headerButton = OptionsUILib.Controls.Button:Create(frame.header.buttonSlot, panel.instance.PP, buttonText)
			page.headerButton.panel = panel
			page.headerButton:SetOnClick(function(button)
				if page.headerButtonCallback then
					page.headerButtonCallback(page, button)
				end
			end)
		end
	end

	frame.body = CreateFrame("Frame", nil, frame)
	page.body = frame.body

	return page
end

function Methods:UpdateLayout()
	local PP = self.panel.instance.PP
	local padding = PP:ToUIScaled(self.panel.layout.pagePadding)
	local headerHeight = PP:ToUIScaled(self.panel.layout.pageHeaderHeight)
	local bodyGap = PP:ToUIScaled(self.panel.layout.pageHeaderBodyGap)
	local controlGap = PP:ToUIScaled(self.panel.layout.pageHeaderControlGap)
	local modeWidth = PP:ToUIScaled(self.panel.layout.pageHeaderModeWidth)
	local buttonWidth = PP:ToUIScaled(self.panel.layout.pageHeaderButtonWidth)

	if self.header then
		self.header:ClearAllPoints()
		self.header:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding, -padding)
		self.header:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -padding, -padding)
		self.header:SetHeight(headerHeight)

		self.header.title:ClearAllPoints()
		self.header.title:SetPoint("LEFT", self.header, "LEFT", 0, 0)
		OptionsUILib.Theme:ApplyFont(self.header.title, PP:ScaleFont(20), "")

		if self.header.modeSlot then
			self.header.modeSlot:Hide()
		end

		if self.header.controlSlot then
			self.header.controlSlot:Hide()
		end

		if self.header.buttonSlot then
			self.header.buttonSlot:Hide()
		end

		local previousSlot
		if self.modeSwitch then
			previousSlot = PositionHeaderSlot(self, self.header.modeSlot, modeWidth, previousSlot, headerHeight, controlGap)
		end

		if self.subpageDropdown then
			previousSlot = PositionHeaderSlot(self, self.header.controlSlot, modeWidth, previousSlot, headerHeight, controlGap)
		end

		if self.headerButton then
			previousSlot = PositionHeaderSlot(self, self.header.buttonSlot, buttonWidth, previousSlot, headerHeight, controlGap)
		end

		if self.modeSwitch then
			self.modeSwitch.layout.width = self.panel.layout.pageHeaderModeWidth
			self.modeSwitch.layout.height = self.panel.layout.pageHeaderControlHeight
			self.modeSwitch.layout.fieldHeight = self.panel.layout.pageHeaderControlHeight
			self.modeSwitch:ClearAllPoints()
			self.modeSwitch:SetPoint("RIGHT", self.header.modeSlot, "RIGHT", 0, 0)
			self.modeSwitch:UpdateLayout()
			self.modeSwitch:SetValue(self.panel:GetActiveMode())
		end

		if self.subpageDropdown then
			self.subpageDropdown.layout.width = self.panel.layout.pageHeaderModeWidth
			self.subpageDropdown.layout.fieldHeight = self.panel.layout.pageHeaderControlHeight
			self.subpageDropdown:ClearAllPoints()
			self.subpageDropdown:SetPoint("RIGHT", self.header.controlSlot, "RIGHT", 0, 0)
			self.subpageDropdown:UpdateLayout()
		end

		if self.headerButton then
			self.headerButton.layout.width = self.panel.layout.pageHeaderButtonWidth
			self.headerButton.layout.height = self.panel.layout.pageHeaderControlHeight
			self.headerButton:ClearAllPoints()
			self.headerButton:SetPoint("RIGHT", self.header.buttonSlot, "RIGHT", 0, 0)
			self.headerButton:UpdateLayout()
		end

		self.body:ClearAllPoints()
		self.body:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, -bodyGap)
	else
		self.body:ClearAllPoints()
		self.body:SetPoint("TOPLEFT", self.frame, "TOPLEFT", padding, -padding)
	end

	self.body:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -padding, padding)

	for _, subpage in ipairs(self.subpages) do
		subpage:UpdateLayout()
	end
end

function Methods:SetTitle(title)
	self.title = title

	if self.header and self.header.title then
		self.header.title:SetText(title or "")
	end

	if self.panel.frame and self.panel.frame.sidebar and self.panel.frame.sidebar.buttons[self.key] then
		self.panel.frame.sidebar.buttons[self.key].text:SetText(title or "")
	end
end

function Methods:UpdateSubPageDropdown()
	UpdateSubPageDropdown(self)
end

function Methods:RegisterSubPage(key, config)
	if self.subpages[key] then
		return self.subpages[key]
	end

	local subpage = OptionsUILib.SubPage:Create(self, key, config)
	self.subpages[key] = subpage
	self.subpages[#self.subpages + 1] = subpage

	if not self.activeSubpageKey then
		self:SetActiveSubPage(key)
	end

	UpdateSubPageDropdown(self)
	return subpage
end

function Methods:SetActiveSubPage(key)
	if not self.subpages[key] then
		return
	end

	self.activeSubpageKey = key

	for _, subpage in ipairs(self.subpages) do
		if subpage.frame then
			subpage.frame:SetShown(subpage.key == key)
		end
	end

	if self.subpageDropdown then
		self.subpageDropdown:SetValue(key)
	end
end

function Methods:UpdateModeSwitch()
	if self.modeSwitch then
		self.modeSwitch:SetValue(self.panel:GetActiveMode())
	end
end

function Methods:UpdateModeOptions()
	if not self.modeSwitch then
		return
	end

	if self.modeSwitchType == "dropdown" then
		self.modeSwitch:SetOptions(GetModeOptions(self.panel))
	else
		self.modeSwitch:SetOptions(
			{ value = self.panel.modes[1], text = GetModeText(self.panel, self.panel.modes[1]) },
			{ value = self.panel.modes[2], text = GetModeText(self.panel, self.panel.modes[2]) }
		)
	end

	self.modeSwitch:SetValue(self.panel:GetActiveMode())
end

function Methods:UpdateLocale()
	if self.titleKey then
		self:SetTitle(self.panel:Localize(self.titleKey))
	end

	if self.headerButtonTextKey then
		self:SetHeaderButtonText(self.panel:Localize(self.headerButtonTextKey))
	end

	self:UpdateModeOptions()

	for _, subpage in ipairs(self.subpages) do
		subpage:UpdateLocale()
	end
end

function Methods:SetHeaderButtonText(text)
	if self.headerButton then
		self.headerButton:SetText(text)
	end
end
