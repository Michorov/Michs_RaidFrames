local _, addon = ...

local FrameRegistry = {}
addon.FrameRegistry = FrameRegistry

local initialized = false

FrameRegistry.restoreLiveDriversAfterCombat = false
FrameRegistry.needsLayoutUpdateAfterCombat = false

local partyHeader = {
	settingsType = "party",
	isSecureHeader = true,
	container = nil,
}

local raidHeaders = {
	settingsType = "raid",
	isSecureHeader = true,
	containers = {},
}

local partyBossGroup = {
	settingsType = "party",
	isBossGroup = true,
	container = nil,
	frames = {},
}

local raidBossGroup = {
	settingsType = "raid",
	isBossGroup = true,
	container = nil,
	frames = {},
}

local testPartyGroup = {
	settingsType = "party",
	isTestGroup = true,
	isActive = false,
	container = nil,
	frames = {},
}

local testRaidGroup = {
	settingsType = "raid",
	isTestGroup = true,
	isActive = false,
	container = nil,
	frames = {},
}

local testPartyBossGroup = {
	settingsType = "party",
	isBossGroup = true,
	isTestGroup = true,
	isActive = false,
	container = nil,
	frames = {},
}

local testRaidBossGroup = {
	settingsType = "raid",
	isBossGroup = true,
	isTestGroup = true,
	isActive = false,
	container = nil,
	frames = {},
}

local previewFrames = {
	party = nil,
	raid = nil,
}

local unitFrameMap = {}

local miniCCProviderRegistered = false
local miniCCRefreshFrames = nil
local miniCCRefreshQueued = false

local IsSupportedUnit = addon.Utilities.IsSupportedUnit

local function UpdateLiveFrameClickCasting(frame)
	if InCombatLockdown() then
		return
	end

	local profile = addon.Database:GetProfile()
	local clickCasting = profile.core.clickCasting

	addon.Frames.ClickCasting:UpdateClickCastBindsForFrame(frame, clickCasting)
end

local function GetFrames()
	local frames = {}

	for _, frame in pairs(unitFrameMap) do
		frames[#frames + 1] = frame
	end

	return frames
end

local function NotifyMiniCCFramesChanged()
	if not miniCCRefreshFrames or miniCCRefreshQueued then
		return
	end

	miniCCRefreshQueued = true
	C_Timer.After(0, function()
		miniCCRefreshQueued = false

		if miniCCRefreshFrames then
			miniCCRefreshFrames()
		end
	end)
end

local function RegisterMiniCCProvider()
	if miniCCProviderRegistered then
		return
	end

	local api = _G.MiniCCApi and _G.MiniCCApi.v1
	if not api or type(api.RegisterFrameProvider) ~= "function" then
		return
	end

	api:RegisterFrameProvider({
		Name = "Michs_RaidFrames",
		GetFrames = GetFrames,
		RegisterRefreshFrames = function(callback)
			if type(callback) == "function" then
				miniCCRefreshFrames = callback
				NotifyMiniCCFramesChanged()
			end
		end,
	})

	miniCCProviderRegistered = true
end

function MRF_OnUnitFrameLoad(frame)
	local parent = frame:GetParent()
	local parentFrameType = parent and parent.frameType
	local parentSettingsType = parent and parent.settingsType

	frame.frameType = frame.frameType or parentFrameType
	frame.settingsType = frame.settingsType or parentSettingsType
	frame.dataProvider = addon.Frames.DataProvider.Live
	frame.managedContainers = {}
	addon.Frames.ClickCasting:CreateClickCastingButton(frame)

	local targetedSpellsApi = _G.TargetedSpellsAPI
	if targetedSpellsApi and targetedSpellsApi.RegisterFrameByName then
		local name = frame:GetName()
		if name then
			targetedSpellsApi.RegisterFrameByName(name)
		end
	end

	UpdateLiveFrameClickCasting(frame)

	local settings = addon.FrameRegistry:GetSettingsForFrame(frame)
	if settings then
		addon.Modules:EnsureFrame(frame, settings)
		addon.Modules:UpdateSettingsFrame(frame, settings)
	end
end

function MRF_OnUnitChanged(frame, unit)
	if frame.frameType == "boss" then
		if addon.IsRestrictedAuraAPI and frame.managedContainers then
			local settings = addon.FrameRegistry:GetSettingsForFrame(frame)

			if frame.managedContainers.debuffs then
				addon.Frames.ManagedContainers.Debuffs:SetUnit(frame, settings)
			end

			if frame.managedContainers.dispels then
				addon.Frames.ManagedContainers.Dispels:SetUnit(frame, settings)
			end

			if frame.managedContainers.buffs then
				addon.Frames.ManagedContainers.Buffs:SetUnit(frame, settings)
			end

			if frame.managedContainers.customBuffs then
				addon.Frames.ManagedContainers.CustomBuffs:SetUnit(frame, settings)
			end

			if frame.managedContainers.defensives then
				addon.Frames.ManagedContainers.Defensives:SetUnit(frame, settings)
			end

			if frame.managedContainers.buffOverlay then
				addon.Frames.ManagedContainers.BuffOverlay:SetUnit(frame, settings)
			end
		end

		return
	end

	frame.RosterKey = nil

	for k, v in pairs(unitFrameMap) do
		if v == frame then
			unitFrameMap[k] = nil
		end
	end

	if unit then
		unitFrameMap[unit] = frame
	end

	NotifyMiniCCFramesChanged()

	local isSupportedUnit = IsSupportedUnit(unit)

	if addon.IsRestrictedAuraAPI and frame.managedContainers then
		local settings = addon.FrameRegistry:GetSettingsForFrame(frame)

		if frame.managedContainers.debuffs then
			addon.Frames.ManagedContainers.Debuffs:SetUnit(frame, settings)
		end

		if frame.managedContainers.dispels then
			addon.Frames.ManagedContainers.Dispels:SetUnit(frame, settings)
		end

		if frame.managedContainers.buffs then
			addon.Frames.ManagedContainers.Buffs:SetUnit(frame, settings)
		end

		if frame.managedContainers.customBuffs then
			addon.Frames.ManagedContainers.CustomBuffs:SetUnit(frame, settings)
		end

		if frame.managedContainers.defensives then
			addon.Frames.ManagedContainers.Defensives:SetUnit(frame, settings)
		end

		if frame.managedContainers.buffOverlay then
			addon.Frames.ManagedContainers.BuffOverlay:SetUnit(frame, settings)
		end

		if frame.managedContainers.raidBuffReminder then
			addon.Frames.ManagedContainers.RaidBuffReminder:SetUnit(frame, settings)
		end
	end

	if not isSupportedUnit then
		return
	end

	local settings = addon.FrameRegistry:GetSettingsForFrame(frame)
	if settings then
		if frame.privateAurasAnchoredUnit ~= unit then
			addon.Frames.Widgets.Icons.PrivateAuras:UpdateSettings(frame, settings)
		end

		if frame.dispelsAnchoredUnit ~= unit then
			addon.Frames.Widgets.Icons.Dispels:UpdateSettings(frame, settings)
		end
	end

	addon.UpdateScheduler:Notify("rosterChanged")
end

local function ApplyBlizzardFramesVisibility()
	local profile = addon.Database:GetProfile()
	local core = profile and profile.core

	if core and core.hideBlizzardRaidFrames == true then
		RegisterStateDriver(CompactPartyFrame, "visibility", "hide")
		RegisterStateDriver(CompactRaidFrameContainer, "visibility", "hide")
	else
		UnregisterStateDriver(CompactPartyFrame, "visibility")
		UnregisterStateDriver(CompactRaidFrameContainer, "visibility")
		CompactPartyFrame:Show()
		CompactRaidFrameContainer:Show()
	end

	if core and core.hideBlizzardRaidFrameManager == true then
		RegisterStateDriver(CompactRaidFrameManager, "visibility", "hide")
	else
		UnregisterStateDriver(CompactRaidFrameManager, "visibility")
		CompactRaidFrameManager:Show()
	end
end

function FrameRegistry:UpdateStateDrivers(allowInCombat)
	local profile = addon.Database:GetProfile()
	local showSoloPartyFrame = profile and profile.core and profile.core.showSoloPartyFrame == true
	local testModeActive = testPartyGroup.isActive or testRaidGroup.isActive
	local partySettings = profile.party or {}
	local raidSettings = self:ResolveRaidSettings(profile)
	local npcPartyEnabled = partySettings.npcEnabled == true
	local npcRaidEnabled = raidSettings.npcEnabled == true

	if InCombatLockdown() and allowInCombat ~= true then
		return
	end

	UnregisterStateDriver(partyHeader.container, "visibility")
	UnregisterStateDriver(partyBossGroup.container, "visibility")
	for _, raidContainer in ipairs(raidHeaders.containers) do
		UnregisterStateDriver(raidContainer, "visibility")
	end
	UnregisterStateDriver(raidBossGroup.container, "visibility")

	local raidGroupSettings = (profile.raid and profile.raid.groups) or {}

	if testModeActive then
		if showSoloPartyFrame then
			RegisterStateDriver(partyHeader.container, "visibility", "[@player,combat,nogroup:raid] show; hide")
			RegisterStateDriver(
				partyBossGroup.container,
				"visibility",
				npcPartyEnabled and "[@player,combat,nogroup:raid] show; hide" or "hide"
			)
		else
			RegisterStateDriver(
				partyHeader.container,
				"visibility",
				"[@player,combat,group:party,nogroup:raid] show; hide"
			)
			RegisterStateDriver(
				partyBossGroup.container,
				"visibility",
				npcPartyEnabled and "[@player,combat,group:party,nogroup:raid] show; hide" or "hide"
			)
		end

		for groupIndex, raidContainer in ipairs(raidHeaders.containers) do
			if raidGroupSettings[groupIndex] then
				RegisterStateDriver(raidContainer, "visibility", "[@player,combat,group:raid] show; hide")
			else
				RegisterStateDriver(raidContainer, "visibility", "hide")
			end
		end
		RegisterStateDriver(
			raidBossGroup.container,
			"visibility",
			npcRaidEnabled and "[@player,combat,group:raid] show; hide" or "hide"
		)

		self.restoreLiveDriversAfterCombat = false
		NotifyMiniCCFramesChanged()
		return
	end

	if showSoloPartyFrame then
		RegisterStateDriver(partyHeader.container, "visibility", "[@player,nogroup:raid] show; hide")
		RegisterStateDriver(
			partyBossGroup.container,
			"visibility",
			npcPartyEnabled and "[@player,nogroup:raid] show; hide" or "hide"
		)
	else
		RegisterStateDriver(partyHeader.container, "visibility", "[@player,group:party,nogroup:raid] show; hide")
		RegisterStateDriver(
			partyBossGroup.container,
			"visibility",
			npcPartyEnabled and "[@player,group:party,nogroup:raid] show; hide" or "hide"
		)
	end

	for groupIndex, raidContainer in ipairs(raidHeaders.containers) do
		if raidGroupSettings[groupIndex] then
			RegisterStateDriver(raidContainer, "visibility", "[@player,group:raid] show; hide")
		else
			RegisterStateDriver(raidContainer, "visibility", "hide")
		end
	end
	RegisterStateDriver(
		raidBossGroup.container,
		"visibility",
		npcRaidEnabled and "[@player,group:raid] show; hide" or "hide"
	)

	self.restoreLiveDriversAfterCombat = false
	NotifyMiniCCFramesChanged()
end

function FrameRegistry:ResolveRaidSettings(profile)
	local partySettings = profile.party or {}
	local raidSettings = profile.raid or {}

	local _, instanceType = IsInInstance()
	local inArena = (instanceType == "arena")

	if inArena then
		return partySettings
	end

	return raidSettings
end

function FrameRegistry:GetSettingsForFrame(frame)
	local profile = addon.Database:GetProfile()
	local parent = frame:GetParent()
	local settingsType = frame.settingsType or (parent and parent.settingsType)

	if settingsType == "party" then
		return profile.party or {}
	end

	if settingsType == "raid" then
		return self:ResolveRaidSettings(profile)
	end

	return nil
end

function FrameRegistry:UpdateClickCasting()
	if InCombatLockdown() then
		return
	end

	local profile = addon.Database:GetProfile()
	local clickCasting = profile.core.clickCasting

	if partyHeader.container then
		for i = 1, 5 do
			local frame = partyHeader.container:GetAttribute("child" .. i)
			addon.Frames.ClickCasting:UpdateClickCastBindsForFrame(frame, clickCasting)
		end
	end

	for _, header in ipairs(raidHeaders.containers) do
		for i = 1, 5 do
			local frame = header:GetAttribute("child" .. i)
			addon.Frames.ClickCasting:UpdateClickCastBindsForFrame(frame, clickCasting)
		end
	end

	for _, frame in ipairs(partyBossGroup.frames) do
		addon.Frames.ClickCasting:UpdateClickCastBindsForFrame(frame, clickCasting)
	end

	for _, frame in ipairs(raidBossGroup.frames) do
		addon.Frames.ClickCasting:UpdateClickCastBindsForFrame(frame, clickCasting)
	end
end

function FrameRegistry:UpdateManagedContainersVisibility(unit)
	if not initialized then
		return
	end

	self:UpdateUnit(unit, function(frame, settings)
		local managedContainers = frame.managedContainers
		if not managedContainers then
			return
		end

		if managedContainers.buffs then
			addon.Frames.ManagedContainers.Buffs:UpdateState(frame, settings)
		end

		if managedContainers.customBuffs then
			addon.Frames.ManagedContainers.CustomBuffs:UpdateState(frame, settings)
		end

		if managedContainers.debuffs then
			addon.Frames.ManagedContainers.Debuffs:UpdateState(frame, settings)
		end

		if managedContainers.dispels then
			addon.Frames.ManagedContainers.Dispels:UpdateState(frame, settings)
		end

		if managedContainers.defensives then
			addon.Frames.ManagedContainers.Defensives:UpdateState(frame, settings)
		end

		if managedContainers.buffOverlay then
			addon.Frames.ManagedContainers.BuffOverlay:UpdateState(frame, settings)
		end

		if managedContainers.raidBuffReminder and settings then
			addon.Frames.ManagedContainers.RaidBuffReminder:UpdateState(frame, settings)
		end
	end)
end

function FrameRegistry:UpdateManagedContainersUnit(unit)
	if not initialized then
		return
	end

	self:UpdateUnit(unit, function(frame, settings)
		if not frame.managedContainers then
			return
		end

		if frame.managedContainers.buffs then
			addon.Frames.ManagedContainers.Buffs:SetUnit(frame, settings)
		end

		if frame.managedContainers.customBuffs then
			addon.Frames.ManagedContainers.CustomBuffs:SetUnit(frame, settings)
		end

		if frame.managedContainers.debuffs then
			addon.Frames.ManagedContainers.Debuffs:SetUnit(frame, settings)
		end

		if frame.managedContainers.dispels then
			addon.Frames.ManagedContainers.Dispels:SetUnit(frame, settings)
		end

		if frame.managedContainers.defensives then
			addon.Frames.ManagedContainers.Defensives:SetUnit(frame, settings)
		end

		if frame.managedContainers.buffOverlay then
			addon.Frames.ManagedContainers.BuffOverlay:SetUnit(frame, settings)
		end

		if frame.managedContainers.raidBuffReminder then
			addon.Frames.ManagedContainers.RaidBuffReminder:SetUnit(frame, settings)
		end
	end)
end

function FrameRegistry:HideManagedContainers(unit)
	if not initialized then
		return
	end

	self:UpdateUnit(unit, function(frame)
		local managedContainers = frame.managedContainers
		if not managedContainers then
			return
		end

		if managedContainers.buffs then
			if managedContainers.buffs.isShown ~= false or managedContainers.buffs:IsShown() then
				managedContainers.buffs.isShown = false
				managedContainers.buffs:Hide()
			end
		end

		if managedContainers.customBuffs then
			if managedContainers.customBuffs.isShown ~= false or managedContainers.customBuffs:IsShown() then
				managedContainers.customBuffs.isShown = false
				managedContainers.customBuffs:Hide()
			end
		end

		if managedContainers.debuffs then
			if managedContainers.debuffs.isShown ~= false or managedContainers.debuffs:IsShown() then
				managedContainers.debuffs.isShown = false
				managedContainers.debuffs:Hide()
			end
		end

		if managedContainers.dispels then
			if managedContainers.dispels.isEnabled ~= false then
				managedContainers.dispels.isEnabled = false
				managedContainers.dispels:SetEnabled(false)
			end
		end

		if managedContainers.defensives then
			if managedContainers.defensives.isShown ~= false or managedContainers.defensives:IsShown() then
				managedContainers.defensives.isShown = false
				managedContainers.defensives:Hide()
			end
		end

		if managedContainers.buffOverlay then
			if managedContainers.buffOverlay.isShown ~= false or managedContainers.buffOverlay:IsShown() then
				managedContainers.buffOverlay.isShown = false
				managedContainers.buffOverlay:Hide()
			end
		end

		if managedContainers.raidBuffReminder then
			if managedContainers.raidBuffReminder.wrapper:IsShown() then
				managedContainers.raidBuffReminder.wrapper:Hide()
			end
		end
	end)
end

local function UpdateFrame(frame, settings, stateCallback, settingsCallback)
	if (not InCombatLockdown()) and type(settingsCallback) == "function" then
		settingsCallback(frame, settings)
	end

	if type(stateCallback) == "function" then
		stateCallback(frame, settings)
	end
end

function FrameRegistry:UpdateUnit(unit, stateCallback, settingsCallback)
	if not initialized then
		error("FrameRegistry is not initialized", 2)
	end

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = self:ResolveRaidSettings(profile)

	local bossIndex = unit and unit:match("^boss(%d)$")
	if bossIndex then
		local partyBossFrame = partyBossGroup.frames[tonumber(bossIndex)]
		if partyBossFrame then
			UpdateFrame(partyBossFrame, partySettings, stateCallback, settingsCallback)
		end

		local raidBossFrame = raidBossGroup.frames[tonumber(bossIndex)]
		if raidBossFrame then
			UpdateFrame(raidBossFrame, raidSettings, stateCallback, settingsCallback)
		end

		return
	end

	local frame = unitFrameMap[unit]
	if frame then
		local settings
		if unit == "player" or unit:match("^party%d$") then
			settings = partySettings
		else
			settings = raidSettings
		end
		UpdateFrame(frame, settings, stateCallback, settingsCallback)
	end
end

function FrameRegistry:UpdateAllUnits(stateCallback, settingsCallback)
	if not initialized then
		error("FrameRegistry is not initialized", 2)
	end

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = self:ResolveRaidSettings(profile)

	for i = 1, 5 do
		local frame = partyHeader.container:GetAttribute("child" .. i)
		if frame then
			UpdateFrame(frame, partySettings, stateCallback, settingsCallback)
		end
	end

	for _, header in ipairs(raidHeaders.containers) do
		for i = 1, 5 do
			local frame = header:GetAttribute("child" .. i)
			if frame then
				UpdateFrame(frame, raidSettings, stateCallback, settingsCallback)
			end
		end
	end

	for _, frame in ipairs(partyBossGroup.frames) do
		UpdateFrame(frame, partySettings, stateCallback, settingsCallback)
	end

	for _, frame in ipairs(raidBossGroup.frames) do
		UpdateFrame(frame, raidSettings, stateCallback, settingsCallback)
	end

	if previewFrames.party then
		UpdateFrame(previewFrames.party, partySettings, stateCallback, settingsCallback)
	end

	if previewFrames.raid then
		UpdateFrame(previewFrames.raid, profile.raid or {}, stateCallback, settingsCallback)
	end
end

function FrameRegistry:UpdateRoster()
	if not initialized then
		error("FrameRegistry is not initialized", 2)
	end

	local profile = addon.Database:GetProfile()
	local showGroupLabel = profile.raid and profile.raid.showGroupLabel == true

	for _, header in ipairs(raidHeaders.containers) do
		if not showGroupLabel then
			header.groupText:Hide()
		else
			local hasUnits = false

			for i = 1, 5 do
				local frame = header:GetAttribute("child" .. i)
				if frame.unit and UnitExists(frame.unit) then
					hasUnits = true
					break
				end
			end

			header.groupText:SetShown(hasUnits)
		end
	end

	for unit, frame in pairs(unitFrameMap) do
		if not IsSupportedUnit(unit) then
			frame.RosterKey = nil
		else
			local guid = UnitExists(unit) and UnitGUID(unit) or nil
			local rosterKey = unit .. ":" .. (guid or "none")
			if frame.RosterKey ~= rosterKey then
				if not addon.IsRestrictedAuraAPI then
					addon.AuraHandler:UpdateAurasForUnit(unit)
				end

				addon.Modules:RequestUpdateState(unit)
				frame.RosterKey = rosterKey
			end
		end
	end
end

function FrameRegistry:UpdateLayout()
	if InCombatLockdown() then
		self.needsLayoutUpdateAfterCombat = true
		return
	end

	self.needsLayoutUpdateAfterCombat = false

	if not initialized then
		error("FrameRegistry is not initialized", 2)
	end

	ApplyBlizzardFramesVisibility()
	self:UpdateStateDrivers()

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = self:ResolveRaidSettings(profile)

	if testPartyGroup.isActive and testPartyGroup.container then
		addon.Frames:UpdateLayout(testPartyGroup, partySettings)
	end

	if testPartyBossGroup.isActive and testPartyBossGroup.container then
		addon.Frames:UpdateLayout(testPartyBossGroup, partySettings)
	end

	if testRaidGroup.isActive and testRaidGroup.container then
		addon.Frames:UpdateLayout(testRaidGroup, profile.raid or {})
	end

	if testRaidBossGroup.isActive and testRaidBossGroup.container then
		addon.Frames:UpdateLayout(testRaidBossGroup, profile.raid or {})
	end

	local previewSection = addon.Options and addon.Options.Preview
	if previewSection and previewSection.UpdateFrameLayout then
		if previewFrames.party then
			previewSection:UpdateFrameLayout(previewFrames.party, partySettings)
		end

		if previewFrames.raid then
			previewSection:UpdateFrameLayout(previewFrames.raid, profile.raid or {})
		end
	end

	addon.Frames:UpdateLayout(partyHeader, partySettings)
	addon.Frames:UpdateLayout(partyBossGroup, partySettings)
	addon.Frames:UpdateLayout(raidHeaders, raidSettings)
	addon.Frames:UpdateLayout(raidBossGroup, raidSettings)
end

function FrameRegistry:Initialize()
	if initialized then
		return
	end

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = self:ResolveRaidSettings(profile)

	partyHeader.container = addon.Frames:CreatePartyHeader(partySettings)
	partyBossGroup.container = addon.Frames:CreateBossUnitGroup("MRF_PartyBossUnitGroup", "party")
	partyBossGroup.frames = partyBossGroup.container.frames

	for groupIndex = 1, 8 do
		raidHeaders.containers[groupIndex] = addon.Frames:CreateRaidHeader(raidSettings, groupIndex)
	end

	raidBossGroup.container = addon.Frames:CreateBossUnitGroup("MRF_RaidBossUnitGroup", "raid")
	raidBossGroup.frames = raidBossGroup.container.frames

	ApplyBlizzardFramesVisibility()
	self:UpdateStateDrivers(true)

	initialized = true
	self:UpdateClickCasting()

	addon.Frames:UpdateLayout(partyHeader, partySettings)
	addon.Frames:UpdateLayout(partyBossGroup, partySettings)
	addon.Frames:UpdateLayout(raidHeaders, raidSettings)
	addon.Frames:UpdateLayout(raidBossGroup, raidSettings)
	RegisterMiniCCProvider()
end

function FrameRegistry:IsInitialized()
	return initialized
end

function FrameRegistry:CreatePreviewFrames(parent)
	if not parent then
		error("FrameRegistry:CreatePreviewFrames requires parent", 2)
	end

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = profile.raid or {}

	if not previewFrames.party then
		previewFrames.party = addon.Frames:CreatePreviewFrame(parent, "party")
		addon.Modules:EnsureFrame(previewFrames.party, partySettings)
		addon.Modules:UpdateSettingsFrame(previewFrames.party, partySettings)
	end

	if not previewFrames.raid then
		previewFrames.raid = addon.Frames:CreatePreviewFrame(parent, "raid")
		addon.Modules:EnsureFrame(previewFrames.raid, raidSettings)
		addon.Modules:UpdateSettingsFrame(previewFrames.raid, raidSettings)
	end

	return previewFrames.party, previewFrames.raid
end

function FrameRegistry:CreateTestGroup(groupType)
	local group
	local settings
	local frameCount
	local frameGroupType

	if groupType == "party" then
		group = testPartyGroup
		settings = addon.Database:GetProfile().party or {}
		frameCount = 5
		frameGroupType = "Party"
	elseif groupType == "raid" then
		group = testRaidGroup
		settings = addon.Database:GetProfile().raid or {}
		frameCount = 40
		frameGroupType = "Raid"
	else
		error("FrameRegistry:CreateTestGroup requires 'party' or 'raid'", 2)
	end

	if group.container then
		return group
	end

	group.container = addon.Frames:CreateTestGroup(frameGroupType)

	for frameIndex = 1, frameCount do
		local frame = addon.Frames:CreateTestFrame(group.container, frameIndex)
		group.frames[frameIndex] = frame
	end

	addon.Frames:UpdateLayout(group, settings)

	group.container:Hide()

	return group
end

function FrameRegistry:CreateBossTestGroup(groupType)
	local group
	local settings
	local groupName

	if groupType == "party" then
		group = testPartyBossGroup
		settings = addon.Database:GetProfile().party or {}
		groupName = "MRF_TestPartyBossGroup"
	elseif groupType == "raid" then
		group = testRaidBossGroup
		settings = addon.Database:GetProfile().raid or {}
		groupName = "MRF_TestRaidBossGroup"
	else
		error("FrameRegistry:CreateBossTestGroup requires 'party' or 'raid'", 2)
	end

	if group.container then
		return group
	end

	group.container = addon.Frames:CreateBossTestGroup(groupName, groupType)

	for frameIndex = 1, 5 do
		local frame = addon.Frames:CreateTestFrame(group.container, frameIndex)
		frame.testName = "NPC Frame"
		frame.testText:SetText("NPC Frame")
		group.frames[frameIndex] = frame
	end

	addon.Frames:UpdateLayout(group, settings)

	group.container:Hide()

	return group
end

function FrameRegistry:EnableTestMode(groupType)
	if InCombatLockdown() then
		return
	end

	local group
	local bossGroup
	if groupType == "party" then
		group = testPartyGroup
		bossGroup = testPartyBossGroup
	elseif groupType == "raid" then
		group = testRaidGroup
		bossGroup = testRaidBossGroup
	else
		error("FrameRegistry:EnableTestMode requires 'party' or 'raid'", 2)
	end

	if not group.container then
		self:CreateTestGroup(groupType)
	else
		local settings
		if groupType == "party" then
			settings = addon.Database:GetProfile().party or {}
		else
			settings = addon.Database:GetProfile().raid or {}
		end

		addon.Frames:UpdateLayout(group, settings)
	end

	if not bossGroup.container then
		self:CreateBossTestGroup(groupType)
	else
		local settings
		if groupType == "party" then
			settings = addon.Database:GetProfile().party or {}
		else
			settings = addon.Database:GetProfile().raid or {}
		end

		addon.Frames:UpdateLayout(bossGroup, settings)
	end

	group.container:Show()
	group.isActive = true
	bossGroup.container:Show()
	bossGroup.isActive = true

	self:UpdateStateDrivers()
end

function FrameRegistry:DisableTestMode(groupType, skipDriverUpdate)
	local disableParty = (groupType == nil or groupType == "party")
	local disableRaid = (groupType == nil or groupType == "raid")

	if groupType ~= nil and groupType ~= "party" and groupType ~= "raid" then
		error("FrameRegistry:DisableTestMode requires 'party', 'raid', or nil", 2)
	end

	if disableParty then
		testPartyGroup.isActive = false

		if testPartyGroup.container then
			testPartyGroup.container:Hide()
		end

		testPartyBossGroup.isActive = false

		if testPartyBossGroup.container then
			testPartyBossGroup.container:Hide()
		end
	end

	if disableRaid then
		testRaidGroup.isActive = false

		if testRaidGroup.container then
			testRaidGroup.container:Hide()
		end

		testRaidBossGroup.isActive = false

		if testRaidBossGroup.container then
			testRaidBossGroup.container:Hide()
		end
	end

	if InCombatLockdown() then
		self.restoreLiveDriversAfterCombat = true
		return
	end

	if not skipDriverUpdate then
		self:UpdateStateDrivers()
	end
end

function FrameRegistry:GetActiveTestMode()
	if testPartyGroup.isActive then
		return "party"
	end

	if testRaidGroup.isActive then
		return "raid"
	end

	return nil
end

function FrameRegistry:ToggleTestMode(groupType)
	if InCombatLockdown() then
		return
	end

	if groupType == "party" then
		if testPartyGroup.isActive then
			self:DisableTestMode("party")
		else
			-- TODO: Change so Live is not applied on Disable and immediately changed on Enable
			self:DisableTestMode("raid", true)
			self:EnableTestMode("party")
		end
		return
	end

	if groupType == "raid" then
		if testRaidGroup.isActive then
			self:DisableTestMode("raid")
		else
			-- TODO: Change so Live is not applied on Disable and immediately changed on Enable
			self:DisableTestMode("party", true)
			self:EnableTestMode("raid")
		end
		return
	end
end
