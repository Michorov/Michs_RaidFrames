local _, addon = ...

local FrameRegistry = {}
addon.FrameRegistry = FrameRegistry

local initialized = false

FrameRegistry.restoreLiveDriversAfterCombat = false
FrameRegistry.needsLayoutUpdateAfterCombat = false

local partyHeader = {
	type = "party",
	isSecureHeader = true,
	container = nil,
}

local raidHeaders = {
	type = "raid",
	isSecureHeader = true,
	containers = {},
}

local testPartyGroup = {
	type = "party",
	isTestGroup = true,
	isActive = false,
	container = nil,
	frames = {},
}

local testRaidGroup = {
	type = "raid",
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
	frame.dataProvider = addon.Frames.DataProvider.Live

	local targetedSpellsApi = _G.TargetedSpellsAPI
	if targetedSpellsApi and targetedSpellsApi.RegisterFrameByName then
		local name = frame:GetName()
		if name then
			targetedSpellsApi.RegisterFrameByName(name)
		end
	end

	if _G.ClickCastFrames then
		_G.ClickCastFrames[frame] = true
	end

	local settings = addon.FrameRegistry:GetSettingsForFrame(frame)
	if settings then
		addon.Modules:EnsureFrame(frame, settings)
		addon.Modules:UpdateSettingsFrame(frame, settings)
	end
end

function MRF_OnUnitChanged(frame, unit)
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
		local managedUnit = isSupportedUnit and unit or "none"

		if frame.managedContainers.debuffs then
			frame.managedContainers.debuffs:SetUnit(managedUnit)
		end

		if frame.managedContainers.buffs then
			frame.managedContainers.buffs:SetUnit(managedUnit)
		end

		if frame.managedContainers.customBuffs then
			frame.managedContainers.customBuffs:SetUnit(managedUnit)
		end

		if frame.managedContainers.defensives then
			frame.managedContainers.defensives:SetUnit(managedUnit)
		end

		if frame.managedContainers.buffOverlay then
			frame.managedContainers.buffOverlay:SetUnit(managedUnit)
		end

		if frame.managedContainers.raidBuffReminder then
			frame.managedContainers.raidBuffReminder:SetUnit(managedUnit)
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

	if InCombatLockdown() and allowInCombat ~= true then
		return
	end

	UnregisterStateDriver(partyHeader.container, "visibility")
	for _, raidContainer in ipairs(raidHeaders.containers) do
		UnregisterStateDriver(raidContainer, "visibility")
	end

	local raidGroupSettings = (profile.raid and profile.raid.groups) or {}

	if testModeActive then
		if showSoloPartyFrame then
			RegisterStateDriver(partyHeader.container, "visibility", "[@player,combat,nogroup:raid] show; hide")
		else
			RegisterStateDriver(
				partyHeader.container,
				"visibility",
				"[@player,combat,group:party,nogroup:raid] show; hide"
			)
		end

		for groupIndex, raidContainer in ipairs(raidHeaders.containers) do
			if raidGroupSettings[groupIndex] then
				RegisterStateDriver(raidContainer, "visibility", "[@player,combat,group:raid] show; hide")
			else
				RegisterStateDriver(raidContainer, "visibility", "hide")
			end
		end

		self.restoreLiveDriversAfterCombat = false
		NotifyMiniCCFramesChanged()
		return
	end

	if showSoloPartyFrame then
		RegisterStateDriver(partyHeader.container, "visibility", "[@player,nogroup:raid] show; hide")
	else
		RegisterStateDriver(partyHeader.container, "visibility", "[@player,group:party,nogroup:raid] show; hide")
	end

	for groupIndex, raidContainer in ipairs(raidHeaders.containers) do
		if raidGroupSettings[groupIndex] then
			RegisterStateDriver(raidContainer, "visibility", "[@player,group:raid] show; hide")
		else
			RegisterStateDriver(raidContainer, "visibility", "hide")
		end
	end

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
	if not parent then
		return nil
	end

	local headerKind = parent.HeaderKind
	if not headerKind then
		local parentName = parent.GetName and parent:GetName() or nil
		if parentName == "MRF_PartyHeader" then
			headerKind = "party"
		elseif parentName and parentName:match("^MRF_RaidHeader%d+$") then
			headerKind = "raid"
		end
	end

	if headerKind == "party" then
		return profile.party or {}
	end

	if headerKind == "raid" then
		return self:ResolveRaidSettings(profile)
	end

	return nil
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

	for unit, frame in pairs(unitFrameMap) do
		if not IsSupportedUnit(unit) then
			frame.RosterKey = nil
		else
			local guid = UnitExists(unit) and UnitGUID(unit) or nil
			local rosterKey = unit .. ":" .. (guid or "none")
			if frame.RosterKey ~= rosterKey then
				addon.AuraHandler:UpdateAurasForUnit(unit)
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

	if testRaidGroup.isActive and testRaidGroup.container then
		addon.Frames:UpdateLayout(testRaidGroup, profile.raid or {})
	end

	local previewSection = addon.Options and addon.Options.Sections and addon.Options.Sections.Preview
	if previewSection and previewSection.UpdateFrameLayout then
		if previewFrames.party then
			previewSection:UpdateFrameLayout(previewFrames.party, partySettings)
		end

		if previewFrames.raid then
			previewSection:UpdateFrameLayout(previewFrames.raid, profile.raid or {})
		end
	end

	addon.Frames:UpdateLayout(partyHeader, partySettings)
	addon.Frames:UpdateLayout(raidHeaders, raidSettings)
end

function FrameRegistry:Initialize()
	if initialized then
		return
	end

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = self:ResolveRaidSettings(profile)

	partyHeader.container = addon.Frames:CreatePartyHeader(partySettings)

	for groupIndex = 1, 8 do
		raidHeaders.containers[groupIndex] = addon.Frames:CreateRaidHeader(raidSettings, groupIndex)
	end

	ApplyBlizzardFramesVisibility()
	self:UpdateStateDrivers(true)

	initialized = true

	addon.Frames:UpdateLayout(partyHeader, partySettings)
	addon.Frames:UpdateLayout(raidHeaders, raidSettings)
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
		previewFrames.party = addon.Frames:CreatePreviewFrame(parent)
		addon.Modules:EnsureFrame(previewFrames.party, partySettings)
		addon.Modules:UpdateSettingsFrame(previewFrames.party, partySettings)
	end

	if not previewFrames.raid then
		previewFrames.raid = addon.Frames:CreatePreviewFrame(parent)
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

function FrameRegistry:EnableTestMode(groupType)
	if InCombatLockdown() then
		return
	end

	local group
	if groupType == "party" then
		group = testPartyGroup
	elseif groupType == "raid" then
		group = testRaidGroup
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

	group.container:Show()
	group.isActive = true

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
	end

	if disableRaid then
		testRaidGroup.isActive = false

		if testRaidGroup.container then
			testRaidGroup.container:Hide()
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
