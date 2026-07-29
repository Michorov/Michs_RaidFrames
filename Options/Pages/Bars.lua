local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}

local Bars = addon.Options.Pages.Bars

function Bars:Create(panel)
	local page = panel:RegisterPage("bars", {
		titleKey = "Bars",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})

	self.Health:Create(page)
	self.Power:Create(page)
	self.HealAbsorbs:Create(page)
	self.Absorbs:Create(page)

	return page
end
