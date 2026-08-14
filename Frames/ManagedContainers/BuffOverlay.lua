local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.BuffOverlay = addon.Frames.ManagedContainers.BuffOverlay or {}

local BuffOverlay = addon.Frames.ManagedContainers.BuffOverlay

local settingsCache = setmetatable({}, { __mode = "k" })

local function ShouldUseManagedContainer(frame)
	return addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility
end

local function GetCurrentOverlaySettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local bars = widgets.bars or {}
	local buffOverlays = bars.buffOverlays or {}
	local overlay = buffOverlays.overlay1 or {}
	local specID = addon.Utilities:GetPlayerSpecID()
	local specSettings = specID and overlay.bySpec and overlay.bySpec[specID] or nil
	local spellID = specSettings and specSettings.spellId or 0
	local color = specSettings and specSettings.color or {}

	local defaultAuraValues = addon.Database:GetCustomAuraDefaults() or {}
	local classAuras = defaultAuraValues[addon.Utilities:GetPlayerClassFileName() or ""] or {}
	local specAuras = (specID and classAuras[specID]) or {}
	local isAllowedAura = specAuras[spellID] ~= nil
	local enabled = specSettings and specSettings.enabled == true and spellID ~= 0 and isAllowedAura

	return {
		enabled = enabled,
		spellID = spellID,
		color = {
			r = color.r or 1,
			g = color.g or 1,
			b = color.b or 1,
		},
		includeSpellIDs = enabled and { [spellID] = true } or {},
	}
end

local function UpdateSettingsCache(settings)
	settingsCache[settings] = GetCurrentOverlaySettings(settings)
end

local function InitializeOverlayButton(button)
	button:EnableMouse(false)

	local overlayFrame = CreateFrame("Frame", nil, button)
	overlayFrame:SetAllPoints(button)
	button.overlayFrame = overlayFrame

	local texture = overlayFrame:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints(overlayFrame)
	texture:SetColorTexture(1, 1, 1, 1)
	button.overlayTexture = texture
end

local function UpdateOverlayButtonSettings(frame, settings)
	local container = frame.managedContainers.buffOverlay
	local slotButton = container.slotButton
	local cachedSettings = settingsCache[settings]
	local healthTexture = frame.healthBar:GetStatusBarTexture()

	slotButton:ClearAllPoints()
	slotButton:SetPoint("TOPLEFT", healthTexture, "TOPLEFT", 0, 0)
	slotButton:SetPoint("BOTTOMRIGHT", healthTexture, "BOTTOMRIGHT", 0, 0)

	slotButton.overlayTexture:SetColorTexture(cachedSettings.color.r, cachedSettings.color.g, cachedSettings.color.b, 1)
end

local function UpdateFilters(frame, settings)
	local container = frame.managedContainers.buffOverlay
	local cachedSettings = settingsCache[settings]

	container:SetAuraSlotCandidateFilters("BuffOverlay", {
		includeSpellIDs = cachedSettings.includeSpellIDs,
	})
end

function BuffOverlay:Ensure(frame, settings)
	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	frame.managedContainers = frame.managedContainers or {}

	if frame.managedContainers.buffOverlay then
		return
	end

	local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	frame.managedContainers.buffOverlay = container

	container.slotButton = container:AddAuraSlot("BuffOverlay", "HELPFUL|PLAYER", {
		candidateFilters = {
			includeSpellIDs = cachedSettings.includeSpellIDs,
		},
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = InitializeOverlayButton,
	})

	container.slotButton:SetFrameLevel(4)
	container.slotButton.overlayFrame:SetFrameLevel(5)

	UpdateOverlayButtonSettings(frame, settings)
end

function BuffOverlay:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not frame.managedContainers or not frame.managedContainers.buffOverlay then
		self:Ensure(frame, settings)
	end

	UpdateOverlayButtonSettings(frame, settings)
	UpdateFilters(frame, settings)
end

function BuffOverlay:UpdateState(frame, settings)
	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not frame.managedContainers or not frame.managedContainers.buffOverlay then
		return
	end

	local unit = frame.unit
	local shouldShow = addon.Utilities:IsManagedAuraUnitVisible(unit)
	local container = frame.managedContainers.buffOverlay

	if container.isShown ~= shouldShow then
		container.isShown = shouldShow
		container:SetShown(shouldShow)
	end
end

function BuffOverlay:SetUnit(frame, settings)
	if not ShouldUseManagedContainer(frame) then
		return
	end

	local container = frame.managedContainers and frame.managedContainers.buffOverlay
	if not container then
		return
	end

	container:SetUnit(addon.Utilities:GetManagedAuraUnit(frame.unit) or "none")
	container:UpdateAllAuras()
	self:UpdateState(frame, settings)
end

function BuffOverlay:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "buffOverlaySettingsChanged",
	})
end
