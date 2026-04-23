local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.BuffFilters = addon.Options.Pages.Auras.BuffFilters or {}

local BuffFilters = addon.Options.Pages.Auras.BuffFilters

local subpage
local L = addon.L
local theme = addon.Options.Theme

local function GetControllerState()
	local content = addon.Options.Sections.Content
	if content and content.GetControllerState then
		return content:GetControllerState()
	end

	addon.Options.ControllerState = addon.Options.ControllerState
		or {
			mode = "party",
			subpages = {
				auras = "buffs",
				texts = "name",
				indicators = "readyCheck",
				bars = "health",
			},
		}

	return addon.Options.ControllerState
end

local function GetModeKey()
	local state = GetControllerState()
	return state.mode == "raid" and "raid" or "party"
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Buff filters are disabled during combat."])
end

local function GetAuraDisplayName(spellId, fallbackName)
	if addon.Locale and addon.Locale.GetAuraDisplayName then
		return addon.Locale:GetAuraDisplayName(spellId, fallbackName)
	end

	return fallbackName
end

local function GetCurrentAuraEntries(profile)
	profile = profile or addon.Database:GetProfile()

	local mode = GetModeKey()
	local section = profile[mode] or {}
	local widgets = section.widgets or {}
	local icons = widgets.icons or {}
	local buffs = icons.buffs or {}
	local customAuraValues = buffs.customAuraValues or {}
	local classFileName = addon.Utilities:GetPlayerClassFileName() or ""
	local classValues = customAuraValues[classFileName] or {}
	local specID = addon.Utilities:GetPlayerSpecID()
	local specValues = (specID and classValues[specID]) or nil
	local entries = {}
	local specName = specID and (select(2, GetSpecializationInfoByID(specID)) or ("Spec " .. tostring(specID))) or nil

	if not specID then
		return {
			specID = nil,
			specName = nil,
			entries = entries,
		}
	end

	if type(specValues) ~= "table" then
		return {
			specID = specID,
			specName = specName,
			entries = entries,
		}
	end

	for spellId, auraData in pairs(specValues) do
		local fallbackName = auraData.name or ("Spell " .. tostring(spellId))

		table.insert(entries, {
			specID = specID,
			spellId = spellId,
			name = GetAuraDisplayName(spellId, fallbackName),
			enabled = auraData.enabled == true,
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

local function EnsureCheckboxPool(targetCount)
	subpage.dynamicCheckboxes = subpage.dynamicCheckboxes or {}

	while #subpage.dynamicCheckboxes < targetCount do
		local checkbox = addon.Options.Controls.Checkbox:Create(subpage, "")
		checkbox:SetLayoutWidth(174)
		checkbox:SetOnValueChanged(function(self, checked)
			if InCombatLockdown() then
				ShowCombatLockMessage()
				if subpage and subpage.UpdateState then
					subpage:UpdateState(addon.Database:GetProfile())
				end
				return
			end

			if not self.specID or not self.spellId then
				return
			end

			local profile = addon.Database:GetProfile()
			local mode = GetModeKey()
			local classFileName = addon.Utilities:GetPlayerClassFileName() or ""

			profile[mode] = profile[mode] or {}
			profile[mode].widgets = profile[mode].widgets or {}
			profile[mode].widgets.icons = profile[mode].widgets.icons or {}
			profile[mode].widgets.icons.buffs = profile[mode].widgets.icons.buffs or {}

			local buffs = profile[mode].widgets.icons.buffs
			buffs.customAuraValues = buffs.customAuraValues or {}
			buffs.customAuraValues[classFileName] = buffs.customAuraValues[classFileName] or {}
			buffs.customAuraValues[classFileName][self.specID] = buffs.customAuraValues[classFileName][self.specID] or {}
			buffs.customAuraValues[classFileName][self.specID][self.spellId] =
				buffs.customAuraValues[classFileName][self.specID][self.spellId] or {}
			buffs.customAuraValues[classFileName][self.specID][self.spellId].enabled = checked == true

			addon.UpdateScheduler:Notify("buffAurasSettingsChanged")
			addon.UpdateScheduler:Notify("aurasStateChanged")
		end)

		table.insert(subpage.dynamicCheckboxes, checkbox)
	end
end

local function RefreshDynamicCheckboxes(profile)
	local currentSpec = GetCurrentAuraEntries(profile)
	local entries = currentSpec.entries

	EnsureCheckboxPool(#entries)
	subpage.activeEntries = entries
	subpage.activeSpecID = currentSpec.specID
	subpage.activeSpecName = currentSpec.specName

	for index, checkbox in ipairs(subpage.dynamicCheckboxes) do
		local entry = entries[index]

		if entry then
			checkbox.specID = entry.specID
			checkbox.spellId = entry.spellId
			checkbox:SetText(entry.name)
			checkbox:SetChecked(entry.enabled)
			checkbox:Show()
		else
			checkbox.specID = nil
			checkbox.spellId = nil
			checkbox:Hide()
		end
	end

	if currentSpec.specName and #entries == 0 then
		subpage.emptyText:Show()
	else
		subpage.emptyText:Hide()
	end
end

function BuffFilters:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.emptyText = subpage:CreateFontString(nil, "OVERLAY")
	subpage.emptyText:SetJustifyH("LEFT")
	theme:ApplyFont(subpage.emptyText, "arialNarrow", 14, "")
	subpage.emptyText:SetTextColor(theme:GetTextColor("secondary"))
	subpage.emptyText:SetText(L["No filter found for this specialization"])
	subpage.emptyText:Hide()

	function subpage:UpdateLocale()
		self.emptyText:SetText(L["No filter found for this specialization"])
		RefreshDynamicCheckboxes(addon.Database:GetProfile())
	end

	function subpage:UpdateLayout()
		local rowStepPx = addon.Utilities:ToPixels(24)

		RefreshDynamicCheckboxes(addon.Database:GetProfile())

		self.emptyText:ClearAllPoints()
		self.emptyText:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)

		for index, checkbox in ipairs(self.dynamicCheckboxes or {}) do
			local entry = self.activeEntries[index]
			if checkbox.UpdateLayout then
				checkbox:UpdateLayout()
			end

			if entry then
				checkbox:ClearAllPoints()
				checkbox:SetPoint(
					"TOPLEFT",
					self,
					"TOPLEFT",
					0,
					-addon.Utilities:ToUI((index - 1) * rowStepPx)
				)
			end
		end
	end

	function subpage:UpdateState(profile)
		RefreshDynamicCheckboxes(profile)
	end

	subpage:UpdateLocale()

	return subpage
end
