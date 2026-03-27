local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.HealAbsorbs = addon.Frames.Widgets.Texts.HealAbsorbs or {}

local HealAbsorbs = addon.Frames.Widgets.Texts.HealAbsorbs

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local texts = widgets.texts or {}
	local healAbsorbs = texts.healAbsorbs or {}
	local position = healAbsorbs.position or {}
	local color = healAbsorbs.color or {}

	local result = {
		enabled = healAbsorbs.enabled == true,
		anchor = healAbsorbs.anchor or "CENTER",
		positionX = addon.Utilities:ToPixels(position.x or 0),
		positionY = addon.Utilities:ToPixels(position.y or 0),
		font = healAbsorbs.font or "Fonts\\FRIZQT__.TTF",
		size = healAbsorbs.size or 10,
		outline = healAbsorbs.outline or "OUTLINE",
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
	if not frame then
		return
	end

	local topTextLayer = frame.topTextLayer
	if not topTextLayer then
		return
	end

	if not frame.healAbsorbText then
		local text = topTextLayer:CreateFontString(nil, "OVERLAY")
		text:Hide()
		frame.healAbsorbText = text
	end
end

function HealAbsorbs:UpdateSettings(frame, settings)
	local text = frame and frame.healAbsorbText
	if not text then
		return
	end

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local scaledPositionX = addon.Utilities:Scale(cachedSettings.positionX)
	local scaledPositionY = addon.Utilities:Scale(cachedSettings.positionY)
	local scaledFontSize = addon.Utilities:ScaleFont(cachedSettings.size)

	text:ClearAllPoints()
	text:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledPositionX),
		addon.Utilities:ToUI(scaledPositionY)
	)

	local fontFlags = cachedSettings.outline
	if fontFlags == "NONE" then
		fontFlags = ""
	end

	text:SetFont(cachedSettings.font, scaledFontSize, fontFlags)

	local c = cachedSettings.color
	text:SetTextColor(c.r, c.g, c.b, c.a)
end

function HealAbsorbs:UpdateState(frame, settings)
	local text = frame and frame.healAbsorbText
	if not text then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]
	if not cachedSettings.enabled then
		text:Hide()
		return
	end

	local provider = frame and frame.dataProvider
	local _, totalHealAbsorbValue = provider:GetHealAbsorbs(frame)

	if not totalHealAbsorbValue then
		text:Hide()
		return
	end

	text:SetText(C_StringUtil.TruncateWhenZero(totalHealAbsorbValue))
	text:Show()
end

function HealAbsorbs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healAbsorbsTextSettingsChanged",
		stateReason = "healAbsorbsStateChanged",
	})
end
