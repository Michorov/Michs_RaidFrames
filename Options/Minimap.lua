local addonName, addon = ...

addon.Options = addon.Options or {}
addon.Options.Minimap = addon.Options.Minimap or {}

local Minimap = addon.Options.Minimap
local initialized = false

local function ToggleOptions()
	if addon.Options:IsOpen() then
		addon.Options:Close()
		return
	end

	addon.Options:Open()
end

function Minimap:Initialize()
	if initialized then
		return
	end

	local ldb = LibStub("LibDataBroker-1.1", true)
	local icon = LibStub("LibDBIcon-1.0", true)
	if not ldb or not icon then
		return
	end

	local dataObject = ldb:NewDataObject(addonName, {
		type = "launcher",
		text = "Mich's RaidFrames",
		icon = "Interface\\AddOns\\Michs_RaidFrames\\Media\\LogoIcon.png",
		OnClick = function(_, button)
			if button == "LeftButton" then
				ToggleOptions()
			end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("Mich's RaidFrames")
			tooltip:AddLine(addon.L["Left-click to open options."])
		end,
	})

	local profile = addon.Database:GetProfile()
	profile.core.minimap = profile.core.minimap or {}
	icon:Register(addonName, dataObject, profile.core.minimap)

	initialized = true
end

function Minimap:Refresh()
	local icon = LibStub("LibDBIcon-1.0", true)
	if not initialized or not icon then
		return
	end

	local profile = addon.Database:GetProfile()
	profile.core.minimap = profile.core.minimap or {}
	icon:Refresh(addonName, profile.core.minimap)
end
