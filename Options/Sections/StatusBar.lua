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
	buttonWidth = 116,
	buttonHeight = 22,
}

local function GetDisplayProfileName(name)
	if name == "Default" then
		return L["Default"]
	end

	return name
end

local function GetControllerState()
	local content = addon.Options.Sections.Content
	if content and content.GetControllerState then
		return content:GetControllerState()
	end

	return addon.Options.ControllerState or { mode = "party" }
end

local function GetModeKey()
	local state = GetControllerState()
	return state.mode == "raid" and "raid" or "party"
end

local function GetUnlockButtonText()
	if addon.FrameRegistry and addon.FrameRegistry.GetActiveTestMode and addon.FrameRegistry:GetActiveTestMode() then
		return L["Lock"]
	end

	return L["Unlock"]
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

	statusBar.unlockButton = addon.Options.Controls.Button:Create(statusBar, GetUnlockButtonText())
	statusBar.unlockButton:SetLayoutSize(layoutValues.buttonWidth, layoutValues.buttonHeight)
	statusBar.unlockButton:SetOnClick(function()
		addon.FrameRegistry:ToggleTestMode(GetModeKey())
		StatusBar:UpdateState()
	end)

	statusBar.controls.unlockButton = statusBar.unlockButton

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

	statusBar.unlockButton:SetText(GetUnlockButtonText())
	self:UpdateState()
end

function StatusBar:UpdateLayout()
	if not statusBar then
		return
	end

	local controls = statusBar.controls
	local horizontalInsetPx = addon.Utilities:ToPixels(layoutValues.horizontalInset)
	local textLeftInsetPx = addon.Utilities:ToPixels(layoutValues.textLeftInset)
	local textRightGapPx = addon.Utilities:ToPixels(layoutValues.textRightGap)

	for _, control in pairs(controls) do
		if control.UpdateLayout then
			control:UpdateLayout()
		end
	end

	statusBar.unlockButton:ClearAllPoints()
	statusBar.unlockButton:SetPoint(
		"RIGHT",
		statusBar,
		"RIGHT",
		-addon.Utilities:ToUI(horizontalInsetPx),
		0
	)

	statusBar.text:ClearAllPoints()
	statusBar.text:SetPoint("LEFT", statusBar, "LEFT", addon.Utilities:ToUI(textLeftInsetPx), 0)
	statusBar.text:SetPoint(
		"RIGHT",
		statusBar.unlockButton,
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

	statusBar.unlockButton:SetText(GetUnlockButtonText())
	statusBar.text:SetText((L["Version %s | Active Profile: |cff00ff00%s|r"]):format(addonVersion, profileName))
end
