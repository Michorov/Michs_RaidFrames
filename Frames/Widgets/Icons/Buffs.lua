local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Buffs = addon.Frames.Widgets.Icons.Buffs or {}

local Buffs = addon.Frames.Widgets.Icons.Buffs

local function GetBuffSettings(settings)
	return settings and settings.widgets and settings.widgets.icons and settings.widgets.icons.buffs
end

local function UpdateIconSettings(icon, buffSettings)
	local iconSizePx = buffSettings.iconSize
	local borderSizePx = buffSettings.borderSizePx
	local stacksFontSize = buffSettings.stacksFontSize

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

function Buffs:UpdateSettings(frame, settings)
	local buffSettings = GetBuffSettings(settings)
	local container = frame and frame.buffsContainer
	if not buffSettings or not container then
		return
	end

	local maxIcons = math.max(1, buffSettings.maxIcons)
	local iconsPerRow = math.max(1, buffSettings.iconsPerRow)
	local iconSizePx = buffSettings.iconSize
	local spacingPx = buffSettings.spacing

	container:ClearAllPoints()
	container:SetPoint(
		"BOTTOMRIGHT",
		container:GetParent(),
		"BOTTOMRIGHT",
		addon.Utilities:FromPixels(buffSettings.offsetX),
		addon.Utilities:FromPixels(buffSettings.offsetY)
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

		UpdateIconSettings(icon, buffSettings)

		local idx = i - 1
		local col = idx % iconsPerRow
		local row = math.floor(idx / iconsPerRow)

		local xPx = -(col * (iconSizePx + spacingPx))
		local yPx = (row * (iconSizePx + spacingPx))

		icon:ClearAllPoints()
		icon:SetPoint(
			"BOTTOMRIGHT",
			container,
			"BOTTOMRIGHT",
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

function Buffs:UpdateState(frame, settings)
	local buffSettings = GetBuffSettings(settings)
	local container = frame and frame.buffsContainer
	if not buffSettings or not container then
		return
	end

	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		container:Hide()
		return
	end

	local bucket = addon.AuraHandler and addon.AuraHandler:GetBucketForUnit(unit)
	local approved = bucket and bucket.buffs
	if not approved or not next(approved) then
		for i = 1, buffSettings.maxIcons do
			local icon = container.icons[i]
			if icon then
				icon:Hide()
			end
		end
		container:SetShown(false)
		return
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
		if auraInstanceID and approved[auraInstanceID] and aura.icon then
			local icon = container.icons[shown + 1]
			if icon and icon.texture then
				shown = shown + 1

				-- Texture
				icon.texture:SetTexture(aura.icon)

				-- Stacks
				if icon.countText then
					icon.countText:SetText("")
					if C_UnitAuras.GetAuraApplicationDisplayCount then
						local stackText = C_UnitAuras.GetAuraApplicationDisplayCount(unit, auraInstanceID, 2, 99)
						if stackText then
							icon.countText:SetText(stackText)
						end
					end
				end

				-- Expiration (Duration)
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
	if not frame or not buffSettings then
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
