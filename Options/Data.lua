local _, addon = ...
addon.Options = addon.Options or {}
addon.Options.Data = addon.Options.Data or {}

local Data = addon.Options.Data

local profile
local subscribers = {}

function Data:RegisterForUpdates(key, callback)
	subscribers[key] = callback
end

function Data:UnregisterForUpdates(key)
	subscribers[key] = nil
end

function Data:RefreshProfile()
	profile = addon.Database:GetProfile()

	for _, callback in pairs(subscribers) do
		callback(profile)
	end
end
