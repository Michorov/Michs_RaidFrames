local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.BigDefensive = addon.Frames.Widgets.Icons.BigDefensive or {}

local BigDefensive = addon.Frames.Widgets.Icons.BigDefensive

local function GetBigDefensiveSettings(settings)
	local bigDefensive = settings
			and settings.widgets
			and settings.widgets.icons
			and settings.widgets.icons.bigDefensive
		or {}

	return {
		anchor = bigDefensive.anchor or "CENTER",
		relativeAnchor = bigDefensive.relativeAnchor or "CENTER",
		offsetXPx = addon.Utilities:ToPixels(bigDefensive.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(bigDefensive.offsetY or 0),
		maxIcons = math.max(1, bigDefensive.maxIcons or 1),
		iconSizePx = addon.Utilities:ToPixels(bigDefensive.iconSize or 32),
		borderSizePx = addon.Utilities:ToPixels(bigDefensive.borderSizePx or 1),
		showStacks = bigDefensive.showStacks ~= false,
		stacksFontSize = bigDefensive.stacksFontSize or 16,
		showCooldown = bigDefensive.showCooldown == true,
		cooldownFontSize = bigDefensive.cooldownFontSize or 10,
	}
end

local function UpdateIconSettings(icon, settings)
	local iconSizePx = addon.Utilities:ScaleEven(settings.iconSizePx)
	local borderSizePx = math.max(1, addon.Utilities:Scale(settings.borderSizePx))

	icon:SetSize(addon.Utilities:ToUI(iconSizePx), addon.Utilities:ToUI(iconSizePx))

	icon.texture:ClearAllPoints()
	icon.texture:SetPoint(
		"TOPLEFT",
		icon,
		"TOPLEFT",
		addon.Utilities:ToUI(borderSizePx),
		-addon.Utilities:ToUI(borderSizePx)
	)
	icon.texture:SetPoint(
		"BOTTOMRIGHT",
		icon,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(borderSizePx),
		addon.Utilities:ToUI(borderSizePx)
	)

	icon.border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = addon.Utilities:ToUI(borderSizePx),
	})
	icon.border:SetBackdropBorderColor(0, 0, 0, 1)

	icon.countText:SetFont("Fonts\\FRIZQT__.TTF", addon.Utilities:ScaleFont(settings.stacksFontSize), "OUTLINE")
	icon.countText:ClearAllPoints()
	icon.countText:SetTextColor(1, 1, 1, 1)
	icon.countText:SetShown(settings.showStacks)
	icon.countText:SetPoint(
		"BOTTOMRIGHT",
		icon,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(borderSizePx),
		addon.Utilities:ToUI(borderSizePx)
	)

	if icon.cooldown and icon.cooldown.SetHideCountdownNumbers then
		icon.cooldown:SetHideCountdownNumbers(not settings.showCooldown)
	end

	if settings.showCooldown and icon.cooldown and icon.cooldown.SetCountdownFont then
		local scaledSize = addon.Utilities:ScaleFont(settings.cooldownFontSize)
		local fontName = "MRF_CooldownFont_" .. tostring(scaledSize)
		local cooldownFont = _G[fontName]
		if not cooldownFont then
			cooldownFont = CreateFont(fontName)
		end
		cooldownFont:SetFont("Fonts\\FRIZQT__.TTF", scaledSize, "OUTLINE")
		icon.cooldown:SetCountdownFont(fontName)
	end
end

function BigDefensive:UpdateSettings(frame, settings)
	local bigDefensiveSettings = GetBigDefensiveSettings(settings)
	local container = frame and frame.bigDefensiveContainer
	if not container then
		return
	end

	local offsetXPx = addon.Utilities:Scale(bigDefensiveSettings.offsetXPx)
	local offsetYPx = addon.Utilities:Scale(bigDefensiveSettings.offsetYPx)
	local iconSizePx = addon.Utilities:ScaleEven(bigDefensiveSettings.iconSizePx)

	container:ClearAllPoints()
	container:SetPoint(
		bigDefensiveSettings.anchor,
		container:GetParent(),
		bigDefensiveSettings.relativeAnchor,
		addon.Utilities:ToUI(offsetXPx),
		addon.Utilities:ToUI(offsetYPx)
	)

	container:SetSize(addon.Utilities:ToUI(iconSizePx), addon.Utilities:ToUI(iconSizePx))

	for i = 1, bigDefensiveSettings.maxIcons do
		local icon = container.icons[i]
		if not icon then
			icon = addon.Frames.Widgets.Icons.Factory:CreateIcon(container, 15)
			container.icons[i] = icon
		end

		UpdateIconSettings(icon, bigDefensiveSettings)
		icon:ClearAllPoints()
		icon:SetPoint("CENTER", container, "CENTER", 0, 0)
	end

	for i = bigDefensiveSettings.maxIcons + 1, #container.icons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end
end

function BigDefensive:UpdateState(frame, settings)
	local bigDefensiveSettings = GetBigDefensiveSettings(settings)
	local container = frame and frame.bigDefensiveContainer
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

	local maxIcons = bigDefensiveSettings.maxIcons
	local shown = 0
	local icon = container.icons[1]

	if not provider or type(provider.GetAuraDataByAuraInstanceID) ~= "function" then
		container:Hide()
		return
	end

	local auraInstanceID = nil
	if unit then
		auraInstanceID = addon.AuraHandler and addon.AuraHandler:GetDefensiveAuraInstanceID(unit)
	end

	local aura = provider:GetAuraDataByAuraInstanceID(frame, auraInstanceID)

	if aura and aura.icon and icon then
		icon.texture:SetTexture(aura.icon)

		if icon.countText then
			icon.countText:SetText("")
			if bigDefensiveSettings.showStacks then
				local stackText = nil
				if type(provider.GetAuraApplicationDisplayCount) == "function" then
					stackText = provider:GetAuraApplicationDisplayCount(frame, aura, 2, 99)
				end
				if stackText then
					icon.countText:SetText(stackText)
				end
			end
		end

		local hasExpiration = false
		if type(provider.DoesAuraHaveExpirationTime) == "function" then
			hasExpiration = provider:DoesAuraHaveExpirationTime(frame, aura)
		end

		if icon.cooldown then
			if icon.cooldown.SetCooldownFromExpirationTime then
				pcall(icon.cooldown.SetCooldownFromExpirationTime, icon.cooldown, aura.expirationTime, aura.duration)
			end
			if icon.cooldown.SetShownFromBoolean then
				icon.cooldown:SetShownFromBoolean(hasExpiration, true, false)
			else
				icon.cooldown:Show()
			end
		end

		icon:Show()
		shown = 1
	end

	for i = shown + 1, maxIcons do
		local extraIcon = container.icons[i]
		if extraIcon then
			extraIcon:Hide()
		end
	end

	container:SetShown(shown > 0)
end

function BigDefensive:Ensure(frame, settings)
	local bigDefensiveSettings = GetBigDefensiveSettings(settings)
	if not frame then
		return
	end

	if not frame.bigDefensiveContainer then
		frame.bigDefensiveContainer = addon.Frames.Widgets.Icons.Factory:CreateContainer(frame, "bigDefensiveContainer")
	end

	local container = frame.bigDefensiveContainer
	if not container then
		return
	end

	for i = 1, bigDefensiveSettings.maxIcons do
		if not container.icons[i] then
			container.icons[i] = addon.Frames.Widgets.Icons.Factory:CreateIcon(container, 15)
		end
	end
end

function BigDefensive:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "bigDefensiveAurasSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
