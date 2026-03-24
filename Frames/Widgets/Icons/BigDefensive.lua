local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.BigDefensive = addon.Frames.Widgets.Icons.BigDefensive or {}

local BigDefensive = addon.Frames.Widgets.Icons.BigDefensive

local function GetBigDefensiveSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local bigDefensive = icons.bigDefensive or {}

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

function BigDefensive:Ensure(frame, settings)
	local bigDefensiveSettings = GetBigDefensiveSettings(settings)
	if not frame then
		return
	end

	if not frame.bigDefensiveContainer then
		frame.bigDefensiveContainer = addon.Frames.Managers.IconManager:CreateContainer(frame, "bigDefensiveContainer")
	end

	local container = frame.bigDefensiveContainer
	if not container then
		return
	end

	for i = 1, bigDefensiveSettings.maxIcons do
		if not container.icons[i] then
			container.icons[i] = addon.Frames.Managers.IconManager:CreateIcon(container, 15)
		end
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
			icon = addon.Frames.Managers.IconManager:CreateIcon(container, 15)
			container.icons[i] = icon
		end

		addon.Frames.Managers.IconManager:ApplyEvenIconSizeSettings(icon, bigDefensiveSettings)
		addon.Frames.Managers.IconManager:ApplyBorderSettings(icon, bigDefensiveSettings)
		addon.Frames.Managers.IconManager:ApplyCountSettings(icon, bigDefensiveSettings)
		addon.Frames.Managers.IconManager:ApplyCooldownSettings(icon, bigDefensiveSettings)

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

	if not isTestProvider and (not unit or not UnitExists(unit) or not UnitIsVisible(unit)) then
		container:Hide()
		return
	end

	local maxIcons = bigDefensiveSettings.maxIcons
	local shown = 0

	local icon = container.icons[1]
	if not icon then
		container:Hide()
		return
	end

	local auras = provider:GetUnitAuras(frame, "helpfulBigDefensive")
	local aura = auras and auras[1]

	if aura and aura.icon and icon then
		local stackText
		if bigDefensiveSettings.showStacks then
			stackText = provider:GetAuraApplicationDisplayCount(frame, aura, 2, 99)
		end

		local hasExpiration = provider:DoesAuraHaveExpirationTime(frame, aura)

		addon.Frames.Managers.IconManager:ApplyIconState(icon, {
			texture = aura.icon,
			countText = stackText,
			durationObject = provider:GetAuraDuration(frame, aura),
			hasExpiration = hasExpiration,
		})

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

function BigDefensive:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "bigDefensiveAurasSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
