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
		enabled = pendingSummon.enabled ~= false,
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

	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	local sizePx = addon.Utilities:Scale(cachedSettings.sizePx)
	local offsetX = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local offsetY = addon.Utilities:Scale(cachedSettings.offsetYPx)
	local statusSizePx = math.max(1, math.floor(sizePx * 0.45))

	container:ClearAllPoints()
	container:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.anchor,
		addon.Utilities:ToUI(offsetX),
		addon.Utilities:ToUI(offsetY)
	)
	container:SetSize(addon.Utilities:ToUI(sizePx), addon.Utilities:ToUI(sizePx))
	container:SetAlpha(cachedSettings.alpha)
	container.icon:SetTexture(cachedSettings.texture)

	container.statusIcon:ClearAllPoints()
	container.statusIcon:SetPoint(
		"BOTTOMRIGHT",
		container,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(statusSizePx * 0.15),
		addon.Utilities:ToUI(statusSizePx * 0.15)
	)
	container.statusIcon:SetSize(addon.Utilities:ToUI(statusSizePx), addon.Utilities:ToUI(statusSizePx))
end

function PendingSummon:UpdateState(frame, settings)
	local container = frame.pendingSummon

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.pendingSummon ~= true then
		container:Hide()
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	local provider = frame.dataProvider
	if not provider or type(provider.GetIncomingSummonStatus) ~= "function" then
		container:Hide()
		return
	end

	local status = provider:GetIncomingSummonStatus(frame)
	if not status then
		container:Hide()
		return
	end

	container.icon:SetTexture(cachedSettings.texture)
	container:Show()

	if status == "accepted" then
		container.statusIcon:SetTexture(cachedSettings.acceptedTexture)
		container.statusIcon:Show()
	elseif status == "declined" then
		container.statusIcon:SetTexture(cachedSettings.declinedTexture)
		container.statusIcon:Show()
	elseif status == "pending" then
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
