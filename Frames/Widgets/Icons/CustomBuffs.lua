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
			local color = icon.colorTextureColor or {}
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
				colorTexture = icon.colorTexture == true,
				colorTextureColor = {
					r = color.r or 1,
					g = color.g or 1,
					b = color.b or 1,
					a = color.a or 1,
				},
			}
		end
	end

	settingsCache[settings] = {
		specAuras = specAuras,
		iconSettings = iconSettings,
	}
end

function CustomBuffs:Ensure(frame)
	if addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility then
		return
	end

	if not frame.customBuffsFrame then
		local container = CreateFrame("Frame", nil, frame)
		container:SetAllPoints(frame)
		container:SetFrameLevel(43)
		frame.customBuffsFrame = container
	end

	if not frame.customBuffs then
		frame.customBuffs = {}
	end

	local classFileName = addon.Utilities:GetPlayerClassFileName()
	local defaultAuraValues = addon.Database:GetCustomAuraDefaults() or {}
	local classDefaults = defaultAuraValues[classFileName] or {}

	for _, specDefaults in pairs(classDefaults) do
		for spellId, defaultEntry in pairs(specDefaults) do
			if defaultEntry.enabled ~= false and not frame.customBuffs[spellId] then
				frame.customBuffs[spellId] = addon.Frames.Managers.IconManager:CreateIcon(frame.customBuffsFrame, 1)
			end
		end
	end
end

function CustomBuffs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility then
		return
	end

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
			local scaledIconSizePx = frame.dataProvider:ScaleEven(frame, s.iconSizePx)
			local scaledOffsetXPx = frame.dataProvider:Scale(frame, s.offsetXPx)
			local scaledOffsetYPx = frame.dataProvider:Scale(frame, s.offsetYPx)

			icon:SetSize(addon.Utilities:ToUI(scaledIconSizePx), addon.Utilities:ToUI(scaledIconSizePx))
			icon:ClearAllPoints()
			icon:SetPoint(
				s.anchor,
				frame.customBuffsFrame,
				s.anchor,
				addon.Utilities:ToUI(scaledOffsetXPx),
				addon.Utilities:ToUI(scaledOffsetYPx)
			)

			addon.Frames.Managers.IconManager:ApplyBorderSettings(icon, s, frame)
			addon.Frames.Managers.IconManager:ApplyCountSettings(icon, s, frame)
			addon.Frames.Managers.IconManager:ApplyCooldownSettings(icon, s, frame)
		elseif icon then
			icon:Hide()
		end
	end
end

function CustomBuffs:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility then
		return
	end

	local customBuffs = frame.customBuffs

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.customBuffs ~= true then
		for _, icon in pairs(customBuffs) do
			icon:Hide()
		end
		return
	end

	local unit = frame.unit
	local provider = frame.dataProvider
	local isTestProvider = provider == addon.Frames.DataProvider.Test

	if not isTestProvider and (not unit or not UnitExists(unit)) then
		for _, icon in pairs(customBuffs) do
			icon:Hide()
		end
		return
	end

	for _, icon in pairs(customBuffs) do
		icon:Hide()
	end

	local auras = provider:GetUnitAuras(frame, "helpfulPlayer")
	for _, aura in pairs(auras) do
		local spellOk, iconSettings = pcall(function()
			return aura.spellId and cachedSettings.iconSettings[aura.spellId]
		end)
		if spellOk and iconSettings then
			local icon = customBuffs[aura.spellId]
			if icon and (aura.icon or iconSettings.colorTexture) then
				local hasExpiration = provider:DoesAuraHaveExpirationTime(frame, aura)
				local stackText = provider:GetAuraApplicationDisplayCount(frame, aura, 2, 99)

				if iconSettings.colorTexture then
					addon.Frames.Managers.IconManager:ApplyColorTexture(icon, iconSettings.colorTextureColor)
				else
					addon.Frames.Managers.IconManager:ApplyTexture(icon, aura.icon)
				end

				addon.Frames.Managers.IconManager:ApplyIconState(icon, {
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
