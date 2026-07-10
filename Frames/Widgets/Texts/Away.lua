local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.Away = addon.Frames.Widgets.Texts.Away or {}

local Away = addon.Frames.Widgets.Texts.Away

local settingsCache = setmetatable({}, { __mode = "k" })
local afkStartedAtByUnit = {}
local awayTicker

local function GetCurrentTime()
	if GetServerTime then
		return GetServerTime()
	end

	return math.floor(GetTime())
end

local function FormatDuration(label, elapsed)
	elapsed = math.max(0, elapsed or 0)
	local minutes = math.floor(elapsed / 60)
	local seconds = elapsed % 60

	return ("%s - %d:%02d"):format(label or "Away", minutes, seconds)
end

local function FormatStartedAt(label, startedAt)
	return FormatDuration(label, GetCurrentTime() - startedAt)
end

local function StopTickerIfIdle()
	if awayTicker and next(afkStartedAtByUnit) == nil then
		awayTicker:Cancel()
		awayTicker = nil
	end
end

local function EnsureTicker()
	if awayTicker then
		return
	end

	awayTicker = C_Timer.NewTicker(1, function()
		for unit in pairs(afkStartedAtByUnit) do
			addon.UpdateScheduler:Notify("awayStateChanged", unit)
		end
	end)
end

local function TrackAfkStart(unit)
	if not afkStartedAtByUnit[unit] then
		afkStartedAtByUnit[unit] = GetCurrentTime()
	end

	EnsureTicker()

	return afkStartedAtByUnit[unit]
end

local function ClearAfkStart(unit)
	if type(unit) ~= "string" or unit == "" then
		return
	end

	afkStartedAtByUnit[unit] = nil
	StopTickerIfIdle()
end

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local texts = widgets.texts or {}
	local away = texts.away or {}
	local position = away.position or {}
	local color = away.color or {}

	local result = {
		enabled = away.enabled ~= false,
		anchor = away.anchor or "CENTER",
		positionX = addon.Utilities:ToPixels(position.x or 0),
		positionY = addon.Utilities:ToPixels(position.y or -18),
		size = away.size or 10,
		outline = addon.Utilities:NormalizeFontOutline(away.outline),
		color = {
			r = color.r or 1,
			g = color.g or 1,
			b = color.b or 1,
			a = color.a or 1,
		},
	}

	settingsCache[settings] = result
end

function Away:Ensure(frame)
	if not frame.awayText then
		local awayFrame = CreateFrame("Frame", nil, frame)
		awayFrame:SetAllPoints(frame)
		awayFrame:SetFrameLevel(32)
		awayFrame.text = awayFrame:CreateFontString(nil, "OVERLAY")
		awayFrame.text:Hide()

		frame.awayText = awayFrame
	end
end

function Away:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]
	local text = frame.awayText.text

	local scaledPositionX = addon.Utilities:Scale(cachedSettings.positionX)
	local scaledPositionY = addon.Utilities:Scale(cachedSettings.positionY)
	local scaledFontSize = addon.Utilities:ScaleFont(cachedSettings.size)

	text:ClearAllPoints()
	text:SetPoint(
		cachedSettings.anchor,
		frame.awayText,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledPositionX),
		addon.Utilities:ToUI(scaledPositionY)
	)

	text:SetFont(addon.Utilities:GetGameFontNormalPath(), scaledFontSize, cachedSettings.outline)
	text:SetShadowColor(0, 0, 0, 0.9)
	text:SetShadowOffset(1, -1)

	local c = cachedSettings.color
	text:SetTextColor(c.r, c.g, c.b, c.a)
end

function Away:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]
	local text = frame.awayText.text
	local unit = frame.unit

	if frame.awayTrackedUnit and frame.awayTrackedUnit ~= unit then
		ClearAfkStart(frame.awayTrackedUnit)
		frame.awayTrackedUnit = nil
	end

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.away ~= true then
		text:Hide()
		return
	end

	if not cachedSettings.enabled then
		ClearAfkStart(unit)
		frame.awayTrackedUnit = nil
		text:Hide()
		return
	end

	local label, elapsed = frame.dataProvider:GetAwayStatus(frame)

	if not label then
		ClearAfkStart(unit)
		frame.awayTrackedUnit = nil
		text:Hide()
		return
	end

	if type(elapsed) == "number" then
		ClearAfkStart(unit)
		frame.awayTrackedUnit = nil
		text:SetText(FormatDuration(label, elapsed))
		text:Show()
		return
	end

	if type(unit) ~= "string" or unit == "" then
		text:Hide()
		return
	end

	frame.awayTrackedUnit = unit
	local startedAt = TrackAfkStart(unit)
	text:SetText(FormatStartedAt(label, startedAt))
	text:Show()
end

function Away:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "awayTextSettingsChanged",
		stateReason = "awayStateChanged",
	})
end
