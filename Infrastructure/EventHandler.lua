local _, addon = ...

local EventHandler = {}
addon.EventHandler = EventHandler

LibStub("AceEvent-3.0"):Embed(EventHandler)

local initialized = false

local trackedEvents = {
	unit = {},
	global = {},
}

local unitInTransition = {}

local function CreateUnitEventTrackers()
	local function CreateUnitEventTracker(unit)
		local frame = CreateFrame("Frame")
		frame.unit = unit

		frame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", unit)
		frame:RegisterUnitEvent("UNIT_IN_RANGE_UPDATE", unit)
		frame:RegisterUnitEvent("UNIT_PHASE", unit)
		frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
		frame:RegisterUnitEvent("UNIT_HEALTH", unit)
		frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
		frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit)
		frame:RegisterUnitEvent("UNIT_AURA", unit)
		frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
		frame:RegisterUnitEvent("UNIT_CONNECTION", unit)
		frame:RegisterUnitEvent("UNIT_ENTERING_VEHICLE", unit)
		frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", unit)
		frame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", unit)
		frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", unit)

		frame:SetScript("OnEvent", function(_, event, eventUnit, ...)
			local handler = EventHandler[event]
			if handler then
				handler(EventHandler, eventUnit, ...)
			end
		end)

		return frame
	end

	local trackers = {}

	trackers.player = CreateUnitEventTracker("player")

	for i = 1, 4 do
		local unit = "party" .. i
		trackers[unit] = CreateUnitEventTracker(unit)
	end

	for i = 1, 40 do
		local unit = "raid" .. i
		trackers[unit] = CreateUnitEventTracker(unit)
	end

	return trackers
end

function EventHandler:RegisterTrackedUnitEvent(event, owner)
	local trackedEvent = trackedEvents.unit[event]

	if not trackedEvent then
		trackedEvent = {
			owners = {},
		}
		trackedEvents.unit[event] = trackedEvent
	end

	if trackedEvent.owners[owner] then
		return
	end

	local shouldRegister = next(trackedEvent.owners) == nil
	trackedEvent.owners[owner] = true

	if shouldRegister then
		for _, tracker in pairs(self.unitEventTrackers or {}) do
			tracker:RegisterUnitEvent(event, tracker.unit)
		end
	end
end

function EventHandler:UnregisterTrackedUnitEvent(event, owner)
	local trackedEvent = trackedEvents.unit[event]

	if not trackedEvent or not trackedEvent.owners[owner] then
		return
	end

	trackedEvent.owners[owner] = nil

	if next(trackedEvent.owners) then
		return
	end

	trackedEvents.unit[event] = nil

	for _, tracker in pairs(self.unitEventTrackers or {}) do
		tracker:UnregisterEvent(event)
	end
end

function EventHandler:RegisterTrackedEvent(event, owner)
	local trackedEvent = trackedEvents.global[event]

	if not trackedEvent then
		trackedEvent = {
			owners = {},
		}
		trackedEvents.global[event] = trackedEvent
	end

	if trackedEvent.owners[owner] then
		return
	end

	local shouldRegister = next(trackedEvent.owners) == nil
	trackedEvent.owners[owner] = true

	if shouldRegister then
		self:RegisterEvent(event)
	end
end

function EventHandler:UnregisterTrackedEvent(event, owner)
	local trackedEvent = trackedEvents.global[event]

	if not trackedEvent or not trackedEvent.owners[owner] then
		return
	end

	trackedEvent.owners[owner] = nil

	if next(trackedEvent.owners) then
		return
	end

	trackedEvents.global[event] = nil
	self:UnregisterEvent(event)
end

function EventHandler:Initialize()
	if initialized then
		error("EventHandler already initialized", 2)
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_UNGHOST")

	if addon.IsRestrictedAuraAPI then
		self:RegisterEvent("CINEMATIC_START")
		self:RegisterEvent("CINEMATIC_STOP")
		self:RegisterEvent("PLAY_MOVIE")
		self:RegisterEvent("STOP_MOVIE")
	end

	self:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")

	self:RegisterEvent("UI_SCALE_CHANGED")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED")

	addon.Frames.RangeChecker:UpdateSettings()
	self.unitEventTrackers = CreateUnitEventTrackers()

	initialized = true
end

function EventHandler:PLAYER_ENTERING_WORLD()
	addon.Database:ApplyProfileForCurrentSpec()
	addon.FrameRegistry:Initialize()

	addon.UpdateScheduler:Notify("aurasStateChanged")
	addon.UpdateScheduler:Notify("statusStateChanged")
	addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged")
end

function EventHandler:ZONE_CHANGED_NEW_AREA()
	addon.UpdateScheduler:Notify("rosterChanged")
	addon.UpdateScheduler:Notify("layoutChanged")
	addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged")
end

function EventHandler:GROUP_ROSTER_UPDATE()
	addon.UpdateScheduler:Notify("rosterChanged")
	addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged")
end

function EventHandler:PARTY_LEADER_CHANGED()
	addon.UpdateScheduler:Notify("groupStatusStateChanged")
end

function EventHandler:PLAYER_REGEN_ENABLED()
	if addon.Options and addon.Options.ShouldOpenAfterCombat and addon.Options:ShouldOpenAfterCombat() then
		addon.Options:Open()
	end

	if addon.FrameRegistry.restoreLiveDriversAfterCombat then
		addon.FrameRegistry:UpdateStateDrivers()
	end

	if addon.FrameRegistry.needsLayoutUpdateAfterCombat then
		addon.UpdateScheduler:Notify("layoutChanged")
	end

	addon.UpdateScheduler:Notify("combatEnded")
end

function EventHandler:PLAYER_REGEN_DISABLED()
	if addon.Options and addon.Options.IsOpen and addon.Options:IsOpen() then
		addon.Options:Close()
	end

	addon.UpdateScheduler:Notify("combatStarted")
end

function EventHandler:PLAYER_ALIVE()
	addon.UpdateScheduler:Notify("statusStateChanged", "player")
end

function EventHandler:PLAYER_UNGHOST()
	addon.UpdateScheduler:Notify("statusStateChanged", "player")
end

function EventHandler:READY_CHECK()
	addon.UpdateScheduler:Notify("readyCheckStateChanged")
end

function EventHandler:READY_CHECK_CONFIRM(unit)
	addon.FrameRegistry:UpdateUnit(unit, function(frame, settings)
		addon.Frames.Widgets.Indicators.ReadyCheck:UpdateState(frame, settings)
	end)
end

function EventHandler:READY_CHECK_FINISHED()
	addon.UpdateScheduler:Notify("readyCheckStateFinished")
end

function EventHandler:INCOMING_SUMMON_CHANGED(unit)
	addon.UpdateScheduler:Notify("pendingSummonStateChanged", unit)
end

function EventHandler:PLAYER_FLAGS_CHANGED(unit)
	addon.UpdateScheduler:Notify("awayStateChanged", unit)
end

function EventHandler:UNIT_IN_RANGE_UPDATE(unit)
	addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged", unit)
end

function EventHandler:UNIT_PHASE(unit)
	addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged", unit)
end

function EventHandler:UNIT_THREAT_SITUATION_UPDATE(unit)
	addon.UpdateScheduler:Notify("threatStateChanged", unit)
end

function EventHandler:UNIT_MAXHEALTH(unit)
	addon.UpdateScheduler:Notify("healthStateChanged", unit)
	addon.UpdateScheduler:Notify("absorbsStateChanged", unit)
	addon.UpdateScheduler:Notify("healAbsorbsStateChanged", unit)
	addon.UpdateScheduler:Notify("statusStateChanged", unit)
end

function EventHandler:UNIT_HEALTH(unit)
	addon.UpdateScheduler:Notify("healthStateChanged", unit)
	addon.UpdateScheduler:Notify("absorbsStateChanged", unit)
	addon.UpdateScheduler:Notify("healAbsorbsStateChanged", unit)
	addon.UpdateScheduler:Notify("statusStateChanged", unit)
end

function EventHandler:UNIT_POWER_UPDATE(unit)
	addon.UpdateScheduler:Notify("powerStateChanged", unit)
end

function EventHandler:UNIT_MAXPOWER(unit)
	addon.UpdateScheduler:Notify("powerStateChanged", unit)
end

function EventHandler:UNIT_DISPLAYPOWER(unit)
	addon.UpdateScheduler:Notify("powerStateChanged", unit)
end

function EventHandler:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	addon.UpdateScheduler:Notify("absorbsStateChanged", unit)
end

function EventHandler:UNIT_HEAL_ABSORB_AMOUNT_CHANGED(unit)
	addon.UpdateScheduler:Notify("healAbsorbsStateChanged", unit)
end

function EventHandler:UNIT_AURA(unit, updateInfo)
	if addon.IsRestrictedAuraAPI then
		if unitInTransition.all or unitInTransition[unit] then
			addon.FrameRegistry:HideManagedContainers(unit)
			return
		end

		addon.FrameRegistry:UpdateManagedContainersVisibility(unit)
		return
	end

	addon.AuraHandler:UpdateAurasForUnit(unit, updateInfo)
	addon.UpdateScheduler:Notify("aurasStateChanged", unit)
end

function EventHandler:CINEMATIC_START()
	unitInTransition.all = true
	addon.FrameRegistry:HideAllManagedContainers()
end

function EventHandler:CINEMATIC_STOP()
	unitInTransition.all = nil
end

function EventHandler:PLAY_MOVIE()
	unitInTransition.all = true
	addon.FrameRegistry:HideAllManagedContainers()
end

function EventHandler:STOP_MOVIE()
	unitInTransition.all = nil
end

function EventHandler:UNIT_ENTERING_VEHICLE(unit)
	if not addon.IsRestrictedAuraAPI or not addon.Utilities.IsSupportedUnit(unit) then
		return
	end

	unitInTransition[unit] = true
	addon.FrameRegistry:HideManagedContainers(unit)
end

function EventHandler:UNIT_ENTERED_VEHICLE(unit)
	if not addon.IsRestrictedAuraAPI or not addon.Utilities.IsSupportedUnit(unit) then
		return
	end

	addon.FrameRegistry:UpdateManagedContainersUnit(unit)
	C_Timer.After(0, function()
		unitInTransition[unit] = nil
		addon.FrameRegistry:UpdateManagedContainersVisibility(unit)
	end)
end

EventHandler.UNIT_EXITING_VEHICLE = EventHandler.UNIT_ENTERING_VEHICLE
EventHandler.UNIT_EXITED_VEHICLE = EventHandler.UNIT_ENTERED_VEHICLE

function EventHandler:UNIT_NAME_UPDATE(unit)
	addon.UpdateScheduler:Notify("nameStateChanged", unit)

	C_Timer.After(1, function()
		addon.UpdateScheduler:Notify("nameStateChanged", unit)
	end)
end

function EventHandler:UNIT_CONNECTION(unit)
	addon.UpdateScheduler:Notify("statusStateChanged", unit)
end

function EventHandler:ACTIVE_PLAYER_SPECIALIZATION_CHANGED()
	addon.Database:ApplyProfileForCurrentSpec()
	addon.UpdateScheduler:Notify("buffOverlaySettingsChanged")
	addon.UpdateScheduler:Notify("aurasStateChanged")

	if addon.Options and addon.Options.RefreshState then
		addon.Options:RefreshState()
	end

	if addon.Options and addon.Options.UpdateLayout then
		addon.Options:UpdateLayout()
	end
end

function EventHandler:UI_SCALE_CHANGED()
	addon.Utilities:RefreshPixelGrid()
	addon.Modules:RequestUpdateAll()
	if addon.Options and addon.Options.UpdateLayout then
		addon.Options:UpdateLayout()
	end
end

function EventHandler:DISPLAY_SIZE_CHANGED()
	addon.Utilities:RefreshPixelGrid()
	addon.Modules:RequestUpdateAll()
	if addon.Options and addon.Options.UpdateLayout then
		addon.Options:UpdateLayout()
	end
end

function EventHandler:RAID_TARGET_UPDATE()
	addon.UpdateScheduler:Notify("raidMarkerStateChanged")
end

function EventHandler:PLAYER_ROLES_ASSIGNED()
	addon.UpdateScheduler:Notify("roleIconStateChanged")
end
