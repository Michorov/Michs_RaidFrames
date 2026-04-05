local _, addon = ...

addon.Options = addon.Options or {}
local Options = addon.Options

local panel
local deferredOpen = false

local function CreateBorder(frame, frameWidth, frameHeight)
	local borderColor = 0.2
	local borderThickness = addon.Utilities:ToUI(addon.Utilities:ToPixels(1))

	local top = frame:CreateTexture(nil, "OVERLAY")
	top:SetColorTexture(borderColor, borderColor, borderColor, 1)
	top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	top:SetSize(addon.Utilities:ToUI(frameWidth), borderThickness)

	local bottom = frame:CreateTexture(nil, "OVERLAY")
	bottom:SetColorTexture(borderColor, borderColor, borderColor, 1)
	bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	bottom:SetSize(addon.Utilities:ToUI(frameWidth), borderThickness)

	local left = frame:CreateTexture(nil, "OVERLAY")
	left:SetColorTexture(borderColor, borderColor, borderColor, 1)
	left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	left:SetSize(borderThickness, addon.Utilities:ToUI(frameHeight))

	local right = frame:CreateTexture(nil, "OVERLAY")
	right:SetColorTexture(borderColor, borderColor, borderColor, 1)
	right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	right:SetSize(borderThickness, addon.Utilities:ToUI(frameHeight))
end

function Options:EnsurePanel()
	if panel then
		return
	end

	panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	panel:Hide()

	local frameWidth = addon.Utilities:ScaleEven(addon.Utilities:ToPixels(900))
	local frameHeight = addon.Utilities:ScaleEven(addon.Utilities:ToPixels(600))
	panel:SetSize(addon.Utilities:ToUI(frameWidth), addon.Utilities:ToUI(frameHeight))

	panel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
	})
	panel:SetBackdropColor(0.08, 0.08, 0.1, 0.95)

	panel:ClearAllPoints()
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	panel:SetFrameStrata("DIALOG")

	CreateBorder(panel, frameWidth, frameHeight)

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
end

function Options:Open()
	if InCombatLockdown() then
		deferredOpen = true
		print("|cffff9900Mich's RaidFrames:|r Options will open after combat.")
	end

	deferredOpen = false
	Options:EnsurePanel()
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
