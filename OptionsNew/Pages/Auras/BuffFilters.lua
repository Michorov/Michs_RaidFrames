local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Auras = addon.OptionsNew.Pages.Auras or {}
addon.OptionsNew.Pages.Auras.BuffFilters = addon.OptionsNew.Pages.Auras.BuffFilters or {}

local BuffFilters = addon.OptionsNew.Pages.Auras.BuffFilters
local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)

local layoutValues = {
	rowHeight = 24,
	rowOffset = 24,
	columns = 2,
}

local function GetAuraDisplayName(spellId, fallbackName)
	if addon.Locale and addon.Locale.GetAuraDisplayName then
		return addon.Locale:GetAuraDisplayName(spellId, fallbackName)
	end

	return fallbackName
end

local function GetCurrentAuraEntries(profile, mode)
	local section = profile[mode]
	local customAuraValues = section.widgets.icons.buffs.customAuraValues
	local classFileName = addon.Utilities:GetPlayerClassFileName() or ""
	local classValues = customAuraValues[classFileName] or {}
	local specID = addon.Utilities:GetPlayerSpecID()
	local specName = specID and (select(2, GetSpecializationInfoByID(specID)) or ("Spec " .. tostring(specID))) or nil
	local specValues = (specID and classValues[specID]) or nil
	local entries = {}

	if not specID or type(specValues) ~= "table" then
		return {
			specID = specID,
			specName = specName,
			entries = entries,
		}
	end

	for spellId, auraData in pairs(specValues) do
		local fallbackName = auraData.name or ("Spell " .. tostring(spellId))

		entries[#entries + 1] = {
			specID = specID,
			spellId = spellId,
			name = GetAuraDisplayName(spellId, fallbackName),
			enabled = auraData.enabled == true,
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

function BuffFilters:Create(page)
	local subpage = page:RegisterSubPage("buffFilters", { titleKey = "Buffs - Filters" })
	local panel = page.panel

	subpage.filterRows = {}

	subpage.emptyText = subpage.frame:CreateFontString(nil, "OVERLAY")
	subpage.emptyText:SetJustifyH("LEFT")
	subpage.emptyText:SetTextColor(OptionsUILib.Theme:GetTextColor("secondary"))
	OptionsUILib.Theme:ApplyFont(subpage.emptyText, panel.instance.PP:ScaleFont(14), "")
	subpage.emptyText:SetText(panel:Localize("No filter found for this specialization"))
	subpage.emptyText:Hide()

	local function EnsureFilterEntry(profile, mode, specID, spellId)
		local buffs = profile[mode].widgets.icons.buffs
		local classFileName = addon.Utilities:GetPlayerClassFileName() or ""

		buffs.customAuraValues[classFileName] = buffs.customAuraValues[classFileName] or {}
		buffs.customAuraValues[classFileName][specID] = buffs.customAuraValues[classFileName][specID] or {}
		buffs.customAuraValues[classFileName][specID][spellId] = buffs.customAuraValues[classFileName][specID][spellId] or {}

		return buffs.customAuraValues[classFileName][specID][spellId]
	end

	local function EnsureRowPool(targetCount)
		while #subpage.filterRows < targetCount do
			local layoutRow = subpage:CreateRow(layoutValues.columns)
			layoutRow:SetLayoutHeight(layoutValues.rowHeight)

			local slot = layoutRow:CreateCheckboxSlot("top")
			local checkbox = slot:CreateControl("Checkbox", "")
			checkbox:SetOnValueChanged(function(control, checked)
				if not control.specID or not control.spellId then
					return
				end

				panel:UpdateValue(function(profile, mode)
					local filterEntry = EnsureFilterEntry(profile, mode, control.specID, control.spellId)
					filterEntry.enabled = checked == true
				end)

				addon.UpdateScheduler:Notify("buffAuraFiltersChanged")
				addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
				addon.UpdateScheduler:Notify("aurasStateChanged")
			end)

			local row = {
				layoutRow = layoutRow,
				checkbox = checkbox,
			}

			subpage.filterRows[#subpage.filterRows + 1] = row
		end
	end

	local function RefreshRows(profile, mode)
		local currentSpec = GetCurrentAuraEntries(profile, mode)
		local entries = currentSpec.entries

		EnsureRowPool(#entries)

		for rowIndex, row in ipairs(subpage.filterRows) do
			local entry = entries[rowIndex]
			local offsetY = -((rowIndex - 1) * layoutValues.rowOffset)

			if entry then
				row.layoutRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, offsetY)
				row.layoutRow.frame:Show()

				row.checkbox.specID = entry.specID
				row.checkbox.spellId = entry.spellId
				row.checkbox:SetText(entry.name)
				row.checkbox:SetChecked(entry.enabled)
				row.checkbox:Show()
			else
				row.checkbox.specID = nil
				row.checkbox.spellId = nil
				row.checkbox:Hide()
				row.layoutRow.frame:Hide()
			end
		end

		subpage.emptyText:SetShown(currentSpec.specName ~= nil and #entries == 0)
	end

	subpage:SetStateUpdater(function(profile, mode)
		RefreshRows(profile, mode)
	end)

	local baseUpdateLocale = subpage.UpdateLocale
	function subpage:UpdateLocale()
		baseUpdateLocale(self)
		self.emptyText:SetText(panel:Localize("No filter found for this specialization"))
		RefreshRows(panel.profileGetter(panel), panel:GetActiveMode())
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
