local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.BuffCustomIcons = addon.Options.Pages.Auras.BuffCustomIcons or {}

local BuffCustomIcons = addon.Options.Pages.Auras.BuffCustomIcons

local subpage
local L = addon.L
local theme = addon.Options.Theme

local anchorOptions = {
	{ value = "TOPLEFT", text = L["Top Left"] },
	{ value = "TOP", text = L["Top Center"] },
	{ value = "TOPRIGHT", text = L["Top Right"] },
	{ value = "LEFT", text = L["Left"] },
	{ value = "CENTER", text = L["Center"] },
	{ value = "RIGHT", text = L["Right"] },
	{ value = "BOTTOMLEFT", text = L["Bottom Left"] },
	{ value = "BOTTOM", text = L["Bottom Center"] },
	{ value = "BOTTOMRIGHT", text = L["Bottom Right"] },
}

local function UpdateAnchorOptions()
	anchorOptions[1].text = L["Top Left"]
	anchorOptions[2].text = L["Top Center"]
	anchorOptions[3].text = L["Top Right"]
	anchorOptions[4].text = L["Left"]
	anchorOptions[5].text = L["Center"]
	anchorOptions[6].text = L["Right"]
	anchorOptions[7].text = L["Bottom Left"]
	anchorOptions[8].text = L["Bottom Center"]
	anchorOptions[9].text = L["Bottom Right"]
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Custom buff settings are disabled during combat."])
end

local function GetAuraDisplayName(spellId, fallbackName)
	if addon.Locale and addon.Locale.GetAuraDisplayName then
		return addon.Locale:GetAuraDisplayName(spellId, fallbackName)
	end

	return fallbackName
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

local function GetBuffDefaults()
	return {
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
end

local function GetCurrentSpecBuffEntries(profile)
	profile = profile or addon.Database:GetProfile()

	local mode = addon.Options.State:GetMode()
	local section = profile[mode] or {}
	local widgets = section.widgets or {}
	local icons = widgets.icons or {}
	local customBuffs = icons.customBuffs or {}
	local classFileName = addon.Utilities:GetPlayerClassFileName() or ""
	local classBuffs = customBuffs[classFileName] or {}
	local specID = addon.Utilities:GetPlayerSpecID()
	local specName = specID and (select(2, GetSpecializationInfoByID(specID)) or ("Spec " .. tostring(specID))) or nil
	local specBuffs = (specID and classBuffs[specID]) or nil
	local entries = {}

	if not specID then
		return {
			specID = nil,
			specName = nil,
			entries = entries,
		}
	end

	if type(specBuffs) ~= "table" then
		return {
			specID = specID,
			specName = specName,
			entries = entries,
		}
	end

	for spellId, buffData in pairs(specBuffs) do
		local fallbackName = buffData.name or ("Spell " .. tostring(spellId))

		table.insert(entries, {
			spellId = spellId,
			name = GetAuraDisplayName(spellId, fallbackName),
		})
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

local function GetSelectedSpellId(specID, entries)
	subpage.selectedSpellIds = subpage.selectedSpellIds or {}
	local mode = addon.Options.State:GetMode()
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

local function SetSelectedSpellId(specID, spellId)
	subpage.selectedSpellIds = subpage.selectedSpellIds or {}
	local mode = addon.Options.State:GetMode()
	subpage.selectedSpellIds[mode] = subpage.selectedSpellIds[mode] or {}
	subpage.selectedSpellIds[mode][specID] = spellId
end

local function ApplySelectedBuffSetting(updateFn)
	if InCombatLockdown() then
		ShowCombatLockMessage()
		if subpage and subpage.UpdateState then
			subpage:UpdateState(addon.Database:GetProfile())
		end
		return
	end

	if not subpage.activeSpecID or not subpage.selectedSpellId then
		return
	end

	local profile = addon.Database:GetProfile()
	local mode = addon.Options.State:GetMode()
	local classFileName = addon.Utilities:GetPlayerClassFileName() or ""

	profile[mode] = profile[mode] or {}
	profile[mode].widgets = profile[mode].widgets or {}
	profile[mode].widgets.icons = profile[mode].widgets.icons or {}
	profile[mode].widgets.icons.customBuffs = profile[mode].widgets.icons.customBuffs or {}
	profile[mode].widgets.icons.customBuffs[classFileName] = profile[mode].widgets.icons.customBuffs[classFileName]
		or {}
	profile[mode].widgets.icons.customBuffs[classFileName][subpage.activeSpecID] = profile[mode].widgets.icons.customBuffs[classFileName][subpage.activeSpecID]
		or {}
	profile[mode].widgets.icons.customBuffs[classFileName][subpage.activeSpecID][subpage.selectedSpellId] = profile[mode].widgets.icons.customBuffs[classFileName][subpage.activeSpecID][subpage.selectedSpellId]
		or {}

	updateFn(profile[mode].widgets.icons.customBuffs[classFileName][subpage.activeSpecID][subpage.selectedSpellId])

	addon.UpdateScheduler:Notify("customBuffSettingsChanged")
	addon.UpdateScheduler:Notify("aurasStateChanged")
end

local function RefreshSelectionState(profile)
	local currentSpec = GetCurrentSpecBuffEntries(profile)
	subpage.activeSpecID = currentSpec.specID
	subpage.activeSpecName = currentSpec.specName
	subpage.activeEntries = currentSpec.entries
	subpage.selectedSpellId = GetSelectedSpellId(currentSpec.specID, currentSpec.entries)

	if currentSpec.specName and #currentSpec.entries == 0 then
		subpage.emptyText:Show()
	else
		subpage.emptyText:Hide()
	end

	local dropdownOptions = {}
	for _, entry in ipairs(currentSpec.entries) do
		table.insert(dropdownOptions, {
			value = entry.spellId,
			text = entry.name,
		})
	end

	subpage.buffDropdown:SetOptions(dropdownOptions)
	subpage.buffDropdown:SetValue(subpage.selectedSpellId)

	local hasSelection = subpage.selectedSpellId ~= nil

	if hasSelection then
		subpage.buffDropdown:Show()
	else
		subpage.buffDropdown:Hide()
	end

	subpage.hasSelection = hasSelection
end

function BuffCustomIcons:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.emptyText = subpage:CreateFontString(nil, "OVERLAY")
	subpage.emptyText:SetJustifyH("LEFT")
	theme:ApplyFont(subpage.emptyText, "arialNarrow", 14, "")
	subpage.emptyText:SetTextColor(theme:GetTextColor("secondary"))
	subpage.emptyText:SetText(L["No custom icons available for this specialization"])
	subpage.emptyText:Hide()

	subpage.buffDropdown = addon.Options.Controls.Dropdown:Create(subpage, L["Buff"])
	subpage.buffDropdown:SetLayoutWidth(174)
	subpage.buffDropdown:SetLabelVisible(false)
	subpage.buffDropdown:SetOnValueChanged(function(_, value)
		SetSelectedSpellId(subpage.activeSpecID, value)
		subpage.selectedSpellId = value
		subpage:UpdateState(addon.Database:GetProfile())
	end)

	subpage.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Enabled"])
	subpage.enabledCheckbox:SetLayoutWidth(174)
	subpage.enabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplySelectedBuffSetting(function(settings)
			settings.enabled = checked == true
		end)
	end)

	subpage.anchorDropdown = addon.Options.Controls.Dropdown:Create(subpage, L["Anchor"])
	subpage.anchorDropdown:SetLayoutWidth(174)
	subpage.anchorDropdown:SetOptions(anchorOptions)
	subpage.anchorDropdown:SetOnValueChanged(function(_, value)
		ApplySelectedBuffSetting(function(settings)
			settings.anchor = value
		end)
	end)

	subpage.iconSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Icon Size"])
	subpage.iconSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.iconSizeSlider, 8, 64, 1)
	subpage.iconSizeSlider:SetOnValueChanged(function(_, value)
		ApplySelectedBuffSetting(function(settings)
			settings.iconSize = value
		end)
	end)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset X"])
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -300, 300, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplySelectedBuffSetting(function(settings)
			settings.offsetX = value
		end)
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset Y"])
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -300, 300, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplySelectedBuffSetting(function(settings)
			settings.offsetY = value
		end)
	end)

	subpage.showStacksCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Show Stacks"])
	subpage.showStacksCheckbox:SetLayoutWidth(174)
	subpage.showStacksCheckbox:SetOnValueChanged(function(_, checked)
		ApplySelectedBuffSetting(function(settings)
			settings.showStacks = checked == true
		end)
	end)

	subpage.stacksFontSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Stacks Size"])
	subpage.stacksFontSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.stacksFontSizeSlider, 6, 32, 1)
	subpage.stacksFontSizeSlider:SetOnValueChanged(function(_, value)
		ApplySelectedBuffSetting(function(settings)
			settings.stacksFontSize = value
		end)
	end)

	subpage.showCooldownCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Show Duration"])
	subpage.showCooldownCheckbox:SetLayoutWidth(174)
	subpage.showCooldownCheckbox:SetOnValueChanged(function(_, checked)
		ApplySelectedBuffSetting(function(settings)
			settings.showCooldown = checked == true
		end)
	end)

	subpage.cooldownFontSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Duration Size"])
	subpage.cooldownFontSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.cooldownFontSizeSlider, 6, 32, 1)
	subpage.cooldownFontSizeSlider:SetOnValueChanged(function(_, value)
		ApplySelectedBuffSetting(function(settings)
			settings.cooldownFontSize = value
		end)
	end)

	subpage.colorTextureCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Color Texture"])
	subpage.colorTextureCheckbox:SetLayoutWidth(174)
	subpage.colorTextureCheckbox:SetOnValueChanged(function(_, checked)
		ApplySelectedBuffSetting(function(settings)
			settings.colorTexture = checked == true
		end)
	end)

	subpage.colorTextureColorPicker = addon.Options.Controls.ColorPicker:Create(subpage, L["Color"])
	subpage.colorTextureColorPicker:SetLayoutWidth(174)
	subpage.colorTextureColorPicker:SetHasOpacity(true)
	subpage.colorTextureColorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplySelectedBuffSetting(function(settings)
			settings.colorTextureColor = {
				r = r,
				g = g,
				b = b,
				a = a,
			}
		end)
	end)

	subpage.controls = {
		buffDropdown = subpage.buffDropdown,
		enabledCheckbox = subpage.enabledCheckbox,
		anchorDropdown = subpage.anchorDropdown,
		iconSizeSlider = subpage.iconSizeSlider,
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		showStacksCheckbox = subpage.showStacksCheckbox,
		stacksFontSizeSlider = subpage.stacksFontSizeSlider,
		showCooldownCheckbox = subpage.showCooldownCheckbox,
		cooldownFontSizeSlider = subpage.cooldownFontSizeSlider,
		colorTextureCheckbox = subpage.colorTextureCheckbox,
		colorTextureColorPicker = subpage.colorTextureColorPicker,
	}

	function subpage:UpdateLocale()
		UpdateAnchorOptions()
		self.emptyText:SetText(L["No custom icons available for this specialization"])
		self.buffDropdown:SetLabel(L["Buff"])
		self.enabledCheckbox:SetText(L["Enabled"])
		self.anchorDropdown:SetLabel(L["Anchor"])
		self.anchorDropdown:SetOptions(anchorOptions)
		self.iconSizeSlider:SetLabel(L["Icon Size"])
		self.offsetXSlider:SetLabel(L["Offset X"])
		self.offsetYSlider:SetLabel(L["Offset Y"])
		self.showStacksCheckbox:SetText(L["Show Stacks"])
		self.stacksFontSizeSlider:SetLabel(L["Stacks Size"])
		self.showCooldownCheckbox:SetText(L["Show Duration"])
		self.cooldownFontSizeSlider:SetLabel(L["Duration Size"])
		self.colorTextureCheckbox:SetText(L["Color Texture"])
		self.colorTextureColorPicker:SetLabel(L["Color"])
		RefreshSelectionState(addon.Database:GetProfile())
	end

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(44)
		local topContentGapPx = addon.Utilities:ToPixels(20)
		local sectionGapPx = addon.Utilities:ToPixels(10)
		local anchorToOffsetsGapPx = addon.Utilities:ToPixels(10)
		local columnGapPx = addon.Utilities:ToPixels(30)
		local columnWidthPx = addon.Utilities:ToPixels(174)
		local secondColumnOffsetPx = columnWidthPx + columnGapPx
		local headerHeightPx = addon.Utilities:ToPixels(controls.buffDropdown.layoutValues.fieldHeight)
		local positionRowOffsetPx = headerHeightPx + topContentGapPx
		local offsetsRowOffsetPx = positionRowOffsetPx + rowStepPx + anchorToOffsetsGapPx
		local iconSizeRowOffsetPx = offsetsRowOffsetPx + rowStepPx
		local stacksRowOffsetPx = iconSizeRowOffsetPx + rowStepPx + sectionGapPx
		local durationRowOffsetPx = stacksRowOffsetPx + rowStepPx
		local colorTextureRowOffsetPx = durationRowOffsetPx + rowStepPx + sectionGapPx

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		self.emptyText:ClearAllPoints()
		self.emptyText:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)

		if not self.hasSelection then
			return
		end

		local checkboxHeightPx = addon.Utilities:ToPixels(controls.enabledCheckbox.layoutValues.height)
		local sliderHeightPx = addon.Utilities:ToPixels(addon.Options.Controls.Slider.defaultHeight)
		local colorPickerSizePx = addon.Utilities:ToPixels(controls.colorTextureColorPicker.layoutValues.pickerSize)
		local colorPickerFieldTopOffsetPx = math.max(0, sliderHeightPx - colorPickerSizePx)
		local headerCheckboxOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (headerHeightPx - checkboxHeightPx) / 2))
		local checkboxOffsetPx = addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - checkboxHeightPx) / 2))
		local colorTextureCheckboxOffsetPx =
			colorPickerFieldTopOffsetPx
			+ addon.Utilities:RoundToNearestInt(math.max(0, (colorPickerSizePx - checkboxHeightPx) / 2))

		controls.buffDropdown:ClearAllPoints()
		controls.buffDropdown:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)

		controls.enabledCheckbox:ClearAllPoints()
		controls.enabledCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(headerCheckboxOffsetPx)
		)

		controls.anchorDropdown:ClearAllPoints()
		controls.anchorDropdown:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(positionRowOffsetPx))

		controls.iconSizeSlider:ClearAllPoints()
		controls.iconSizeSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(iconSizeRowOffsetPx))

		controls.offsetXSlider:ClearAllPoints()
		controls.offsetXSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(offsetsRowOffsetPx))

		controls.offsetYSlider:ClearAllPoints()
		controls.offsetYSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(offsetsRowOffsetPx)
		)

		controls.showStacksCheckbox:ClearAllPoints()
		controls.showStacksCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(stacksRowOffsetPx + checkboxOffsetPx)
		)

		controls.stacksFontSizeSlider:ClearAllPoints()
		controls.stacksFontSizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(stacksRowOffsetPx)
		)

		controls.showCooldownCheckbox:ClearAllPoints()
		controls.showCooldownCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(durationRowOffsetPx + checkboxOffsetPx)
		)

		controls.cooldownFontSizeSlider:ClearAllPoints()
		controls.cooldownFontSizeSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(durationRowOffsetPx)
		)

		controls.colorTextureCheckbox:ClearAllPoints()
		controls.colorTextureCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			0,
			-addon.Utilities:ToUI(colorTextureRowOffsetPx + colorTextureCheckboxOffsetPx)
		)

		controls.colorTextureColorPicker:ClearAllPoints()
		controls.colorTextureColorPicker:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(colorTextureRowOffsetPx)
		)
	end

	function subpage:UpdateState(profile)
		profile = profile or addon.Database:GetProfile()

		RefreshSelectionState(profile)

		local controls = self.controls
		if not self.hasSelection or not self.activeSpecID or not self.selectedSpellId then
			for key, control in pairs(controls) do
				if key ~= "buffDropdown" then
					control:Hide()
				end
			end
			return
		end

		local mode = addon.Options.State:GetMode()
		local classFileName = addon.Utilities:GetPlayerClassFileName() or ""
		local settings = (((((profile[mode] or {}).widgets or {}).icons or {}).customBuffs or {})[classFileName] or {})[self.activeSpecID]
			or {}
		settings = settings[self.selectedSpellId] or {}
		local defaults = GetBuffDefaults()

		controls.enabledCheckbox:SetChecked(settings.enabled == true)
		controls.anchorDropdown:SetOptions(anchorOptions)
		controls.anchorDropdown:SetValue(settings.anchor or defaults.anchor)
		controls.iconSizeSlider:SetValueSilently(settings.iconSize or defaults.iconSize)
		controls.offsetXSlider:SetValueSilently(settings.offsetX or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(settings.offsetY or defaults.offsetY)
		controls.showStacksCheckbox:SetChecked(settings.showStacks == true)
		controls.stacksFontSizeSlider:SetValueSilently(settings.stacksFontSize or defaults.stacksFontSize)
		controls.showCooldownCheckbox:SetChecked(settings.showCooldown == true)
		controls.cooldownFontSizeSlider:SetValueSilently(settings.cooldownFontSize or defaults.cooldownFontSize)
		controls.colorTextureCheckbox:SetChecked(settings.colorTexture == true)

		local color = settings.colorTextureColor or defaults.colorTextureColor
		controls.colorTextureColorPicker:SetColor(color.r, color.g, color.b, color.a)

		for _, control in pairs(controls) do
			control:Show()
		end
	end

	subpage:UpdateLocale()

	return subpage
end
