local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.StatusText = addon.Frames.Widgets.Texts.StatusText or {}

local StatusText = addon.Frames.Widgets.Texts.StatusText

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local widgets = (settings and settings.widgets) or {}
	local texts = widgets.texts or {}
	local statusText = texts.statusText or {}
	local position = statusText.position or {}
	local color = statusText.color or {}

	local result = {
		anchor = statusText.anchor or "CENTER",
		positionX = addon.Utilities:ToPixels(position.x or 0),
		positionY = addon.Utilities:ToPixels(position.y or 0),
		font = addon.Styles.Fonts:Resolve(statusText.lsmFont),
		size = statusText.size or 16,
		outline = addon.Utilities:NormalizeFontOutline(statusText.outline),
		color = {
			r = color.r or 0.55,
			g = color.g or 0.55,
			b = color.b or 0.55,
			a = color.a or 1,
		},
	}

	settingsCache[settings] = result
end

function StatusText:Ensure(frame)
	if not frame.statusText then
		local statusFrame = CreateFrame("Frame", nil, frame)
		statusFrame:SetAllPoints(frame)
		statusFrame:SetFrameLevel(31)

		local text = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("CENTER", statusFrame, "CENTER", 0, 0)
		text:SetFont(addon.Styles.Fonts:Resolve(-1), frame.dataProvider:ScaleFont(frame, 16), "")
		text:SetTextColor(0.55, 0.55, 0.55, 1)
		text:SetShadowColor(0, 0, 0, 0.9)
		text:SetShadowOffset(1, -1)
		text:Hide()

		statusFrame.text = text
		frame.statusText = statusFrame
	end
end

function StatusText:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]
	local scaledFontSize = frame.dataProvider:ScaleFont(frame, cachedSettings.size)
	local scaledPositionX = frame.dataProvider:Scale(frame, cachedSettings.positionX)
	local scaledPositionY = frame.dataProvider:Scale(frame, cachedSettings.positionY)
	local text = frame.statusText.text

	text:ClearAllPoints()
	text:SetPoint(
		cachedSettings.anchor,
		frame.statusText,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledPositionX),
		addon.Utilities:ToUI(scaledPositionY)
	)

	text:SetFont(cachedSettings.font, scaledFontSize, cachedSettings.outline)
	text:SetTextColor(cachedSettings.color.r, cachedSettings.color.g, cachedSettings.color.b, cachedSettings.color.a)
end

function StatusText:UpdateState(frame)
	local text = frame.statusText.text

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.statusText ~= true then
		text:Hide()
		return
	end

	local statusText = frame.dataProvider:GetStatusText(frame)
	if statusText then
		text:SetText(statusText)
		text:Show()
	else
		text:Hide()
	end
end

function StatusText:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "statusTextSettingsChanged",
		stateReason = "statusStateChanged",
	})
end
