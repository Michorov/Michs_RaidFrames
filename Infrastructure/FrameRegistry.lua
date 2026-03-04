local _, addon = ...

local FrameRegistry = {}
addon.FrameRegistry = FrameRegistry

local initialized = false
local compactOverlayHooksInstalled = false

local soloGroup = {
	type = "party",
	container = nil,
	frames = {},
}

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

local function ApplySoloVisibilityDriver()
	local profile = addon.Database:GetProfile()
	local showSoloPartyFrame = profile and profile.core and profile.core.showSoloPartyFrame == true

	if InCombatLockdown() then
		return
	end

	if showSoloPartyFrame then
		RegisterStateDriver(soloGroup.container, "visibility", "[group] hide; show")
	else
		RegisterStateDriver(soloGroup.container, "visibility", "hide")
	end
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

	UpdateGroup(soloGroup, partySettings)
	UpdateGroup(partyGroup, partySettings)
	UpdateGroup(raidGroup, raidSettings)
end

function FrameRegistry:UpdateUnit(unit, stateCallback, settingsCallback)
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
			if frame and frame.unit == unit then
				if (not inCombat) and type(settingsCallback) == "function" then
					settingsCallback(frame, settings)
				end

				if type(stateCallback) == "function" then
					stateCallback(frame, settings)
				end

				return
			end
		end
	end

	UpdateGroup(soloGroup, partySettings)
	UpdateGroup(partyGroup, partySettings)
	UpdateGroup(raidGroup, raidSettings)
end

function FrameRegistry:UpdateLayout()
	if InCombatLockdown() then
		return
	end

	if not initialized then
		error("FrameRegistry is not initialized", 2)
	end

	ApplySoloVisibilityDriver()
	ApplyBlizzardFramesVisibility()

	local profile = addon.Database:GetProfile()
	local partySettings = profile.party or {}
	local raidSettings = ResolveRaidSettings(profile)

	addon.Frames:UpdateLayout(soloGroup, partySettings)
	addon.Frames:UpdateLayout(partyGroup, partySettings)
	addon.Frames:UpdateLayout(raidGroup, raidSettings)
end

function FrameRegistry:Initialize()
	if initialized then
		return
	end

	local profile = addon.Database:GetProfile()
	local showSoloPartyFrame = profile and profile.core and profile.core.showSoloPartyFrame == true
	local partySettings = profile.party or {}
	local raidSettings = ResolveRaidSettings(profile)

	soloGroup.container = addon.Frames:CreateGroup("Solo")
	partyGroup.container = addon.Frames:CreateGroup("Party")
	raidGroup.container = addon.Frames:CreateGroup("Raid")

	local function CreateUnitFramesForGroup(group, units)
		for unitIndex, unit in ipairs(units) do
			local frame = addon.Frames:CreateFrame(group.container, unit, unitIndex)
			group.frames[unitIndex] = frame
		end
	end

	local raidUnits = {}
	for raidIndex = 1, 40 do
		raidUnits[raidIndex] = "raid" .. raidIndex
	end

	CreateUnitFramesForGroup(soloGroup, { "player" })
	CreateUnitFramesForGroup(partyGroup, { "player", "party1", "party2", "party3", "party4" })
	CreateUnitFramesForGroup(raidGroup, raidUnits)

	RegisterStateDriver(raidGroup.container, "visibility", "[@player,group:raid] show; hide")
	RegisterStateDriver(partyGroup.container, "visibility", "[@player,group:party,nogroup:raid] show; hide")

	if showSoloPartyFrame then
		RegisterStateDriver(soloGroup.container, "visibility", "[@player,nogroup] show; hide")
	else
		RegisterStateDriver(soloGroup.container, "visibility", "hide")
	end

	local function EnsureWidgetsAndUpdateSettings(group, settings)
		if not group or not group.frames then
			return
		end

		for _, unitFrame in ipairs(group.frames) do
			addon.Modules:EnsureFrame(unitFrame, settings)
			addon.Modules:UpdateSettingsFrame(unitFrame, settings)
		end
	end

	EnsureWidgetsAndUpdateSettings(soloGroup, partySettings)
	EnsureWidgetsAndUpdateSettings(partyGroup, partySettings)
	EnsureWidgetsAndUpdateSettings(raidGroup, raidSettings)

	initialized = true

	addon.Frames:UpdateLayout(soloGroup, partySettings)
	addon.Frames:UpdateLayout(partyGroup, partySettings)
	addon.Frames:UpdateLayout(raidGroup, raidSettings)
end

function FrameRegistry:IsInitialized()
	return initialized
end
