local _, addon = ...

addon.AuraHandler = addon.AuraHandler or {}
local AuraHandler = addon.AuraHandler

local AURA_FILTERS = {
	helpfulPlayer = "HELPFUL|PLAYER",
	helpfulBigDefensive = "HELPFUL|BIG_DEFENSIVE",
	helpfulExternalDefensive = "HELPFUL|EXTERNAL_DEFENSIVE",
	harmful = "HARMFUL",
	harmfulRaidPlayerDispellable = "HARMFUL|RAID_PLAYER_DISPELLABLE",
}

AuraHandler.unitAuras = {
	helpfulPlayer = {},
	helpfulBigDefensive = {},
	helpfulExternalDefensive = {},
	harmful = {},
	harmfulRaidPlayerDispellable = {},
}

AuraHandler.auraByInstanceID = {
	helpfulPlayer = {},
	helpfulBigDefensive = {},
	helpfulExternalDefensive = {},
	harmful = {},
	harmfulRaidPlayerDispellable = {},
}

function AuraHandler:UpdateAurasForUnit(unit)
	if type(unit) ~= "string" or unit == "" or not UnitExists(unit) then
		return
	end

	for collectionKey, filter in pairs(AURA_FILTERS) do
		local auras = C_UnitAuras.GetUnitAuras(unit, filter) or {}
		self.unitAuras[collectionKey][unit] = auras or {}

		local auraMap = {}
		for _, aura in ipairs(auras) do
			local auraInstanceID = aura and aura.auraInstanceID
			if auraInstanceID then
				auraMap[auraInstanceID] = true
			end
		end

		self.auraByInstanceID[collectionKey][unit] = auraMap
	end

	addon.UpdateScheduler:Notify("aurasStateChanged", unit)
end

function AuraHandler:GetUnitAuras(unit, collectionKey)
	local collection = self.unitAuras[collectionKey]
	return collection and collection[unit] or {}
end

function AuraHandler:GetUnitAuraInstanceIDs(unit, collectionKey)
	local collection = self.auraByInstanceID[collectionKey]
	return collection and collection[unit] or {}
end
