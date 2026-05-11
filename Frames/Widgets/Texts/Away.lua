local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.Away = addon.Frames.Widgets.Texts.Away or {}

local Away = addon.Frames.Widgets.Texts.Away

local settingsCache = setmetatable({}, { __mode = "k" })

local function GetGameFontNormalPath()
	return (GameFontNormal and select(1, GameFontNormal:GetFont()))
		or STANDARD_TEXT_FONT
		or "Fonts\\FRIZQT__.TTF"
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
		positionY = addon.Utilities:ToPixels(position.y or -10),
		size = away.size or 10,
		outline = addon.Utilities:NormalizeFontOutline(away.outline, "OUTLINE"),
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

	text:SetFont(GetGameFontNormalPath(), scaledFontSize, cachedSettings.outline)

	local c = cachedSettings.color
	text:SetTextColor(c.r, c.g, c.b, c.a)
end

function Away:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]
	local text = frame.awayText.text

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.away ~= true then
		text:Hide()
		return
	end

	if not cachedSettings.enabled then
		text:Hide()
		return
	end

	local unit = frame.unit
	if type(unit) ~= "string" or unit == "" or not UnitIsAFK(unit) then
		text:Hide()
		return
	end

	text:SetText("AFK")
	text:Show()
end

function Away:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "awayTextSettingsChanged",
		stateReason = "awayStateChanged",
	})
end
