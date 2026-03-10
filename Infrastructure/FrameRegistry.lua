local _, addon = ...

local FrameRegistry = {}
addon.FrameRegistry = FrameRegistry

local initialized = false
local compactOverlayHooksInstalled = false
local restoreLiveDriversAfterCombat = false

local partyGroup = {
	type = "party",
	container = nil,
	frames = {},
}

local raidGroup = {
	type = "raid",
	container = nil,
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

function FrameRegistry:UpdateStateDrivers(allowInCombat)
	local profile = addon.Database:GetProfile()
	local showSoloPartyFrame = profile and profile.core and profile.core.showSoloPartyFrame == true
	local testModeActive = testPartyGroup.isActive or testRaidGroup.isActive

	if InCombatLockdown() and allowInCombat ~= true then
		return
	end

	UnregisterStateDriver(raidGroup.container, "visibility")
	UnregisterStateDriver(partyGroup.container, "visibility")

	if testModeActive then
		RegisterStateDriver(raidGroup.container, "visibility", "[@player,combat,group:raid] show; hide")

		if showSoloPartyFrame then
			RegisterStateDriver(partyGroup.container, "visibility", "[@player,combat,nogroup:raid] show; hide")
		else
			RegisterStateDriver(
				partyGroup.container,
				"visibility",
				"[@player,combat,group:party,nogroup:raid] show; hide"
			)
		end

		restoreLiveDriversAfterCombat = false
		return
	end

	RegisterStateDriver(raidGroup.container, "visibility", "[@player,group:raid] show; hide")

	if showSoloPartyFrame then
		RegisterStateDriver(partyGroup.container, "visibility", "[@player,group:raid] hide; show")
	else
		RegisterStateDriver(partyGroup.container, "visibility", "[@player,group:party,nogroup:raid] show; hide")
	end

	restoreLiveDriversAfterCombat = false
end

local function ShouldHideBlizzardFrames()
	local profile = addon.Database:GetProfile()
	return profile and profile.core and profile.core.hideBlizzardRaidFrames == true
end

local function IsRaidPartyCompactUnit(frame)
	if not frame then
		return false
	end
	local unit = frame.displayedUnit or frame.unit
	if type(unit) ~= "string" then
		return false
	end
	return unit == "player" or unit:match("^party%d$") or unit:match("^raid%d+$")
end

local function SafeHide(obj)
	if obj and obj.Hide then
		pcall(function()
			obj:Hide()
		end)
	end
end

local function HideCompactVisualOverlays(frame)
	if not frame or not IsRaidPartyCompactUnit(frame) then
		return
	end

	SafeHide(frame.selectionHighlight)
	SafeHide(frame.aggroHighlight)

	SafeHide(frame.readyCheckIcon)
	SafeHide(frame.readyCheckStatus)

	SafeHide(frame.summonStatus)
	SafeHide(frame.summonIcon)
	SafeHide(frame.summonFrame)
end

local function InstallCompactOverlayHooks()
	if compactOverlayHooksInstalled then
		return
	end
	compactOverlayHooksInstalled = true

	local function HideIfNeeded(frame)
		if ShouldHideBlizzardFrames() then
			HideCompactVisualOverlays(frame)
		end
	end

	local hookNames = {
		"CompactUnitFrame_UpdateSelectionHighlight",
		"CompactUnitFrame_UpdateAggroHighlight",
		"CompactUnitFrame_UpdateReadyCheck",
		"CompactUnitFrame_UpdateReadyCheckStatus",
		"CompactUnitFrame_UpdateSummonStatus",
		"CompactUnitFrame_UpdateStatusIcon",
	}

	for _, fnName in ipairs(hookNames) do
		local fn = _G[fnName]
		if type(fn) == "function" then
			hooksecurefunc(fnName, HideIfNeeded)
		end
	end
end

local function ApplyBlizzardFramesVisibility()
	local hide = ShouldHideBlizzardFrames()
	local visible = not hide

	local function SetFrameTreeVisibility(frame, visible)
		if not frame then
			return
		end

		frame:SetAlpha(visible and 1 or 0)

		if frame.EnableMouse then
			frame:EnableMouse(visible)
		end

		if frame.SetMouseClickEnabled then
			frame:SetMouseClickEnabled(visible)
		end

		if frame.SetMouseMotionEnabled then
			frame:SetMouseMotionEnabled(visible)
		end

		local children = { frame:GetChildren() }
		for _, child in ipairs(children) do
			if child.SetAlpha then
				child:SetAlpha(visible and 1 or 0)
			end
			if child.EnableMouse then
				child:EnableMouse(visible)
			end
		end
	end

	SetFrameTreeVisibility(CompactPartyFrame, visible)
	SetFrameTreeVisibility(CompactRaidFrameContainer, visible)
	SetFrameTreeVisibility(CompactRaidFrameManager, visible)

	InstallCompactOverlayHooks()
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

	UpdateGroup(partyGroup, partySettings)
	UpdateGroup(raidGroup, raidSettings)

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

	local frame = unitFrameMap[unit]
	if not frame then
		return
	end

	local settings
	if frame.unit == "player" or frame.unit:match("^party%d$") then
		settings = partySettings
	else
		settings = raidSettings
	end

	if (not inCombat) and type(settingsCallback) == "function" then
		settingsCallback(frame, settings)
	end

	if type(stateCallback) == "function" then
		stateCallback(frame, settings)
	end
end

function FrameRegistry:UpdateLayout()
	if InCombatLockdown() then
		return
	end

	if not initialized then
		error("FrameRegistry is not initialized", 2)
	end

	ApplyBlizzardFramesVisibility()

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = ResolveRaidSettings(profile)

	if testPartyGroup.isActive and testPartyGroup.container then
		addon.Frames:UpdateLayout(testPartyGroup, partySettings)
	end

	if testRaidGroup.isActive and testRaidGroup.container then
		addon.Frames:UpdateLayout(testRaidGroup, profile.raid or {})
	end

	addon.Frames:UpdateLayout(partyGroup, partySettings)
	addon.Frames:UpdateLayout(raidGroup, raidSettings)
end

function FrameRegistry:Initialize()
	if initialized then
		return
	end

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = ResolveRaidSettings(profile)

	partyGroup.container = addon.Frames:CreateGroup("Party")
	raidGroup.container = addon.Frames:CreateGroup("Raid")

	local function CreateUnitFramesForGroup(group, units)
		for unitIndex, unit in ipairs(units) do
			local frame = addon.Frames:CreateFrame(group.container, unit, unitIndex)
			group.frames[unitIndex] = frame
			unitFrameMap[unit] = frame
		end
	end

	local raidUnits = {}
	for raidIndex = 1, 40 do
		raidUnits[raidIndex] = "raid" .. raidIndex
	end

	CreateUnitFramesForGroup(partyGroup, { "player", "party1", "party2", "party3", "party4" })
	CreateUnitFramesForGroup(raidGroup, raidUnits)

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

	EnsureWidgetsAndUpdateSettings(partyGroup, partySettings)
	EnsureWidgetsAndUpdateSettings(raidGroup, raidSettings)

	initialized = true

	addon.Frames:UpdateLayout(partyGroup, partySettings)
	addon.Frames:UpdateLayout(raidGroup, raidSettings)
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
		restoreLiveDriversAfterCombat = true
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

function FrameRegistry:ShouldRestoreLiveDriversAfterCombat()
	return restoreLiveDriversAfterCombat
end
