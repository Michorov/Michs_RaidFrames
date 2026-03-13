local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Buffs = addon.Frames.Widgets.Icons.Buffs or {}

local Buffs = addon.Frames.Widgets.Icons.Buffs

local function GetCustomBuffFilterEntry(settings, aura)
	if not settings or not aura then
		return nil
	end

	local widgets = settings.widgets or {}
	local icons = widgets.icons or {}
	local buffs = icons.buffs or {}
	local customAuraValues = buffs.customAuraValues or {}
	local classAuras = customAuraValues[addon.Utilities:GetPlayerClassFileName() or ""] or {}
	local specID = addon.Utilities:GetPlayerSpecID()
	local specAuras = classAuras[specID] or classAuras[-1] or {}

	local ok, customBuff = pcall(function()
		return specAuras[aura.spellId]
	end)

	if ok then
		return customBuff
	end

	return nil
end

local function GetBuffSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local buffs = icons.buffs or {}

	return {
		enabled = buffs.enabled ~= false,
		anchor = buffs.anchor or "BOTTOMRIGHT",
		relativeAnchor = buffs.relativeAnchor or "BOTTOMRIGHT",
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
		useCustomBuffFilter = buffs.useCustomBuffFilter == true,
		borderSizePx = addon.Utilities:ToPixels(buffs.borderSizePx or 1),
	}
end

function Buffs:UpdateSettings(frame, settings)
	local buffSettings = GetBuffSettings(settings)
	local container = frame and frame.buffsContainer
	if not container then
		return
	end

	local iconSizePx = addon.Utilities:Scale(buffSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(buffSettings.spacingPx)
	local offsetXPx = addon.Utilities:Scale(buffSettings.offsetXPx)
	local offsetYPx = addon.Utilities:Scale(buffSettings.offsetYPx)
	local stepPx = iconSizePx + spacingPx
	local visibleCols = math.min(buffSettings.maxIcons, buffSettings.iconsPerRow)
	local rowCount = math.max(1, math.ceil(buffSettings.maxIcons / buffSettings.iconsPerRow))

	local widthPx = (visibleCols * iconSizePx) + ((visibleCols - 1) * spacingPx)
	local heightPx = (rowCount * iconSizePx) + ((rowCount - 1) * spacingPx)

	container:ClearAllPoints()
	container:SetPoint(
		buffSettings.anchor,
		container:GetParent(),
		buffSettings.relativeAnchor,
		addon.Utilities:ToUI(offsetXPx),
		addon.Utilities:ToUI(offsetYPx)
	)
	container:SetSize(addon.Utilities:ToUI(widthPx), addon.Utilities:ToUI(heightPx))

	for i = 1, buffSettings.maxIcons do
		local icon = container.icons[i]
		if not icon then
			icon = addon.Frames.Managers.IconManager:CreateIcon(container, 1)
			container.icons[i] = icon
		end

		addon.Frames.Managers.IconManager:ApplyIconSizeSettings(icon, buffSettings)
		addon.Frames.Managers.IconManager:ApplyBorderSettings(icon, buffSettings)
		addon.Frames.Managers.IconManager:ApplyCountSettings(icon, buffSettings)
		addon.Frames.Managers.IconManager:ApplyCooldownSettings(icon, buffSettings)

		local idx = i - 1
		local col = idx % buffSettings.iconsPerRow
		local row = math.floor(idx / buffSettings.iconsPerRow)

		local xPx = -(col * stepPx)
		local yPx = row * stepPx

		icon:ClearAllPoints()
		icon:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", addon.Utilities:ToUI(xPx), addon.Utilities:ToUI(yPx))
	end

	for i = buffSettings.maxIcons + 1, #container.icons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end
end

function Buffs:UpdateState(frame, settings)
	local buffSettings = GetBuffSettings(settings)
	local container = frame and frame.buffsContainer
	if not container then
		return
	end

	local unit = frame.unit
	local provider = frame and frame.dataProvider
	local isTestProvider = provider == addon.Frames.DataProvider.Test

	if not buffSettings.enabled then
		addon.Frames.Managers.IconManager:HideIcons(container, buffSettings.maxIcons)
		return
	end

	if not isTestProvider and (not unit or not UnitExists(unit)) then
		container:Hide()
		return
	end

	local approved
	if not buffSettings.useCustomBuffFilter and not isTestProvider then
		local bucket = addon.AuraHandler and addon.AuraHandler:GetBucketForUnit(unit)
		approved = bucket and bucket.buffs
		if not approved or not next(approved) then
			addon.Frames.Managers.IconManager:HideIcons(container, buffSettings.maxIcons)
			return
		end
	end

	local maxIcons = buffSettings.maxIcons
	local shown, auraIndex = 0, 1
	local filter = "HELPFUL"

	local maxScan = isTestProvider and (maxIcons * 3) or math.huge

	while shown < maxIcons and auraIndex <= maxScan do
		local aura = provider:GetAuraDataByIndex(frame, auraIndex, filter)
		if not aura then
			break
		end
		auraIndex = auraIndex + 1

		local auraInstanceID = aura.auraInstanceID
		local shouldShowAura = false

		if buffSettings.useCustomBuffFilter then
			local customBuff = GetCustomBuffFilterEntry(settings, aura)
			local isMine = aura.isFromPlayerOrPlayerPet

			shouldShowAura = customBuff ~= nil
				and customBuff.enabled == true
				and (isMine or customBuff.allowMissingSource == true)
		else
			if isTestProvider then
				shouldShowAura = true
			else
				shouldShowAura = auraInstanceID ~= nil and approved[auraInstanceID] == true
			end
		end

		if shouldShowAura and aura.icon then
			local icon = container.icons[shown + 1]
			if icon and icon.texture then
				shown = shown + 1

				local stackText
				if buffSettings.showStacks then
					stackText = provider:GetAuraApplicationDisplayCount(frame, aura, 2, 99)
				end

				local hasExpiration = provider:DoesAuraHaveExpirationTime(frame, aura)

				addon.Frames.Managers.IconManager:ApplyIconState(icon, {
					texture = aura.icon,
					countText = stackText,
					expirationTime = aura.expirationTime,
					duration = aura.duration,
					hasExpiration = hasExpiration,
				})
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

function Buffs:Ensure(frame, settings)
	local buffSettings = GetBuffSettings(settings)
	if not frame then
		return
	end

	if not frame.buffsContainer then
		frame.buffsContainer = addon.Frames.Managers.IconManager:CreateContainer(frame, "buffsContainer")
	end

	local container = frame.buffsContainer

	for i = 1, buffSettings.maxIcons do
		if not container.icons[i] then
			container.icons[i] = addon.Frames.Managers.IconManager:CreateIcon(container, 1)
		end
	end
end

function Buffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "buffAurasSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
