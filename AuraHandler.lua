local _, addon = ...

addon.AuraHandler = addon.AuraHandler or {}
local AuraHandler = addon.AuraHandler

AuraHandler.ready = false
AuraHandler.approvedByGuid = {}

local issecretvalue = issecretvalue

function AuraHandler:Prune(maxAgeSeconds)
	if not self.lastSeen then
		return
	end

	local now = GetTime()
	for guid, t in pairs(self.lastSeen) do
		if (now - t) > (maxAgeSeconds or 300) then
			self.lastSeen[guid] = nil
			self.approvedByGuid[guid] = nil
		end
	end
end

local function SafeMark(setTable, key)
	if not key then
		return
	end

	if issecretvalue and issecretvalue(key) then
		return
	end

	setTable[key] = true
end

local function GetOrCreateBucket(service, guid)
	local bucket = service.approvedByGuid[guid]
	if not bucket then
		bucket = { buffs = {}, debuffs = {}, dispellable = {}, defensive = {} }
		service.approvedByGuid[guid] = bucket
	end

	return bucket
end

local function ClearBucket(bucket)
	wipe(bucket.buffs)
	wipe(bucket.debuffs)
	wipe(bucket.dispellable)
	wipe(bucket.defensive)
end

local function IsNameplateUnit(unit)
	return type(unit) == "string" and unit:find("^nameplate")
end

local function CaptureCompactFrameAuras(service, compactFrame)
	if not compactFrame then
		return
	end

	local unit = compactFrame.unit or compactFrame.displayedUnit

	if not unit or not UnitExists(unit) then
		return
	end

	if IsNameplateUnit(unit) then
		return
	end

	local guid = UnitGUID(unit)
	if not guid then
		return
	end

	if issecretvalue and issecretvalue(guid) then
		return
	end

	service.lastSeen = service.lastSeen or {}
	service.lastSeen[guid] = GetTime()

	local bucket = GetOrCreateBucket(service, guid)
	ClearBucket(bucket)

	if compactFrame.buffFrames then
		for _, f in ipairs(compactFrame.buffFrames) do
			if f:IsShown() then
				SafeMark(bucket.buffs, f.auraInstanceID)
			end
		end
	end

	if compactFrame.debuffFrames then
		for _, f in ipairs(compactFrame.debuffFrames) do
			if f:IsShown() then
				SafeMark(bucket.debuffs, f.auraInstanceID)
			end
		end
	end

	if compactFrame.dispelDebuffFrames then
		for _, f in ipairs(compactFrame.dispelDebuffFrames) do
			if f:IsShown() then
				SafeMark(bucket.debuffs, f.auraInstanceID)

				local atlas
				if f.icon and f.icon.GetAtlas then
					atlas = f.icon:GetAtlas()
				elseif f.GetAtlas then
					atlas = f:GetAtlas()
				end

				table.insert(bucket.dispellable, {
					auraInstanceID = f.auraInstanceID,
					atlas = atlas,
				})
			end
		end
	end

	local def = compactFrame.CenterDefensiveBuff
	if def and def:IsShown() then
		SafeMark(bucket.defensive, def.auraInstanceID)
	end
end

function AuraHandler:ScanAllCompactFrames()
	for i = 1, 5 do
		local f = _G["CompactPartyFrameMember" .. i]
		if f then
			CaptureCompactFrameAuras(self, f)
		end
	end

	for i = 1, 40 do
		local f = _G["CompactRaidFrame" .. i]
		if f then
			CaptureCompactFrameAuras(self, f)
		end
	end

	for g = 1, 8 do
		for m = 1, 5 do
			local f = _G["CompactRaidGroup" .. g .. "Member" .. m]
			if f then
				CaptureCompactFrameAuras(self, f)
			end
		end
	end
end

function AuraHandler:Ensure()
	if self.ready then
		return
	end

	self.ready = true

	local function Hook(funcName)
		if _G[funcName] then
			hooksecurefunc(funcName, function(frame)
				CaptureCompactFrameAuras(self, frame)
			end)
		end
	end

	Hook("CompactUnitFrame_UpdateAuras")
	Hook("CompactUnitFrame_UpdateBuffs")
	Hook("CompactUnitFrame_UpdateDebuffs")

	if not self._pruneTicker then
		self._pruneTicker = C_Timer.NewTicker(60, function()
			self:Prune(120)
		end)
	end
end

function AuraHandler:GetBucketForUnit(unit)
	local guid = unit and UnitGUID(unit)
	if not guid then
		return nil
	end

	if issecretvalue and issecretvalue(guid) then
		return nil
	end

	return self.approvedByGuid[guid]
end

function AuraHandler:IsApprovedBuff(unit, auraInstanceID)
	local b = self:GetBucketForUnit(unit)
	return b and auraInstanceID and b.buffs[auraInstanceID] or false
end

function AuraHandler:IsApprovedDebuff(unit, auraInstanceID)
	local b = self:GetBucketForUnit(unit)
	return b and auraInstanceID and b.debuffs[auraInstanceID] or false
end

function AuraHandler:GetDefensiveAuraInstanceID(unit)
	local b = self:GetBucketForUnit(unit)
	if not b then
		return nil
	end

	for auraInstanceID in pairs(b.defensive) do
		return auraInstanceID
	end

	return nil
end

function AuraHandler:Prime()
	C_Timer.After(0.1, function()
		self:ScanAllCompactFrames()
	end)
	C_Timer.After(0.5, function()
		self:ScanAllCompactFrames()
	end)
	C_Timer.After(1.5, function()
		self:ScanAllCompactFrames()
	end)
end
