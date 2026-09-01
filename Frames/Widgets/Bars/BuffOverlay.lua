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

function BuffOverlay:Ensure(frame)
	if addon.IsRestrictedAuraAPI and frame.frameType ~= "preview" then
		return
	end

	frame.buffOverlays = frame.buffOverlays or {}

	local overlay = frame.buffOverlays.overlay1

	if not overlay then
		overlay = CreateFrame("Frame", nil, frame)
		overlay:SetFrameLevel(5)
		overlay:Hide()

		overlay.texture = overlay:CreateTexture(nil, "ARTWORK")
		overlay.texture:SetAllPoints(overlay)
		overlay.texture:SetColorTexture(1, 1, 1, 1)

		frame.buffOverlays.overlay1 = overlay
	end
end

function BuffOverlay:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if addon.IsRestrictedAuraAPI and frame.frameType ~= "preview" then
		return
	end

	local healthTexture = frame.healthBar:GetStatusBarTexture()

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
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if addon.IsRestrictedAuraAPI and frame.frameType ~= "preview" then
		return
	end

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.buffOverlay ~= true then
		for _, overlay in pairs(frame.buffOverlays) do
			overlay:Hide()
		end
		return
	end

	local provider = frame.dataProvider
	if not provider then
		for _, overlay in pairs(frame.buffOverlays) do
			overlay:Hide()
		end
		return
	end

	local isTestProvider = provider == addon.Frames.DataProvider.Test
	local unit = frame.unit
	if not isTestProvider and (not unit or not UnitExists(unit)) then
		for _, overlay in pairs(frame.buffOverlays) do
			overlay:Hide()
		end
		return
	end

	local specID = addon.Utilities:GetPlayerSpecID()
	local defaultAuraValues = addon.Database:GetCustomAuraDefaults() or {}
	local classAuras = defaultAuraValues[addon.Utilities:GetPlayerClassFileName() or ""] or {}
	local specAuras = classAuras[specID] or {}

	local auras = isTestProvider and nil or provider:GetUnitAuras(frame, "helpfulPlayer")

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

			if not enabled or not color or (not isTestProvider and (spellId == 0 or not isAllowedAura)) then
				overlay:Hide()
			else
				local hasBuff = isTestProvider

				if not isTestProvider then
					for _, aura in pairs(auras) do
						local matchesSpell = false
						local ok = pcall(function()
							matchesSpell = aura.spellId == spellId
						end)

						if ok and matchesSpell then
							hasBuff = true
							break
						end
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
