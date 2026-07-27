local addonName, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
local OptionsNew = addon.OptionsNew
local L = addon.L

local panel
local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
local profileSubscribers = {}
local _, _, _, interfaceVersion = GetBuildInfo()
local isRestrictedAuraAPI = (tonumber(interfaceVersion) or 0) >= 120100

local function GetDisplayProfileName(name)
	if name == "Default" then
		return L["Default"]
	end

	return name
end

function OptionsNew:UpdateFooter()
	if not panel then
		return
	end

	local profileName = GetDisplayProfileName(addon.Database:GetCurrentProfileName() or "Default")
	panel:SetFooterText((L["Version %s | Active Profile: |cff00ff00%s|r"]):format(addonVersion, profileName))
end

function OptionsNew:Initialize()
	if panel then
		return
	end

	panel = addon.OptionsUI:CreatePanel({
		name = "MichsRaidFramesOptionsNew",
		title = "Mich's Raid Frames",
		previewEnabled = true,
	})

	OptionsNew.Pages.General:Create(panel)

	local layoutPage = panel:RegisterPage("layout", { title = L["Layout"], type = "subpages", showHeader = true })
	layoutPage:RegisterSubPage("layout", { title = L["Layout"], type = "form" })

	local framesPage = panel:RegisterPage("frames", { title = L["Frames"], type = "subpages", showHeader = true })
	framesPage:RegisterSubPage("frames", { title = L["Frames"], type = "form" })

	local barsPage = panel:RegisterPage("bars", { title = L["Bars"], type = "subpages", showHeader = true })
	barsPage:RegisterSubPage("health", { title = L["Health"], type = "form" })
	barsPage:RegisterSubPage("power", { title = L["Power"], type = "form" })
	barsPage:RegisterSubPage("healAbsorbs", { title = L["Heal Absorbs"], type = "form" })
	barsPage:RegisterSubPage("absorbs", { title = L["Absorbs"], type = "form" })

	local textsPage = panel:RegisterPage("texts", { title = L["Texts"], type = "subpages", showHeader = true })
	textsPage:RegisterSubPage("name", { title = L["Name"], type = "form" })
	textsPage:RegisterSubPage("away", { title = L["Away"], type = "form" })
	textsPage:RegisterSubPage("healAbsorbs", { title = L["Heal Absorbs"], type = "form" })

	local aurasPage = panel:RegisterPage("auras", { title = L["Auras"], type = "subpages", showHeader = true })
	aurasPage:RegisterSubPage("buffs", { title = L["Buffs"], type = "form" })
	aurasPage:RegisterSubPage("buffFilters", { title = L["Buffs - Filters"], type = "form" })
	aurasPage:RegisterSubPage("buffOverlay", { title = L["Buffs - Overlay"], type = "form" })
	aurasPage:RegisterSubPage("buffCustomIcons", { title = L["Buffs - Custom Icons"], type = "form" })
	aurasPage:RegisterSubPage("debuffs", { title = L["Debuffs"], type = "form" })
	aurasPage:RegisterSubPage("dispels", { title = L["Dispels"], type = "form" })
	aurasPage:RegisterSubPage("bigDefensive", { title = L["Big Defensive"], type = "form" })
	if not isRestrictedAuraAPI then
		aurasPage:RegisterSubPage("privateAuras", { title = L["Private Auras"], type = "form" })
	end
	aurasPage:RegisterSubPage("raidBuffReminder", { title = L["Raid Buff Reminder"], type = "form" })

	local indicatorsPage =
	panel:RegisterPage("indicators", { title = L["Indicators"], type = "subpages", showHeader = true })
	indicatorsPage:RegisterSubPage("readyCheck", { title = L["Ready Check"], type = "form" })
	indicatorsPage:RegisterSubPage("pendingSummon", { title = L["Summon"], type = "form" })
	indicatorsPage:RegisterSubPage("raidMarker", { title = L["Raid Marker"], type = "form" })
	indicatorsPage:RegisterSubPage("roleIcon", { title = L["Role Indicator"], type = "form" })
	indicatorsPage:RegisterSubPage("groupStatus", { title = L["Group Leader"], type = "form" })
	indicatorsPage:RegisterSubPage("threat", { title = L["Threat"], type = "form" })

	panel:RegisterPage("profiles", {
		title = L["Profiles"],
		type = "canvas",
		sidebarPlacement = "bottom",
	})
	panel:SetDefaultPage("general")

	self:RegisterForProfileUpdates("footer", function()
		OptionsNew:UpdateFooter()
	end)
	self:RefreshProfile()

	addon.Options.Data:RegisterForUpdates(OptionsNew, function()
		OptionsNew:RefreshProfile()
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
end

function OptionsNew:Close()
	if panel then
		panel:Hide()
	end
end

function OptionsNew:IsOpen()
	return panel and panel:IsShown()
end

function OptionsNew:RegisterForProfileUpdates(key, callback)
	profileSubscribers[key] = callback
end

function OptionsNew:RefreshProfile()
	local profile = addon.Database:GetProfile()

	for _, callback in pairs(profileSubscribers) do
		callback(profile)
	end
end
