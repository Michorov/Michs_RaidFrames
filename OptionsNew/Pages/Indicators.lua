local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Indicators = addon.OptionsNew.Pages.Indicators or {}

local Indicators = addon.OptionsNew.Pages.Indicators

function Indicators:Create(panel)
	local page = panel:RegisterPage("indicators", {
		titleKey = "Indicators",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})

	self.ReadyCheck:Create(page)
	self.PendingSummon:Create(page)
	self.RaidMarker:Create(page)
	self.RoleIndicator:Create(page)
	self.GroupStatus:Create(page)
	self.Threat:Create(page)

	return page
end
