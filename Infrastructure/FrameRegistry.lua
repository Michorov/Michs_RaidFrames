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
	frames = {},
}

local raidHeaders = {
	type = "raid",
	isSecureHeader = true,
	containers = {},
	frames = {},
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

local unitFrameMap = {}

function MRF_OnUnitChanged(frame, unit)
	if unit then
		unitFrameMap[unit] = frame
	else
		for k, v in pairs(unitFrameMap) do
			if v == frame then
				unitFrameMap[k] = nil
				break
			end
		end
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

local function ResolveRaidSettings(profile)
	local partySettings = profile.party or {}
	local raidSettings = profile.raid or {}

	local _, instanceType = IsInInstance()
	local inArena = (instanceType == "arena")

	if inArena then
		return partySettings
	end

	return raidSettings
end

function FrameRegistry:UpdateAllUnits(stateCallback, settingsCallback)
	if not initialized then
		error("FrameRegistry is not initialized", 2)
	end

	local inCombat = InCombatLockdown()

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = ResolveRaidSettings(profile)

	local function UpdateGroup(group, settings)
		if not group or not group.frames then
			return
		end

		for _, frame in ipairs(group.frames) do
			if (not inCombat) and type(settingsCallback) == "function" then
				settingsCallback(frame, settings)
			end

			if type(stateCallback) == "function" then
				stateCallback(frame, settings)
			end
		end
	end

	UpdateGroup(partyHeader, partySettings)
	UpdateGroup(raidHeaders, raidSettings)

	if testPartyGroup.isActive then
		UpdateGroup(testPartyGroup, partySettings)
	end

	if testRaidGroup.isActive then
		UpdateGroup(testRaidGroup, profile.raid or {})
	end
end

function FrameRegistry:UpdateUnit(unit, stateCallback, settingsCallback)
	if not initialized then
		error("FrameRegistry is not initialized", 2)
	end

	local inCombat = InCombatLockdown()

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = ResolveRaidSettings(profile)

	local function UpdateFrame(frame, settings)
		if (not inCombat) and type(settingsCallback) == "function" then
			settingsCallback(frame, settings)
		end
		if type(stateCallback) == "function" then
			stateCallback(frame, settings)
		end
	end

	local frame = unitFrameMap[unit]
	if frame then
		local settings
		if unit == "player" or unit:match("^party%d$") then
			settings = partySettings
		else
			settings = raidSettings
		end
		UpdateFrame(frame, settings)
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
	local raidSettings = ResolveRaidSettings(profile)

	if testPartyGroup.isActive and testPartyGroup.container then
		addon.Frames:UpdateLayout(testPartyGroup, partySettings)
	end

	if testRaidGroup.isActive and testRaidGroup.container then
		addon.Frames:UpdateLayout(testRaidGroup, profile.raid or {})
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
	local raidSettings = ResolveRaidSettings(profile)

	local header = addon.Frames:CreatePartyHeader(partySettings)
	partyHeader.container = header

	for i = 1, 5 do
		local frame = header:GetAttribute("child" .. i)
		if frame then
			partyHeader.frames[i] = frame
		end
	end

	for groupIndex = 1, 8 do
		local raidHeader = addon.Frames:CreateRaidHeader(raidSettings, groupIndex)
		raidHeaders.containers[groupIndex] = raidHeader

		for i = 1, 5 do
			local frame = raidHeader:GetAttribute("child" .. i)
			if frame then
				table.insert(raidHeaders.frames, frame)
			end
		end
	end

	ApplyBlizzardFramesVisibility()
	self:UpdateStateDrivers(true)

	local function EnsureWidgetsAndUpdateSettings(group, settings)
		if not group or not group.frames then
			return
		end

		for _, unitFrame in ipairs(group.frames) do
			addon.Modules:EnsureFrame(unitFrame, settings)
			addon.Modules:UpdateSettingsFrame(unitFrame, settings)
		end
	end

	EnsureWidgetsAndUpdateSettings(partyHeader, partySettings)
	EnsureWidgetsAndUpdateSettings(raidHeaders, raidSettings)

	initialized = true

	addon.Frames:UpdateLayout(partyHeader, partySettings)
	addon.Frames:UpdateLayout(raidHeaders, raidSettings)
end

function FrameRegistry:IsInitialized()
	return initialized
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

		addon.Modules:EnsureFrame(frame, settings)
		addon.Modules:UpdateSettingsFrame(frame, settings)
		addon.Frames.Base.Health:UpdateState(frame, settings)
		addon.Frames.Base.Power:UpdateState(frame, settings)
		addon.Frames.Widgets.Texts.Name:UpdateState(frame, settings)
		addon.Frames.Widgets.Bars.Absorbs:UpdateState(frame, settings)
		addon.Frames.Widgets.Bars.HealAbsorbs:UpdateState(frame, settings)
		addon.Frames.Widgets.Icons.Buffs:UpdateState(frame, settings)
		addon.Frames.Widgets.Icons.Debuffs:UpdateState(frame, settings)
		addon.Frames.Widgets.Icons.BigDefensive:UpdateState(frame, settings)
		addon.Frames.Widgets.Icons.Dispels:UpdateState(frame, settings)
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

		for _, frame in ipairs(group.frames) do
			addon.Modules:UpdateSettingsFrame(frame, settings)
			addon.Frames.Base.Health:UpdateState(frame, settings)
			addon.Frames.Base.Power:UpdateState(frame, settings)
			addon.Frames.Widgets.Texts.Name:UpdateState(frame, settings)
			addon.Frames.Widgets.Bars.Absorbs:UpdateState(frame, settings)
			addon.Frames.Widgets.Bars.HealAbsorbs:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.Buffs:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.Debuffs:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.BigDefensive:UpdateState(frame, settings)
			addon.Frames.Widgets.Icons.Dispels:UpdateState(frame, settings)
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

