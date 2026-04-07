local addonName, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.StatusBar = addon.Options.Sections.StatusBar or {}

local StatusBar = addon.Options.Sections.StatusBar

local statusBar
local theme = addon.Options.Theme

local function GetAddonVersion()
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		return C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"
	end

	return GetAddOnMetadata(addonName, "Version") or "dev"
end

function StatusBar:Ensure(parent)
	if statusBar then
		return statusBar
	end

	statusBar = CreateFrame("Frame", nil, parent)

	statusBar.text = statusBar:CreateFontString(nil, "OVERLAY")
	statusBar.text:SetJustifyH("LEFT")
	statusBar.text:SetFont(theme.fonts.arialNarrow, 12, "")
	statusBar.text:SetTextColor(0.65, 0.65, 0.68, 1)

	statusBar.topBorder = statusBar:CreateTexture(nil, "OVERLAY")
	statusBar.topBorder:SetColorTexture(
		theme.colors.border[1],
		theme.colors.border[2],
		theme.colors.border[3],
		theme.colors.border[4]
	)

	addon.Options.Data:RegisterForUpdates(StatusBar, function()
		StatusBar:UpdateState()
	end)

	self:UpdateLayout()
	self:UpdateState()

	return statusBar
end

function StatusBar:UpdateLayout()
	if not statusBar then
		return
	end

	statusBar.text:ClearAllPoints()
	statusBar.text:SetPoint("LEFT", statusBar, "LEFT", addon.Utilities:ToUI(addon.Utilities:ToPixels(10)), 0)

	statusBar.topBorder:ClearAllPoints()
	statusBar.topBorder:SetPoint("TOPLEFT", statusBar, "TOPLEFT", addon.Utilities:ToUI(addon.Utilities:ToPixels(8)), 0)
	statusBar.topBorder:SetPoint(
		"TOPRIGHT",
		statusBar,
		"TOPRIGHT",
		addon.Utilities:ToUI(addon.Utilities:ToPixels(-8)),
		0
	)
	statusBar.topBorder:SetHeight(addon.Utilities:ToUI(addon.Utilities:ToPixels(1)))
end

function StatusBar:UpdateState()
	if not statusBar then
		return
	end

	local version = GetAddonVersion()
	local profileName = addon.Database:GetCurrentProfileName() or "Default"

	statusBar.text:SetText(("Version %s | Active Profile: |cff00ff00%s|r"):format(version, profileName))
end
