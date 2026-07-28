local addonName, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
local OptionsNew = addon.OptionsNew
local L = addon.L

local panel
local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
local _, _, _, interfaceVersion = GetBuildInfo()
local isRestrictedAuraAPI = (tonumber(interfaceVersion) or 0) >= 120100

local function GetDisplayProfileName(name)
	if name == "Default" then
		return L["Default"]
	end

	return name
end

local function GetTestModeButtonText()
	if addon.FrameRegistry:GetActiveTestMode() == panel:GetActiveMode() then
		return L["Lock"]
	end

	return L["Unlock"]
end

local function GetModeOptions()
	return {
		{ value = "party", textKey = "Party" },
		{ value = "raid", textKey = "Raid" },
	}
end

local function RefreshTestModeButtons()
	if not panel then
		return
	end

	local layoutPage = panel:GetPage("layout")
	if layoutPage then
		layoutPage:SetHeaderButtonText(GetTestModeButtonText())
	end

	local framesPage = panel:GetPage("frames")
	if framesPage then
		framesPage:SetHeaderButtonText(GetTestModeButtonText())
	end
end

local function SyncTestMode(mode)
	local activeTestMode = addon.FrameRegistry:GetActiveTestMode()
	if activeTestMode and activeTestMode ~= mode then
		addon.FrameRegistry:ToggleTestMode(mode)
	end
end

local function ToggleTestMode()
	addon.FrameRegistry:ToggleTestMode(panel:GetActiveMode())
	RefreshTestModeButtons()
	panel:UpdateState()
end

function OptionsNew:Initialize()
	if panel then
		return
	end

	panel = addon.OptionsUI:CreatePanel({
		name = "MichsRaidFramesOptionsNew",
		titleKey = "Mich's Raid Frames",
		localize = function(key)
			return L[key]
		end,
		localeGetter = function()
			return addon.Locale:GetCurrentLocale()
		end,
		previewEnabled = true,
		modes = { "party", "raid" },
		modeOptions = GetModeOptions(),
		activeMode = "party",
		profileGetter = function()
			return addon.Database:GetProfile()
		end,
	})

	panel:SetFooterUpdater(function()
		local profileName = GetDisplayProfileName(addon.Database:GetCurrentProfileName() or "Default")
		return (L["Version %s | Active Profile: |cff00ff00%s|r"]):format(addonVersion, profileName)
	end)

	panel:RegisterStateUpdater(OptionsNew, function(_, mode)
		SyncTestMode(mode)
		RefreshTestModeButtons()
	end)

	OptionsNew.Pages.General:Create(panel)

	OptionsNew.Pages.Layout:Create(panel, {
		headerButtonText = GetTestModeButtonText(),
		headerButtonCallback = ToggleTestMode,
	})

	local framesPage = panel:RegisterPage("frames", {
		titleKey = "Frames",
		showHeader = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
		showHeaderButton = true,
		headerButtonText = GetTestModeButtonText(),
		headerButtonCallback = ToggleTestMode,
	})
	framesPage:RegisterSubPage("frames", { titleKey = "Frames" })

	local barsPage = panel:RegisterPage("bars", {
		titleKey = "Bars",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})
	barsPage:RegisterSubPage("health", { titleKey = "Health" })
	barsPage:RegisterSubPage("power", { titleKey = "Power" })
	barsPage:RegisterSubPage("healAbsorbs", { titleKey = "Heal Absorbs" })
	barsPage:RegisterSubPage("absorbs", { titleKey = "Absorbs" })

	local textsPage = panel:RegisterPage("texts", {
		titleKey = "Texts",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})
	textsPage:RegisterSubPage("name", { titleKey = "Name" })
	textsPage:RegisterSubPage("away", { titleKey = "Away" })
	textsPage:RegisterSubPage("healAbsorbs", { titleKey = "Heal Absorbs" })

	local aurasPage = panel:RegisterPage("auras", {
		titleKey = "Auras",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})
	aurasPage:RegisterSubPage("buffs", { titleKey = "Buffs" })
	aurasPage:RegisterSubPage("buffFilters", { titleKey = "Buffs - Filters" })
	aurasPage:RegisterSubPage("buffOverlay", { titleKey = "Buffs - Overlay" })
	aurasPage:RegisterSubPage("buffCustomIcons", { titleKey = "Buffs - Custom Icons" })
	aurasPage:RegisterSubPage("debuffs", { titleKey = "Debuffs" })
	aurasPage:RegisterSubPage("dispels", { titleKey = "Dispels" })
	aurasPage:RegisterSubPage("bigDefensive", { titleKey = "Big Defensive" })
	if not isRestrictedAuraAPI then
		aurasPage:RegisterSubPage("privateAuras", { titleKey = "Private Auras" })
	end
	aurasPage:RegisterSubPage("raidBuffReminder", { titleKey = "Raid Buff Reminder" })

	local indicatorsPage = panel:RegisterPage("indicators", {
		titleKey = "Indicators",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})
	indicatorsPage:RegisterSubPage("readyCheck", { titleKey = "Ready Check" })
	indicatorsPage:RegisterSubPage("pendingSummon", { titleKey = "Summon" })
	indicatorsPage:RegisterSubPage("raidMarker", { titleKey = "Raid Marker" })
	indicatorsPage:RegisterSubPage("roleIcon", { titleKey = "Role Indicator" })
	indicatorsPage:RegisterSubPage("groupStatus", { titleKey = "Group Leader" })
	indicatorsPage:RegisterSubPage("threat", { titleKey = "Threat" })

	OptionsNew.Pages.Profiles:Create(panel)
	panel:SetDefaultPage("general")

	addon.Options.Data:RegisterForUpdates(OptionsNew, function()
		panel:UpdateState()
	end)

	addon.Locale:RegisterForUpdates("optionsNew", function()
		OptionsNew:UpdateLocale()
	end)

	SLASH_MICHRAIDFRAMESNEW1 = "/mrfnew"
	SlashCmdList["MICHRAIDFRAMESNEW"] = function()
		if OptionsNew:IsOpen() then
			OptionsNew:Close()
		else
			OptionsNew:Open()
		end
	end
end

function OptionsNew:Open()
	if not panel then
		self:Initialize()
	end

	panel:Show()
	RefreshTestModeButtons()
end

function OptionsNew:Close()
	if panel then
		panel:Hide()
	end
end

function OptionsNew:IsOpen()
	return panel and panel:IsShown()
end

function OptionsNew:UpdateLocale()
	if not panel then
		return
	end

	panel:UpdateLocale()
	RefreshTestModeButtons()
end
