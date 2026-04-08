local _, addon = ...

addon.Options = addon.Options or {}
local Options = addon.Options
local theme = addon.Options.Theme

local panel
local deferredOpen = false

function Options:SetActivePage(pageKey)
	addon.Options.Sections.Content:SetActivePage(pageKey)
	addon.Options.Sections.SideMenu:SetActivePage(pageKey)
end

function Options:UpdateLayout()
	if not panel then
		return
	end

	local frameWidth = addon.Utilities:ScaleEven(addon.Utilities:ToPixels(800))
	local frameHeight = addon.Utilities:ScaleEven(addon.Utilities:ToPixels(500))
	panel:SetSize(addon.Utilities:ToUI(frameWidth), addon.Utilities:ToUI(frameHeight))

	panel.header:ClearAllPoints()
	panel.header:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
	panel.header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
	panel.header:SetHeight(addon.Utilities:ToUI(addon.Utilities:ToPixels(40)))
	addon.Options.Sections.Header:UpdateLayout()

	panel.statusBar:ClearAllPoints()
	panel.statusBar:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
	panel.statusBar:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
	panel.statusBar:SetHeight(addon.Utilities:ToUI(addon.Utilities:ToPixels(32)))
	addon.Options.Sections.StatusBar:UpdateLayout()

	panel.sideMenu:ClearAllPoints()
	panel.sideMenu:SetPoint("TOPLEFT", panel.header, "BOTTOMLEFT", 0, 0)
	panel.sideMenu:SetPoint("BOTTOMLEFT", panel.statusBar, "TOPLEFT", 0, 0)
	panel.sideMenu:SetWidth(addon.Utilities:ToUI(addon.Utilities:ToPixels(154)))
	addon.Options.Sections.SideMenu:UpdateLayout()

	panel.content:ClearAllPoints()
	panel.content:SetPoint("TOPLEFT", panel.sideMenu, "TOPRIGHT", 0, 0)
	panel.content:SetPoint("TOPRIGHT", panel.header, "BOTTOMRIGHT", 0, 0)
	panel.content:SetPoint("BOTTOMRIGHT", panel.statusBar, "TOPRIGHT", 0, 0)
	addon.Options.Sections.Content:UpdateLayout()
end

function Options:Ensure()
	if panel then
		return
	end

	panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	panel:Hide()

	panel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	panel:SetBackdropColor(
		theme.colors.panelBackground[1],
		theme.colors.panelBackground[2],
		theme.colors.panelBackground[3],
		theme.colors.panelBackground[4]
	)

	panel:ClearAllPoints()
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	panel:SetFrameStrata("DIALOG")

	local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(1))

	panel.topBorder = panel:CreateTexture(nil, "OVERLAY")
	panel.topBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	panel.topBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
	panel.topBorder:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
	panel.topBorder:SetHeight(borderThickness)

	panel.bottomBorder = panel:CreateTexture(nil, "OVERLAY")
	panel.bottomBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	panel.bottomBorder:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
	panel.bottomBorder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
	panel.bottomBorder:SetHeight(borderThickness)

	panel.leftBorder = panel:CreateTexture(nil, "OVERLAY")
	panel.leftBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	panel.leftBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
	panel.leftBorder:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
	panel.leftBorder:SetWidth(borderThickness)

	panel.rightBorder = panel:CreateTexture(nil, "OVERLAY")
	panel.rightBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)
	panel.rightBorder:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
	panel.rightBorder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
	panel.rightBorder:SetWidth(borderThickness)

	panel:SetMovable(true)
	panel:EnableMouse(true)
	panel:RegisterForDrag("LeftButton")

	panel:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)

	panel:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		Options:Snap()
	end)

	panel.header = addon.Options.Sections.Header:Ensure(panel)
	panel.statusBar = addon.Options.Sections.StatusBar:Ensure(panel)

	panel.sideMenu = addon.Options.Sections.SideMenu:Ensure(panel)
	panel.content = addon.Options.Sections.Content:Ensure(panel)

	self:UpdateLayout()
	self:SetActivePage(addon.Options.Sections.Content:GetActivePage())
end

function Options:Open()
	if InCombatLockdown() then
		deferredOpen = true
		print("|cffff9900Mich's RaidFrames:|r Options will open after combat.")
		return
	end

	deferredOpen = false
	Options:Ensure()
	addon.Options.Data:RefreshProfile()
	panel:Show()
end

function Options:Close()
	if not panel then
		return
	end

	panel:Hide()
end

function Options:IsOpen()
	return panel and panel:IsShown() or false
end

function Options:ShouldOpenAfterCombat()
	return deferredOpen
end

function Options:Snap()
	if not panel then
		return
	end

	local point = select(1, panel:GetPoint(1))
	if point == "CENTER" then
		return
	end

	panel:StopMovingOrSizing()

	local leftPx = addon.Utilities:ToPixels(panel:GetLeft())
	local bottomPx = addon.Utilities:ToPixels(panel:GetBottom())
	local widthPx = addon.Utilities:ToPixels(panel:GetWidth())
	local heightPx = addon.Utilities:ToPixels(panel:GetHeight())

	panel:ClearAllPoints()
	panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", addon.Utilities:ToUI(leftPx), addon.Utilities:ToUI(bottomPx))
	panel:SetPoint(
		"TOPRIGHT",
		UIParent,
		"BOTTOMLEFT",
		addon.Utilities:ToUI(leftPx + widthPx),
		addon.Utilities:ToUI(bottomPx + heightPx)
	)
end

function Options:Initialize()
	SLASH_MICHRAIDFRAMES1 = "/mrfnew"

	SlashCmdList["MICHRAIDFRAMES"] = function(msg)
		if Options:IsOpen() then
			Options:Close()
			return
		end

		Options:Open()
	end
end
