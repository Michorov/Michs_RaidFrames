local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.ClickCasting = addon.Options.Pages.ClickCasting or {}

local ClickCasting = addon.Options.Pages.ClickCasting

local MAX_BINDING_ROWS = 10

local sourceOptions = {
	{ value = "local", textKey = "MRF" },
	{ value = "external", textKey = "Clique" },
}

local typeOptions = {
	{ value = "action", textKey = "Action" },
	{ value = "spell", textKey = "Spell" },
	{ value = "macro", textKey = "Macro" },
}

local actionOptions = {
	{ value = "target", textKey = "Target" },
	{ value = "togglemenu", textKey = "Menu" },
}

local modifierOptions = {
	{ value = "", textKey = "None" },
	{ value = "shift-", textKey = "Shift" },
	{ value = "ctrl-", textKey = "Ctrl" },
	{ value = "alt-", textKey = "Alt" },
	{ value = "ctrl-shift-", textKey = "Shift + Ctrl" },
	{ value = "alt-shift-", textKey = "Shift + Alt" },
	{ value = "alt-ctrl-", textKey = "Ctrl + Alt" },
	{ value = "alt-ctrl-shift-", textKey = "Shift + Ctrl + Alt" },
}

local buttonOptions = {
	{ value = "1", textKey = "Left Button" },
	{ value = "2", textKey = "Right Button" },
	{ value = "3", textKey = "Scroll Button" },
	{ value = "4", textKey = "Side Button 1" },
	{ value = "5", textKey = "Side Button 2" },
}

local function GetClickCastingSource(profile)
	local source = profile.core.clickCasting.source

	return source == "local" and "local" or "external"
end

local function BuildRows(subpage, anchorFrame)
	local rows = {}
	local previousRow = nil

	for i = 1, MAX_BINDING_ROWS do
		local row = subpage:CreateRow(4)
		row:SetLayoutHeight(24)
		if previousRow then
			row:SetLayoutPoint("TOPLEFT", previousRow.frame, "BOTTOMLEFT", 0, -8)
		else
			row:SetLayoutPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -24)
		end

		row.typeDropdown = row:CreateControl("Dropdown", { placeholderKey = "Type" })
		row.typeDropdown:SetLabelVisible(false)
		row.typeDropdown:SetOptions(typeOptions)

		row.actionDropdown = row:CreateControl("Dropdown", { placeholderKey = "Action" })
		row.actionDropdown:SetLabelVisible(false)
		row.actionDropdown:SetOptions(actionOptions)

		row.modifierDropdown = row:CreateControl("Dropdown", { placeholderKey = "Modifier" })
		row.modifierDropdown:SetLabelVisible(false)
		row.modifierDropdown:SetOptions(modifierOptions)

		row.buttonDropdown = row:CreateControl("Dropdown", { placeholderKey = "Button" })
		row.buttonDropdown:SetLabelVisible(false)
		row.buttonDropdown:SetOptions(buttonOptions)

		rows[i] = row
		previousRow = row
	end

	return rows
end

local function RefreshRows(rows, bindings)
	bindings = bindings or {}

	for i, row in ipairs(rows) do
		local binding = bindings[i]

		row.typeDropdown:SetValue(binding and binding.type or nil)
		row.actionDropdown:SetValue(binding and binding.action or nil)
		row.modifierDropdown:SetValue(binding and binding.modifier or nil)
		row.buttonDropdown:SetValue(binding and binding.button or nil)
	end
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
	externalMessage:SetLayoutPoint("TOPLEFT", settingsRow.frame, "BOTTOMLEFT", 0, -24)

	local localRows = BuildRows(subpage, settingsRow.frame)

	subpage:SetStateUpdater(function(profile)
		local isLocal = GetClickCastingSource(profile) == "local"

		externalMessage:SetShown(not isLocal)
		RefreshRows(localRows, profile.core.clickCasting.bindings)
		for _, row in ipairs(localRows) do
			row.frame:SetShown(isLocal)
		end
	end)

	return page
end
