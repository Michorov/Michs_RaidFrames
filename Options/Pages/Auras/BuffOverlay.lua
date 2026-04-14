local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.BuffOverlay = addon.Options.Pages.Auras.BuffOverlay or {}

local BuffOverlay = addon.Options.Pages.Auras.BuffOverlay

local subpage
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
	print("|cffff9900Mich's RaidFrames:|r Buff overlay settings are disabled during combat.")
end

local function GetCurrentSpecOverlayData(profile)
	profile = profile or addon.Database:GetProfile()

	local mode = GetModeKey()
	local section = profile[mode] or {}
	local widgets = section.widgets or {}
	local bars = widgets.bars or {}
	local buffOverlays = bars.buffOverlays or {}
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
		table.insert(spellEntries, {
			spellId = spellId,
			name = auraData.name or ("Spell " .. tostring(spellId)),
		})
	end

	table.sort(spellEntries, function(a, b)
		return string.lower(a.name) < string.lower(b.name)
	end)

	local spellOptions = {
		{
			text = "None",
			value = 0,
		},
	}

	for _, entry in ipairs(spellEntries) do
		table.insert(spellOptions, {
			text = entry.name,
			value = entry.spellId,
		})
	end

	local overlayKeys = {}
	for overlayKey in pairs(buffOverlays) do
		table.insert(overlayKeys, overlayKey)
	end
	table.sort(overlayKeys)

	for _, overlayKey in ipairs(overlayKeys) do
		local overlay = buffOverlays[overlayKey] or {}
		local bySpec = overlay.bySpec or {}
		local specSettings = bySpec[specID] or {}

		table.insert(rows, {
			overlayKey = overlayKey,
			enabled = specSettings.enabled == true,
			spellId = specSettings.spellId or 0,
			color = specSettings.color or { r = 1, g = 1, b = 1 },
			spellOptions = spellOptions,
		})
	end

	return {
		specID = specID,
		specName = specName,
		rows = rows,
	}
end

local function EnsureRowPool(targetCount)
	subpage.dynamicRows = subpage.dynamicRows or {}

	while #subpage.dynamicRows < targetCount do
		local row = {}

		row.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, "Enabled")
		row.enabledCheckbox:SetLayoutWidth(110)
		row.enabledCheckbox:SetOnValueChanged(function(self, checked)
			if InCombatLockdown() then
				ShowCombatLockMessage()
				if subpage and subpage.UpdateState then
					subpage:UpdateState(addon.Database:GetProfile())
				end
				return
			end

			if not self.overlayKey or not self.specID then
				return
			end

			local profile = addon.Database:GetProfile()
			local mode = GetModeKey()

			profile[mode] = profile[mode] or {}
			profile[mode].widgets = profile[mode].widgets or {}
			profile[mode].widgets.bars = profile[mode].widgets.bars or {}
			profile[mode].widgets.bars.buffOverlays = profile[mode].widgets.bars.buffOverlays or {}
			profile[mode].widgets.bars.buffOverlays[self.overlayKey] =
				profile[mode].widgets.bars.buffOverlays[self.overlayKey] or {}

			local overlay = profile[mode].widgets.bars.buffOverlays[self.overlayKey]
			overlay.bySpec = overlay.bySpec or {}
			overlay.bySpec[self.specID] = overlay.bySpec[self.specID]
				or {
					enabled = false,
					spellId = 0,
					color = { r = 1, g = 1, b = 1 },
				}
			overlay.bySpec[self.specID].enabled = checked == true

			addon.UpdateScheduler:Notify("buffOverlaySettingsChanged")
			addon.UpdateScheduler:Notify("aurasStateChanged")
		end)

		row.spellDropdown = addon.Options.Controls.Dropdown:Create(subpage, "Buff")
		row.spellDropdown:SetLayoutWidth(174)
		row.spellDropdown:SetLabelVisible(false)
		row.spellDropdown:SetOnValueChanged(function(self, value)
			if InCombatLockdown() then
				ShowCombatLockMessage()
				if subpage and subpage.UpdateState then
					subpage:UpdateState(addon.Database:GetProfile())
				end
				return
			end

			if not self.overlayKey or not self.specID then
				return
			end

			local profile = addon.Database:GetProfile()
			local mode = GetModeKey()

			profile[mode] = profile[mode] or {}
			profile[mode].widgets = profile[mode].widgets or {}
			profile[mode].widgets.bars = profile[mode].widgets.bars or {}
			profile[mode].widgets.bars.buffOverlays = profile[mode].widgets.bars.buffOverlays or {}
			profile[mode].widgets.bars.buffOverlays[self.overlayKey] =
				profile[mode].widgets.bars.buffOverlays[self.overlayKey] or {}

			local overlay = profile[mode].widgets.bars.buffOverlays[self.overlayKey]
			overlay.bySpec = overlay.bySpec or {}
			overlay.bySpec[self.specID] = overlay.bySpec[self.specID]
				or {
					enabled = false,
					spellId = 0,
					color = { r = 1, g = 1, b = 1 },
				}
			overlay.bySpec[self.specID].spellId = value or 0

			addon.UpdateScheduler:Notify("buffOverlaySettingsChanged")
			addon.UpdateScheduler:Notify("aurasStateChanged")
		end)

		row.colorPicker = addon.Options.Controls.ColorPicker:Create(subpage, "Color")
		row.colorPicker:SetLayoutWidth(96)
		row.colorPicker:SetOnValueChanged(function(self, r, g, b)
			if InCombatLockdown() then
				ShowCombatLockMessage()
				if subpage and subpage.UpdateState then
					subpage:UpdateState(addon.Database:GetProfile())
				end
				return
			end

			if not self.overlayKey or not self.specID then
				return
			end

			local profile = addon.Database:GetProfile()
			local mode = GetModeKey()

			profile[mode] = profile[mode] or {}
			profile[mode].widgets = profile[mode].widgets or {}
			profile[mode].widgets.bars = profile[mode].widgets.bars or {}
			profile[mode].widgets.bars.buffOverlays = profile[mode].widgets.bars.buffOverlays or {}
			profile[mode].widgets.bars.buffOverlays[self.overlayKey] =
				profile[mode].widgets.bars.buffOverlays[self.overlayKey] or {}

			local overlay = profile[mode].widgets.bars.buffOverlays[self.overlayKey]
			overlay.bySpec = overlay.bySpec or {}
			overlay.bySpec[self.specID] = overlay.bySpec[self.specID]
				or {
					enabled = false,
					spellId = 0,
					color = { r = 1, g = 1, b = 1 },
				}
			overlay.bySpec[self.specID].color = {
				r = r,
				g = g,
				b = b,
			}

			addon.UpdateScheduler:Notify("buffOverlaySettingsChanged")
			addon.UpdateScheduler:Notify("aurasStateChanged")
		end)

		table.insert(subpage.dynamicRows, row)
	end
end

local function RefreshDynamicRows(profile)
	local currentSpec = GetCurrentSpecOverlayData(profile)
	local rows = currentSpec.rows

	EnsureRowPool(#rows)
	subpage.activeRows = rows
	subpage.activeSpecID = currentSpec.specID
	subpage.activeSpecName = currentSpec.specName

	for index, row in ipairs(subpage.dynamicRows) do
		local entry = rows[index]

		if entry then
			row.enabledCheckbox.overlayKey = entry.overlayKey
			row.enabledCheckbox.specID = currentSpec.specID
			row.enabledCheckbox:SetChecked(entry.enabled)
			row.enabledCheckbox:Show()

			row.spellDropdown.overlayKey = entry.overlayKey
			row.spellDropdown.specID = currentSpec.specID
			row.spellDropdown:SetOptions(entry.spellOptions)
			row.spellDropdown:SetValue(entry.spellId)
			row.spellDropdown:Show()

			row.colorPicker.overlayKey = entry.overlayKey
			row.colorPicker.specID = currentSpec.specID
			row.colorPicker:SetColor(entry.color.r or 1, entry.color.g or 1, entry.color.b or 1, 1)
			row.colorPicker:Show()
		else
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

	if currentSpec.specName and #rows == 0 then
		subpage.emptyText:Show()
	else
		subpage.emptyText:Hide()
	end
end

function BuffOverlay:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.emptyText = subpage:CreateFontString(nil, "OVERLAY")
	subpage.emptyText:SetJustifyH("LEFT")
	subpage.emptyText:SetFont(theme.fonts.arialNarrow, 14, "")
	subpage.emptyText:SetTextColor(theme:GetTextColor("secondary"))
	subpage.emptyText:SetText("No overlays available for this specialization")
	subpage.emptyText:Hide()

	function subpage:UpdateLayout()
		local rowStepPx = addon.Utilities:ToPixels(40)
		local checkboxToDropdownGapPx = addon.Utilities:ToPixels(12)
		local dropdownToColorGapPx = addon.Utilities:ToPixels(10)

		RefreshDynamicRows(addon.Database:GetProfile())

		self.emptyText:ClearAllPoints()
		self.emptyText:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)

		for index, row in ipairs(self.dynamicRows or {}) do
			local entry = self.activeRows[index]

			if row.enabledCheckbox.UpdateLayout then
				row.enabledCheckbox:UpdateLayout()
			end
			if row.spellDropdown.UpdateLayout then
				row.spellDropdown:UpdateLayout()
			end
			if row.colorPicker.UpdateLayout then
				row.colorPicker:UpdateLayout()
			end

			if entry then
				local checkboxHeightPx = addon.Utilities:ToPixels(row.enabledCheckbox.layoutValues.height)
				local dropdownHeightPx = addon.Utilities:ToPixels(row.spellDropdown.layoutValues.fieldHeight)
				local checkboxOffsetPx =
					addon.Utilities:RoundToNearestInt(math.max(0, (dropdownHeightPx - checkboxHeightPx) / 2))
				local checkboxWidthPx = addon.Utilities:ToPixels(row.enabledCheckbox.layoutValues.width)
				local dropdownWidthPx = addon.Utilities:ToPixels(row.spellDropdown.layoutValues.width)
				local dropdownOffsetPx = checkboxWidthPx + checkboxToDropdownGapPx
				local colorOffsetPx = dropdownOffsetPx + dropdownWidthPx + dropdownToColorGapPx
				local rowOffsetPx = (index - 1) * rowStepPx

				row.enabledCheckbox:ClearAllPoints()
				row.enabledCheckbox:SetPoint(
					"TOPLEFT",
					self,
					"TOPLEFT",
					0,
					-addon.Utilities:ToUI(rowOffsetPx + checkboxOffsetPx)
				)

				row.spellDropdown:ClearAllPoints()
				row.spellDropdown:SetPoint(
					"TOPLEFT",
					self,
					"TOPLEFT",
					addon.Utilities:ToUI(dropdownOffsetPx),
					-addon.Utilities:ToUI(rowOffsetPx)
				)

				row.colorPicker:ClearAllPoints()
				row.colorPicker:SetPoint(
					"TOPLEFT",
					self,
					"TOPLEFT",
					addon.Utilities:ToUI(colorOffsetPx),
					-addon.Utilities:ToUI(rowOffsetPx)
				)
			end
		end
	end

	function subpage:UpdateState(profile)
		RefreshDynamicRows(profile)
	end

	return subpage
end
