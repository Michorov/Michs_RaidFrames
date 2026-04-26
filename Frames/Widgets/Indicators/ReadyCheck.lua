local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.ReadyCheck = addon.Frames.Widgets.Indicators.ReadyCheck or {}

local ReadyCheck = addon.Frames.Widgets.Indicators.ReadyCheck

local settingsCache = setmetatable({}, { __mode = "k" })

local READY_CHECK_HOLD = 5

local hideTimer = nil

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local readyCheck = indicators.readyCheck or {}
	local textures = readyCheck.textures or {}

	local result = {
		enabled = readyCheck.enabled ~= false,
		sizePx = addon.Utilities:ToPixels(readyCheck.size or 36),
		anchor = readyCheck.anchor or "CENTER",
		offsetXPx = addon.Utilities:ToPixels(readyCheck.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(readyCheck.offsetY or 0),
		readyTexture = textures.ready or "Interface\\RaidFrame\\ReadyCheck-Ready",
		notReadyTexture = textures.notReady or "Interface\\RaidFrame\\ReadyCheck-NotReady",
		waitingTexture = textures.waiting or "Interface\\RaidFrame\\ReadyCheck-Waiting",
	}

	settingsCache[settings] = result
end

function ReadyCheck:Ensure(frame)
	if not frame.readyCheck then
		local container = CreateFrame("Frame", nil, frame)
		container:SetFrameLevel(55)
		container.texture = container:CreateTexture(nil, "ARTWORK")
		container.texture:SetAllPoints(container)
		container.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
		container.texture:SetTexCoord(0, 1, 0, 1)
		container:Hide()
		frame.readyCheck = container
	end
end

function ReadyCheck:UpdateSettings(frame, settings)
	local container = frame.readyCheck

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	local sizePx = addon.Utilities:Scale(cachedSettings.sizePx)
	local offsetX = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local offsetY = addon.Utilities:Scale(cachedSettings.offsetYPx)

	container:ClearAllPoints()
	container:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.anchor,
		addon.Utilities:ToUI(offsetX),
		addon.Utilities:ToUI(offsetY)
	)
	container:SetSize(addon.Utilities:ToUI(sizePx), addon.Utilities:ToUI(sizePx))
	container:SetAlpha(1)
end

function ReadyCheck:UpdateState(frame, settings)
	local container = frame.readyCheck

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		container:Hide()
		return
	end

	local status = GetReadyCheckStatus(unit)
	if not status then
		if hideTimer then
			container:Show()
		else
			container:Hide()
		end
		return
	end

	if status == "ready" then
		container.texture:SetTexture(cachedSettings.readyTexture)
	elseif status == "notready" then
		container.texture:SetTexture(cachedSettings.notReadyTexture)
	elseif status == "waiting" then
		container.texture:SetTexture(cachedSettings.waitingTexture)
	else
		container:Hide()
		return
	end

	container:Show()
end

function ReadyCheck:StartHold()
	if hideTimer then
		hideTimer:Cancel()
	end

	hideTimer = C_Timer.NewTimer(READY_CHECK_HOLD, function()
		hideTimer = nil
		addon.UpdateScheduler:Notify("readyCheckStateChanged")
	end)
end

function ReadyCheck:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "readyCheckSettingsChanged",
		stateReason = "readyCheckStateChanged",
	})
end
