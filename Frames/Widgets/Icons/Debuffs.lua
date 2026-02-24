local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Debuffs = addon.Frames.Widgets.Icons.Debuffs or {}

local Debuffs = addon.Frames.Widgets.Icons.Debuffs

local function GetDebuffSettings(settings)
	return settings and settings.widgets and settings.widgets.icons and settings.widgets.icons.debuffs
end

local function UpdateIconSettings(icon, debuffSettings)
	local iconSizePx = debuffSettings.iconSize
	local borderSizePx = debuffSettings.borderSizePx
	local stacksFontSize = debuffSettings.stacksFontSize

	local iconSize = addon.Utilities:FromPixels(iconSizePx)
	local inset = addon.Utilities:FromPixels(borderSizePx)

	icon:SetSize(iconSize, iconSize)

	icon.texture:ClearAllPoints()
	icon.texture:SetPoint("TOPLEFT", icon, "TOPLEFT", inset, -inset)
	icon.texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -inset, inset)

	icon.border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = addon.Utilities:FromPixels(borderSizePx),
	})
	icon.border:SetBackdropBorderColor(0, 0, 0, 1)

	icon.countText:SetFont("Fonts\\FRIZQT__.TTF", stacksFontSize, "OUTLINE")
	icon.countText:ClearAllPoints()
	icon.countText:SetTextColor(1, 1, 1, 1)
	icon.countText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -inset, inset)
end

function Debuffs:UpdateSettings(frame, settings)
	local debuffSettings = GetDebuffSettings(settings)
	local container = frame and frame.debuffsContainer
	if not debuffSettings or not container then
		return
	end

	local maxIcons = math.max(1, debuffSettings.maxIcons)
	local iconsPerRow = math.max(1, debuffSettings.iconsPerRow)
	local iconSizePx = debuffSettings.iconSize
	local spacingPx = debuffSettings.spacing

	container:ClearAllPoints()
	container:SetPoint(
		"BOTTOMLEFT",
		container:GetParent(),
		"BOTTOMLEFT",
		addon.Utilities:FromPixels(debuffSettings.offsetX),
		addon.Utilities:FromPixels(debuffSettings.offsetY)
	)

	local visibleCols = math.min(maxIcons, iconsPerRow)
	local rowCount = math.max(1, math.ceil(maxIcons / iconsPerRow))

	local widthPx = (visibleCols * iconSizePx) + ((visibleCols - 1) * spacingPx)
	local heightPx = (rowCount * iconSizePx) + ((rowCount - 1) * spacingPx)

	container:SetSize(addon.Utilities:FromPixels(widthPx), addon.Utilities:FromPixels(heightPx))

	for i = 1, maxIcons do
		local icon = container.icons[i]
		if not icon then
			icon = addon.Frames.Widgets.Icons.Factory:CreateIcon(container, 1)
			container.icons[i] = icon
		end

		UpdateIconSettings(icon, debuffSettings)

		local idx = i - 1
		local col = idx % iconsPerRow
		local row = math.floor(idx / iconsPerRow)

		local xPx = (col * (iconSizePx + spacingPx))
		local yPx = (row * (iconSizePx + spacingPx))

		icon:ClearAllPoints()
		icon:SetPoint(
			"BOTTOMLEFT",
			container,
			"BOTTOMLEFT",
			addon.Utilities:FromPixels(xPx),
			addon.Utilities:FromPixels(yPx)
		)
	end

	for i = maxIcons + 1, #container.icons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end
end

function Debuffs:UpdateState(frame, settings)
	local debuffSettings = GetDebuffSettings(settings)
	local container = frame and frame.debuffsContainer
	if not debuffSettings or not container then
		return
	end

	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		container:Hide()
		return
	end

	local bucket = addon.AuraHandler and addon.AuraHandler:GetBucketForUnit(unit)
	local approved = bucket and bucket.debuffs
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

	local maxIcons = debuffSettings.maxIcons
	local shown, auraIndex = 0, 1
	local filter = "HARMFUL"

	while shown < maxIcons do
		local aura = C_UnitAuras.GetAuraDataByIndex(unit, auraIndex, filter)
		if not aura then
			break
		end
		auraIndex = auraIndex + 1

		local auraInstanceID = aura.auraInstanceID
		if auraInstanceID and approved[auraInstanceID] and aura.icon then
			local icon = container.icons[shown + 1]
			if icon and icon.texture then
				shown = shown + 1

				-- texture
				icon.texture:SetTexture(aura.icon)

				-- stacks
				if icon.countText then
					icon.countText:SetText("")
					if C_UnitAuras.GetAuraApplicationDisplayCount then
						local stackText = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 99)
						if stackText then
							icon.countText:SetText(stackText)
						end
					end
				end

				-- expiration / cooldown (secret-safe)
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

function Debuffs:Ensure(frame, settings)
	local debuffSettings = GetDebuffSettings(settings)
	if not frame or not debuffSettings then
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
