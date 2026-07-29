local addonName, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
local OptionsNew = addon.OptionsNew
local L = addon.L

local panel
local deferredOpen = false
local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""

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

	panel.frame:HookScript("OnHide", function()
		addon.FrameRegistry:DisableTestMode()
		RefreshTestModeButtons()
	end)

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

	OptionsNew.Pages.Frames:Create(panel, {
		headerButtonText = GetTestModeButtonText(),
		headerButtonCallback = ToggleTestMode,
	})

	OptionsNew.Pages.Bars:Create(panel)

	OptionsNew.Pages.Texts:Create(panel)

	OptionsNew.Pages.Auras:Create(panel)

	OptionsNew.Pages.Indicators:Create(panel)

	OptionsNew.Pages.Profiles:Create(panel)
	OptionsNew.Preview:Create(panel)
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
	if InCombatLockdown() then
		deferredOpen = true
		print("|cffff9900Mich's RaidFrames:|r " .. L["Options will open after combat."])
		return
	end

	deferredOpen = false

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

function OptionsNew:ShouldOpenAfterCombat()
	return deferredOpen
end

function OptionsNew:UpdateLocale()
	if not panel then
		return
	end

	panel:UpdateLocale()
	OptionsNew.Preview:UpdateLocale()
	RefreshTestModeButtons()
end
