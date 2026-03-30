local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Bars = addon.Frames.Widgets.Bars or {}
addon.Frames.Widgets.Bars.BuffOverlay = addon.Frames.Widgets.Bars.BuffOverlay or {}

local BuffOverlay = addon.Frames.Widgets.Bars.BuffOverlay

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local bars = widgets.bars or {}
	local buffOverlays = bars.buffOverlays or {}

	local result = {
		overlayKeys = {},
	}

	for overlayKey, overlaySettings in pairs(buffOverlays) do
		table.insert(result.overlayKeys, overlayKey)
		result[overlayKey] = overlaySettings
	end

	table.sort(result.overlayKeys)
	settingsCache[settings] = result
end

function BuffOverlay:Ensure(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	frame.buffOverlays = frame.buffOverlays or {}

	for index = 1, #cachedSettings.overlayKeys do
		local overlayKey = cachedSettings.overlayKeys[index]
		local overlay = frame.buffOverlays[overlayKey]

		if not overlay then
			overlay = CreateFrame("Frame", nil, frame)
			overlay:SetFrameLevel(4 + index)
			overlay:Hide()

			overlay.texture = overlay:CreateTexture(nil, "ARTWORK")
			overlay.texture:SetAllPoints(overlay)
			overlay.texture:SetColorTexture(1, 1, 1, 1)

			frame.buffOverlays[overlayKey] = overlay
		end
	end
end

function BuffOverlay:UpdateSettings(frame, settings)
	local healthTexture = frame.healthBar:GetStatusBarTexture()

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	for index = 1, #cachedSettings.overlayKeys do
		local overlayKey = cachedSettings.overlayKeys[index]
		local overlay = frame.buffOverlays[overlayKey]

		if overlay then
			overlay:ClearAllPoints()
			overlay:SetPoint("TOPLEFT", healthTexture, "TOPLEFT", 0, 0)
			overlay:SetPoint("BOTTOMRIGHT", healthTexture, "BOTTOMRIGHT", 0, 0)
		end
	end
end

function BuffOverlay:UpdateState(frame, settings)
	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		for _, overlay in pairs(frame.buffOverlays) do
			overlay:Hide()
		end
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	local specID = addon.Utilities:GetPlayerSpecID()
	local defaultAuraValues = addon.Database:GetCustomAuraDefaults() or {}
	local classAuras = defaultAuraValues[addon.Utilities:GetPlayerClassFileName() or ""] or {}
	local specAuras = classAuras[specID] or {}

	local provider = frame.dataProvider
	local auras = provider and provider:GetUnitAuras(frame, "helpfulPlayer") or {}

	for index = 1, #cachedSettings.overlayKeys do
		local overlayKey = cachedSettings.overlayKeys[index]
		local overlay = frame.buffOverlays[overlayKey]
		local overlaySettings = cachedSettings[overlayKey]

		if not overlay or not overlaySettings or not specID then
			if overlay then
				overlay:Hide()
			end
		else
			local specSettings = overlaySettings.bySpec and overlaySettings.bySpec[specID]
			local enabled = specSettings and specSettings.enabled == true
			local spellId = specSettings and specSettings.spellId or 0
			local color = specSettings and specSettings.color or nil

			local ok, isAllowedAura = pcall(function()
				return specAuras[spellId] ~= nil
			end)
			if not ok then
				isAllowedAura = false
			end

			if not enabled or spellId == 0 or not color or not isAllowedAura then
				overlay:Hide()
			else
				local hasBuff = false

				for _, aura in ipairs(auras) do
					local matchesSpell = false
					local ok = pcall(function()
						matchesSpell = aura.spellId == spellId
					end)

					if ok and matchesSpell then
						hasBuff = true
						break
					end
				end

				if hasBuff then
					overlay.texture:SetColorTexture(color.r or 1, color.g or 1, color.b or 1, 1)
					overlay:Show()
				else
					overlay:Hide()
				end
			end
		end
	end
end

function BuffOverlay:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "buffOverlaySettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
