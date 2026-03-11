local _, addon = ...

local Updater = {}
addon.Updater = Updater

local initialized = false

local function BuildSettingsUpdater(updateReasons)
	if updateReasons.outOfRangeAlphaSettingChanged then
		addon.Frames.RangeChecker:UpdateSettings()
	end

	if updateReasons.soloFrameChanged then
		addon.FrameRegistry:UpdateStateDrivers()
	end

	return function(frame, settings)
		if updateReasons.backgroundSettingsChanged then
			addon.Frames.Base.Background:UpdateSettings(frame, settings)
		end

		if updateReasons.healthSettingsChanged then
			addon.Frames.Base.Health:UpdateSettings(frame, settings)
		end

		if updateReasons.powerSettingsChanged then
			addon.Frames.Base.Power:UpdateSettings(frame, settings)
		end

		if updateReasons.borderSettingsChanged then
			addon.Frames.Base.Border:UpdateSettings(frame, settings)
		end

		if updateReasons.readyCheckSettingsChanged then
			addon.Frames.Widgets.Indicators.ReadyCheck:UpdateSettings(frame, settings)
		end

		if updateReasons.pendingSummonSettingsChanged then
			addon.Frames.Widgets.Indicators.PendingSummon:UpdateSettings(frame, settings)
		end

		if updateReasons.nameSettingsChanged then
			addon.Frames.Widgets.Texts.Name:UpdateSettings(frame, settings)
		end

		if updateReasons.absorbsSettingsChanged then
			addon.Frames.Widgets.Bars.Absorbs:UpdateSettings(frame, settings)
		end

		if updateReasons.healAbsorbsSettingsChanged then
			addon.Frames.Widgets.Bars.HealAbsorbs:UpdateSettings(frame, settings)
		end

		if updateReasons.buffAurasSettingsChanged then
			addon.Frames.Widgets.Icons.Buffs:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.Buffs:UpdateState(frame, settings)
		end

		if updateReasons.buffOverlaySettingsChanged then
			addon.Frames.Widgets.Bars.BuffOverlay:UpdateSettings(frame, settings)
		end

		if updateReasons.debuffAurasSettingsChanged then
			addon.Frames.Widgets.Icons.Debuffs:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.Debuffs:UpdateState(frame, settings)
		end

		if updateReasons.bigDefensiveAurasSettingsChanged then
			addon.Frames.Widgets.Icons.BigDefensive:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.BigDefensive:UpdateState(frame, settings)
		end

		if updateReasons.privateAurasSettingsChanged then
			addon.Frames.Widgets.Icons.PrivateAuras:UpdateSettings(frame, settings)
		end

		if updateReasons.dispelsSettingsChanged then
			addon.Frames.Widgets.Indicators.Dispels:UpdateSettings(frame, settings)
		end
	end
end

local function BuildStateUpdater(updateReasons)
	return function(frame, settings)
		if updateReasons.rosterChanged or updateReasons.healthStateChanged then
			addon.Frames.Base.Health:UpdateState(frame, settings)
		end

		if updateReasons.rosterChanged or updateReasons.powerStateChanged or updateReasons.powerSettingsChanged then
			addon.Frames.Base.Power:UpdateState(frame, settings)
		end

		if updateReasons.rosterChanged or updateReasons.nameStateChanged or updateReasons.healthStateChanged then
			addon.Frames.Widgets.Texts.Name:UpdateState(frame, settings)
		end

		if updateReasons.rosterChanged or updateReasons.readyCheckStateChanged then
			addon.Frames.Widgets.Indicators.ReadyCheck:UpdateState(frame, settings)
		end

		if updateReasons.rosterChanged or updateReasons.pendingSummonStateChanged then
			addon.Frames.Widgets.Indicators.PendingSummon:UpdateState(frame, settings)
		end

		if updateReasons.rosterChanged or updateReasons.absorbsStateChanged then
			addon.Frames.Widgets.Bars.Absorbs:UpdateState(frame, settings)
		end

		if updateReasons.rosterChanged or updateReasons.healAbsorbsStateChanged then
			addon.Frames.Widgets.Bars.HealAbsorbs:UpdateState(frame, settings)
		end

		if updateReasons.rosterChanged or updateReasons.statusStateChanged then
			addon.Frames.Widgets.Texts.StatusText:UpdateState(frame)
		end

		if updateReasons.rosterChanged or updateReasons.aurasStateChanged then
			addon.Frames.Widgets.Icons.Buffs:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.Debuffs:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.BigDefensive:UpdateState(frame, settings)
			addon.Frames.Widgets.Indicators.Dispels:UpdateState(frame, settings)
			addon.Frames.Widgets.Bars.BuffOverlay:UpdateState(frame, settings)
		end

		if updateReasons.outOfRangeAlphaStateChanged or updateReasons.outOfRangeAlphaSettingChanged then
			addon.Frames.RangeChecker:UpdateState(frame)
		end
	end
end

local function Flush(updateReasons)
	if not addon.FrameRegistry:IsInitialized() then
		return
	end

	local globalReasons = updateReasons.global or {}
	local hasUnits = next(updateReasons.units or {}) ~= nil
	local hasGlobal = next(globalReasons) ~= nil
	if not hasUnits and not hasGlobal then
		return
	end

	if globalReasons.layoutChanged then
		addon.FrameRegistry:UpdateLayout()
	end

	for unit, unitReasons in pairs(updateReasons.units or {}) do
		local stateUpdater = BuildStateUpdater(unitReasons)
		local settingsUpdater = BuildSettingsUpdater(unitReasons)

		addon.FrameRegistry:UpdateUnit(unit, stateUpdater, settingsUpdater)
	end

	if hasGlobal then
		local stateUpdater = BuildStateUpdater(globalReasons)
		local settingsUpdater = BuildSettingsUpdater(globalReasons)

		addon.FrameRegistry:UpdateAllUnits(stateUpdater, settingsUpdater)
	end
end

function Updater:CreateFlushCallback()
	if initialized then
		error("Flush Callback was already created", 2)
	end

	initialized = true

	return Flush
end
