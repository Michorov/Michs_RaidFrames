local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.State = addon.Options.State or {}

local State = addon.Options.State

local state = {
	mode = "party",
	subpages = {
		auras = "buffs",
		texts = "name",
		indicators = "readyCheck",
		bars = "health",
	},
}

function State:GetMode()
	return state.mode
end

function State:SetMode(mode)
	state.mode = mode == "raid" and "raid" or "party"
	return state.mode
end

function State:GetSubpage(section)
	return state.subpages[section]
end

function State:SetSubpage(section, subpage)
	state.subpages[section] = subpage
	return state.subpages[section]
end
