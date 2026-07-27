local addonName, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
local OptionsNew = addon.OptionsNew
local L = addon.L

local panel
local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or ""
local profileSubscribers = {}

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
	})

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
