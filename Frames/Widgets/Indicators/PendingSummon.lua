local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.PendingSummon = addon.Frames.Widgets.Indicators.PendingSummon or {}

local PendingSummon = addon.Frames.Widgets.Indicators.PendingSummon

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local pendingSummon = indicators.pendingSummon or {}

	local result = {
		sizePx = addon.Utilities:ToPixels(pendingSummon.size or 36),
		alpha = pendingSummon.alpha or 1,
		anchor = pendingSummon.anchor or "CENTER",
		relativeAnchor = pendingSummon.relativeAnchor or "CENTER",
		offsetXPx = addon.Utilities:ToPixels(pendingSummon.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(pendingSummon.offsetY or 0),
		texture = pendingSummon.texture or "Interface\\RaidFrame\\Raid-Icon-SummonPending",
		pendingTexture = pendingSummon.pendingTexture or "Interface\\RaidFrame\\ReadyCheck-Waiting",
		acceptedTexture = pendingSummon.acceptedTexture or "Interface\\RaidFrame\\ReadyCheck-Ready",
		declinedTexture = pendingSummon.declinedTexture or "Interface\\RaidFrame\\ReadyCheck-NotReady",
	}

	settingsCache[settings] = result
end

function PendingSummon:Ensure(frame)
	if not frame then
		return
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not widgetsOverlay then
		return
	end

	if not frame.pendingSummonIcon then
		local icon = widgetsOverlay:CreateTexture(nil, "ARTWORK")
		icon:SetTexture("Interface\\RaidFrame\\Raid-Icon-SummonPending")
		icon:SetTexCoord(0, 1, 0, 1)
		icon:Hide()
		frame.pendingSummonIcon = icon
	end

	if not frame.pendingSummonStatusIcon then
		local statusIcon = widgetsOverlay:CreateTexture(nil, "OVERLAY")
		statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
		statusIcon:SetTexCoord(0, 1, 0, 1)
		statusIcon:Hide()
		frame.pendingSummonStatusIcon = statusIcon
	end
end

function PendingSummon:UpdateSettings(frame, settings)
	local icon = frame and frame.pendingSummonIcon
	local statusIcon = frame and frame.pendingSummonStatusIcon
	if not icon or not statusIcon then
		return
	end

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local sizePx = addon.Utilities:Scale(cachedSettings.sizePx)
	local offsetX = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local offsetY = addon.Utilities:Scale(cachedSettings.offsetYPx)
	local statusSizePx = math.max(1, math.floor(sizePx * 0.45))

	icon:ClearAllPoints()
	icon:SetPoint(
		cachedSettings.anchor,
		icon:GetParent(),
		cachedSettings.relativeAnchor,
		addon.Utilities:ToUI(offsetX),
		addon.Utilities:ToUI(offsetY)
	)
	icon:SetSize(addon.Utilities:ToUI(sizePx), addon.Utilities:ToUI(sizePx))
	icon:SetAlpha(cachedSettings.alpha)
	icon:SetTexture(cachedSettings.texture)

	statusIcon:ClearAllPoints()
	statusIcon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
	statusIcon:SetSize(addon.Utilities:ToUI(statusSizePx), addon.Utilities:ToUI(statusSizePx))
	statusIcon:SetAlpha(cachedSettings.alpha)
end

function PendingSummon:UpdateState(frame, settings)
	local icon = frame and frame.pendingSummonIcon
	local statusIcon = frame and frame.pendingSummonStatusIcon
	if not icon or not statusIcon then
		return
	end

	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		icon:Hide()
		statusIcon:Hide()
		return
	end

	if not C_IncomingSummon or not C_IncomingSummon.IncomingSummonStatus or not Enum or not Enum.SummonStatus then
		icon:Hide()
		statusIcon:Hide()
		return
	end

	local status = C_IncomingSummon.IncomingSummonStatus(unit)
	if not status or status == Enum.SummonStatus.None then
		icon:Hide()
		statusIcon:Hide()
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	icon:SetTexture(cachedSettings.texture)
	icon:Show()

	if status == Enum.SummonStatus.Accepted then
		statusIcon:SetTexture(cachedSettings.acceptedTexture)
		statusIcon:Show()
	elseif status == Enum.SummonStatus.Declined then
		statusIcon:SetTexture(cachedSettings.declinedTexture)
		statusIcon:Show()
	elseif status == Enum.SummonStatus.Pending then
		statusIcon:SetTexture(cachedSettings.pendingTexture)
		statusIcon:Show()
	else
		statusIcon:Hide()
	end
end

function PendingSummon:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "pendingSummonSettingsChanged",
		stateReason = "pendingSummonStateChanged",
	})
end
