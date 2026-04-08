local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.SideMenu = addon.Options.Sections.SideMenu or {}

local SideMenu = addon.Options.Sections.SideMenu

local sideMenu
local theme = addon.Options.Theme
local activePage

local function GetButtonsByPageKey()
	if not sideMenu then
		return {}
	end

	return {
		general = sideMenu.generalButton,
		layout = sideMenu.layoutButton,
		texts = sideMenu.textsButton,
		auras = sideMenu.aurasButton,
		indicators = sideMenu.indicatorsButton,
		profiles = sideMenu.profilesButton,
	}
end

local function InitializeButton(button)
	button:SetBackdropColor(0, 0, 0, 0)

	button.borderTop:Hide()
	button.borderBottom:Hide()
	button.borderLeft:Hide()
	button.borderRight:Hide()

	button.normalTextColor = { 0.80, 0.80, 0.84, 1 }
	button.activeTextColor = {
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4],
	}

	button.hoverTexture = button:CreateTexture(nil, "BACKGROUND")
	button.hoverTexture:SetColorTexture(1, 1, 1, 0.02)
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

local function UpdateButtonLayout(button)
	local buttonHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(32))
	local textInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(10))

	button:SetHeight(buttonHeight)

	button.text:ClearAllPoints()
	button.text:SetPoint("LEFT", button, "LEFT", textInset, 0)
	button.text:SetJustifyH("LEFT")
	button.text:SetFont(theme.fonts.arialNarrow, 16, "")
	button.text:SetTextColor(
		button.normalTextColor[1],
		button.normalTextColor[2],
		button.normalTextColor[3],
		button.normalTextColor[4]
	)
end

function SideMenu:Ensure(parent)
	if sideMenu then
		return sideMenu
	end

	sideMenu = CreateFrame("Frame", nil, parent)

	sideMenu.generalButton = addon.Options.Controls.Button:Create(sideMenu, "General")
	InitializeButton(sideMenu.generalButton)
	sideMenu.generalButton:SetOnClick(function()
		addon.Options:SetActivePage("general")
	end)

	sideMenu.layoutButton = addon.Options.Controls.Button:Create(sideMenu, "Layout")
	InitializeButton(sideMenu.layoutButton)
	sideMenu.layoutButton:SetOnClick(function()
		addon.Options:SetActivePage("layout")
	end)

	sideMenu.textsButton = addon.Options.Controls.Button:Create(sideMenu, "Texts")
	InitializeButton(sideMenu.textsButton)
	sideMenu.textsButton:SetOnClick(function()
		addon.Options:SetActivePage("texts")
	end)

	sideMenu.aurasButton = addon.Options.Controls.Button:Create(sideMenu, "Auras")
	InitializeButton(sideMenu.aurasButton)
	sideMenu.aurasButton:SetOnClick(function()
		addon.Options:SetActivePage("auras")
	end)

	sideMenu.indicatorsButton = addon.Options.Controls.Button:Create(sideMenu, "Indicators")
	InitializeButton(sideMenu.indicatorsButton)
	sideMenu.indicatorsButton:SetOnClick(function()
		addon.Options:SetActivePage("indicators")
	end)

	sideMenu.profilesButton = addon.Options.Controls.Button:Create(sideMenu, "Profiles")
	InitializeButton(sideMenu.profilesButton)
	sideMenu.profilesButton:SetOnClick(function()
		addon.Options:SetActivePage("profiles")
	end)

	sideMenu.rightBorder = sideMenu:CreateTexture(nil, "OVERLAY")
	sideMenu.rightBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)

	self:UpdateLayout()

	return sideMenu
end

function SideMenu:SetActivePage(pageKey)
	if not sideMenu then
		return
	end

	activePage = pageKey

	for key, button in pairs(GetButtonsByPageKey()) do
		local isActive = key == pageKey

		if isActive then
			button.text:SetTextColor(
				button.activeTextColor[1],
				button.activeTextColor[2],
				button.activeTextColor[3],
				button.activeTextColor[4]
			)
		else
			button.text:SetTextColor(
				button.normalTextColor[1],
				button.normalTextColor[2],
				button.normalTextColor[3],
				button.normalTextColor[4]
			)
		end
	end
end

function SideMenu:UpdateLayout()
	if not sideMenu then
		return
	end

	local outerInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(8))
	local compactSpacing = addon.Utilities:ToUI(addon.Utilities:ToPixels(4))

	UpdateButtonLayout(sideMenu.generalButton)
	sideMenu.generalButton:ClearAllPoints()
	sideMenu.generalButton:SetPoint("TOPLEFT", sideMenu, "TOPLEFT", outerInset, -outerInset)
	sideMenu.generalButton:SetPoint("TOPRIGHT", sideMenu, "TOPRIGHT", -outerInset, -outerInset)

	UpdateButtonLayout(sideMenu.layoutButton)
	sideMenu.layoutButton:ClearAllPoints()
	sideMenu.layoutButton:SetPoint("TOPLEFT", sideMenu.generalButton, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.layoutButton:SetPoint("TOPRIGHT", sideMenu.generalButton, "BOTTOMRIGHT", 0, -compactSpacing)

	UpdateButtonLayout(sideMenu.textsButton)
	sideMenu.textsButton:ClearAllPoints()
	sideMenu.textsButton:SetPoint("TOPLEFT", sideMenu.layoutButton, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.textsButton:SetPoint("TOPRIGHT", sideMenu.layoutButton, "BOTTOMRIGHT", 0, -compactSpacing)

	UpdateButtonLayout(sideMenu.aurasButton)
	sideMenu.aurasButton:ClearAllPoints()
	sideMenu.aurasButton:SetPoint("TOPLEFT", sideMenu.textsButton, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.aurasButton:SetPoint("TOPRIGHT", sideMenu.textsButton, "BOTTOMRIGHT", 0, -compactSpacing)

	UpdateButtonLayout(sideMenu.indicatorsButton)
	sideMenu.indicatorsButton:ClearAllPoints()
	sideMenu.indicatorsButton:SetPoint("TOPLEFT", sideMenu.aurasButton, "BOTTOMLEFT", 0, -compactSpacing)
	sideMenu.indicatorsButton:SetPoint("TOPRIGHT", sideMenu.aurasButton, "BOTTOMRIGHT", 0, -compactSpacing)

	UpdateButtonLayout(sideMenu.profilesButton)
	sideMenu.profilesButton:ClearAllPoints()
	sideMenu.profilesButton:SetPoint("BOTTOMLEFT", sideMenu, "BOTTOMLEFT", outerInset, outerInset)
	sideMenu.profilesButton:SetPoint("BOTTOMRIGHT", sideMenu, "BOTTOMRIGHT", -outerInset, outerInset)

	sideMenu.rightBorder:ClearAllPoints()
	sideMenu.rightBorder:SetPoint("TOPRIGHT", sideMenu, "TOPRIGHT", 0, -outerInset)
	sideMenu.rightBorder:SetPoint("BOTTOMRIGHT", sideMenu, "BOTTOMRIGHT", 0, outerInset)
	sideMenu.rightBorder:SetWidth(addon.Utilities:ToUI(addon.Utilities:ToPixels(1)))

	if activePage then
		self:SetActivePage(activePage)
	end
end
