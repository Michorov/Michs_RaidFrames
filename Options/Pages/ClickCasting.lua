local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.ClickCasting = addon.Options.Pages.ClickCasting or {}

local ClickCasting = addon.Options.Pages.ClickCasting

local MAX_BINDING_ROWS = 10
local CLEAR_TYPE = "clear"

local sourceOptions = {
	{ value = "local", textKey = "MRF" },
	{ value = "external", textKey = "Clique" },
}

local typeOptions = {
	{ value = CLEAR_TYPE, textKey = "Clear" },
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

local function CreateDefaultBindings()
	local bindings = {
		{
			action = "target",
			button = "1",
			modifier = "",
			type = "action",
		},
		{
			action = "togglemenu",
			button = "2",
			modifier = "",
			type = "action",
		},
	}

	for i = 3, MAX_BINDING_ROWS do
		bindings[i] = {}
	end

	return bindings
end

local function EnsureCurrentSpecSettings(profile)
	local clickCasting = profile.core.clickCasting
	clickCasting.specs = type(clickCasting.specs) == "table" and clickCasting.specs or {}

	local specID = addon.Utilities:GetPlayerSpecID()
	if not specID then
		return nil
	end

	local specSettings = clickCasting.specs[specID]
	if type(specSettings) ~= "table" then
		specSettings = {}
		clickCasting.specs[specID] = specSettings
	end

	if type(specSettings.bindings) ~= "table" then
		specSettings.bindings = CreateDefaultBindings()
	end

	return specSettings
end

local function AddActionOption(options, seen, value, text, texture)
	if not value or value == "" or seen[value] then
		return
	end

	seen[value] = true
	options[#options + 1] = {
		value = value,
		text = text or value,
		texture = texture,
	}
end

local function SortActionOptions(options)
	table.sort(options, function(left, right)
		local leftText = left.text or ""
		local rightText = right.text or ""

		if leftText == rightText then
			return tostring(left.value or "") < tostring(right.value or "")
		end

		return leftText < rightText
	end)

	return options
end

local function GetCurrentSpecID()
	if not GetSpecialization or not GetSpecializationInfo then
		return nil
	end

	local specIndex = GetSpecialization()
	if not specIndex then
		return nil
	end

	local specID = GetSpecializationInfo(specIndex)

	return specID
end

local function ShouldIncludeSpellBookSkillLine(skillLineInfo, currentSpecID)
	if not skillLineInfo or skillLineInfo.shouldHide or skillLineInfo.isGuild then
		return false
	end

	if skillLineInfo.offSpecID then
		return false
	end

	if skillLineInfo.specID and skillLineInfo.specID ~= currentSpecID then
		return false
	end

	return true
end

local function IsSpellBookSpellItem(itemInfo, spellItemType, futureSpellItemType)
	return itemInfo.itemType == spellItemType or (futureSpellItemType and itemInfo.itemType == futureSpellItemType)
end

local function BuildSpellOptions()
	local options = {}
	local seen = {}

	if
		C_SpellBook
		and C_SpellBook.GetNumSpellBookSkillLines
		and C_SpellBook.GetSpellBookSkillLineInfo
		and C_SpellBook.GetSpellBookItemInfo
	then
		local spellBank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
		local spellItemType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
		local futureSpellItemType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.FutureSpell
		local currentSpecID = GetCurrentSpecID()

		for skillLineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
			if ShouldIncludeSpellBookSkillLine(skillLineInfo, currentSpecID) then
				local offset = skillLineInfo.itemIndexOffset
				local numItems = skillLineInfo.numSpellBookItems

				if offset and numItems then
					for slotIndex = offset + 1, offset + numItems do
						local itemInfo = C_SpellBook.GetSpellBookItemInfo(slotIndex, spellBank)
						if
							itemInfo
							and IsSpellBookSpellItem(itemInfo, spellItemType, futureSpellItemType)
							and not itemInfo.isPassive
							and not itemInfo.isOffSpec
						then
							AddActionOption(options, seen, itemInfo.name, itemInfo.name, itemInfo.iconID)
						end
					end
				end
			end
		end
	elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo and GetSpellBookItemName then
		for tabIndex = 1, GetNumSpellTabs() do
			local _, _, offset, numSlots, isGuild, offSpecID = GetSpellTabInfo(tabIndex)

			if offset and numSlots and not isGuild and not offSpecID then
				for slotIndex = offset + 1, offset + numSlots do
					local itemType = GetSpellBookItemInfo(slotIndex, BOOKTYPE_SPELL)
					local isPassive = IsPassiveSpell and IsPassiveSpell(slotIndex, BOOKTYPE_SPELL)

					if (itemType == "SPELL" or itemType == "FUTURESPELL") and not isPassive then
						local name = GetSpellBookItemName(slotIndex, BOOKTYPE_SPELL)
						local texture = GetSpellTexture and GetSpellTexture(slotIndex, BOOKTYPE_SPELL)

						AddActionOption(options, seen, name, name, texture)
					end
				end
			end
		end
	end

	return SortActionOptions(options)
end

local function GetMaxAccountMacros()
	if Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_ACCOUNT_MACROS then
		return Constants.MacroConsts.MAX_ACCOUNT_MACROS
	end

	return MAX_ACCOUNT_MACROS or 120
end

local function GetMaxCharacterMacros()
	if Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_CHARACTER_MACROS then
		return Constants.MacroConsts.MAX_CHARACTER_MACROS
	end

	return MAX_CHARACTER_MACROS or 30
end

local function AddMacroOption(options, macroIndex)
	local name, texture = GetMacroInfo(macroIndex)
	if not name or name == "" then
		return
	end

	options[#options + 1] = {
		value = macroIndex,
		text = name,
		texture = texture,
	}
end

local function BuildMacroOptions()
	local options = {}

	if not GetMacroInfo then
		return options
	end

	local maxAccountMacros = GetMaxAccountMacros()
	local maxCharacterMacros = GetMaxCharacterMacros()

	for macroIndex = 1, maxAccountMacros do
		AddMacroOption(options, macroIndex)
	end

	for macroIndex = maxAccountMacros + 1, maxAccountMacros + maxCharacterMacros do
		AddMacroOption(options, macroIndex)
	end

	return SortActionOptions(options)
end

local function BuildActionOptions(bindingType)
	if bindingType == "action" then
		return actionOptions
	end

	if bindingType == "spell" then
		return BuildSpellOptions()
	end

	if bindingType == "macro" then
		return BuildMacroOptions()
	end

	return {}
end

local function SetRowActionOptions(row, bindingType)
	local options = BuildActionOptions(bindingType)

	row.actionDropdown:SetOptions(options)

	return options
end

local function HasActionOption(options, value)
	if not value then
		return false
	end

	for _, option in ipairs(options or {}) do
		if option.value == value then
			return true
		end
	end

	return false
end

local function ClearRow(row)
	row.typeDropdown:SetValue(nil)
	row.actionDropdown:SetValue(nil)
	SetRowActionOptions(row, nil)
	row.modifierDropdown:SetValue(nil)
	row.buttonDropdown:SetValue(nil)
end

local function SetRowValueChangedCallback(row, callback)
	row.typeDropdown:SetOnValueChanged(function(_, value)
		if value == CLEAR_TYPE then
			ClearRow(row)
		else
			row.actionDropdown:SetValue(nil)
			SetRowActionOptions(row, value)
		end

		callback()
	end)
	row.actionDropdown:SetOnValueChanged(callback)
	row.modifierDropdown:SetOnValueChanged(callback)
	row.buttonDropdown:SetOnValueChanged(callback)
end

local function BuildBindings(rows)
	local bindings = {}

	for i = 1, MAX_BINDING_ROWS do
		local row = rows[i]
		local bindingType = row.typeDropdown:GetValue()
		local action = row.actionDropdown:GetValue()
		local modifier = row.modifierDropdown:GetValue()
		local button = row.buttonDropdown:GetValue()

		if bindingType == CLEAR_TYPE then
			bindingType = nil
		end

		local hasValue = bindingType ~= nil or action ~= nil or modifier ~= nil or button ~= nil

		if hasValue then
			bindings[i] = {
				action = action,
				button = button,
				modifier = modifier or "",
				type = bindingType,
			}
		else
			bindings[i] = {}
		end
	end

	return bindings
end

local function SaveRows(panel, rows)
	panel:UpdateValue(function(profile)
		local specSettings = EnsureCurrentSpecSettings(profile)
		if specSettings then
			specSettings.bindings = BuildBindings(rows)
		end
	end)
	addon.UpdateScheduler:Notify("clickCastingSettingsChanged")
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
		row.actionDropdown:SetOptions({})

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
		local bindingType = binding and binding.type or nil

		if bindingType ~= "action" and bindingType ~= "spell" and bindingType ~= "macro" then
			bindingType = nil
		end

		row.typeDropdown:SetValue(bindingType)
		local actionOptions = SetRowActionOptions(row, bindingType)
		local action = binding and binding.action or nil
		if not HasActionOption(actionOptions, action) then
			action = nil
		end

		row.actionDropdown:SetValue(action)
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
	for _, row in ipairs(localRows) do
		SetRowValueChangedCallback(row, function()
			SaveRows(panel, localRows)
		end)
	end

	subpage:SetStateUpdater(function(profile)
		local isLocal = GetClickCastingSource(profile) == "local"
		local specSettings = EnsureCurrentSpecSettings(profile)

		externalMessage:SetShown(not isLocal)
		RefreshRows(localRows, specSettings and specSettings.bindings or nil)
		for _, row in ipairs(localRows) do
			row.frame:SetShown(isLocal)
		end
	end)

	return page
end
