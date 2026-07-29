local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Bars = addon.OptionsNew.Pages.Bars or {}

local Bars = addon.OptionsNew.Pages.Bars

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
