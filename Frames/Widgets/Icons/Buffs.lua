local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Buffs = addon.Frames.Widgets.Icons.Buffs or {}

local Buffs = addon.Frames.Widgets.Icons.Buffs

local function HideIcons(container, maxIcons)
	for i = 1, maxIcons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end
	container:SetShown(false)
end

local function GetPlayerClassFileName()
	local _, classFileName = UnitClass("player")
	return classFileName
end

local function GetPlayerSpecID()
	local specIndex = GetSpecialization and GetSpecialization()
	if not specIndex then
		return nil
	end

	return select(1, GetSpecializationInfo(specIndex))
end

local function GetCustomBuffFilterEntry(settings, aura)
	if not settings or not aura then
		return nil
	end

	local buffs = settings.widgets and settings.widgets.icons and settings.widgets.icons.buffs or {}
	local customAuraValues = buffs.customAuraValues or {}
	local classAuras = customAuraValues[GetPlayerClassFileName() or ""] or {}
	local specAuras = classAuras[GetPlayerSpecID() or 0] or {}

	local ok, customBuff = pcall(function()
		return specAuras[aura.spellId]
	end)

	if ok then
		return customBuff
	end

	return nil
end

local function GetBuffSettings(settings)
	local buffs = settings and settings.widgets and settings.widgets.icons and settings.widgets.icons.buffs or {}

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

local function UpdateIconSettings(icon, buffSettings)
	local scaledIconPx = addon.Utilities:Scale(buffSettings.iconSizePx)
	local scaledBorderPx = math.max(1, addon.Utilities:Scale(buffSettings.borderSizePx))
	icon:SetSize(addon.Utilities:ToUI(scaledIconPx), addon.Utilities:ToUI(scaledIconPx))

	icon.texture:ClearAllPoints()
	icon.texture:SetPoint(
		"TOPLEFT",
		icon,
		"TOPLEFT",
		addon.Utilities:ToUI(scaledBorderPx),
		-addon.Utilities:ToUI(scaledBorderPx)
	)
	icon.texture:SetPoint(
		"BOTTOMRIGHT",
		icon,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(scaledBorderPx),
		addon.Utilities:ToUI(scaledBorderPx)
	)

	icon.border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = addon.Utilities:ToUI(scaledBorderPx),
	})
	icon.border:SetBackdropBorderColor(0, 0, 0, 1)

	icon.countText:SetFont("Fonts\\FRIZQT__.TTF", addon.Utilities:ScaleFont(buffSettings.stacksFontSize), "OUTLINE")
	icon.countText:ClearAllPoints()
	icon.countText:SetTextColor(1, 1, 1, 1)
	icon.countText:SetShown(buffSettings.showStacks)
	icon.countText:SetPoint(
		"BOTTOMRIGHT",
		icon,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(scaledBorderPx),
		addon.Utilities:ToUI(scaledBorderPx)
	)

	if icon.cooldown and icon.cooldown.SetHideCountdownNumbers then
		icon.cooldown:SetHideCountdownNumbers(not buffSettings.showCooldown)
	end
	if buffSettings.showCooldown and icon.cooldown and icon.cooldown.SetCountdownFont then
		local scaledSize = addon.Utilities:ScaleFont(buffSettings.cooldownFontSize)
		local fontName = "MRF_CooldownFont_" .. tostring(scaledSize)
		local cooldownFont = _G[fontName]
		if not cooldownFont then
			cooldownFont = CreateFont(fontName)
		end
		cooldownFont:SetFont("Fonts\\FRIZQT__.TTF", scaledSize, "OUTLINE")
		icon.cooldown:SetCountdownFont(fontName)
	end
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
			icon = addon.Frames.Widgets.Icons.Factory:CreateIcon(container, 1)
			container.icons[i] = icon
		end

		UpdateIconSettings(icon, buffSettings)

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
	if not unit or not UnitExists(unit) then
		container:Hide()
		return
	end

	if not buffSettings.enabled then
		HideIcons(container, buffSettings.maxIcons)
		return
	end

	local approved
	if not buffSettings.useCustomBuffFilter then
		local bucket = addon.AuraHandler and addon.AuraHandler:GetBucketForUnit(unit)
		approved = bucket and bucket.buffs
		if not approved or not next(approved) then
			HideIcons(container, buffSettings.maxIcons)
			return
		end
	end

	local maxIcons = buffSettings.maxIcons
	local shown, auraIndex = 0, 1
	local filter = "HELPFUL"

	while shown < maxIcons do
		local aura = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, filter)
		if not aura then
			break
		end
		auraIndex = auraIndex + 1

		local auraInstanceID = aura.auraInstanceID
		local shouldShowAura = false

		if buffSettings.useCustomBuffFilter then
			local customBuff = GetCustomBuffFilterEntry(settings, aura)

			local isPlayerSource = aura.sourceUnit == "player"
			local allowMissingSource = aura.spellId == 444490

			shouldShowAura = customBuff ~= nil and customBuff.enabled == true and (isPlayerSource or allowMissingSource)
		else
			shouldShowAura = auraInstanceID ~= nil and approved[auraInstanceID] == true
		end

		if shouldShowAura and aura.icon then
			local icon = container.icons[shown + 1]
			if icon and icon.texture then
				shown = shown + 1

				icon.texture:SetTexture(aura.icon)

				if icon.countText then
					icon.countText:SetText("")
					if buffSettings.showStacks then
						if C_UnitAuras.GetAuraApplicationDisplayCount then
							local stackText = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 99)
							if stackText then
								icon.countText:SetText(stackText)
							end
						end
					end
				end

				local hasExpiration = false
				if C_UnitAuras.DoesAuraHaveExpirationTime then
					hasExpiration = C_UnitAuras.DoesAuraHaveExpirationTime(unit, auraInstanceID)
				end

				if icon.cooldown then
					if icon.cooldown.SetCooldownFromExpirationTime then
						pcall(
							icon.cooldown.SetCooldownFromExpirationTime,
							icon.cooldown,
							aura.expirationTime,
							aura.duration
						)
					end

					if icon.cooldown.SetShownFromBoolean then
						icon.cooldown:SetShownFromBoolean(hasExpiration, true, false)
					else
						icon.cooldown:Show()
					end
				end

				icon:Show()
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
		frame.buffsContainer = addon.Frames.Widgets.Icons.Factory:CreateContainer(frame, "buffsContainer")
	end

	local container = frame.buffsContainer

	for i = 1, buffSettings.maxIcons do
		if not container.icons[i] then
			container.icons[i] = addon.Frames.Widgets.Icons.Factory:CreateIcon(container, 1)
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
