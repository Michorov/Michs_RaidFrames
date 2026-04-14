local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.SideMenu = addon.Options.Sections.SideMenu or {}

local SideMenu = addon.Options.Sections.SideMenu

local sideMenu
local theme = addon.Options.Theme
local activePage

local function InitializeButton(button)
	button:SetBackdropColor(0, 0, 0, 0)
	button:SetLayoutBorderSize(0)
	button:SetLayoutHeight(32)

	button.text:SetJustifyH("LEFT")
	button.text:SetFont(theme.fonts.arialNarrow, 16, "")

	button.hoverTexture = button:CreateTexture(nil, "BACKGROUND")
	button.hoverTexture:SetColorTexture(theme:GetColor("controlHoverOverlay"))
	button.hoverTexture:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	button.hoverTexture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	button.hoverTexture:Hide()

	button:SetScript("OnEnter", function(self)
		self.hoverTexture:Show()
	end)

	button:SetScript("OnLeave", function(self)
		self.hoverTexture:Hide()
	end)
end

local function ApplySideMenuButtonLayout(button)
	local textInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(10))

	button.text:ClearAllPoints()
	button.text:SetPoint("LEFT", button, "LEFT", textInset, 0)
end

function SideMenu:Ensure(parent)
	if sideMenu then
		return sideMenu
	end

	sideMenu = CreateFrame("Frame", nil, parent)

	local generalButton = addon.Options.Controls.Button:Create(sideMenu, "General")
	InitializeButton(generalButton)
	generalButton:SetOnClick(function()
		addon.Options:SetActivePage("general")
	end)

	local layoutButton = addon.Options.Controls.Button:Create(sideMenu, "Layout")
	InitializeButton(layoutButton)
	layoutButton:SetOnClick(function()
		addon.Options:SetActivePage("layout")
	end)

	local frameButton = addon.Options.Controls.Button:Create(sideMenu, "Frames")
	InitializeButton(frameButton)
	frameButton:SetOnClick(function()
		addon.Options:SetActivePage("frames")
	end)

	local barsButton = addon.Options.Controls.Button:Create(sideMenu, "Bars")
	InitializeButton(barsButton)
	barsButton:SetOnClick(function()
		addon.Options:SetActivePage("bars")
	end)

	local textsButton = addon.Options.Controls.Button:Create(sideMenu, "Texts")
	InitializeButton(textsButton)
	textsButton:SetOnClick(function()
		addon.Options:SetActivePage("texts")
	end)

	local aurasButton = addon.Options.Controls.Button:Create(sideMenu, "Auras")
	InitializeButton(aurasButton)
	aurasButton:SetOnClick(function()
		addon.Options:SetActivePage("auras")
	end)

	local indicatorsButton = addon.Options.Controls.Button:Create(sideMenu, "Indicators")
	InitializeButton(indicatorsButton)
	indicatorsButton:SetOnClick(function()
		addon.Options:SetActivePage("indicators")
	end)

	local profilesButton = addon.Options.Controls.Button:Create(sideMenu, "Profiles")
	InitializeButton(profilesButton)
	profilesButton:SetOnClick(function()
		addon.Options:SetActivePage("profiles")
	end)

	sideMenu.controls = {
		general = generalButton,
		layout = layoutButton,
		frames = frameButton,
		bars = barsButton,
		texts = textsButton,
		auras = aurasButton,
		indicators = indicatorsButton,
		profiles = profilesButton,
	}

	sideMenu.rightBorder = sideMenu:CreateTexture(nil, "OVERLAY")
	sideMenu.rightBorder:SetColorTexture(theme:GetColor("border"))

	self:UpdateLayout()

	return sideMenu
end

function SideMenu:SetActivePage(pageKey)
	if not sideMenu then
		return
	end

	activePage = pageKey

	for key, button in pairs(sideMenu.controls) do
		local isActive = key == pageKey

		if isActive then
			button.text:SetTextColor(theme:GetColor("brand"))
		else
			button.text:SetTextColor(theme:GetTextColor("primary"))
		end
	end
end

function SideMenu:UpdateLayout()
	if not sideMenu then
		return
	end

	local outerInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(8))
	local compactSpacing = addon.Utilities:ToUI(addon.Utilities:ToPixels(4))

	for _, button in pairs(sideMenu.controls) do
		if button.UpdateLayout then
			button:UpdateLayout()
		end

		ApplySideMenuButtonLayout(button)
	end

	sideMenu.controls.general:ClearAllPoints()
	sideMenu.controls.general:SetPoint("TOPLEFT", sideMenu, "TOPLEFT", outerInset, -outerInset)
	sideMenu.controls.general:SetPoint("TOPRIGHT", sideMenu, "TOPRIGHT", -outerInset, -outerInset)

	sideMenu.controls.layout:ClearAllPoints()
	sideMenu.controls.layout:SetPoint("TOPLEFT", sideMenu.controls.general, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.controls.layout:SetPoint("TOPRIGHT", sideMenu.controls.general, "BOTTOMRIGHT", 0, -compactSpacing)

	sideMenu.controls.frames:ClearAllPoints()
	sideMenu.controls.frames:SetPoint("TOPLEFT", sideMenu.controls.layout, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.controls.frames:SetPoint("TOPRIGHT", sideMenu.controls.layout, "BOTTOMRIGHT", 0, -compactSpacing)

	sideMenu.controls.texts:ClearAllPoints()
	sideMenu.controls.texts:SetPoint("TOPLEFT", sideMenu.controls.bars, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.controls.texts:SetPoint("TOPRIGHT", sideMenu.controls.bars, "BOTTOMRIGHT", 0, -compactSpacing)

	sideMenu.controls.bars:ClearAllPoints()
	sideMenu.controls.bars:SetPoint("TOPLEFT", sideMenu.controls.frames, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.controls.bars:SetPoint("TOPRIGHT", sideMenu.controls.frames, "BOTTOMRIGHT", 0, -compactSpacing)

	sideMenu.controls.auras:ClearAllPoints()
	sideMenu.controls.auras:SetPoint("TOPLEFT", sideMenu.controls.texts, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.controls.auras:SetPoint("TOPRIGHT", sideMenu.controls.texts, "BOTTOMRIGHT", 0, -compactSpacing)

	sideMenu.controls.indicators:ClearAllPoints()
	sideMenu.controls.indicators:SetPoint("TOPLEFT", sideMenu.controls.auras, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.controls.indicators:SetPoint("TOPRIGHT", sideMenu.controls.auras, "BOTTOMRIGHT", 0, -compactSpacing)

	sideMenu.controls.profiles:ClearAllPoints()
	sideMenu.controls.profiles:SetPoint("BOTTOMLEFT", sideMenu, "BOTTOMLEFT", outerInset, outerInset)
	sideMenu.controls.profiles:SetPoint("BOTTOMRIGHT", sideMenu, "BOTTOMRIGHT", -outerInset, outerInset)

	sideMenu.rightBorder:ClearAllPoints()
	sideMenu.rightBorder:SetPoint("TOPRIGHT", sideMenu, "TOPRIGHT", 0, -outerInset)
	sideMenu.rightBorder:SetPoint("BOTTOMRIGHT", sideMenu, "BOTTOMRIGHT", 0, outerInset)
	sideMenu.rightBorder:SetWidth(addon.Utilities:ToUI(addon.Utilities:ToPixels(1)))

	if activePage then
		self:SetActivePage(activePage)
	end
end
