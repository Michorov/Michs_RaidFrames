local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.HealAbsorbs = addon.Frames.Widgets.Texts.HealAbsorbs or {}

local HealAbsorbs = addon.Frames.Widgets.Texts.HealAbsorbs

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
	local healAbsorbs = texts.healAbsorbs or {}
	local position = healAbsorbs.position or {}
	local color = healAbsorbs.color or {}

	local result = {
		enabled = healAbsorbs.enabled == true,
		abbreviate = healAbsorbs.abbreviate ~= false,
		anchor = healAbsorbs.anchor or "CENTER",
		positionX = addon.Utilities:ToPixels(position.x or 0),
		positionY = addon.Utilities:ToPixels(position.y or 0),
		size = healAbsorbs.size or 10,
		outline = addon.Utilities:NormalizeFontOutline(healAbsorbs.outline, "OUTLINE"),
		color = {
			r = color.r or 1,
			g = color.g or 1,
			b = color.b or 1,
			a = color.a or 1,
		},
	}

	settingsCache[settings] = result
end

function HealAbsorbs:Ensure(frame)
	if not frame.healAbsorbText then
		local healAbsorbTextFrame = CreateFrame("Frame", nil, frame)
		healAbsorbTextFrame:SetAllPoints(frame)
		healAbsorbTextFrame:SetFrameLevel(100)
		healAbsorbTextFrame.text = healAbsorbTextFrame:CreateFontString(nil, "OVERLAY")
		healAbsorbTextFrame.text:Hide()

		frame.healAbsorbText = healAbsorbTextFrame
	end
end

function HealAbsorbs:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]
	local text = frame.healAbsorbText.text

	local scaledPositionX = addon.Utilities:Scale(cachedSettings.positionX)
	local scaledPositionY = addon.Utilities:Scale(cachedSettings.positionY)
	local scaledFontSize = addon.Utilities:ScaleFont(cachedSettings.size)

	text:ClearAllPoints()
	text:SetPoint(
		cachedSettings.anchor,
		frame.healAbsorbText,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledPositionX),
		addon.Utilities:ToUI(scaledPositionY)
	)

	text:SetFont(GetGameFontNormalPath(), scaledFontSize, cachedSettings.outline)
	text:SetShadowColor(0, 0, 0, 0.9)
	text:SetShadowOffset(1, -1)

	local c = cachedSettings.color
	text:SetTextColor(c.r, c.g, c.b, c.a)
end

function HealAbsorbs:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.healAbsorbsText ~= true then
		frame.healAbsorbText.text:Hide()
		return
	end

	if not cachedSettings.enabled then
		frame.healAbsorbText.text:Hide()
		return
	end

	local _, totalHealAbsorbValue = frame.dataProvider:GetHealAbsorbs(frame)
	totalHealAbsorbValue = totalHealAbsorbValue or 0

	local displayText = cachedSettings.abbreviate and AbbreviateNumbers(totalHealAbsorbValue) or tostring(totalHealAbsorbValue)
	frame.healAbsorbText.text:SetText(displayText)
	frame.healAbsorbText.text:SetAlpha(totalHealAbsorbValue)
	frame.healAbsorbText.text:Show()
end

function HealAbsorbs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healAbsorbsTextSettingsChanged",
		stateReason = "healAbsorbsStateChanged",
	})
end
