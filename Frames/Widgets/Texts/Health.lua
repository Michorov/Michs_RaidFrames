local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.Health = addon.Frames.Widgets.Texts.Health or {}

local Health = addon.Frames.Widgets.Texts.Health

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local widgets = (settings and settings.widgets) or {}
	local texts = widgets.texts or {}
	local healthText = texts.healthText or {}
	local position = healthText.position or {}
	local color = healthText.color or {}

	settingsCache[settings] = {
		enabled = healthText.enabled == true,
		format = healthText.format or "abbreviated",
		anchor = healthText.anchor or "CENTER",
		classColor = healthText.classColor == true,
		positionX = addon.Utilities:ToPixels(position.x or 0),
		positionY = addon.Utilities:ToPixels(position.y or 0),
		font = addon.Styles.Fonts:Resolve(healthText.lsmFont),
		size = healthText.size or 16,
		outline = healthText.outline or "",
		color = {
			r = color.r or 1,
			g = color.g or 1,
			b = color.b or 1,
			a = color.a or 1,
		},
	}
end

local function UpdateColor(frame, cachedSettings)
	local color = cachedSettings.color
	local r = color.r
	local g = color.g
	local b = color.b
	local a = color.a

	if cachedSettings.classColor then
		local unit = frame.frameType == "preview" and "player" or frame.unit
		local classToken = unit and UnitExists(unit) and select(2, UnitClass(unit))
		local classColor = classToken and C_ClassColor.GetClassColor(classToken)
		if classColor then
			r, g, b = classColor:GetRGB()
		end
	end

	frame.healthText.text:SetTextColor(r, g, b, a)
end

function Health:Ensure(frame)
	if frame.frameType == "boss" then
		return
	end

	if not frame.healthText then
		local healthTextFrame = CreateFrame("Frame", nil, frame)
		healthTextFrame:SetAllPoints(frame)
		healthTextFrame:SetFrameLevel(32)
		healthTextFrame.text = healthTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		healthTextFrame.text:Hide()

		frame.healthText = healthTextFrame
	end
end

function Health:UpdateSettings(frame, settings)
	if frame.frameType == "boss" then
		return
	end

	UpdateSettingsCache(settings)

	local cachedSettings = settingsCache[settings]
	local text = frame.healthText.text
	local scaledPositionX = frame.dataProvider:Scale(frame, cachedSettings.positionX)
	local scaledPositionY = frame.dataProvider:Scale(frame, cachedSettings.positionY)
	local scaledFontSize = frame.dataProvider:ScaleFont(frame, cachedSettings.size)

	text:ClearAllPoints()
	text:SetPoint(
		cachedSettings.anchor,
		frame.healthText,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledPositionX),
		addon.Utilities:ToUI(scaledPositionY)
	)

	text:SetFont(cachedSettings.font, scaledFontSize, cachedSettings.outline)
	text:SetShadowColor(0, 0, 0, 0.9)
	text:SetShadowOffset(1, -1)

	self:UpdateState(frame, settings)
end

function Health:UpdateState(frame, settings)
	if frame.frameType == "boss" then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	local cachedSettings = settingsCache[settings]

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.healthText ~= true then
		frame.healthText.text:Hide()
		return
	end

	if not cachedSettings.enabled then
		frame.healthText.text:Hide()
		return
	end

	local text = frame.dataProvider:GetFormattedHealth(frame, cachedSettings.format)
	frame.healthText.text:SetText(text)
	UpdateColor(frame, cachedSettings)
	frame.healthText.text:Show()
end

function Health:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healthTextSettingsChanged",
		stateReason = "healthStateChanged",
	})
end
