local _, addon = ...

local EventHandler = {}
addon.EventHandler = EventHandler

LibStub("AceEvent-3.0"):Embed(EventHandler)

local initialized = false

local IsSupportedUnit = addon.Utilities.IsSupportedUnit

local function CreateRangeTrackers()
	local function CreateRangeTracker(unit)
		local frame = CreateFrame("Frame")
		frame:RegisterUnitEvent("UNIT_IN_RANGE_UPDATE", unit)
		frame:RegisterUnitEvent("UNIT_PHASE", unit)
		frame:SetScript("OnEvent", function(_, event, eventUnit)
			addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged", eventUnit)
		end)
		return frame
	end

	local trackers = {}

	trackers.player = CreateRangeTracker("player")

	for i = 1, 4 do
		local unit = "party" .. i
		trackers[unit] = CreateRangeTracker(unit)
	end

	for i = 1, 40 do
		local unit = "raid" .. i
		trackers[unit] = CreateRangeTracker(unit)
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
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")

	self:RegisterEvent("UNIT_MAXHEALTH")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_POWER_UPDATE")
	self:RegisterEvent("UNIT_MAXPOWER")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
	self:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
	self:RegisterEvent("UNIT_AURA")

	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("UNIT_CONNECTION")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED")

	self:RegisterEvent("UI_SCALE_CHANGED")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED")

	addon.Frames.RangeChecker:UpdateSettings()
	self.rangeTrackers = CreateRangeTrackers()

	if addon.IsRestrictedAuraAPI and not self.unitVisibilityTicker then
		self.unitVisibilityTicker = C_Timer.NewTicker(0.25, function()
			if IsInGroup() or IsInRaid() then
				addon.UpdateScheduler:Notify("unitVisibilityChanged")
			end
		end)
	end

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
	local openedDeferredOptions = false

	if addon.OptionsNew and addon.OptionsNew.ShouldOpenAfterCombat and addon.OptionsNew:ShouldOpenAfterCombat() then
		addon.OptionsNew:Open()
		openedDeferredOptions = true
	end

	if
		not openedDeferredOptions
		and addon.Options
		and addon.Options.ShouldOpenAfterCombat
		and addon.Options:ShouldOpenAfterCombat()
	then
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
	if addon.OptionsNew and addon.OptionsNew.IsOpen and addon.OptionsNew:IsOpen() then
		addon.OptionsNew:Close()
	end

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

function EventHandler:UNIT_ABSORB_AMOUNT_CHANGED(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("absorbsStateChanged", unit)
end

function EventHandler:UNIT_HEAL_ABSORB_AMOUNT_CHANGED(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("healAbsorbsStateChanged", unit)
end

function EventHandler:UNIT_NAME_UPDATE(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("nameStateChanged", unit)

	C_Timer.After(1, function()
		addon.UpdateScheduler:Notify("nameStateChanged", unit)
	end)
end

function EventHandler:UNIT_HEALTH(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("healthStateChanged", unit)
	addon.UpdateScheduler:Notify("absorbsStateChanged", unit)
	addon.UpdateScheduler:Notify("healAbsorbsStateChanged", unit)
	addon.UpdateScheduler:Notify("statusStateChanged", unit)
end

function EventHandler:UNIT_MAXHEALTH(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("healthStateChanged", unit)
	addon.UpdateScheduler:Notify("absorbsStateChanged", unit)
	addon.UpdateScheduler:Notify("healAbsorbsStateChanged", unit)
	addon.UpdateScheduler:Notify("statusStateChanged", unit)
end

function EventHandler:UNIT_POWER_UPDATE(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("powerStateChanged", unit)
end

function EventHandler:UNIT_MAXPOWER(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("powerStateChanged", unit)
end

function EventHandler:UNIT_DISPLAYPOWER(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("powerStateChanged", unit)
end

function EventHandler:UNIT_AURA(event, unit, updateInfo)
	if addon.IsRestrictedAuraAPI then
		return
	end

	if not IsSupportedUnit(unit) then
		return
	end

	addon.AuraHandler:UpdateAurasForUnit(unit, updateInfo)
	addon.UpdateScheduler:Notify("aurasStateChanged", unit)
end

function EventHandler:UNIT_CONNECTION(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("statusStateChanged", unit)
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

	if addon.Options and addon.Options.Data and addon.Options.Data.RefreshProfile then
		addon.Options.Data:RefreshProfile()
	end

	if addon.OptionsNew and addon.OptionsNew.RefreshState then
		addon.OptionsNew:RefreshState()
	end

	if addon.Options and addon.Options.UpdateLayout then
		addon.Options:UpdateLayout()
	end
end

function EventHandler:UI_SCALE_CHANGED()
	addon.Utilities:RefreshPixelGrid()
	addon.Modules:RequestUpdateAll()
	addon.Options:UpdateLayout()
end

function EventHandler:DISPLAY_SIZE_CHANGED()
	addon.Utilities:RefreshPixelGrid()
	addon.Modules:RequestUpdateAll()
	addon.Options:UpdateLayout()
end

function EventHandler:RAID_TARGET_UPDATE()
	addon.UpdateScheduler:Notify("raidMarkerStateChanged")
end

function EventHandler:PLAYER_ROLES_ASSIGNED()
	addon.UpdateScheduler:Notify("roleIconStateChanged")
end

function EventHandler:UNIT_THREAT_SITUATION_UPDATE(event, unit)
	if not IsSupportedUnit(unit) then
		return
	end

	addon.UpdateScheduler:Notify("threatStateChanged", unit)
end
