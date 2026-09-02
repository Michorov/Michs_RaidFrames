local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Texts = addon.Options.Pages.Texts or {}

local Texts = addon.Options.Pages.Texts

function Texts:Create(panel)
	local page = panel:RegisterPage("texts", {
		titleKey = "Texts",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})

	self.Name:Create(page)
	self.Power:Create(page)
	self.StatusText:Create(page)
	self.Away:Create(page)
	self.HealAbsorbs:Create(page)

	return page
end
