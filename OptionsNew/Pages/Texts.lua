local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Texts = addon.OptionsNew.Pages.Texts or {}

local Texts = addon.OptionsNew.Pages.Texts

function Texts:Create(panel)
	local page = panel:RegisterPage("texts", {
		titleKey = "Texts",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})

	self.Name:Create(page)
	self.Away:Create(page)
	self.HealAbsorbs:Create(page)

	return page
end
