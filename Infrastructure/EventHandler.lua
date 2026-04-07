local _, addon = ...

local EventHandler = {}
addon.EventHandler = EventHandler

LibStub("AceEvent-3.0"):Embed(EventHandler)

local initialized = false

local function IsSupportedUnit(unit)
	return type(unit) == "string" and (unit == "player" or unit:match("^party%d$") or unit:match("^raid%d+$"))
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

	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("READY_CHECK_FINISHED")
	self:RegisterEvent("RAID_TARGET_UPDATE")
	self:RegisterEvent("INCOMING_SUMMON_CHANGED")
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED")

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

	self:RegisterEvent("UI_SCALE_CHANGED")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED")

	if not self.rangeTicker then
		addon.Frames.RangeChecker:UpdateSettings()

		self.rangeTicker = C_Timer.NewTicker(0.5, function()
			if IsInGroup() or IsInRaid() then
				addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged")
			end
		end)
	end

	initialized = true
end

local function QueueLateRosterRefresh()
	local delays = { 0.2, 0.8, 1.5 }
	for _, delay in ipairs(delays) do
		C_Timer.After(delay, function()
			addon.UpdateScheduler:Notify("rosterChanged")
			addon.UpdateScheduler:Notify("layoutChanged")
		end)
	end
end

function EventHandler:PLAYER_ENTERING_WORLD()
	addon.FrameRegistry:Initialize()
	addon.UpdateScheduler:Notify("layoutChanged")
	addon.UpdateScheduler:Notify("aurasStateChanged")
	addon.UpdateScheduler:Notify("statusStateChanged")
	addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged")

	C_Timer.After(0.1, function()
		addon.UpdateScheduler:Notify("rosterChanged")
	end)

	QueueLateRosterRefresh()
end

function EventHandler:ZONE_CHANGED_NEW_AREA()
	addon.UpdateScheduler:Notify("rosterChanged")
	addon.UpdateScheduler:Notify("layoutChanged")
	addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged")

	QueueLateRosterRefresh()
end

function EventHandler:GROUP_ROSTER_UPDATE()
	addon.UpdateScheduler:Notify("rosterChanged")
	addon.UpdateScheduler:Notify("outOfRangeAlphaStateChanged")

	if InCombatLockdown() then
		addon.Frames.Widgets.Icons.PrivateAuras.needsUpdateAfterCombat = true
	end

	QueueLateRosterRefresh()
end

function EventHandler:PLAYER_REGEN_ENABLED()
	if addon.Options:ShouldOpenAfterCombat() then
		addon.Options:Open()
	end

	if addon.optionsDeferredOpen then
		addon.optionsDeferredOpen = false
		C_Timer.After(0, function()
			if addon.OpenOptions then
				addon:OpenOptions()
			end
		end)
	end

	if addon.FrameRegistry.restoreLiveDriversAfterCombat then
		addon.FrameRegistry:UpdateStateDrivers()
	end

	if addon.FrameRegistry.needsLayoutUpdateAfterCombat then
		addon.UpdateScheduler:Notify("layoutChanged")
	end

	if addon.Frames.Widgets.Icons.PrivateAuras.needsUpdateAfterCombat then
		addon.Frames.Widgets.Icons.PrivateAuras.needsUpdateAfterCombat = false
		addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
	end

	addon.UpdateScheduler:Notify("combatEnded")
end

function EventHandler:PLAYER_REGEN_DISABLED()
	if addon.Options:IsOpen() then
		addon.Options:Close()
	end

	if addon.IsOptionsOpen and addon:IsOptionsOpen() then
		addon:CloseOptions()
	end

	addon.UpdateScheduler:Notify("combatStarted")
end

function EventHandler:READY_CHECK()
	addon.UpdateScheduler:Notify("readyCheckStateChanged")
end

function EventHandler:READY_CHECK_CONFIRM()
	addon.UpdateScheduler:Notify("readyCheckStateChanged")
end

function EventHandler:READY_CHECK_FINISHED()
	local ReadyCheck = addon.Frames.Widgets.Indicators.ReadyCheck
	ReadyCheck.lastFinishedAt = GetTime()

	if ReadyCheck.hideTimer then
		ReadyCheck.hideTimer:Cancel()
	end

	ReadyCheck.hideTimer = C_Timer.NewTimer(5, function()
		addon.UpdateScheduler:Notify("readyCheckStateChanged")
		ReadyCheck.hideTimer = nil
	end)

	addon.UpdateScheduler:Notify("readyCheckStateChanged")
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

function EventHandler:PLAYER_SPECIALIZATION_CHANGED(event, unit)
	if unit ~= "player" then
		return
	end

	addon.UpdateScheduler:Notify("buffOverlaySettingsChanged")
	addon.UpdateScheduler:Notify("aurasStateChanged")
end

function EventHandler:UI_SCALE_CHANGED()
	addon.Utilities:RefreshPixelGrid()
	addon.Modules:RequestUpdateAll()
	addon.Options:UpdateLayout()
	addon.Options:Snap()
end

function EventHandler:DISPLAY_SIZE_CHANGED()
	addon.Utilities:RefreshPixelGrid()
	addon.Modules:RequestUpdateAll()
	addon.Options:UpdateLayout()
	addon.Options:Snap()
end

function EventHandler:RAID_TARGET_UPDATE()
	addon.UpdateScheduler:Notify("raidMarkerStateChanged")
end

function EventHandler:PLAYER_ROLES_ASSIGNED()
	addon.UpdateScheduler:Notify("roleIconStateChanged")
end
