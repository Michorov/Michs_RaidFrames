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
	if not frame.pendingSummon then
		local container = CreateFrame("Frame", nil, frame)
		container:SetFrameLevel(50)

		container.icon = container:CreateTexture(nil, "ARTWORK")
		container.icon:SetAllPoints(container)
		container.icon:SetTexture("Interface\\RaidFrame\\Raid-Icon-SummonPending")
		container.icon:SetTexCoord(0, 1, 0, 1)

		container.statusIcon = container:CreateTexture(nil, "OVERLAY")
		container.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
		container.statusIcon:SetTexCoord(0, 1, 0, 1)
		container.statusIcon:Hide()

		container:Hide()
		frame.pendingSummon = container
	end
end

function PendingSummon:UpdateSettings(frame, settings)
	local container = frame.pendingSummon

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local sizePx = addon.Utilities:Scale(cachedSettings.sizePx)
	local offsetX = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local offsetY = addon.Utilities:Scale(cachedSettings.offsetYPx)
	local statusSizePx = math.max(1, math.floor(sizePx * 0.45))

	container:ClearAllPoints()
	container:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.relativeAnchor,
		addon.Utilities:ToUI(offsetX),
		addon.Utilities:ToUI(offsetY)
	)
	container:SetSize(addon.Utilities:ToUI(sizePx), addon.Utilities:ToUI(sizePx))
	container:SetAlpha(cachedSettings.alpha)
	container.icon:SetTexture(cachedSettings.texture)

	container.statusIcon:ClearAllPoints()
	container.statusIcon:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
	container.statusIcon:SetSize(addon.Utilities:ToUI(statusSizePx), addon.Utilities:ToUI(statusSizePx))
end

function PendingSummon:UpdateState(frame, settings)
	local container = frame.pendingSummon

	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		container:Hide()
		return
	end

	if
		not C_IncomingSummon
		or not C_IncomingSummon.HasIncomingSummon
		or not C_IncomingSummon.IncomingSummonStatus
		or not Enum
		or not Enum.SummonStatus
	then
		container:Hide()
		return
	end

	local hasIncomingSummon = C_IncomingSummon.HasIncomingSummon(unit)
	print("Unit has pending summon: ")
	print(hasIncomingSummon)
	if not hasIncomingSummon then
		container:Hide()
		return
	end

	local status = C_IncomingSummon.IncomingSummonStatus(unit)
	if not status or status == Enum.SummonStatus.None then
		container:Hide()
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	container.icon:SetTexture(cachedSettings.texture)
	container:Show()

	if status == Enum.SummonStatus.Accepted then
		container.statusIcon:SetTexture(cachedSettings.acceptedTexture)
		container.statusIcon:Show()
	elseif status == Enum.SummonStatus.Declined then
		container.statusIcon:SetTexture(cachedSettings.declinedTexture)
		container.statusIcon:Show()
	elseif status == Enum.SummonStatus.Pending then
		container.statusIcon:SetTexture(cachedSettings.pendingTexture)
		container.statusIcon:Show()
	else
		container.statusIcon:Hide()
	end
end

function PendingSummon:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "pendingSummonSettingsChanged",
		stateReason = "pendingSummonStateChanged",
	})
end
