local _, addon = ...

addon.AuraHandler = addon.AuraHandler or {}
local AuraHandler = addon.AuraHandler

local AURA_FILTERS = {
	helpful = "HELPFUL",
	helpfulPlayer = "HELPFUL|PLAYER",
	helpfulBigDefensive = "HELPFUL|BIG_DEFENSIVE",
	helpfulExternalDefensive = "HELPFUL|EXTERNAL_DEFENSIVE",
	harmful = "HARMFUL",
	harmfulRaidPlayerDispellable = "HARMFUL|RAID_PLAYER_DISPELLABLE",
}

AuraHandler.unitAuras = {
	helpful = {},
	helpfulPlayer = {},
	helpfulBigDefensive = {},
	helpfulExternalDefensive = {},
	harmful = {},
	harmfulRaidPlayerDispellable = {},
}

local IsAuraFilteredOutByInstanceID = C_UnitAuras.IsAuraFilteredOutByInstanceID

local function FullRefresh(unit)
	for collectionKey, filter in pairs(AURA_FILTERS) do
		local auras = C_UnitAuras.GetUnitAuras(unit, filter) or {}
		local map = {}
		for _, aura in ipairs(auras) do
			local id = aura and aura.auraInstanceID
			if id then
				map[id] = aura
			end
		end
		AuraHandler.unitAuras[collectionKey][unit] = map
	end
end

function AuraHandler:UpdateAurasForUnit(unit, updateInfo)
	if type(unit) ~= "string" or unit == "" or not UnitExists(unit) then
		return
	end

	if not updateInfo or updateInfo.isFullUpdate then
		FullRefresh(unit)
		return
	end

	for collectionKey in pairs(AURA_FILTERS) do
		if not self.unitAuras[collectionKey][unit] then
			self.unitAuras[collectionKey][unit] = {}
		end
	end

	if updateInfo.removedAuraInstanceIDs then
		for _, id in ipairs(updateInfo.removedAuraInstanceIDs) do
			for collectionKey in pairs(AURA_FILTERS) do
				self.unitAuras[collectionKey][unit][id] = nil
			end
		end
	end

	if updateInfo.addedAuras and IsAuraFilteredOutByInstanceID then
		for _, aura in ipairs(updateInfo.addedAuras) do
			local id = aura and aura.auraInstanceID
			if id then
				for collectionKey, filter in pairs(AURA_FILTERS) do
					local unitMap = self.unitAuras[collectionKey][unit]
					if not IsAuraFilteredOutByInstanceID(unit, id, filter) then
						unitMap[id] = aura
					end
				end
			end
		end
	end

	if updateInfo.updatedAuraInstanceIDs then
		for _, id in ipairs(updateInfo.updatedAuraInstanceIDs) do
			local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
			for collectionKey in pairs(AURA_FILTERS) do
				local unitMap = self.unitAuras[collectionKey][unit]
				if unitMap[id] then
					unitMap[id] = auraData or nil
				end
			end
		end
	end
end

function AuraHandler:GetUnitAuras(unit, collectionKey)
	local collection = self.unitAuras[collectionKey]
	return collection and collection[unit] or {}
end

function AuraHandler:GetUnitAuraInstanceIDs(unit, collectionKey)
	local collection = self.unitAuras[collectionKey]
	return collection and collection[unit] or {}
end
