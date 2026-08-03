local _, addon = ...

local EventHandler = {}
addon.EventHandler = EventHandler

LibStub("AceEvent-3.0"):Embed(EventHandler)

local initialized = false

local IsSupportedUnit = addon.Utilities.IsSupportedUnit

local function NotifyRangeStateChanged(eventUnit)
	addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged", eventUnit)
end

local unitEventDispatcher = {
	UNIT_IN_RANGE_UPDATE = NotifyRangeStateChanged,
	UNIT_PHASE = NotifyRangeStateChanged,
	UNIT_THREAT_SITUATION_UPDATE = function(eventUnit)
		addon.UpdateScheduler:Notify("threatStateChanged", eventUnit)
	end,
	UNIT_MAXHEALTH = function(eventUnit)
		addon.UpdateScheduler:Notify("healthStateChanged", eventUnit)
		addon.UpdateScheduler:Notify("absorbsStateChanged", eventUnit)
		addon.UpdateScheduler:Notify("healAbsorbsStateChanged", eventUnit)
		addon.UpdateScheduler:Notify("statusStateChanged", eventUnit)
	end,
	UNIT_HEALTH = function(eventUnit)
		addon.UpdateScheduler:Notify("healthStateChanged", eventUnit)
		addon.UpdateScheduler:Notify("absorbsStateChanged", eventUnit)
		addon.UpdateScheduler:Notify("healAbsorbsStateChanged", eventUnit)
		addon.UpdateScheduler:Notify("statusStateChanged", eventUnit)
	end,
	UNIT_POWER_UPDATE = function(eventUnit)
		addon.UpdateScheduler:Notify("powerStateChanged", eventUnit)
	end,
	UNIT_MAXPOWER = function(eventUnit)
		addon.UpdateScheduler:Notify("powerStateChanged", eventUnit)
	end,
	UNIT_DISPLAYPOWER = function(eventUnit)
		addon.UpdateScheduler:Notify("powerStateChanged", eventUnit)
	end,
	UNIT_ABSORB_AMOUNT_CHANGED = function(eventUnit)
		addon.UpdateScheduler:Notify("absorbsStateChanged", eventUnit)
	end,
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = function(eventUnit)
		addon.UpdateScheduler:Notify("healAbsorbsStateChanged", eventUnit)
	end,
	UNIT_AURA = function(eventUnit, updateInfo)
		if addon.IsRestrictedAuraAPI then
			addon.FrameRegistry:UpdateManagedContainersVisibility(eventUnit)
			return
		end

		addon.AuraHandler:UpdateAurasForUnit(eventUnit, updateInfo)
		addon.UpdateScheduler:Notify("aurasStateChanged", eventUnit)
	end,
	UNIT_NAME_UPDATE = function(eventUnit)
		addon.UpdateScheduler:Notify("nameStateChanged", eventUnit)

		C_Timer.After(1, function()
			addon.UpdateScheduler:Notify("nameStateChanged", eventUnit)
		end)
	end,
	UNIT_CONNECTION = function(eventUnit)
		addon.UpdateScheduler:Notify("statusStateChanged", eventUnit)
	end,
}

local function CreateUnitEventTrackers()
	local function CreateUnitEventTracker(unit)
		local frame = CreateFrame("Frame")
		frame:RegisterUnitEvent("UNIT_IN_RANGE_UPDATE", unit)
		frame:RegisterUnitEvent("UNIT_PHASE", unit)
		frame:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", unit)
		frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
		frame:RegisterUnitEvent("UNIT_HEALTH", unit)
		frame:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
		frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
		frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
		frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
		frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit)
		frame:RegisterUnitEvent("UNIT_AURA", unit)
		frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
		frame:RegisterUnitEvent("UNIT_CONNECTION", unit)

		frame:SetScript("OnEvent", function(_, event, eventUnit, ...)
			local handler = unitEventDispatcher[event]
			if handler then
				handler(eventUnit, ...)
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

function EventHandler:Initialize()
	if initialized then
		error("EventHandler already initialized", 2)
	end

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_LEADER_CHANGED")

	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_UNGHOST")

	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("READY_CHECK_FINISHED")
	self:RegisterEvent("RAID_TARGET_UPDATE")
	self:RegisterEvent("INCOMING_SUMMON_CHANGED")
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED")

	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED")

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

function EventHandler:READY_CHECK_CONFIRM(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.FrameRegistry:UpdateUnit(unit, function(frame, settings)
		addon.Frames.Widgets.Indicators.ReadyCheck:UpdateState(frame, settings)
	end)
end

function EventHandler:READY_CHECK_FINISHED()
	addon.UpdateScheduler:Notify("readyCheckStateFinished")
end

function EventHandler:INCOMING_SUMMON_CHANGED(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("pendingSummonStateChanged", unit)
end

function EventHandler:PLAYER_FLAGS_CHANGED(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("awayStateChanged", unit)
end

function EventHandler:PLAYER_SPECIALIZATION_CHANGED(event, unit)
	if unit ~= "player" then
		return
	end

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

