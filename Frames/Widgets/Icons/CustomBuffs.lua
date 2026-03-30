local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.CustomBuffs = addon.Frames.Widgets.Icons.CustomBuffs or {}

local CustomBuffs = addon.Frames.Widgets.Icons.CustomBuffs

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local classFileName = addon.Utilities:GetPlayerClassFileName()
	local specID = addon.Utilities:GetPlayerSpecID()
	local section = (settings and settings.widgets and settings.widgets.icons and settings.widgets.icons.customBuffs)
		or {}
	local classAuras = section[classFileName] or {}
	local specAuras = classAuras[specID] or classAuras[-1] or {}

	local iconSettings = {}
	for spellId, iconData in pairs(specAuras) do
		if iconData.enabled then
			local icon = iconData or {}
			iconSettings[spellId] = {
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
	end

	settingsCache[settings] = {
		specAuras = specAuras,
		iconSettings = iconSettings,
	}
end

function CustomBuffs:Ensure(frame, settings)
	if not frame.customBuffsFrame then
		local container = CreateFrame("Frame", nil, frame)
		container:SetAllPoints(frame)
		container:SetFrameLevel(43)
		frame.customBuffsFrame = container
	end

	if not frame.customBuffs then
		frame.customBuffs = {}
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	for spellId, iconSettings in pairs(cachedSettings.specAuras) do
		if iconSettings.enabled and not frame.customBuffs[spellId] then
			frame.customBuffs[spellId] = addon.Frames.Managers.IconManager:CreateIcon(frame.customBuffsFrame, 1)
		end
	end
end

function CustomBuffs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]
	local customBuffs = frame.customBuffs

	for spellId, iconSettings in pairs(cachedSettings.specAuras) do
		local icon = customBuffs[spellId]

		if iconSettings.enabled then
			if not icon then
				icon = addon.Frames.Managers.IconManager:CreateIcon(frame.customBuffsFrame, 1)
				customBuffs[spellId] = icon
			end

			local s = cachedSettings.iconSettings[spellId]
			local scaledIconSizePx = addon.Utilities:ScaleEven(s.iconSizePx)
			local scaledOffsetXPx = addon.Utilities:Scale(s.offsetXPx)
			local scaledOffsetYPx = addon.Utilities:Scale(s.offsetYPx)

			icon:SetSize(addon.Utilities:ToUI(scaledIconSizePx), addon.Utilities:ToUI(scaledIconSizePx))
			icon:ClearAllPoints()
			icon:SetPoint(
				s.anchor,
				frame.customBuffsFrame,
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

function CustomBuffs:UpdateState(frame, settings)
	local customBuffs = frame.customBuffs

	local unit = frame.unit
	local provider = frame.dataProvider
	local isTestProvider = provider == addon.Frames.DataProvider.Test

	if not isTestProvider and (not unit or not UnitExists(unit)) then
		for _, icon in pairs(customBuffs) do
			icon:Hide()
		end
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	for _, icon in pairs(customBuffs) do
		icon:Hide()
	end

	local auras = provider:GetUnitAuras(frame, "helpfulPlayer")
	for _, aura in ipairs(auras) do
		local spellOk, isEnabled = pcall(function()
			return aura.spellId and cachedSettings.iconSettings[aura.spellId] ~= nil
		end)
		if spellOk and isEnabled then
			local icon = customBuffs[aura.spellId]
			if icon and aura.icon then
				local hasExpiration = provider:DoesAuraHaveExpirationTime(frame, aura)
				local stackText = provider:GetAuraApplicationDisplayCount(frame, aura, 2, 99)
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

function CustomBuffs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "customBuffSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
