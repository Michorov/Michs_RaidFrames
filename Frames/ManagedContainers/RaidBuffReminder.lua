local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.RaidBuffReminder = addon.Frames.ManagedContainers.RaidBuffReminder or {}

local RaidBuffReminder = addon.Frames.ManagedContainers.RaidBuffReminder

local settingsCache = setmetatable({}, { __mode = "k" })

local function CreateIcon(parent)
	local icon = CreateFrame("Frame", nil, parent, "DisableUntrustedLayoutScriptsTemplate")
	icon:EnableMouse(false)

	icon.border = icon:CreateTexture(nil, "BORDER")
	icon.border:SetAllPoints(icon)
	icon.border:SetColorTexture(0, 0, 0, 1)

	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	icon:Hide()
	return icon
end

local function GetReminderSpellIDs()
	local dataProvider = addon.Frames.DataProvider and addon.Frames.DataProvider.Live
	if not dataProvider or type(dataProvider.GetRaidBuffReminderSpellIds) ~= "function" then
		return nil
	end

	local classBuffSpellIds, blessingOfTheBronzeSpellIds = dataProvider:GetRaidBuffReminderSpellIds()
	return blessingOfTheBronzeSpellIds or classBuffSpellIds
end

local function BuildIncludeSpellIDs(spellIDs)
	local includeSpellIDs = {}

	for _, spellID in ipairs(spellIDs or {}) do
		includeSpellIDs[spellID] = true
	end

	return includeSpellIDs
end

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local raidBuffReminder = icons.raidBuffReminder or {}
	local spellIDs = GetReminderSpellIDs()
	local borderColor = raidBuffReminder.borderColor or {}

	local result = {
		enabled = raidBuffReminder.enabled ~= false,
		showInCombat = raidBuffReminder.showInCombat == true,
		anchor = raidBuffReminder.anchor or "CENTER",
		offsetXPx = addon.Utilities:ToPixels(raidBuffReminder.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(raidBuffReminder.offsetY or 0),
		iconSizePx = addon.Utilities:ToPixels(raidBuffReminder.iconSize or 32),
		borderSizePx = addon.Utilities:ToPixels((raidBuffReminder.borderSizePx ~= 0) and 1 or 0),
		borderColor = {
			r = borderColor.r or 1,
			g = borderColor.g or 0,
			b = borderColor.b or 0,
			a = borderColor.a or 1,
		},
		texture = spellIDs and spellIDs[1] and C_Spell.GetSpellTexture(spellIDs[1]) or nil,
		includeSpellIDs = BuildIncludeSpellIDs(spellIDs),
		hasSpellIDs = spellIDs ~= nil and #spellIDs > 0,
	}

	settingsCache[settings] = result
end

local function ShouldShow(frame, cachedSettings)
	if not cachedSettings.enabled or not cachedSettings.hasSpellIDs then
		return false
	end

	if not cachedSettings.showInCombat and InCombatLockdown() then
		return false
	end

	local unit = frame.unit
	if not addon.Utilities:IsManagedAuraUnitVisible(unit) then
		return false
	end

	if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
		return false
	end

	if not UnitIsPlayer(unit) then
		return false
	end

	return true
end

local function InitializePresenceButton(button, container)
	container.auraButtons = container.auraButtons or {}
	container.auraButtons[button] = true

	button:SetAlpha(0)

	if button.SetMouseClickEnabled then
		button:SetMouseClickEnabled(false)
	end

	if button.SetMouseMotionEnabled then
		button:SetMouseMotionEnabled(false)
	else
		button:EnableMouse(false)
	end
end

local function UpdateManagedSettings(frame, settings)
	local container = frame.managedContainers.raidBuffReminder
	local wrapper = container.wrapper
	local icon = container.icon
	local cachedSettings = settingsCache[settings]
	local scaledIconSizePx = addon.Utilities:ScaleEven(cachedSettings.iconSizePx)
	local scaledBorderSizePx = math.max(0, addon.Utilities:Scale(cachedSettings.borderSizePx))
	local scaledOffsetXPx = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local scaledOffsetYPx = addon.Utilities:Scale(cachedSettings.offsetYPx)
	local iconSize = addon.Utilities:ToUI(scaledIconSizePx)
	local wrapperSize = addon.Utilities:ToUI(scaledIconSizePx + addon.Utilities:Scale(2))
	local textureInset = addon.Utilities:ToUI(scaledBorderSizePx)
	local borderColor = cachedSettings.borderColor

	for button in pairs(container.auraButtons or {}) do
		button:SetSize(wrapperSize, wrapperSize)
	end

	wrapper:SetSize(wrapperSize, wrapperSize)
	wrapper:ClearAllPoints()
	wrapper:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledOffsetXPx),
		addon.Utilities:ToUI(scaledOffsetYPx)
	)

	container:ClearAllPoints()
	container:SetPoint("TOPLEFT", wrapper, "TOPLEFT", 0, 0)
	container:SetFlowLayoutAnchorPoint("TOPLEFT")
	container:SetFlowLayoutMaximumLineSize(wrapperSize)
	container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Down)

	icon:ClearAllPoints()
	icon:SetPoint("TOPLEFT", container, "TOPRIGHT", 0, 0)

	icon:SetSize(iconSize, iconSize)
	icon.border:SetShown(scaledBorderSizePx > 0)
	icon.border:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
	icon.border:ClearAllPoints()
	icon.border:SetAllPoints(icon)

	icon.texture:ClearAllPoints()
	icon.texture:SetPoint("TOPLEFT", icon, "TOPLEFT", textureInset, -textureInset)
	icon.texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -textureInset, textureInset)
	icon.texture:SetTexture(cachedSettings.texture)
	icon:Show()

	container:SetAuraGroupMaxFrameCount(
		"raidBuffReminder",
		cachedSettings.enabled and cachedSettings.hasSpellIDs and 1 or 0
	)
	container:SetAuraGroupCandidateFilters("raidBuffReminder", {
		includeSpellIDs = cachedSettings.includeSpellIDs,
	})
	container:SetAuraGroupLayout("raidBuffReminder", {
		elementWidth = wrapperSize,
		elementHeight = wrapperSize,
		elementSpacing = 0,
		lineSpacing = 0,
	})
end

function RaidBuffReminder:Ensure(frame, settings)
	if frame.frameType == "preview" then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if frame.managedContainers.raidBuffReminder then
		return
	end

	local wrapper = CreateFrame("Frame", nil, frame)
	wrapper:SetFrameLevel(40)
	wrapper:SetClipsChildren(true)

	local container = CreateFrame("AuraContainer", nil, wrapper, "CustomAuraContainerTemplate")
	container:SetFrameLevel(wrapper:GetFrameLevel())
	container.wrapper = wrapper
	container.auraButtons = {}
	frame.managedContainers.raidBuffReminder = container

	container.icon = CreateIcon(wrapper)
	container.icon:SetFrameLevel(wrapper:GetFrameLevel() + 1)

	container:AddAuraGroup("raidBuffReminder", "HELPFUL", {
		maxFrameCount = cachedSettings.enabled and cachedSettings.hasSpellIDs and 1 or 0,
		candidateFilters = {
			includeSpellIDs = cachedSettings.includeSpellIDs,
		},
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = function(button)
			InitializePresenceButton(button, container)
		end,
	})

	UpdateManagedSettings(frame, settings)
	self:UpdateState(frame, settings)
end

function RaidBuffReminder:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if frame.frameType == "preview" then
		return
	end

	UpdateManagedSettings(frame, settings)
	self:UpdateState(frame, settings)
end

function RaidBuffReminder:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	if frame.frameType == "preview" then
		return
	end

	local container = frame.managedContainers.raidBuffReminder
	if not container then
		return
	end

	container.wrapper:SetShown(ShouldShow(frame, settingsCache[settings]))
end

function RaidBuffReminder:SetUnit(frame, settings)
	if frame.frameType == "preview" then
		return
	end

	local container = frame.managedContainers.raidBuffReminder

	container:SetUnit(frame.unit or "none")
	container:UpdateAllAuras()
	self:UpdateState(frame, settings)
end

function RaidBuffReminder:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "raidBuffReminderSettingsChanged",
		stateReason = "statusStateChanged",
	})
end
