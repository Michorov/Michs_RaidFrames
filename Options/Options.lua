local _, addon = ...

addon.Options = addon.Options or {}
local Options = addon.Options
local L = addon.L
local theme = addon.Options.Theme

local panel
local deferredOpen = false
local panelPosition = {
	xRatio = 0.5,
	yRatio = 0.5,
}

local layoutValues = {
	panelWidth = 800,
	panelHeight = 500,
	headerHeight = 40,
	statusBarHeight = 32,
	sideMenuWidth = 154,
}

local function SavePanelPosition()
	if not panel then
		return
	end

	local parentWidthPx = addon.Utilities:ToPixels(UIParent:GetWidth())
	local parentHeightPx = addon.Utilities:ToPixels(UIParent:GetHeight())
	local panelWidthPx = addon.Utilities:ToPixels(panel:GetWidth())
	local panelHeightPx = addon.Utilities:ToPixels(panel:GetHeight())

	local availableWidthPx = math.max(0, parentWidthPx - panelWidthPx)
	local availableHeightPx = math.max(0, parentHeightPx - panelHeightPx)

	local leftPx = addon.Utilities:ToPixels(panel:GetLeft())
	local bottomPx = addon.Utilities:ToPixels(panel:GetBottom())

	if availableWidthPx > 0 then
		panelPosition.xRatio = math.max(0, math.min(1, leftPx / availableWidthPx))
	else
		panelPosition.xRatio = 0.5
	end

	if availableHeightPx > 0 then
		panelPosition.yRatio = math.max(0, math.min(1, bottomPx / availableHeightPx))
	else
		panelPosition.yRatio = 0.5
	end
end

function Options:Initialize()
	SLASH_MICHRAIDFRAMES1 = "/mrf"

	addon.Locale:RegisterForUpdates("options", function()
		Options:UpdateLocale()
	end)

	SlashCmdList["MICHRAIDFRAMES"] = function(msg)
		local normalizedMessage = (msg or ""):match("^%s*(.-)%s*$")

		if normalizedMessage ~= "" then
			print("|cffff9900Mich's RaidFrames:|r " .. L["Unknown command. Use /mrf"])
			return
		end

		if Options:IsOpen() then
			Options:Close()
			return
		end

		Options:Open()
	end
end

function Options:Ensure()
	if panel then
		return
	end

	panel = CreateFrame("Frame", "MichsRaidFramesOptionsPanel", UIParent, "BackdropTemplate")
	panel:Hide()

	panel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	panel:SetBackdropColor(theme:GetColor("panelBackground"))

	panel:ClearAllPoints()
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	panel:SetFrameStrata("DIALOG")

	panel.topBorder = panel:CreateTexture(nil, "OVERLAY")
	panel.topBorder:SetColorTexture(theme:GetColor("border"))
	panel.topBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
	panel.topBorder:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)

	panel.bottomBorder = panel:CreateTexture(nil, "OVERLAY")
	panel.bottomBorder:SetColorTexture(theme:GetColor("border"))
	panel.bottomBorder:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
	panel.bottomBorder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)

	panel.leftBorder = panel:CreateTexture(nil, "OVERLAY")
	panel.leftBorder:SetColorTexture(theme:GetColor("border"))
	panel.leftBorder:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
	panel.leftBorder:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)

	panel.rightBorder = panel:CreateTexture(nil, "OVERLAY")
	panel.rightBorder:SetColorTexture(theme:GetColor("border"))
	panel.rightBorder:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
	panel.rightBorder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)

	if panel:GetName() and not tContains(UISpecialFrames, panel:GetName()) then
		table.insert(UISpecialFrames, panel:GetName())
	end

	panel:SetMovable(true)
	panel:EnableMouse(true)
	panel:RegisterForDrag("LeftButton")

	panel:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)

	panel:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePanelPosition()
		Options:Snap()
	end)

	panel:HookScript("OnHide", function()
		addon.FrameRegistry:DisableTestMode()
	end)

	panel.header = addon.Options.Sections.Header:Ensure(panel)
	panel.header:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
	panel.header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)

	panel.statusBar = addon.Options.Sections.StatusBar:Ensure(panel)
	panel.statusBar:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
	panel.statusBar:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)

	panel.sideMenu = addon.Options.Sections.SideMenu:Ensure(panel)
	panel.sideMenu:SetPoint("TOPLEFT", panel.header, "BOTTOMLEFT", 0, 0)
	panel.sideMenu:SetPoint("BOTTOMLEFT", panel.statusBar, "TOPLEFT", 0, 0)

	panel.content = addon.Options.Sections.Content:Ensure(panel)
	panel.content:SetPoint("TOPLEFT", panel.sideMenu, "TOPRIGHT", 0, 0)
	panel.content:SetPoint("TOPRIGHT", panel.header, "BOTTOMRIGHT", 0, 0)
	panel.content:SetPoint("BOTTOMRIGHT", panel.statusBar, "TOPRIGHT", 0, 0)

	self:UpdateLayout()
	self:UpdateLocale()
	self:SetActivePage(addon.Options.Sections.Content:GetActivePage())
end

function Options:UpdateLayout()
	if not panel then
		return
	end

	local panelWidth = addon.Utilities:ScaleEven(addon.Utilities:ToPixels(layoutValues.panelWidth))
	local panelHeight = addon.Utilities:ScaleEven(addon.Utilities:ToPixels(layoutValues.panelHeight))
	panel:SetSize(addon.Utilities:ToUI(panelWidth), addon.Utilities:ToUI(panelHeight))

	local borderThicknessPx = addon.Utilities:ToPixels(1)
	panel.topBorder:SetHeight(addon.Utilities:ToUI(borderThicknessPx))
	panel.bottomBorder:SetHeight(addon.Utilities:ToUI(borderThicknessPx))
	panel.leftBorder:SetWidth(addon.Utilities:ToUI(borderThicknessPx))
	panel.rightBorder:SetWidth(addon.Utilities:ToUI(borderThicknessPx))

	self:Snap()

	panel.header:SetHeight(addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.headerHeight)))
	addon.Options.Sections.Header:UpdateLayout()

	panel.statusBar:SetHeight(addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.statusBarHeight)))
	addon.Options.Sections.StatusBar:UpdateLayout()

	panel.sideMenu:SetWidth(addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.sideMenuWidth)))
	addon.Options.Sections.SideMenu:UpdateLayout()

	addon.Options.Sections.Content:UpdateLayout()
end

function Options:Snap()
	if not panel then
		return
	end

	local parentWidthPx = addon.Utilities:ToPixels(UIParent:GetWidth())
	local parentHeightPx = addon.Utilities:ToPixels(UIParent:GetHeight())
	local panelWidthPx = addon.Utilities:ToPixels(panel:GetWidth())
	local panelHeightPx = addon.Utilities:ToPixels(panel:GetHeight())

	local availableWidthPx = math.max(0, parentWidthPx - panelWidthPx)
	local availableHeightPx = math.max(0, parentHeightPx - panelHeightPx)

	local leftPx = addon.Utilities:RoundToNearestInt(panelPosition.xRatio * availableWidthPx)
	local bottomPx = addon.Utilities:RoundToNearestInt(panelPosition.yRatio * availableHeightPx)

	panel:ClearAllPoints()
	panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", addon.Utilities:ToUI(leftPx), addon.Utilities:ToUI(bottomPx))
end

function Options:IsOpen()
	return panel and panel:IsShown() or false
end

function Options:ShouldOpenAfterCombat()
	return deferredOpen
end

function Options:Open()
	if InCombatLockdown() then
		deferredOpen = true
		print("|cffff9900Mich's RaidFrames:|r " .. L["Options will open after combat."])
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

function Options:UpdateLocale()
	if not panel then
		return
	end

	addon.Options.Controls.Dropdown:CloseOpenDropdown()
	addon.Options.Theme:RefreshFonts()

	addon.Options.Sections.Header:UpdateLocale()
	addon.Options.Sections.StatusBar:UpdateLocale()
	addon.Options.Sections.SideMenu:UpdateLocale()
	addon.Options.Sections.Content:UpdateLocale()
	addon.Options.Data:RefreshProfile()
end

function Options:SetActivePage(pageKey)
	addon.Options.Sections.Content:SetActivePage(pageKey)
	addon.Options.Sections.SideMenu:SetActivePage(pageKey)
end
