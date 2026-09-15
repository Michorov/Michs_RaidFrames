local _, addon = ...

addon.Utilities = addon.Utilities or {}

local Math = {}
addon.Utilities.Math = Math

function Math:RoundToNearestInt(value)
	value = value or 0

	if value >= 0 then
		return math.floor(value + 0.5)
	end

	return math.ceil(value - 0.5)
end
