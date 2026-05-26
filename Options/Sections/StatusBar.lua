local addonName, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.StatusBar = addon.Options.Sections.StatusBar or {}

local StatusBar = addon.Options.Sections.StatusBar

local statusBar
local L = addon.L
local theme = addon.Options.Theme
local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
local layoutValues = {
	textLeftInset = 10,
	textRightGap = 10,
	horizontalInset = 8,
	buttonWidth = 150,
	buttonHeight = 22,
	buttonSpacing = 2,
}

local function GetDisplayProfileName(name)
	if name == "Default" then
		return L["Default"]
	end

	return name
end

function StatusBar:Ensure(parent)
	if statusBar then
		return statusBar
	end

	statusBar = CreateFrame("Frame", nil, parent)
	statusBar.controls = {}

	statusBar.text = statusBar:CreateFontString(nil, "OVERLAY")
	statusBar.text:SetJustifyH("LEFT")
	theme:ApplyFont(statusBar.text, "arialNarrow", 12, "")
	statusBar.text:SetTextColor(0.65, 0.65, 0.68, 1)

	statusBar.topBorder = statusBar:CreateTexture(nil, "OVERLAY")
	statusBar.topBorder:SetColorTexture(theme:GetColor("border"))

	statusBar.partyTestButton = addon.Options.Controls.Button:Create(statusBar, L["Unlock Party"])
	statusBar.partyTestButton:SetLayoutSize(layoutValues.buttonWidth, layoutValues.buttonHeight)
	statusBar.partyTestButton:SetOnClick(function()
		addon.FrameRegistry:ToggleTestMode("party")
	end)

	statusBar.raidTestButton = addon.Options.Controls.Button:Create(statusBar, L["Unlock Raid"])
	statusBar.raidTestButton:SetLayoutSize(layoutValues.buttonWidth, layoutValues.buttonHeight)
	statusBar.raidTestButton:SetOnClick(function()
		addon.FrameRegistry:ToggleTestMode("raid")
	end)

	statusBar.controls.partyTestButton = statusBar.partyTestButton
	statusBar.controls.raidTestButton = statusBar.raidTestButton

	addon.Options.Data:RegisterForUpdates(StatusBar, function()
		StatusBar:UpdateState()
	end)

	self:UpdateLocale()
	self:UpdateLayout()
	self:UpdateState()

	return statusBar
end

function StatusBar:UpdateLocale()
	if not statusBar then
		return
	end

	statusBar.partyTestButton:SetText(L["Unlock Party"])
	statusBar.raidTestButton:SetText(L["Unlock Raid"])
	self:UpdateState()
end

function StatusBar:UpdateLayout()
	if not statusBar then
		return
	end

	local controls = statusBar.controls
	local horizontalInsetPx = addon.Utilities:ToPixels(layoutValues.horizontalInset)
	local buttonSpacingPx = addon.Utilities:ToPixels(layoutValues.buttonSpacing)
	local textLeftInsetPx = addon.Utilities:ToPixels(layoutValues.textLeftInset)
	local textRightGapPx = addon.Utilities:ToPixels(layoutValues.textRightGap)

	for _, control in pairs(controls) do
		if control.UpdateLayout then
			control:UpdateLayout()
		end
	end

	statusBar.raidTestButton:ClearAllPoints()
	statusBar.raidTestButton:SetPoint(
		"RIGHT",
		statusBar,
		"RIGHT",
		-addon.Utilities:ToUI(horizontalInsetPx),
		0
	)

	statusBar.partyTestButton:ClearAllPoints()
	statusBar.partyTestButton:SetPoint(
		"RIGHT",
		statusBar.raidTestButton,
		"LEFT",
		-addon.Utilities:ToUI(buttonSpacingPx),
		0
	)

	statusBar.text:ClearAllPoints()
	statusBar.text:SetPoint("LEFT", statusBar, "LEFT", addon.Utilities:ToUI(textLeftInsetPx), 0)
	statusBar.text:SetPoint(
		"RIGHT",
		statusBar.partyTestButton,
		"LEFT",
		-addon.Utilities:ToUI(textRightGapPx),
		0
	)

	statusBar.topBorder:ClearAllPoints()
	statusBar.topBorder:SetPoint("TOPLEFT", statusBar, "TOPLEFT", addon.Utilities:ToUI(horizontalInsetPx), 0)
	statusBar.topBorder:SetPoint(
		"TOPRIGHT",
		statusBar,
		"TOPRIGHT",
		-addon.Utilities:ToUI(horizontalInsetPx),
		0
	)
	statusBar.topBorder:SetHeight(addon.Utilities:ToUI(addon.Utilities:ToPixels(1)))
end

function StatusBar:UpdateState()
	if not statusBar then
		return
	end

	local profileName = GetDisplayProfileName(addon.Database:GetCurrentProfileName() or "Default")

	statusBar.text:SetText((L["Version %s | Active Profile: |cff00ff00%s|r"]):format(addonVersion, profileName))
end
