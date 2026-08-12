local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.CustomBuffs = addon.Frames.ManagedContainers.CustomBuffs or {}

local CustomBuffs = addon.Frames.ManagedContainers.CustomBuffs
local AuraButtons = addon.Frames.ManagedContainers.AuraButtons

local settingsCache = setmetatable({}, { __mode = "k" })

local function ShouldUseManagedContainer(frame)
	return addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility
end

local function GetSlotKey(spellID)
	return "CustomBuff" .. tostring(spellID)
end

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local classFileName = addon.Utilities:GetPlayerClassFileName()
	local specID = addon.Utilities:GetPlayerSpecID()
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local buffs = icons.buffs or {}
	local customBuffs = icons.customBuffs or {}
	local classAuras = customBuffs[classFileName] or {}
	local specAuras = classAuras[specID] or classAuras[-1] or {}
	local slotKeys = {}
	local slotSettings = {}

	local defaultAuraValues = addon.Database:GetCustomAuraDefaults() or {}
	local classDefaults = defaultAuraValues[classFileName] or {}
	for _, specDefaults in pairs(classDefaults) do
		for spellID, defaultEntry in pairs(specDefaults) do
			if defaultEntry.enabled ~= false then
				local numericSpellID = tonumber(spellID) or spellID
				slotKeys[GetSlotKey(numericSpellID)] = true
			end
		end
	end

	for _, specSettings in pairs(classAuras) do
		for spellID in pairs(specSettings) do
			local numericSpellID = tonumber(spellID) or spellID
			slotKeys[GetSlotKey(numericSpellID)] = true
		end
	end

	for spellID, iconData in pairs(specAuras) do
		local numericSpellID = tonumber(spellID) or spellID
		local icon = iconData or {}
		local color = icon.colorTextureColor or {}

		if icon.enabled == true then
			slotSettings[GetSlotKey(numericSpellID)] = {
				spellID = numericSpellID,
				anchor = icon.anchor or "CENTER",
				offsetXPx = addon.Utilities:ToPixels(icon.offsetX or 0),
				offsetYPx = addon.Utilities:ToPixels(icon.offsetY or 0),
				iconSizePx = addon.Utilities:ToPixels(icon.iconSize or 16),
				borderSizePx = addon.Utilities:ToPixels(1),
				showStacks = icon.showStacks == true,
				stacksFontSize = icon.stacksFontSize or 10,
				showCooldown = icon.showCooldown == true,
				cooldownFontSize = icon.cooldownFontSize or 10,
				showTooltips = buffs.showTooltips == true,
				colorTexture = icon.colorTexture == true,
				colorTextureColor = {
					r = color.r or 1,
					g = color.g or 1,
					b = color.b or 1,
					a = color.a or 1,
				},
				includeSpellIDs = {
					[numericSpellID] = true,
				},
			}
		end
	end

	settingsCache[settings] = {
		slotKeys = slotKeys,
		slotSettings = slotSettings,
	}
end

local function ApplySlotIconSettings(button, cachedSettings)
	local scaledIconSizePx = addon.Utilities:ScaleEven(cachedSettings.iconSizePx)

	button:SetSize(addon.Utilities:ToUI(scaledIconSizePx), addon.Utilities:ToUI(scaledIconSizePx))
end

local function ApplySlotTextureSettings(button, cachedSettings)
	if cachedSettings.colorTexture then
		if button.ClearIcon then
			button:ClearIcon()
		end

		button.icon:SetTexCoord(0, 1, 0, 1)
		button.icon:SetColorTexture(
			cachedSettings.colorTextureColor.r,
			cachedSettings.colorTextureColor.g,
			cachedSettings.colorTextureColor.b,
			cachedSettings.colorTextureColor.a
		)
	else
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

		if button.SetIcon then
			button:SetIcon(button.icon)
		end
	end
end

local function UpdateSlotButtonSettings(frame, slotKey, cachedSettings)
	local container = frame.managedContainers.customBuffs
	local slotButton = container.auraSlots[slotKey]
	local scaledOffsetXPx = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local scaledOffsetYPx = addon.Utilities:Scale(cachedSettings.offsetYPx)

	ApplySlotIconSettings(slotButton, cachedSettings)
	ApplySlotTextureSettings(slotButton, cachedSettings)
	AuraButtons:ApplyBorderSettings(slotButton, cachedSettings)
	AuraButtons:ApplyCooldownSettings(slotButton, cachedSettings)
	AuraButtons:ApplyCountSettings(slotButton, cachedSettings)
	AuraButtons:ApplyTooltipSettings(slotButton, cachedSettings)

	slotButton:ClearAllPoints()
	slotButton:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledOffsetXPx),
		addon.Utilities:ToUI(scaledOffsetYPx)
	)
end

local function EnsureSlot(frame, slotKey)
	local container = frame.managedContainers.customBuffs

	if container.auraSlots[slotKey] then
		return
	end

	container.auraSlots[slotKey] = container:AddAuraSlot(slotKey, "HELPFUL|PLAYER", {
		candidateFilters = {
			includeSpellIDs = {},
		},
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = function(button)
			AuraButtons:Initialize(button, container)
		end,
	})
end

local function UpdateFilters(frame, settings)
	local container = frame.managedContainers.customBuffs
	local cachedSettings = settingsCache[settings]

	for slotKey in pairs(container.auraSlots) do
		local slotSettings = cachedSettings.slotSettings[slotKey]
		container:SetAuraSlotCandidateFilters(slotKey, {
			includeSpellIDs = slotSettings and slotSettings.includeSpellIDs or {},
		})
	end
end

function CustomBuffs:Ensure(frame, settings)
	if not ShouldUseManagedContainer(frame) then
		return
	end

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	frame.managedContainers = frame.managedContainers or {}

	if frame.managedContainers.customBuffs then
		return
	end

	local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
	container:SetFrameLevel(60)
	container.auraSlots = {}

	frame.managedContainers.customBuffs = container

	for slotKey in pairs(cachedSettings.slotKeys) do
		EnsureSlot(frame, slotKey)
	end
end

function CustomBuffs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not frame.managedContainers or not frame.managedContainers.customBuffs then
		self:Ensure(frame, settings)
	end

	for slotKey, slotSettings in pairs(cachedSettings.slotSettings) do
		UpdateSlotButtonSettings(frame, slotKey, slotSettings)
	end

	UpdateFilters(frame, settings)
end

function CustomBuffs:UpdateState(frame, settings)
	if not ShouldUseManagedContainer(frame) then
		return
	end

	if not frame.managedContainers or not frame.managedContainers.customBuffs then
		return
	end

	local unit = frame.unit
	local shouldShow = addon.Utilities:IsManagedAuraUnitVisible(unit)
	local container = frame.managedContainers.customBuffs

	if container.isShown ~= shouldShow then
		container.isShown = shouldShow
		container:SetShown(shouldShow)
	end
end

function CustomBuffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "customBuffSettingsChanged",
	})
end
