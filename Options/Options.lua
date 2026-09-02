local addonName, addon = ...

addon.Options = addon.Options or {}
local Options = addon.Options
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

function Options:Initialize()
	SLASH_MICHRAIDFRAMES1 = "/mrf"
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

	panel = addon.OptionsUI:CreatePanel({
		name = "MichsRaidFramesOptions",
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

	panel:RegisterStateUpdater(Options, function(_, mode)
		SyncTestMode(mode)
		RefreshTestModeButtons()
	end)

	Options.Pages.General:Create(panel)

	Options.Pages.Layout:Create(panel, {
		headerButtonText = GetTestModeButtonText(),
		headerButtonCallback = ToggleTestMode,
	})

	Options.Pages.Frames:Create(panel, {
		headerButtonText = GetTestModeButtonText(),
		headerButtonCallback = ToggleTestMode,
	})

	Options.Pages.Bars:Create(panel)

	Options.Pages.Texts:Create(panel)

	Options.Pages.Auras:Create(panel)

	Options.Pages.Indicators:Create(panel)

	Options.Pages.ClickCasting:Create(panel)

	Options.Pages.Profiles:Create(panel)
	Options.Preview:Create(panel)
	panel:SetDefaultPage("general")

	addon.Locale:RegisterForUpdates("options", function()
		Options:UpdateLocale()
	end)
end

function Options:Open()
	if InCombatLockdown() then
		deferredOpen = true
		print("|cffff9900Mich's RaidFrames:|r " .. L["Options will open after combat."])
		return
	end

	deferredOpen = false

	if not panel then
		self:Ensure()
	end

	panel:Show()
	RefreshTestModeButtons()
end

function Options:Close()
	if panel then
		panel:Hide()
	end
end

function Options:IsOpen()
	return panel and panel:IsShown()
end

function Options:RefreshState()
	if panel then
		panel:UpdateState()
	end
end

function Options:UpdateLayout()
	if panel then
		panel:UpdateLayout()
	end
end

function Options:ShouldOpenAfterCombat()
	return deferredOpen
end

function Options:UpdateLocale()
	if not panel then
		return
	end

	panel:UpdateLocale()
	Options.Preview:UpdateLocale()
	RefreshTestModeButtons()
end
