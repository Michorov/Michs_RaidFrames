local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.CustomIcons = addon.Frames.Widgets.Icons.CustomIcons or {}

local CustomIcons = addon.Frames.Widgets.Icons.CustomIcons

local function GetCustomIconSettings(iconSettings)
	local icon = iconSettings or {}

	return {
		anchor = icon.anchor or "CENTER",
		offsetXPx = addon.Utilities:ToPixels(icon.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(icon.offsetY or 0),
		iconSizePx = addon.Utilities:ToPixels(icon.iconSize or 16),
		borderSizePx = addon.Utilities:ToPixels(1),
		showStacks = icon.showStacks == true,
		stacksFontSize = icon.stacksFontSize or 10,
		showCooldown = icon.showCooldown == true,
		cooldownFontSize = icon.cooldownFontSize or 10,
	}
end

local function GetSpecAuras(settings)
	local classFileName = addon.Utilities:GetPlayerClassFileName()
	local specID = addon.Utilities:GetPlayerSpecID()
	local section = (settings and settings.widgets and settings.widgets.icons and settings.widgets.icons.customBuffs)
		or {}
	local classAuras = section[classFileName] or {}
	return classAuras[specID] or classAuras[-1] or {}
end

function CustomIcons:Ensure(frame, settings)
	if not frame then
		return
	end

	if not frame.customIcons then
		frame.customIcons = {}
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not widgetsOverlay then
		return
	end

	local specAuras = GetSpecAuras(settings)

	for spellId, iconSettings in pairs(specAuras) do
		if iconSettings.enabled and not frame.customIcons[spellId] then
			frame.customIcons[spellId] = addon.Frames.Managers.IconManager:CreateIcon(widgetsOverlay, 20)
		end
	end
end

function CustomIcons:UpdateSettings(frame, settings)
	local widgetsOverlay = frame and frame.widgetsOverlay
	local customIcons = frame and frame.customIcons
	if not widgetsOverlay or not customIcons then
		return
	end

	local specAuras = GetSpecAuras(settings)

	for spellId, iconSettings in pairs(specAuras) do
		local icon = customIcons[spellId]

		if iconSettings.enabled then
			if not icon then
				icon = addon.Frames.Managers.IconManager:CreateIcon(widgetsOverlay, 20)
				customIcons[spellId] = icon
			end

			local s = GetCustomIconSettings(iconSettings)
			local scaledIconSizePx = addon.Utilities:ScaleEven(s.iconSizePx)
			local scaledOffsetXPx = addon.Utilities:Scale(s.offsetXPx)
			local scaledOffsetYPx = addon.Utilities:Scale(s.offsetYPx)

			icon:SetSize(addon.Utilities:ToUI(scaledIconSizePx), addon.Utilities:ToUI(scaledIconSizePx))
			icon:ClearAllPoints()
			icon:SetPoint(
				s.anchor,
				widgetsOverlay,
				s.anchor,
				addon.Utilities:ToUI(scaledOffsetXPx),
				addon.Utilities:ToUI(scaledOffsetYPx)
			)

			addon.Frames.Managers.IconManager:ApplyBorderSettings(icon, s)
			addon.Frames.Managers.IconManager:ApplyCountSettings(icon, s)
			addon.Frames.Managers.IconManager:ApplyCooldownSettings(icon, s)
		elseif icon then
			icon:Hide()
		end
	end
end

function CustomIcons:UpdateState(frame, settings)
	local customIcons = frame and frame.customIcons
	if not customIcons then
		return
	end

	local unit = frame and frame.unit
	local provider = frame and frame.dataProvider
	local isTestProvider = provider == addon.Frames.DataProvider.Test

	if not isTestProvider and (not unit or not UnitExists(unit)) then
		for _, icon in pairs(customIcons) do
			icon:Hide()
		end
		return
	end

	local specAuras = GetSpecAuras(settings)

	local enabledSpells = {}
	for spellId, iconSettings in pairs(specAuras) do
		if iconSettings.enabled then
			enabledSpells[spellId] = true
		end
	end

	for _, icon in pairs(customIcons) do
		icon:Hide()
	end

	local auras = provider:GetUnitAuras(frame, "helpfulPlayer")
	for _, aura in ipairs(auras) do
		local spellOk, isEnabled = pcall(function() return aura.spellId and enabledSpells[aura.spellId] end)
		if spellOk and isEnabled then
			local icon = customIcons[aura.spellId]
			if icon and aura.icon then
				local hasExpiration = provider:DoesAuraHaveExpirationTime(frame, aura)
				local stackText = provider:GetAuraApplicationDisplayCount(frame, aura, 2, 99)
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
end

function CustomIcons:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "customBuffSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
