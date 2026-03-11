local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.RangeChecker = addon.Frames.RangeChecker or {}

local RangeChecker = addon.Frames.RangeChecker

local cachedOutOfRangeAlpha = 0.5

local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitInRange = UnitInRange
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid

local function GetOutOfRangeAlpha()
	local profile = addon.Database:GetProfile()
	local core = profile and profile.core
	local alpha = core and core.outOfRangeAlpha

	if type(alpha) ~= "number" then
		return 0.5
	end

	if alpha < 0 then
		return 0
	end

	if alpha > 1 then
		return 1
	end

	return alpha
end

function RangeChecker:UpdateSettings()
	cachedOutOfRangeAlpha = GetOutOfRangeAlpha()
end

function RangeChecker:UpdateState(frame)
	if not frame then
		return
	end

	local unit = frame.unit
	if not UnitExists(unit) then
		return
	end

	local outOfRangeAlpha = cachedOutOfRangeAlpha
	local inGroupContext = IsInGroup() or IsInRaid()

	local inRange
	if UnitIsUnit(unit, "player") or not inGroupContext then
		inRange = true
	else
		inRange = UnitInRange(unit)
		if inRange == nil then
			inRange = true
		end
	end

	if frame.SetAlphaFromBoolean then
		frame:SetAlphaFromBoolean(inRange, 1, outOfRangeAlpha)
		return
	end

	if type(inRange) == "boolean" then
		frame:SetAlpha(inRange and 1 or outOfRangeAlpha)
	else
		frame:SetAlpha(1)
	end
end
