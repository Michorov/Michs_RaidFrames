local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}

local Auras = addon.Options.Pages.Auras

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
	self.RaidBuffReminder:Create(page)

	return page
end
