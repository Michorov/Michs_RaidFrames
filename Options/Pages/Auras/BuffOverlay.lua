local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.BuffOverlay = addon.Options.Pages.Auras.BuffOverlay or {}

local BuffOverlay = addon.Options.Pages.Auras.BuffOverlay
local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)

local layoutValues = {
	rowHeight = 88,
	columnWidth = 132,
	columnGap = 16,
	controlHeight = 24,
	controlRowHeight = 44,
}

local function GetAuraDisplayName(spellId, fallbackName)
	if addon.Locale and addon.Locale.GetAuraDisplayName then
		return addon.Locale:GetAuraDisplayName(spellId, fallbackName)
	end

	return fallbackName
end

local function EnsureOverlaySpec(profile, mode, overlayKey, specID)
	profile[mode].widgets.bars.buffOverlays[overlayKey] = profile[mode].widgets.bars.buffOverlays[overlayKey] or {}

	local overlay = profile[mode].widgets.bars.buffOverlays[overlayKey]
	overlay.bySpec = overlay.bySpec or {}
	overlay.bySpec[specID] = overlay.bySpec[specID]
		or {
			enabled = false,
			spellId = 0,
			color = { r = 1, g = 1, b = 1 },
		}

	return overlay.bySpec[specID]
end

local function GetCurrentSpecOverlayData(profile, mode, panel)
	local section = profile[mode]
	local buffOverlays = section.widgets.bars.buffOverlays
	local classFileName = addon.Utilities:GetPlayerClassFileName() or ""
	local defaultAuraValues = addon.Database:GetCustomAuraDefaults() or {}
	local classAuras = defaultAuraValues[classFileName] or {}
	local specID = addon.Utilities:GetPlayerSpecID()
	local specName = specID and (select(2, GetSpecializationInfoByID(specID)) or ("Spec " .. tostring(specID))) or nil
	local specAuras = (specID and classAuras[specID]) or nil
	local rows = {}

	if not specID then
		return {
			specID = nil,
			specName = nil,
			rows = rows,
		}
	end

	if type(specAuras) ~= "table" or next(specAuras) == nil then
		return {
			specID = specID,
			specName = specName,
			rows = rows,
		}
	end

	local spellEntries = {}
	for spellId, auraData in pairs(specAuras) do
		local fallbackName = auraData.name or ("Spell " .. tostring(spellId))

		spellEntries[#spellEntries + 1] = {
			spellId = spellId,
			name = GetAuraDisplayName(spellId, fallbackName),
		}
	end

	table.sort(spellEntries, function(a, b)
		return string.lower(a.name) < string.lower(b.name)
	end)

	local spellOptions = {
		{
			text = panel:Localize("None"),
			value = 0,
		},
	}

	for _, entry in ipairs(spellEntries) do
		spellOptions[#spellOptions + 1] = {
			text = entry.name,
			value = entry.spellId,
		}
	end

	local overlayKeys = {}
	for overlayKey in pairs(buffOverlays) do
		overlayKeys[#overlayKeys + 1] = overlayKey
	end
	table.sort(overlayKeys)

	for _, overlayKey in ipairs(overlayKeys) do
		local overlay = buffOverlays[overlayKey]
		local specSettings = overlay.bySpec and overlay.bySpec[specID] or {}

		rows[#rows + 1] = {
			overlayKey = overlayKey,
			enabled = specSettings.enabled == true,
			spellId = specSettings.spellId or 0,
			color = specSettings.color or { r = 1, g = 1, b = 1 },
			spellOptions = spellOptions,
		}
	end

	return {
		specID = specID,
		specName = specName,
		rows = rows,
	}
end

function BuffOverlay:Create(page)
	local subpage = page:RegisterSubPage("buffOverlay", { titleKey = "Buffs - Overlay" })
	local panel = page.panel

	subpage.overlayRows = {}

	subpage.emptyText = subpage.frame:CreateFontString(nil, "OVERLAY")
	subpage.emptyText:SetJustifyH("LEFT")
	subpage.emptyText:SetTextColor(OptionsUILib.Theme:GetTextColor("secondary"))
	OptionsUILib.Theme:ApplyFont(subpage.emptyText, panel.instance.PP:ScaleFont(14), "")
	subpage.emptyText:SetText(panel:Localize("No overlays available for this specialization"))
	subpage.emptyText:Hide()

	local function UpdateOverlaySetting(overlayKey, specID, callback)
		panel:UpdateValue(function(profile, mode)
			callback(EnsureOverlaySpec(profile, mode, overlayKey, specID))
		end)

		addon.UpdateScheduler:Notify("buffOverlaySettingsChanged")
		addon.UpdateScheduler:Notify("aurasStateChanged")
	end

	local function EnsureRowPool(targetCount)
		while #subpage.overlayRows < targetCount do
			local row = {}

			row.checkboxRow = subpage:CreateRow(4)
			row.checkboxSlot = row.checkboxRow:CreateCheckboxSlot("top")
			row.enabledCheckbox = row.checkboxSlot:CreateControl("Checkbox", { labelKey = "Enabled" })
			row.enabledCheckbox:SetOnValueChanged(function(control, checked)
				if not control.overlayKey or not control.specID then
					return
				end

				UpdateOverlaySetting(control.overlayKey, control.specID, function(specSettings)
					specSettings.enabled = checked == true
				end)
			end)

			row.spellDropdown = subpage:CreateControl("Dropdown", { labelKey = "Buff" })
			row.spellDropdown:SetLabelVisible(false)
			row.spellDropdown:SetLayoutWidth(layoutValues.columnWidth)
			row.spellDropdown:SetLayoutHeight(layoutValues.controlHeight)
			row.spellDropdown:SetOnValueChanged(function(control, value)
				if not control.overlayKey or not control.specID then
					return
				end

				UpdateOverlaySetting(control.overlayKey, control.specID, function(specSettings)
					specSettings.spellId = value or 0
				end)
			end)

			row.colorPicker = subpage:CreateControl("ColorPicker", { labelKey = "Color" })
			row.colorPicker:SetLabelVisible(false)
			row.colorPicker:SetLayoutWidth(layoutValues.columnWidth)
			row.colorPicker:SetLayoutHeight(layoutValues.controlHeight)
			row.colorPicker:SetHasOpacity(false)
			row.colorPicker:SetOnValueChanged(function(control, r, g, b)
				if not control.overlayKey or not control.specID then
					return
				end

				UpdateOverlaySetting(control.overlayKey, control.specID, function(specSettings)
					specSettings.color = { r = r, g = g, b = b }
				end)
			end)

			subpage.overlayRows[#subpage.overlayRows + 1] = row
		end
	end

	local function RefreshRows(profile, mode)
		local currentSpec = GetCurrentSpecOverlayData(profile, mode, panel)
		local rows = currentSpec.rows
		local secondColumnOffsetX = layoutValues.columnWidth + layoutValues.columnGap

		EnsureRowPool(#rows)

		for index, row in ipairs(subpage.overlayRows) do
			local entry = rows[index]
			local offsetY = -((index - 1) * layoutValues.rowHeight)
			local secondRowOffsetY = offsetY - layoutValues.controlRowHeight

			if entry then
				row.checkboxRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, offsetY)
				row.checkboxRow.frame:Show()

				row.enabledCheckbox.overlayKey = entry.overlayKey
				row.enabledCheckbox.specID = currentSpec.specID
				row.enabledCheckbox:SetChecked(entry.enabled)
				row.enabledCheckbox:Show()

				row.spellDropdown.overlayKey = entry.overlayKey
				row.spellDropdown.specID = currentSpec.specID
				row.spellDropdown:SetOptions(entry.spellOptions)
				row.spellDropdown:SetValue(entry.spellId)
				row.spellDropdown:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, secondRowOffsetY)
				row.spellDropdown:Show()

				row.colorPicker.overlayKey = entry.overlayKey
				row.colorPicker.specID = currentSpec.specID
				row.colorPicker:SetColor(entry.color.r or 1, entry.color.g or 1, entry.color.b or 1, 1)
				row.colorPicker:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", secondColumnOffsetX, secondRowOffsetY)
				row.colorPicker:Show()
			else
				row.checkboxRow.frame:Hide()

				row.enabledCheckbox.overlayKey = nil
				row.enabledCheckbox.specID = nil
				row.enabledCheckbox:Hide()

				row.spellDropdown.overlayKey = nil
				row.spellDropdown.specID = nil
				row.spellDropdown:Hide()

				row.colorPicker.overlayKey = nil
				row.colorPicker.specID = nil
				row.colorPicker:Hide()
			end
		end

		subpage.emptyText:SetShown(currentSpec.specName ~= nil and #rows == 0)
	end

	subpage:SetStateUpdater(function(profile, mode)
		RefreshRows(profile, mode)
	end)

	local baseUpdateLocale = subpage.UpdateLocale
	function subpage:UpdateLocale()
		baseUpdateLocale(self)
		self.emptyText:SetText(panel:Localize("No overlays available for this specialization"))
	end

	local baseUpdateLayout = subpage.UpdateLayout
	function subpage:UpdateLayout()
		baseUpdateLayout(self)

		local PP = panel.instance.PP
		self.emptyText:ClearAllPoints()
		self.emptyText:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
		OptionsUILib.Theme:ApplyFont(self.emptyText, PP:ScaleFont(14), "")
	end

	RefreshRows(panel.profileGetter(panel), panel:GetActiveMode())

	return subpage
end
