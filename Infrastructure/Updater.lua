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

		if updateReasons.pingSettingsChanged then
			addon.Frames.Widgets.Indicators.Ping:UpdateSettings(frame, settings)
		end

		if updateReasons.raidMarkerSettingsChanged then
			addon.Frames.Widgets.Indicators.RaidMarker:UpdateSettings(frame, settings)
		end

		if updateReasons.roleIconSettingsChanged then
			addon.Frames.Widgets.Indicators.RoleIcon:UpdateSettings(frame, settings)
		end

		if updateReasons.groupStatusSettingsChanged then
			addon.Frames.Widgets.Indicators.GroupStatus:UpdateSettings(frame, settings)
		end

		if updateReasons.threatSettingsChanged or updateReasons.borderSettingsChanged then
			addon.Frames.Widgets.Indicators.Threat:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Indicators.Threat:UpdateState(frame, settings)
		end

		if updateReasons.nameSettingsChanged then
			addon.Frames.Widgets.Texts.Name:UpdateSettings(frame, settings)
		end

		if updateReasons.powerTextSettingsChanged then
			addon.Frames.Widgets.Texts.Power:UpdateSettings(frame, settings)
		end

		if updateReasons.healthTextSettingsChanged then
			addon.Frames.Widgets.Texts.Health:UpdateSettings(frame, settings)
		end

		if updateReasons.statusTextSettingsChanged then
			addon.Frames.Widgets.Texts.StatusText:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Texts.StatusText:UpdateState(frame, settings)
		end

		if updateReasons.awayTextSettingsChanged then
			addon.Frames.Widgets.Texts.Away:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Texts.Away:UpdateState(frame, settings)
		end

		if updateReasons.absorbsSettingsChanged then
			addon.Frames.Widgets.Bars.Absorbs:UpdateSettings(frame, settings)
		end

		if updateReasons.healAbsorbsSettingsChanged then
			addon.Frames.Widgets.Bars.HealAbsorbs:UpdateSettings(frame, settings)
		end

		if updateReasons.healAbsorbsTextSettingsChanged then
			addon.Frames.Widgets.Texts.HealAbsorbs:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Texts.HealAbsorbs:UpdateState(frame, settings)
		end

		if updateReasons.buffAurasSettingsChanged then
			addon.Frames.ManagedContainers.Buffs:UpdateSettings(frame, settings)
			addon.Frames.ManagedContainers.CustomBuffs:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.Buffs:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.Buffs:UpdateState(frame, settings)
		end

		if updateReasons.buffAuraFiltersChanged then
			addon.Frames.ManagedContainers.Buffs:UpdateFilters(frame, settings)
		end

		if updateReasons.customBuffSettingsChanged then
			addon.Frames.ManagedContainers.CustomBuffs:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.CustomBuffs:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.CustomBuffs:UpdateState(frame, settings)
		end

		if updateReasons.buffOverlaySettingsChanged then
			addon.Frames.ManagedContainers.BuffOverlay:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Bars.BuffOverlay:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Bars.BuffOverlay:UpdateState(frame, settings)
		end

		if updateReasons.debuffAurasSettingsChanged then
			addon.Frames.ManagedContainers.Debuffs:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.Debuffs:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.Debuffs:UpdateState(frame, settings)
		end

		if updateReasons.bigDefensiveAurasSettingsChanged then
			addon.Frames.ManagedContainers.Defensives:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.BigDefensive:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.BigDefensive:UpdateState(frame, settings)
		end

		if updateReasons.raidBuffReminderSettingsChanged then
			addon.Frames.ManagedContainers.RaidBuffReminder:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.RaidBuffReminder:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.RaidBuffReminder:UpdateState(frame, settings)
		end

		if updateReasons.dispelsSettingsChanged then
			addon.Frames.ManagedContainers.Dispels:UpdateSettings(frame, settings)
			addon.Frames.Widgets.Icons.Dispels:UpdateSettings(frame, settings)
		elseif
			(updateReasons.layoutChanged or updateReasons.healthSettingsChanged or updateReasons.borderSettingsChanged)
			and not InCombatLockdown()
		then
			-- Refresh overlay dimensions, the health clip, and the outer-border inset.
			addon.Frames.ManagedContainers.Dispels:UpdateSettings(frame, settings)
		end
	end
end

local function BuildStateUpdater(updateReasons)
	if updateReasons.readyCheckStateFinished then
		addon.Frames.Widgets.Indicators.ReadyCheck:StartHold()
	end

	return function(frame, settings)
		if updateReasons.healthStateChanged or updateReasons.healthSettingsChanged then
			addon.Frames.Base.Health:UpdateState(frame, settings)
		end

		if updateReasons.powerStateChanged or updateReasons.powerSettingsChanged then
			addon.Frames.Base.Power:UpdateState(frame, settings)
		end

		if updateReasons.powerStateChanged then
			addon.Frames.Widgets.Texts.Power:UpdateState(frame, settings)
		end

		if updateReasons.healthStateChanged then
			addon.Frames.Widgets.Texts.Health:UpdateState(frame, settings)
		end

		if updateReasons.nameStateChanged or updateReasons.nameSettingsChanged then
			addon.Frames.Widgets.Texts.Name:UpdateState(frame, settings)
		end

		if
			updateReasons.readyCheckStateChanged
			or updateReasons.readyCheckStateFinished
			or updateReasons.readyCheckSettingsChanged
		then
			addon.Frames.Widgets.Indicators.ReadyCheck:UpdateState(frame, settings)
		end

		if updateReasons.pendingSummonStateChanged or updateReasons.pendingSummonSettingsChanged then
			addon.Frames.Widgets.Indicators.PendingSummon:UpdateState(frame, settings)
		end

		if updateReasons.pingStateChanged or updateReasons.pingSettingsChanged then
			addon.Frames.Widgets.Indicators.Ping:UpdateState(frame, settings)
		end

		if updateReasons.raidMarkerStateChanged or updateReasons.raidMarkerSettingsChanged then
			addon.Frames.Widgets.Indicators.RaidMarker:UpdateState(frame, settings)
		end

		if updateReasons.roleIconStateChanged or updateReasons.roleIconSettingsChanged then
			addon.Frames.Widgets.Indicators.RoleIcon:UpdateState(frame, settings)
		end

		if updateReasons.groupStatusStateChanged or updateReasons.groupStatusSettingsChanged then
			addon.Frames.Widgets.Indicators.GroupStatus:UpdateState(frame, settings)
		end

		if updateReasons.threatStateChanged then
			addon.Frames.Widgets.Indicators.Threat:UpdateState(frame, settings)
		end

		if updateReasons.absorbsStateChanged then
			addon.Frames.Widgets.Bars.Absorbs:UpdateState(frame, settings)
		end

		if updateReasons.healAbsorbsStateChanged then
			addon.Frames.Widgets.Bars.HealAbsorbs:UpdateState(frame, settings)
			addon.Frames.Widgets.Texts.HealAbsorbs:UpdateState(frame, settings)
		end

		if updateReasons.statusStateChanged then
			addon.Frames.Widgets.Texts.StatusText:UpdateState(frame)
		end

		if updateReasons.awayStateChanged or updateReasons.combatStarted or updateReasons.combatEnded then
			addon.Frames.Widgets.Texts.Away:UpdateState(frame, settings)
		end

		if updateReasons.aurasStateChanged then
			addon.Frames.ManagedContainers.Dispels:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.Buffs:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.CustomBuffs:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.Debuffs:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.BigDefensive:UpdateState(frame, settings)
			addon.Frames.Widgets.Bars.BuffOverlay:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.RaidBuffReminder:UpdateState(frame, settings)
		end

		if updateReasons.unitVisibilityChanged then
			addon.Frames.ManagedContainers.Defensives:UpdateState(frame, settings)
		end

		if updateReasons.statusStateChanged or updateReasons.outOfRangeAlphaStateChanged then
			addon.Frames.ManagedContainers.RaidBuffReminder:UpdateState(frame, settings)
		end

		if updateReasons.combatStarted then
			addon.Frames.ManagedContainers.RaidBuffReminder:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.RaidBuffReminder:UpdateState(frame, settings)
		end

		if updateReasons.combatEnded then
			addon.Frames.ManagedContainers.RaidBuffReminder:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.RaidBuffReminder:UpdateState(frame, settings)
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
	if globalReasons.rosterChanged then
		addon.FrameRegistry:UpdateRoster()
		globalReasons.rosterChanged = nil
	end

	if globalReasons.clickCastingSettingsChanged then
		addon.FrameRegistry:UpdateClickCasting()
		globalReasons.clickCastingSettingsChanged = nil
	end

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
