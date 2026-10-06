local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Debuffs = addon.Frames.Widgets.Icons.Debuffs or {}

local Debuffs = addon.Frames.Widgets.Icons.Debuffs

local settingsCache = setmetatable({}, { __mode = "k" })
local ENSURE_MAX_ICONS = 10

local issecretvalue = issecretvalue

local DEBUFF_BLACKLIST = {
	[57723] = true, -- Exhaustion
	[57724] = true, -- Sated
	[80354] = true, -- Temporal Displacement
	[95809] = true, -- Hunter Pet Insanity
	[160455] = true, -- Hunter Pet Fatigued
	[264689] = true, -- Hunter Pet Fatigued
	[390435] = true, -- Exhaustion

	[26013] = true, -- BG Deserter
	[71041] = true, -- Dungeon Deserter

	[427490] = true, -- Ride Along Available
	[447959] = true, -- Ride Along Active
	[447960] = true, -- Ride Along Inactive
}

local DISPEL_CURVE_DEFAULTS = {
	None = { 0, DEBUFF_TYPE_NONE_COLOR },
	Magic = { 1, DEBUFF_TYPE_MAGIC_COLOR },
	Curse = { 2, DEBUFF_TYPE_CURSE_COLOR },
	Disease = { 3, DEBUFF_TYPE_DISEASE_COLOR },
	Poison = { 4, DEBUFF_TYPE_POISON_COLOR },
	Enrage = { 9, DEBUFF_TYPE_BLEED_COLOR },
	Bleed = { 11, DEBUFF_TYPE_BLEED_COLOR },
}

local dispelCurve = C_CurveUtil.CreateColorCurve()
dispelCurve:SetType(Enum.LuaCurveType.Step)

for _, data in pairs(DISPEL_CURVE_DEFAULTS) do
	dispelCurve:AddPoint(data[1], data[2])
end

local function IsBlacklistedAura(aura)
	if not aura then
		return false
	end

	local spellId = aura.spellId
	if spellId == nil then
		return false
	end

	if issecretvalue and issecretvalue(spellId) then
		return false
	end

	return DEBUFF_BLACKLIST[spellId] == true
end

local function EnsureDebuffTypeBorder(icon)
	if not icon or icon.debuffTypeBorder then
		return icon and icon.debuffTypeBorder
	end

	local border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
	border:SetFrameLevel(icon:GetFrameLevel() + 3)
	icon.debuffTypeBorder = border

	return border
end

local function UpdateDebuffTypeBorderSettings(icon, cachedSettings, frame)
	local border = EnsureDebuffTypeBorder(icon)
	if not border then
		return
	end

	local scaledBorderSizePx = math.max(0, frame.dataProvider:Scale(frame, cachedSettings.borderSizePx))
	if scaledBorderSizePx <= 0 or not cachedSettings.borderColorByDebuffType then
		border:SetBackdrop(nil)
		border:Hide()
		return
	end

	local borderSize = addon.Utilities:ToUI(scaledBorderSizePx)

	border:ClearAllPoints()
	border:SetPoint("TOPLEFT", icon, "TOPLEFT", borderSize, -borderSize)
	border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -borderSize, borderSize)
	border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = borderSize,
	})
	border:Show()
end

local function UpdateDebuffTypeBorderColor(icon, color)
	local border = icon and icon.debuffTypeBorder
	if not border then
		return
	end

	if not border:IsShown() then
		return
	end

	if color then
		border:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
	else
		border:SetBackdropBorderColor(0, 0, 0, 1)
	end
end

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local debuffs = icons.debuffs or {}

	local result = {
		enabled = debuffs.enabled ~= false,
		borderColorByDebuffType = debuffs.borderColorByDebuffType == true,
		anchor = debuffs.anchor or "BOTTOMLEFT",
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
		borderSizePx = addon.Utilities:ToPixels((debuffs.borderSizePx ~= 0) and 1 or 0),
	}

	settingsCache[settings] = result
end

function Debuffs:Ensure(frame)
	if frame.frameType ~= "preview" then
		return
	end

	if not frame.debuffsContainer then
		frame.debuffsContainer = addon.Frames.Managers.IconManager:CreateContainer(frame, "debuffsContainer", 41)
	end

	local container = frame.debuffsContainer

	for i = 1, ENSURE_MAX_ICONS do
		if not container.icons[i] then
			container.icons[i] = addon.Frames.Managers.IconManager:CreateIcon(container, 1)
		end
	end
end

local function UpdateContainerSettings(frame, settings)
	local container = frame.debuffsContainer
	local cachedSettings = settingsCache[settings]

	local iconSizePx = frame.dataProvider:Scale(frame, cachedSettings.iconSizePx)
	local spacingPx = frame.dataProvider:Scale(frame, cachedSettings.spacingPx)
	local containerOffsetXPx = frame.dataProvider:Scale(frame, cachedSettings.offsetXPx)
	local containerOffsetYPx = frame.dataProvider:Scale(frame, cachedSettings.offsetYPx)
	local anchor = cachedSettings.anchor

	container:ClearAllPoints()
	container:SetPoint(
		anchor,
		frame,
		anchor,
		addon.Utilities:ToUI(containerOffsetXPx),
		addon.Utilities:ToUI(containerOffsetYPx)
	)

	local visibleCols = math.min(cachedSettings.maxIcons, cachedSettings.iconsPerRow)
	local rowCount = math.max(1, math.ceil(cachedSettings.maxIcons / cachedSettings.iconsPerRow))

	local widthPx = (visibleCols * iconSizePx) + ((visibleCols - 1) * spacingPx)
	local heightPx = (rowCount * iconSizePx) + ((rowCount - 1) * spacingPx)

	container:SetSize(addon.Utilities:ToUI(widthPx), addon.Utilities:ToUI(heightPx))
end

local function UpdateIconSettings(frame, settings)
	local container = frame.debuffsContainer
	local cachedSettings = settingsCache[settings]

	local iconSizePx = frame.dataProvider:Scale(frame, cachedSettings.iconSizePx)
	local spacingPx = frame.dataProvider:Scale(frame, cachedSettings.spacingPx)
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

		addon.Frames.Managers.IconManager:ApplyIconSizeSettings(icon, cachedSettings, frame)
		addon.Frames.Managers.IconManager:ApplyBorderSettings(icon, cachedSettings, frame)
		addon.Frames.Managers.IconManager:ApplyCountSettings(icon, cachedSettings, frame)
		addon.Frames.Managers.IconManager:ApplyCooldownSettings(icon, cachedSettings, frame)
		UpdateDebuffTypeBorderSettings(icon, cachedSettings, frame)

		local gridIndex = i - 1
		local column = gridIndex % cachedSettings.iconsPerRow
		local row = math.floor(gridIndex / cachedSettings.iconsPerRow)

		local offsetXPx = column * stepPx * xDirection
		local offsetYPx = row * stepPx * yDirection

		icon:ClearAllPoints()
		icon:SetPoint(
			anchor,
			container,
			anchor,
			addon.Utilities:ToUI(offsetXPx),
			addon.Utilities:ToUI(offsetYPx)
		)
	end

	for i = cachedSettings.maxIcons + 1, #container.icons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end
end

function Debuffs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if frame.frameType ~= "preview" then
		return
	end

	UpdateContainerSettings(frame, settings)
	UpdateIconSettings(frame, settings)
end

function Debuffs:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if frame.frameType ~= "preview" then
		return
	end

	local container = frame.debuffsContainer

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.debuffs ~= true then
		addon.Frames.Managers.IconManager:HideIcons(container, cachedSettings.maxIcons)
		return
	end

	local unit = frame.unit
	local provider = frame.dataProvider
	local isTestProvider = provider == addon.Frames.DataProvider.Test

	if not cachedSettings.enabled then
		addon.Frames.Managers.IconManager:HideIcons(container, cachedSettings.maxIcons)
		return
	end

	if not isTestProvider and (not unit or not UnitExists(unit)) then
		container:Hide()
		return
	end

	local shown = 0
	local maxIcons = cachedSettings.maxIcons
	local auras = provider:GetUnitAuras(frame, "harmful")

	for _, aura in pairs(auras) do
		if shown >= maxIcons then
			break
		end

		if aura.icon and not IsBlacklistedAura(aura) then
			local icon = container.icons[shown + 1]
			if icon then
				shown = shown + 1

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

				if cachedSettings.borderColorByDebuffType then
					local color = provider:GetAuraDispelTypeColor(frame, aura, dispelCurve)
					UpdateDebuffTypeBorderColor(icon, color)
				else
					UpdateDebuffTypeBorderColor(icon)
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

function Debuffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "debuffAurasSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
