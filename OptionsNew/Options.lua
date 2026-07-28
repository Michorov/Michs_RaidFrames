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
		title = "Mich's Raid Frames",
		previewEnabled = true,
		modes = { "party", "raid" },
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
		title = L["Frames"],
		showHeader = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
		showHeaderButton = true,
		headerButtonText = GetTestModeButtonText(),
		headerButtonCallback = ToggleTestMode,
	})
	framesPage:RegisterSubPage("frames", { title = L["Frames"] })

	local barsPage = panel:RegisterPage("bars", {
		title = L["Bars"],
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})
	barsPage:RegisterSubPage("health", { title = L["Health"] })
	barsPage:RegisterSubPage("power", { title = L["Power"] })
	barsPage:RegisterSubPage("healAbsorbs", { title = L["Heal Absorbs"] })
	barsPage:RegisterSubPage("absorbs", { title = L["Absorbs"] })

	local textsPage = panel:RegisterPage("texts", {
		title = L["Texts"],
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})
	textsPage:RegisterSubPage("name", { title = L["Name"] })
	textsPage:RegisterSubPage("away", { title = L["Away"] })
	textsPage:RegisterSubPage("healAbsorbs", { title = L["Heal Absorbs"] })

	local aurasPage = panel:RegisterPage("auras", {
		title = L["Auras"],
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})
	aurasPage:RegisterSubPage("buffs", { title = L["Buffs"] })
	aurasPage:RegisterSubPage("buffFilters", { title = L["Buffs - Filters"] })
	aurasPage:RegisterSubPage("buffOverlay", { title = L["Buffs - Overlay"] })
	aurasPage:RegisterSubPage("buffCustomIcons", { title = L["Buffs - Custom Icons"] })
	aurasPage:RegisterSubPage("debuffs", { title = L["Debuffs"] })
	aurasPage:RegisterSubPage("dispels", { title = L["Dispels"] })
	aurasPage:RegisterSubPage("bigDefensive", { title = L["Big Defensive"] })
	if not isRestrictedAuraAPI then
		aurasPage:RegisterSubPage("privateAuras", { title = L["Private Auras"] })
	end
	aurasPage:RegisterSubPage("raidBuffReminder", { title = L["Raid Buff Reminder"] })

	local indicatorsPage = panel:RegisterPage("indicators", {
		title = L["Indicators"],
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})
	indicatorsPage:RegisterSubPage("readyCheck", { title = L["Ready Check"] })
	indicatorsPage:RegisterSubPage("pendingSummon", { title = L["Summon"] })
	indicatorsPage:RegisterSubPage("raidMarker", { title = L["Raid Marker"] })
	indicatorsPage:RegisterSubPage("roleIcon", { title = L["Role Indicator"] })
	indicatorsPage:RegisterSubPage("groupStatus", { title = L["Group Leader"] })
	indicatorsPage:RegisterSubPage("threat", { title = L["Threat"] })

	OptionsNew.Pages.Profiles:Create(panel)
	panel:SetDefaultPage("general")

	addon.Options.Data:RegisterForUpdates(OptionsNew, function()
		panel:UpdateState()
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
