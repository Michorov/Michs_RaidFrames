local _, addon = ...

local UpdateScheduler = {}
addon.UpdateScheduler = UpdateScheduler

local updateReasons = {
	global = {},
	units = {},
}

local flushCallback
local initialized = false
local flushScheduled = false
local flushScheduledAt = nil

local STALE_FLUSH_SECONDS = 1

local function ScheduleFlush()
	if flushCallback == nil then
		error("Update Scheduler not initialized", 1)
	end

	if flushScheduled then
		if flushScheduledAt and (GetTime() - flushScheduledAt) > STALE_FLUSH_SECONDS then
			flushScheduled = false
			flushScheduledAt = nil
		else
			return
		end
	end

	flushScheduled = true
	flushScheduledAt = GetTime()

	C_Timer.After(0, function()
		flushScheduled = false
		flushScheduledAt = nil

		local reasons = updateReasons
		updateReasons = {
			global = {},
			units = {},
		}

		flushCallback(reasons)
	end)
end

function UpdateScheduler:Notify(updateReason, unit)
	if not initialized then
		error("Update Scheduler not initialized", 2)
	end

	if updateReason == nil then
		return
	end

	if unit then
		updateReasons.units[unit] = updateReasons.units[unit] or {}
		updateReasons.units[unit][updateReason] = true
	else
		updateReasons.global[updateReason] = true
	end

	ScheduleFlush()
end

function UpdateScheduler:SetFlushCallback(callback)
	if initialized then
		error("Update Scheduler already initialized", 2)
	end

	if type(callback) ~= "function" then
		error("Flush Callback is not a function", 2)
	end

	flushCallback = callback
	initialized = true
end
