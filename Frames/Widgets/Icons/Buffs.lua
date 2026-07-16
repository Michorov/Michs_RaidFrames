local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Buffs = addon.Frames.Widgets.Icons.Buffs or {}

local Buffs = addon.Frames.Widgets.Icons.Buffs

local settingsCache = setmetatable({}, { __mode = "k" })
local ENSURE_MAX_ICONS = 10

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local buffs = icons.buffs or {}
	local customAuraValues = buffs.customAuraValues or {}
	local classAuras = customAuraValues[addon.Utilities:GetPlayerClassFileName() or ""] or {}
	local specID = addon.Utilities:GetPlayerSpecID()
	local specAuras = classAuras[specID] or classAuras[-1] or {}

	local result = {
		enabled = buffs.enabled ~= false,
		anchor = buffs.anchor or "BOTTOMRIGHT",
		offsetXPx = addon.Utilities:ToPixels(buffs.offsetX or -2),
		offsetYPx = addon.Utilities:ToPixels(buffs.offsetY or 2),
		maxIcons = math.max(1, buffs.maxIcons or 6),
		iconsPerRow = math.max(1, buffs.iconsPerRow or 3),
		iconSizePx = addon.Utilities:ToPixels(buffs.iconSize or 20),
		spacingPx = addon.Utilities:ToPixels(buffs.spacing or -1),
		showStacks = buffs.showStacks ~= false,
		stacksFontSize = buffs.stacksFontSize or 10,
		showCooldown = buffs.showCooldown == true,
		cooldownFontSize = buffs.cooldownFontSize or 10,
		showExternals = buffs.showExternals == true,
		borderSizePx = addon.Utilities:ToPixels(buffs.borderSizePx or 1),
		specAuras = specAuras,
	}

	settingsCache[settings] = result
end

function Buffs:Ensure(frame)
	if addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility then
		return
	end

	if not frame.buffsContainer then
		frame.buffsContainer = addon.Frames.Managers.IconManager:CreateContainer(frame, "buffsContainer", 42)
	end

	local container = frame.buffsContainer

	for i = 1, ENSURE_MAX_ICONS do
		if not container.icons[i] then
			container.icons[i] = addon.Frames.Managers.IconManager:CreateIcon(container, 1)
		end
	end
end

local function UpdateContainerSettings(frame, settings)
	local container = frame.buffsContainer
	local cachedSettings = settingsCache[settings]

	local iconSizePx = addon.Utilities:Scale(cachedSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(cachedSettings.spacingPx)
	local containerOffsetXPx = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local containerOffsetYPx = addon.Utilities:Scale(cachedSettings.offsetYPx)
	local visibleCols = math.min(cachedSettings.maxIcons, cachedSettings.iconsPerRow)
	local rowCount = math.max(1, math.ceil(cachedSettings.maxIcons / cachedSettings.iconsPerRow))
	local anchor = cachedSettings.anchor

	local widthPx = (visibleCols * iconSizePx) + ((visibleCols - 1) * spacingPx)
	local heightPx = (rowCount * iconSizePx) + ((rowCount - 1) * spacingPx)

	container:ClearAllPoints()
	container:SetPoint(
		anchor,
		frame,
		anchor,
		addon.Utilities:ToUI(containerOffsetXPx),
		addon.Utilities:ToUI(containerOffsetYPx)
	)
	container:SetSize(addon.Utilities:ToUI(widthPx), addon.Utilities:ToUI(heightPx))
end

local function UpdateIconSettings(frame, settings)
	local container = frame.buffsContainer
	local cachedSettings = settingsCache[settings]

	local iconSizePx = addon.Utilities:Scale(cachedSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(cachedSettings.spacingPx)
	local stepPx = iconSizePx + spacingPx
	local anchor = cachedSettings.anchor

	local xDirection = anchor:find("LEFT", 1, true) and 1 or -1
	local yDirection = anchor:find("TOP", 1, true) and -1 or 1

	for i = 1, cachedSettings.maxIcons do
		local icon = container.icons[i]
		if not icon then
			icon = addon.Frames.Managers.IconManager:CreateIcon(container, 1)
			container.icons[i] = icon
		end

		addon.Frames.Managers.IconManager:ApplyIconSizeSettings(icon, cachedSettings)
		addon.Frames.Managers.IconManager:ApplyBorderSettings(icon, cachedSettings)
		addon.Frames.Managers.IconManager:ApplyCountSettings(icon, cachedSettings)
		addon.Frames.Managers.IconManager:ApplyCooldownSettings(icon, cachedSettings)

		local gridIndex = i - 1
		local column = gridIndex % cachedSettings.iconsPerRow
		local row = math.floor(gridIndex / cachedSettings.iconsPerRow)

		local offsetXPx = column * stepPx * xDirection
		local offsetYPx = row * stepPx * yDirection

		icon:ClearAllPoints()
		icon:SetPoint(anchor, container, anchor, addon.Utilities:ToUI(offsetXPx), addon.Utilities:ToUI(offsetYPx))
	end

	for i = cachedSettings.maxIcons + 1, #container.icons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end
end

function Buffs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility then
		return
	end

	UpdateContainerSettings(frame, settings)
	UpdateIconSettings(frame, settings)
end

function Buffs:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility then
		return
	end

	local container = frame.buffsContainer

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.buffs ~= true then
		addon.Frames.Managers.IconManager:HideIcons(container, cachedSettings.maxIcons)
		return
	end

	if not cachedSettings.enabled then
		addon.Frames.Managers.IconManager:HideIcons(container, cachedSettings.maxIcons)
		return
	end

	local unit = frame.unit
	local provider = frame.dataProvider
	local isTestProvider = provider == addon.Frames.DataProvider.Test

	if not isTestProvider and (not unit or not UnitExists(unit)) then
		container:Hide()
		return
	end

	local maxIcons = cachedSettings.maxIcons
	local shown = 0
	local shownAuraInstanceIDs = {}

	if cachedSettings.showExternals then
		local bigDefensive = provider:GetUnitAuraInstanceIDs(frame, "helpfulBigDefensive")
		for auraInstanceID in pairs(bigDefensive) do
			shownAuraInstanceIDs[auraInstanceID] = true
		end
	end

	local auras = provider:GetUnitAuras(frame, "helpfulPlayer")

	for _, aura in pairs(auras) do
		if shown >= maxIcons then
			break
		end

		local ok, customAuraSettings = pcall(function()
			return cachedSettings.specAuras[aura.spellId]
		end)
		if not ok then
			customAuraSettings = nil
		end

		local auraInstanceID = aura.auraInstanceID

		local alreadyShown = auraInstanceID and shownAuraInstanceIDs[auraInstanceID] == true
		local shouldShowAura = customAuraSettings ~= nil and customAuraSettings.enabled == true

		if shouldShowAura and not alreadyShown and aura.icon then
			local icon = container.icons[shown + 1]
			if icon and icon.texture then
				shown = shown + 1

				if auraInstanceID then
					shownAuraInstanceIDs[auraInstanceID] = true
				end

				local stackText
				if cachedSettings.showStacks then
					stackText = provider:GetAuraApplicationDisplayCount(frame, aura, 2, 99)
				end

				local hasExpiration = provider:DoesAuraHaveExpirationTime(frame, aura)

				addon.Frames.Managers.IconManager:ApplyIconState(icon, {
					texture = aura.icon,
					countText = stackText,
					durationObject = provider:GetAuraDuration(frame, aura),
					hasExpiration = hasExpiration,
				})
			end
		end
	end

	if cachedSettings.showExternals and shown < maxIcons then
		local externals = provider:GetUnitAuras(frame, "helpfulExternalDefensive")

		for _, aura in pairs(externals) do
			if shown >= maxIcons then
				break
			end

			local auraInstanceID = aura.auraInstanceID
			local alreadyShown = auraInstanceID and shownAuraInstanceIDs[auraInstanceID] == true

			if not alreadyShown and aura.icon then
				local icon = container.icons[shown + 1]
				if icon and icon.texture then
					shown = shown + 1

					if auraInstanceID then
						shownAuraInstanceIDs[auraInstanceID] = true
					end

					local stackText
					if cachedSettings.showStacks then
						stackText = provider:GetAuraApplicationDisplayCount(frame, aura, 2, 99)
					end

					local hasExpiration = provider:DoesAuraHaveExpirationTime(frame, aura)

					addon.Frames.Managers.IconManager:ApplyIconState(icon, {
						texture = aura.icon,
						countText = stackText,
						durationObject = provider:GetAuraDuration(frame, aura),
						hasExpiration = hasExpiration,
					})
				end
			end
		end
	end

	for i = shown + 1, maxIcons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end

	container:SetShown(shown > 0)
end

function Buffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "buffAurasSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
