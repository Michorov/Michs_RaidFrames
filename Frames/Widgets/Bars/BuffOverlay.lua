local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Bars = addon.Frames.Widgets.Bars or {}
addon.Frames.Widgets.Bars.BuffOverlay = addon.Frames.Widgets.Bars.BuffOverlay or {}

local BuffOverlay = addon.Frames.Widgets.Bars.BuffOverlay

local function GetBuffOverlaySettings(settings)
	local bars = settings and settings.widgets and settings.widgets.bars or {}
	local buffOverlays = bars.buffOverlays or {}
	local normalized = {
		overlayKeys = {},
	}

	for overlayKey, overlaySettings in pairs(buffOverlays) do
		table.insert(normalized.overlayKeys, overlayKey)
		normalized[overlayKey] = overlaySettings
	end

	table.sort(normalized.overlayKeys)
	return normalized
end

local function GetPlayerSpecID()
	local specIndex = GetSpecialization and GetSpecialization()
	if not specIndex then
		return nil
	end

	return select(1, GetSpecializationInfo(specIndex))
end

local function GetPlayerClassFileName()
	local _, classFileName = UnitClass("player")
	return classFileName
end

local function IsAllowedSpecAura(specID, spellId)
	if not specID or not spellId or spellId == 0 then
		return nil
	end

	local defaultAuraValues = addon.Database:GetCustomAuraDefaults() or {}
	local classAuras = defaultAuraValues[GetPlayerClassFileName() or ""] or {}
	local specAuras = classAuras[specID] or {}

	local ok, hasAura = pcall(function()
		return specAuras[spellId] ~= nil
	end)

	if ok then
		return hasAura == true
	end

	return false
end

local function UnitHasPlayerBuffBySpellID(unit, spellId)
	if not unit or not spellId or spellId == 0 then
		return false
	end

	local auraIndex = 1
	while true do
		local aura = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, "HELPFUL")
		if not aura then
			break
		end

		auraIndex = auraIndex + 1

		local matchesSpell = false
		local ok = pcall(function()
			matchesSpell = aura.spellId == spellId
		end)

		if ok and matchesSpell and aura.sourceUnit == "player" then
			return true
		end
	end

	return false
end

function BuffOverlay:Ensure(frame, settings)
	if not frame then
		return
	end

	local healthBar = frame.healthBar
	if not healthBar then
		return
	end

	local buffOverlaySettings = GetBuffOverlaySettings(settings)

	frame.buffOverlays = frame.buffOverlays or {}

	for index = 1, #buffOverlaySettings.overlayKeys do
		local overlayKey = buffOverlaySettings.overlayKeys[index]
		local overlay = frame.buffOverlays[overlayKey]

		if not overlay then
			overlay = CreateFrame("Frame", nil, frame)
			overlay:SetFrameStrata(frame:GetFrameStrata())
			overlay:SetFrameLevel(healthBar:GetFrameLevel() + index)
			overlay:Hide()

			overlay.texture = overlay:CreateTexture(nil, "ARTWORK")
			overlay.texture:SetAllPoints(overlay)
			overlay.texture:SetColorTexture(1, 1, 1, 1)

			frame.buffOverlays[overlayKey] = overlay
		end
	end
end

function BuffOverlay:UpdateSettings(frame, settings)
	local buffOverlays = frame and frame.buffOverlays
	if not buffOverlays then
		return
	end

	local healthBar = frame.healthBar
	if not healthBar then
		return
	end

	local healthTexture = healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
	if not healthTexture then
		return
	end

	local buffOverlaySettings = GetBuffOverlaySettings(settings)
	local specID = GetPlayerSpecID()

	for index = 1, #buffOverlaySettings.overlayKeys do
		local overlayKey = buffOverlaySettings.overlayKeys[index]
		local overlay = buffOverlays[overlayKey]
		local overlaySettings = buffOverlaySettings[overlayKey]

		if overlay then
			local specSettings = overlaySettings and overlaySettings.bySpec and overlaySettings.bySpec[specID] or nil
			overlay:SetFrameLevel(healthBar:GetFrameLevel() + index)
			overlay:ClearAllPoints()
			overlay:SetPoint("TOPLEFT", healthTexture, "TOPLEFT", 0, 0)
			overlay:SetPoint("BOTTOMRIGHT", healthTexture, "BOTTOMRIGHT", 0, 0)
		end
	end
end

function BuffOverlay:UpdateState(frame, settings)
	if not frame or not frame.buffOverlays then
		return
	end

	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		for _, overlay in pairs(frame.buffOverlays) do
			overlay:Hide()
		end
		return
	end

	local buffOverlaySettings = GetBuffOverlaySettings(settings)
	local specID = GetPlayerSpecID()

	for index = 1, #buffOverlaySettings.overlayKeys do
		local overlayKey = buffOverlaySettings.overlayKeys[index]
		local overlay = frame.buffOverlays[overlayKey]
		local overlaySettings = buffOverlaySettings[overlayKey]

		if not overlay or not overlaySettings or not specID then
			if overlay then
				overlay:Hide()
			end
		else
			local specSettings = overlaySettings.bySpec and overlaySettings.bySpec[specID]
			local enabled = specSettings and specSettings.enabled == true
			local spellId = specSettings and specSettings.spellId or 0
			local color = specSettings and specSettings.color or nil
			local isAllowedAura = IsAllowedSpecAura(specID, spellId)

			if not enabled or spellId == 0 or not color or not isAllowedAura then
				overlay:Hide()
			else
				local hasBuff = UnitHasPlayerBuffBySpellID(unit, spellId)

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
