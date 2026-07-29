local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Auras = addon.OptionsNew.Pages.Auras or {}

local Auras = addon.OptionsNew.Pages.Auras
local _, _, _, interfaceVersion = GetBuildInfo()
local isRestrictedAuraAPI = (tonumber(interfaceVersion) or 0) >= 120100

function Auras:Create(panel)
	local page = panel:RegisterPage("auras", {
		titleKey = "Auras",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})

	self.Buffs:Create(page)
	self.BuffFilters:Create(page)
	self.BuffOverlay:Create(page)
	self.BuffCustomIcons:Create(page)
	self.Debuffs:Create(page)
	self.Dispels:Create(page)
	self.BigDefensive:Create(page)
	if not isRestrictedAuraAPI then
		self.PrivateAuras:Create(page)
	end
	self.RaidBuffReminder:Create(page)

	return page
end
