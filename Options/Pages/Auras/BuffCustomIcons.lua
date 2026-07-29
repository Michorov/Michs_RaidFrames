local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.BuffCustomIcons = addon.Options.Pages.Auras.BuffCustomIcons or {}

local BuffCustomIcons = addon.Options.Pages.Auras.BuffCustomIcons
local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)

local anchorOptions = {
	{ value = "TOPLEFT", textKey = "Top Left" },
	{ value = "TOP", textKey = "Top Center" },
	{ value = "TOPRIGHT", textKey = "Top Right" },
	{ value = "LEFT", textKey = "Left" },
	{ value = "CENTER", textKey = "Center" },
	{ value = "RIGHT", textKey = "Right" },
	{ value = "BOTTOMLEFT", textKey = "Bottom Left" },
	{ value = "BOTTOM", textKey = "Bottom Center" },
	{ value = "BOTTOMRIGHT", textKey = "Bottom Right" },
}

local visibilityOptions = {
	{ value = true, textKey = "Show" },
	{ value = false, textKey = "Hide" },
}

local colorTextureOptions = {
	{ value = false, textKey = "Aura Texture" },
	{ value = true, textKey = "Solid Color" },
}

local defaultSettings = {
	enabled = false,
	anchor = "CENTER",
	offsetX = 0,
	offsetY = 0,
	iconSize = 16,
	showStacks = false,
	stacksFontSize = 10,
	showCooldown = false,
	cooldownFontSize = 10,
	colorTexture = false,
	colorTextureColor = {
		r = 1,
		g = 1,
		b = 1,
		a = 1,
	},
}

local function FormatInteger(value)
	return string.format("%d", value)
end

local function GetAuraDisplayName(spellId, fallbackName)
	if addon.Locale and addon.Locale.GetAuraDisplayName then
		return addon.Locale:GetAuraDisplayName(spellId, fallbackName)
	end

	return fallbackName
end

local function GetCurrentSpecBuffEntries(profile, mode)
	local section = profile[mode]
	local customBuffs = section.widgets.icons.customBuffs
	local classFileName = addon.Utilities:GetPlayerClassFileName() or ""
	local classBuffs = customBuffs[classFileName] or {}
	local specID = addon.Utilities:GetPlayerSpecID()
	local specName = specID and (select(2, GetSpecializationInfoByID(specID)) or ("Spec " .. tostring(specID))) or nil
	local specBuffs = (specID and classBuffs[specID]) or nil
	local entries = {}

	if not specID or type(specBuffs) ~= "table" then
		return {
			specID = specID,
			specName = specName,
			entries = entries,
		}
	end

	for spellId, buffData in pairs(specBuffs) do
		local fallbackName = buffData.name or ("Spell " .. tostring(spellId))

		entries[#entries + 1] = {
			spellId = spellId,
			name = GetAuraDisplayName(spellId, fallbackName),
		}
	end

	table.sort(entries, function(a, b)
		return string.lower(a.name) < string.lower(b.name)
	end)

	return {
		specID = specID,
		specName = specName,
		entries = entries,
	}
end

function BuffCustomIcons:Create(page)
	local subpage = page:RegisterSubPage("buffCustomIcons", { titleKey = "Buffs - Custom Icons" })
	local panel = page.panel

	subpage.selectedSpellIds = {}

	subpage.emptyText = subpage.frame:CreateFontString(nil, "OVERLAY")
	subpage.emptyText:SetJustifyH("LEFT")
	subpage.emptyText:SetTextColor(OptionsUILib.Theme:GetTextColor("secondary"))
	OptionsUILib.Theme:ApplyFont(subpage.emptyText, panel.instance.PP:ScaleFont(14), "")
	subpage.emptyText:SetText(panel:Localize("No custom icons available for this specialization"))
	subpage.emptyText:Hide()

	local selectorRow = subpage:CreateRow(4)
	selectorRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local buffDropdown = selectorRow:CreateControl("Dropdown", { labelKey = "Buff" })
	local enabledSlot = selectorRow:CreateCheckboxSlot("bottom")
	local enabledCheckbox = enabledSlot:CreateControl("Checkbox", { labelKey = "Enabled" })

	local positionRow = subpage:CreateRow(4)
	positionRow:SetLayoutPoint("TOPLEFT", selectorRow.frame, "BOTTOMLEFT", 0, -32)

	local anchorDropdown = positionRow:CreateControl("Dropdown", { labelKey = "Position" })
	anchorDropdown:SetOptions(anchorOptions)

	local offsetXSlider = positionRow:CreateControl("Slider", { labelKey = "Offset X" })
	offsetXSlider:SetMinMaxValues(-300, 300)
	offsetXSlider:SetStep(1)
	offsetXSlider:SetValueFormatter(FormatInteger)

	local offsetYSlider = positionRow:CreateControl("Slider", { labelKey = "Offset Y" })
	offsetYSlider:SetMinMaxValues(-300, 300)
	offsetYSlider:SetStep(1)
	offsetYSlider:SetValueFormatter(FormatInteger)

	local iconSizeSlider = positionRow:CreateControl("Slider", { labelKey = "Icon Size" })
	iconSizeSlider:SetMinMaxValues(8, 64)
	iconSizeSlider:SetStep(1)
	iconSizeSlider:SetValueFormatter(FormatInteger)

	local textRow = subpage:CreateRow(4)
	textRow:SetLayoutPoint("TOPLEFT", positionRow.frame, "BOTTOMLEFT", 0, -16)

	local showStacksDropdown = textRow:CreateControl("Dropdown", { labelKey = "Stacks" })
	showStacksDropdown:SetOptions(visibilityOptions)

	local stacksFontSizeSlider = textRow:CreateControl("Slider", { labelKey = "Stacks Size" })
	stacksFontSizeSlider:SetMinMaxValues(6, 32)
	stacksFontSizeSlider:SetStep(1)
	stacksFontSizeSlider:SetValueFormatter(FormatInteger)

	local durationRow = subpage:CreateRow(4)
	durationRow:SetLayoutPoint("TOPLEFT", textRow.frame, "BOTTOMLEFT", 0, -16)

	local showCooldownDropdown = durationRow:CreateControl("Dropdown", { labelKey = "Duration" })
	showCooldownDropdown:SetOptions(visibilityOptions)

	local cooldownFontSizeSlider = durationRow:CreateControl("Slider", { labelKey = "Duration Size" })
	cooldownFontSizeSlider:SetMinMaxValues(6, 32)
	cooldownFontSizeSlider:SetStep(1)
	cooldownFontSizeSlider:SetValueFormatter(FormatInteger)

	local colorRow = subpage:CreateRow(4)
	colorRow:SetLayoutPoint("TOPLEFT", durationRow.frame, "BOTTOMLEFT", 0, -16)

	local colorTextureDropdown = colorRow:CreateControl("Dropdown", { labelKey = "Color Texture" })
	colorTextureDropdown:SetOptions(colorTextureOptions)

	local colorTextureColorPicker = colorRow:CreateControl("ColorPicker", { labelKey = "Color" })
	colorTextureColorPicker:SetHasOpacity(true)

	local controls = {
		buffDropdown,
		enabledCheckbox,
		anchorDropdown,
		offsetXSlider,
		offsetYSlider,
		iconSizeSlider,
		showStacksDropdown,
		stacksFontSizeSlider,
		showCooldownDropdown,
		cooldownFontSizeSlider,
		colorTextureDropdown,
		colorTextureColorPicker,
	}

	local settingControls = {
		enabledCheckbox,
		anchorDropdown,
		offsetXSlider,
		offsetYSlider,
		iconSizeSlider,
		showStacksDropdown,
		stacksFontSizeSlider,
		showCooldownDropdown,
		cooldownFontSizeSlider,
		colorTextureDropdown,
		colorTextureColorPicker,
	}

	local rows = {
		selectorRow,
		positionRow,
		textRow,
		durationRow,
		colorRow,
	}

	local function GetSelectedSpellId(mode, specID, entries)
		if not specID then
			return nil
		end

		subpage.selectedSpellIds[mode] = subpage.selectedSpellIds[mode] or {}

		local selectedSpellId = subpage.selectedSpellIds[mode][specID]
		if selectedSpellId then
			for _, entry in ipairs(entries or {}) do
				if entry.spellId == selectedSpellId then
					return selectedSpellId
				end
			end
		end

		if entries and entries[1] then
			selectedSpellId = entries[1].spellId
			subpage.selectedSpellIds[mode][specID] = selectedSpellId
			return selectedSpellId
		end

		subpage.selectedSpellIds[mode][specID] = nil
		return nil
	end

	local function SetSelectedSpellId(mode, specID, spellId)
		if not specID then
			return
		end

		subpage.selectedSpellIds[mode] = subpage.selectedSpellIds[mode] or {}
		subpage.selectedSpellIds[mode][specID] = spellId
	end

	local function EnsureSelectedSettings(profile, mode)
		local classFileName = addon.Utilities:GetPlayerClassFileName() or ""
		local customBuffs = profile[mode].widgets.icons.customBuffs

		customBuffs[classFileName] = customBuffs[classFileName] or {}
		customBuffs[classFileName][subpage.activeSpecID] = customBuffs[classFileName][subpage.activeSpecID] or {}
		customBuffs[classFileName][subpage.activeSpecID][subpage.selectedSpellId] = customBuffs[classFileName][subpage.activeSpecID][subpage.selectedSpellId]
			or {}

		return customBuffs[classFileName][subpage.activeSpecID][subpage.selectedSpellId]
	end

	local function UpdateSelectedSetting(callback)
		if not subpage.activeSpecID or not subpage.selectedSpellId then
			return
		end

		panel:UpdateValue(function(profile, mode)
			callback(EnsureSelectedSettings(profile, mode))
		end)

		addon.UpdateScheduler:Notify("customBuffSettingsChanged")
		addon.UpdateScheduler:Notify("aurasStateChanged")
	end

	buffDropdown:SetOnValueChanged(function(_, value)
		SetSelectedSpellId(panel:GetActiveMode(), subpage.activeSpecID, value)
		subpage.selectedSpellId = value
		subpage:UpdateState(panel.profileGetter(panel), panel:GetActiveMode())
	end)

	enabledCheckbox:SetOnValueChanged(function(_, checked)
		UpdateSelectedSetting(function(settings)
			settings.enabled = checked == true
		end)
	end)

	anchorDropdown:SetOnValueChanged(function(_, value)
		UpdateSelectedSetting(function(settings)
			settings.anchor = value
		end)
	end)

	offsetXSlider:SetOnValueChanged(function(_, value)
		UpdateSelectedSetting(function(settings)
			settings.offsetX = value
		end)
	end)

	offsetYSlider:SetOnValueChanged(function(_, value)
		UpdateSelectedSetting(function(settings)
			settings.offsetY = value
		end)
	end)

	iconSizeSlider:SetOnValueChanged(function(_, value)
		UpdateSelectedSetting(function(settings)
			settings.iconSize = value
		end)
	end)

	showStacksDropdown:SetOnValueChanged(function(_, value)
		UpdateSelectedSetting(function(settings)
			settings.showStacks = value == true
		end)
	end)

	stacksFontSizeSlider:SetOnValueChanged(function(_, value)
		UpdateSelectedSetting(function(settings)
			settings.stacksFontSize = value
		end)
	end)

	showCooldownDropdown:SetOnValueChanged(function(_, value)
		UpdateSelectedSetting(function(settings)
			settings.showCooldown = value == true
		end)
	end)

	cooldownFontSizeSlider:SetOnValueChanged(function(_, value)
		UpdateSelectedSetting(function(settings)
			settings.cooldownFontSize = value
		end)
	end)

	colorTextureDropdown:SetOnValueChanged(function(_, value)
		UpdateSelectedSetting(function(settings)
			settings.colorTexture = value == true
		end)
	end)

	colorTextureColorPicker:SetOnValueChanged(function(_, r, g, b, a)
		UpdateSelectedSetting(function(settings)
			settings.colorTextureColor = {
				r = r,
				g = g,
				b = b,
				a = a,
			}
		end)
	end)

	local function RefreshSelectionState(profile, mode)
		local currentSpec = GetCurrentSpecBuffEntries(profile, mode)
		local dropdownOptions = {}

		subpage.activeSpecID = currentSpec.specID
		subpage.activeSpecName = currentSpec.specName
		subpage.activeEntries = currentSpec.entries
		subpage.selectedSpellId = GetSelectedSpellId(mode, currentSpec.specID, currentSpec.entries)

		for _, entry in ipairs(currentSpec.entries) do
			dropdownOptions[#dropdownOptions + 1] = {
				value = entry.spellId,
				text = entry.name,
			}
		end

		buffDropdown:SetOptions(dropdownOptions)
		buffDropdown:SetValue(subpage.selectedSpellId)
		buffDropdown:SetShown(subpage.selectedSpellId ~= nil)
		subpage.emptyText:SetShown(currentSpec.specName ~= nil and #currentSpec.entries == 0)
		subpage.hasSelection = subpage.selectedSpellId ~= nil
	end

	subpage:SetStateUpdater(function(profile, mode)
		RefreshSelectionState(profile, mode)

		if not subpage.hasSelection then
			for _, control in ipairs(settingControls) do
				control:Hide()
			end

			for index = 2, #rows do
				rows[index].frame:Hide()
			end

			return
		end

		local classFileName = addon.Utilities:GetPlayerClassFileName() or ""
		local settings = profile[mode].widgets.icons.customBuffs[classFileName][subpage.activeSpecID][subpage.selectedSpellId]
			or {}
		local color = settings.colorTextureColor or defaultSettings.colorTextureColor

		enabledCheckbox:SetChecked(settings.enabled == true)
		anchorDropdown:SetValue(settings.anchor or defaultSettings.anchor)
		offsetXSlider:SetValueSilently(settings.offsetX or defaultSettings.offsetX)
		offsetYSlider:SetValueSilently(settings.offsetY or defaultSettings.offsetY)
		iconSizeSlider:SetValueSilently(settings.iconSize or defaultSettings.iconSize)
		showStacksDropdown:SetValue(settings.showStacks == true)
		stacksFontSizeSlider:SetValueSilently(settings.stacksFontSize or defaultSettings.stacksFontSize)
		showCooldownDropdown:SetValue(settings.showCooldown == true)
		cooldownFontSizeSlider:SetValueSilently(settings.cooldownFontSize or defaultSettings.cooldownFontSize)
		colorTextureDropdown:SetValue(settings.colorTexture == true)
		colorTextureColorPicker:SetColor(color.r, color.g, color.b, color.a)

		for _, row in ipairs(rows) do
			row.frame:Show()
		end

		for _, control in ipairs(controls) do
			control:Show()
		end
	end)

	local baseUpdateLocale = subpage.UpdateLocale
	function subpage:UpdateLocale()
		baseUpdateLocale(self)
		self.emptyText:SetText(panel:Localize("No custom icons available for this specialization"))
		RefreshSelectionState(panel.profileGetter(panel), panel:GetActiveMode())
	end

	local baseUpdateLayout = subpage.UpdateLayout
	function subpage:UpdateLayout()
		baseUpdateLayout(self)

		local PP = panel.instance.PP
		self.emptyText:ClearAllPoints()
		self.emptyText:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
		OptionsUILib.Theme:ApplyFont(self.emptyText, PP:ScaleFont(14), "")
	end

	subpage:UpdateState(panel.profileGetter(panel), panel:GetActiveMode())

	return subpage
end
