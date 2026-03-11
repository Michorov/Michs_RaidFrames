local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Debuffs = addon.Frames.Widgets.Icons.Debuffs or {}

local Debuffs = addon.Frames.Widgets.Icons.Debuffs

local function GetDebuffSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local debuffs = icons.debuffs or {}

	return {
		anchor = debuffs.anchor or "BOTTOMLEFT",
		relativeAnchor = debuffs.relativeAnchor or "BOTTOMLEFT",
		offsetXPx = addon.Utilities:ToPixels(debuffs.offsetX or 2),
		offsetYPx = addon.Utilities:ToPixels(debuffs.offsetY or 2),
		maxIcons = math.max(1, debuffs.maxIcons or 6),
		iconsPerRow = math.max(1, debuffs.iconsPerRow or 3),
		iconSizePx = addon.Utilities:ToPixels(debuffs.iconSize or 20),
		spacingPx = addon.Utilities:ToPixels(debuffs.spacing or -1),
		showStacks = debuffs.showStacks ~= false,
		stacksFontSize = debuffs.stacksFontSize or 10,
		showCooldown = debuffs.showCooldown == true,
		cooldownFontSize = debuffs.cooldownFontSize or 10,
		borderSizePx = addon.Utilities:ToPixels(debuffs.borderSizePx or 1),
	}
end

local function UpdateIconSettings(icon, debuffSettings)
	local scaledIconPx = addon.Utilities:Scale(debuffSettings.iconSizePx)
	local scaledBorderPx = math.max(1, addon.Utilities:Scale(debuffSettings.borderSizePx))

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

	icon.countText:SetFont("Fonts\\FRIZQT__.TTF", addon.Utilities:ScaleFont(debuffSettings.stacksFontSize), "OUTLINE")
	icon.countText:ClearAllPoints()
	icon.countText:SetTextColor(1, 1, 1, 1)
	icon.countText:SetShown(debuffSettings.showStacks)
	icon.countText:SetPoint(
		"BOTTOMRIGHT",
		icon,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(scaledBorderPx - 2),
		addon.Utilities:ToUI(scaledBorderPx - 2)
	)

	if icon.cooldown and icon.cooldown.SetHideCountdownNumbers then
		icon.cooldown:SetHideCountdownNumbers(not debuffSettings.showCooldown)
	end
	if debuffSettings.showCooldown and icon.cooldown and icon.cooldown.SetCountdownFont then
		local scaledSize = addon.Utilities:ScaleFont(debuffSettings.cooldownFontSize)
		local fontName = "MRF_CooldownFont_" .. tostring(scaledSize)
		local cooldownFont = _G[fontName]
		if not cooldownFont then
			cooldownFont = CreateFont(fontName)
		end
		cooldownFont:SetFont("Fonts\\FRIZQT__.TTF", scaledSize, "OUTLINE")
		icon.cooldown:SetCountdownFont(fontName)
	end
end

function Debuffs:UpdateSettings(frame, settings)
	local debuffSettings = GetDebuffSettings(settings)
	local container = frame and frame.debuffsContainer
	if not container then
		return
	end

	local iconSizePx = addon.Utilities:Scale(debuffSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(debuffSettings.spacingPx)
	local offsetXPx = addon.Utilities:Scale(debuffSettings.offsetXPx)
	local offsetYPx = addon.Utilities:Scale(debuffSettings.offsetYPx)

	container:ClearAllPoints()
	container:SetPoint(
		debuffSettings.anchor,
		container:GetParent(),
		debuffSettings.relativeAnchor,
		addon.Utilities:ToUI(offsetXPx),
		addon.Utilities:ToUI(offsetYPx)
	)

	local visibleCols = math.min(debuffSettings.maxIcons, debuffSettings.iconsPerRow)
	local rowCount = math.max(1, math.ceil(debuffSettings.maxIcons / debuffSettings.iconsPerRow))

	local widthPx = (visibleCols * iconSizePx) + ((visibleCols - 1) * spacingPx)
	local heightPx = (rowCount * iconSizePx) + ((rowCount - 1) * spacingPx)

	container:SetSize(addon.Utilities:ToUI(widthPx), addon.Utilities:ToUI(heightPx))

	for i = 1, debuffSettings.maxIcons do
		local icon = container.icons[i]
		if not icon then
			icon = addon.Frames.Widgets.Icons.Factory:CreateIcon(container, 1)
			container.icons[i] = icon
		end

		UpdateIconSettings(icon, debuffSettings)

		local idx = i - 1
		local col = idx % debuffSettings.iconsPerRow
		local row = math.floor(idx / debuffSettings.iconsPerRow)

		local stepPx = iconSizePx + spacingPx
		local xPx = (col * stepPx)
		local yPx = (row * stepPx)

		icon:ClearAllPoints()
		icon:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", addon.Utilities:ToUI(xPx), addon.Utilities:ToUI(yPx))
	end

	for i = debuffSettings.maxIcons + 1, #container.icons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end
end

function Debuffs:UpdateState(frame, settings)
	local debuffSettings = GetDebuffSettings(settings)
	local container = frame and frame.debuffsContainer
	if not container then
		return
	end

	local unit = frame.unit
	local provider = frame and frame.dataProvider
	local isTestProvider = provider == addon.Frames.DataProvider.Test

	if not isTestProvider and (not unit or not UnitExists(unit)) then
		container:Hide()
		return
	end

	local approved
	if not isTestProvider then
		local bucket = addon.AuraHandler and addon.AuraHandler:GetBucketForUnit(unit)
		approved = bucket and bucket.debuffs
		if not approved or not next(approved) then
			for i = 1, debuffSettings.maxIcons do
				local icon = container.icons[i]
				if icon then
					icon:Hide()
				end
			end
			container:SetShown(false)
			return
		end
	end

	local maxIcons = debuffSettings.maxIcons
	local shown, auraIndex = 0, 1
	local filter = "HARMFUL"
	local maxScan = isTestProvider and (maxIcons * 10) or math.huge

	while shown < maxIcons and auraIndex <= maxScan do
		local aura = provider:GetAuraDataByIndex(frame, auraIndex, filter)
		if not aura then
			break
		end
		auraIndex = auraIndex + 1

		local auraInstanceID = aura.auraInstanceID
		local shouldShowAura = false

		if isTestProvider then
			shouldShowAura = true
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
					if debuffSettings.showStacks then
						local stackText = provider:GetAuraApplicationDisplayCount(frame, aura, 2, 99)
						if stackText then
							icon.countText:SetText(stackText)
						end
					end
				end

				local hasExpiration = provider:DoesAuraHaveExpirationTime(frame, aura)

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

function Debuffs:Ensure(frame, settings)
	local debuffSettings = GetDebuffSettings(settings)
	if not frame then
		return
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not widgetsOverlay then
		return
	end

	if not frame.debuffsContainer then
		frame.debuffsContainer = addon.Frames.Widgets.Icons.Factory:CreateContainer(frame, "debuffsContainer")
	end

	local container = frame.debuffsContainer

	for i = 1, debuffSettings.maxIcons do
		if not container.icons[i] then
			container.icons[i] = addon.Frames.Widgets.Icons.Factory:CreateIcon(container, 1)
		end
	end
end

function Debuffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "debuffAurasSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
