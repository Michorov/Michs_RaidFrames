local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}

local Indicators = addon.Options.Pages.Indicators

function Indicators:Create(panel)
	local page = panel:RegisterPage("indicators", {
		titleKey = "Indicators",
		showHeader = true,
		showSubpageDropdown = true,
		showModeSwitch = true,
		modeSwitchType = "toggle",
	})

	self.Ping:Create(page)
	self.RaidMarker:Create(page)
	self.PendingSummon:Create(page)
	self.ReadyCheck:Create(page)
	self.RoleIndicator:Create(page)
	self.GroupStatus:Create(page)
	self.Threat:Create(page)

	return page
end
