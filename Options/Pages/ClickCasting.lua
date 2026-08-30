local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.ClickCasting = addon.Options.Pages.ClickCasting or {}

local ClickCasting = addon.Options.Pages.ClickCasting

local sourceOptions = {
	{ value = "local", textKey = "MRF" },
	{ value = "external", textKey = "Clique" },
}

local typeOptions = {
	{ value = "spell", textKey = "Spell" },
	{ value = "target", textKey = "Target" },
	{ value = "togglemenu", textKey = "Menu" },
}

local function GetClickCastingSource(profile)
	local source = profile.core.clickCasting.source

	return source == "local" and "local" or "external"
end

function ClickCasting:Create(panel)
	local page = panel:RegisterPage("clickCasting", {
		titleKey = "Click Casting",
		showHeader = true,
	})
	local subpage = page:RegisterSubPage("clickCasting", { titleKey = "Click Casting" })

	local settingsRow = subpage:CreateRow(3)
	settingsRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local sourceDropdown = settingsRow:CreateControl("Dropdown", { labelKey = "Source" })
	sourceDropdown:SetOptions(sourceOptions)
	sourceDropdown:BindValue({
		get = function(profile)
			return GetClickCastingSource(profile)
		end,
		set = function(profile, _, value)
			profile.core.clickCasting.source = value
		end,
		onChange = function()
			panel:UpdateState()
			addon.UpdateScheduler:Notify("clickCastingSettingsChanged")
		end,
	})

	local externalMessage = subpage:CreateControl("Label", {
		textKey = "Configure click casting bindings in the Clique addon.",
	})
	externalMessage:SetLayoutWidth(576)
	externalMessage:SetLayoutPoint("TOPLEFT", settingsRow.frame, "BOTTOMLEFT", 0, -16)

	local localTypeRow = subpage:CreateRow(3)
	localTypeRow:SetLayoutPoint("TOPLEFT", settingsRow.frame, "BOTTOMLEFT", 0, -16)

	local typeDropdown = localTypeRow:CreateControl("Dropdown", { labelKey = "Type" })
	typeDropdown:SetOptions(typeOptions)
	typeDropdown:SetValue("spell")

	subpage:SetStateUpdater(function(profile)
		local isLocal = GetClickCastingSource(profile) == "local"

		externalMessage:SetShown(not isLocal)
		localTypeRow.frame:SetShown(isLocal)
	end)

	return page
end
