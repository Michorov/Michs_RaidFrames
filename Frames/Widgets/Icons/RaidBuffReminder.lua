local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.RaidBuffReminder = addon.Frames.Widgets.Icons.RaidBuffReminder or {}

local RaidBuffReminder = addon.Frames.Widgets.Icons.RaidBuffReminder

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local raidBuffReminder = icons.raidBuffReminder or {}

	local borderColor = raidBuffReminder.borderColor or {}
	settingsCache[settings] = {
		enabled = raidBuffReminder.enabled ~= false,
		showInCombat = raidBuffReminder.showInCombat == true,
		anchor = raidBuffReminder.anchor or "CENTER",
		offsetXPx = addon.Utilities:ToPixels(raidBuffReminder.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(raidBuffReminder.offsetY or 0),
		iconSizePx = addon.Utilities:ToPixels(raidBuffReminder.iconSize or 32),
		borderSizePx = addon.Utilities:ToPixels(raidBuffReminder.borderSizePx or 1),
		borderColor = {
			r = borderColor.r or 1,
			g = borderColor.g or 0,
			b = borderColor.b or 0,
			a = borderColor.a or 1,
		},
	}
end

function RaidBuffReminder:Ensure(frame)
	if addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility then
		return
	end

	if not frame.raidBuffReminderContainer then
		frame.raidBuffReminderContainer = addon.Frames.Managers.IconManager:CreateContainer(frame, "raidBuffReminderContainer", 39)
		frame.raidBuffReminderIcon = addon.Frames.Managers.IconManager:CreateIcon(frame.raidBuffReminderContainer, 1)
	end
	frame.raidBuffReminderIcon:Hide()
end

function RaidBuffReminder:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility then
		return
	end

	local cachedSettings = settingsCache[settings]

	local icon = frame.raidBuffReminderIcon
	if not icon then
		frame.raidBuffReminderContainer = addon.Frames.Managers.IconManager:CreateContainer(frame, "raidBuffReminderContainer", 39)
		frame.raidBuffReminderIcon = addon.Frames.Managers.IconManager:CreateIcon(frame.raidBuffReminderContainer, 1)
		icon = frame.raidBuffReminderIcon
	end

	local offsetXPx = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local offsetYPx = addon.Utilities:Scale(cachedSettings.offsetYPx)

	addon.Frames.Managers.IconManager:ApplyEvenIconSizeSettings(icon, cachedSettings)
	addon.Frames.Managers.IconManager:ApplyBorderSettings(icon, cachedSettings)
	addon.Frames.Managers.IconManager:ApplyBorderColor(icon, cachedSettings.borderColor)

	icon:ClearAllPoints()
	icon:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.anchor,
		addon.Utilities:ToUI(offsetXPx),
		addon.Utilities:ToUI(offsetYPx)
	)
end

function RaidBuffReminder:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if addon.IsRestrictedAuraAPI and not frame.previewWidgetVisibility then
		return
	end

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.raidBuffReminder ~= true then
		frame.raidBuffReminderIcon:Hide()
		return
	end

	if not cachedSettings.enabled then
		frame.raidBuffReminderIcon:Hide()
		return
	end

	if not cachedSettings.showInCombat and InCombatLockdown() then
		frame.raidBuffReminderIcon:Hide()
		return
	end

	local unit = frame.unit
	local provider = frame.dataProvider
	local isTestProvider = provider == addon.Frames.DataProvider.Test
	local classBuffSpellIds, blessingOfTheBronzeSpellIds = provider:GetRaidBuffReminderSpellIds(frame)

	if not classBuffSpellIds and not blessingOfTheBronzeSpellIds then
		frame.raidBuffReminderIcon:Hide()
		return
	end

	if not isTestProvider and (not unit or not UnitExists(unit) or not UnitIsVisible(unit)) then
		frame.raidBuffReminderIcon:Hide()
		return
	end

	if not isTestProvider and (UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit)) then
		frame.raidBuffReminderIcon:Hide()
		return
	end

	if not isTestProvider and not UnitIsPlayer(unit) then
		frame.raidBuffReminderIcon:Hide()
		return
	end

	local icon = frame.raidBuffReminderIcon
	local auras = provider:GetUnitAuras(frame, "helpful")

	if blessingOfTheBronzeSpellIds then
		local hasBlessingOfTheBronze = false
		for _, aura in pairs(auras) do
			local auraSpellId = aura.spellId
			if auraSpellId and not issecretvalue(auraSpellId) then
				for _, bronzeSpellId in ipairs(blessingOfTheBronzeSpellIds) do
					if auraSpellId == bronzeSpellId then
						hasBlessingOfTheBronze = true
						break
					end
				end
			end
			if hasBlessingOfTheBronze then
				break
			end
		end

		if not hasBlessingOfTheBronze then
			addon.Frames.Managers.IconManager:ApplyIconState(icon, {
				texture = C_Spell.GetSpellTexture(blessingOfTheBronzeSpellIds[1]),
			})
		else
			icon:Hide()
		end
	else
		local hasBuff = false
		for _, aura in pairs(auras) do
			local auraSpellId = aura.spellId
			if auraSpellId and not issecretvalue(auraSpellId) then
				for _, spellId in ipairs(classBuffSpellIds) do
					if auraSpellId == spellId then
						hasBuff = true
						break
					end
				end
			end
			if hasBuff then
				break
			end
		end

		if not hasBuff then
			addon.Frames.Managers.IconManager:ApplyIconState(icon, {
				texture = C_Spell.GetSpellTexture(classBuffSpellIds[1]),
			})
		else
			icon:Hide()
		end
	end
end

function RaidBuffReminder:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "raidBuffReminderSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
