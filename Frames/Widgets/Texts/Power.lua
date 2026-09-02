local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.Power = addon.Frames.Widgets.Texts.Power or {}

local Power = addon.Frames.Widgets.Texts.Power

local settingsCache = setmetatable({}, { __mode = "k" })
local eventsRegistered = nil

local UNIT_EVENTS = {
	"UNIT_POWER_UPDATE",
	"UNIT_MAXPOWER",
	"UNIT_DISPLAYPOWER",
}

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local widgets = (settings and settings.widgets) or {}
	local texts = widgets.texts or {}
	local powerText = texts.powerText or {}
	local position = powerText.position or {}
	local color = powerText.color or {}

	settingsCache[settings] = {
		enabled = powerText.enabled == true,
		healerOnly = powerText.healerOnly == true,
		format = powerText.format or "abbreviated",
		anchor = powerText.anchor or "BOTTOM",
		colorByPowerType = powerText.colorByPowerType == true,
		positionX = addon.Utilities:ToPixels(position.x or 0),
		positionY = addon.Utilities:ToPixels(position.y or 1),
		font = addon.Styles.Fonts:Resolve(powerText.lsmFont),
		size = powerText.size or 10,
		outline = powerText.outline or "",
		color = {
			r = color.r or 1,
			g = color.g or 1,
			b = color.b or 1,
			a = color.a or 1,
		},
	}
end

local function UpdateEvents()
	local profile = addon.Database:GetProfile()
	local partyPowerText = profile.party.widgets.texts.powerText
	local raidPowerText = addon.FrameRegistry:ResolveRaidSettings(profile).widgets.texts.powerText
	local shouldRegister = partyPowerText.enabled == true or raidPowerText.enabled == true

	if eventsRegistered == shouldRegister then
		return
	end

	eventsRegistered = shouldRegister

	for _, event in ipairs(UNIT_EVENTS) do
		if shouldRegister then
			addon.EventHandler:RegisterTrackedUnitEvent(event, Power)
		else
			addon.EventHandler:UnregisterTrackedUnitEvent(event, Power)
		end
	end
end

local function UpdateColor(frame, cachedSettings, powerToken)
	local color = cachedSettings.color
	local r = color.r
	local g = color.g
	local b = color.b
	local a = color.a

	if cachedSettings.colorByPowerType then
		if type(powerToken) == "string" then
			powerToken = powerToken:gsub("^POWER_TYPE_", "")
		end

		local powerColor = PowerBarColor[powerToken]
		if powerColor then
			r = powerColor.r
			g = powerColor.g
			b = powerColor.b
		end
	end

	frame.powerText.text:SetTextColor(r, g, b, a)
end

function Power:Ensure(frame)
	if frame.frameType == "boss" then
		return
	end

	if not frame.powerText then
		local powerTextFrame = CreateFrame("Frame", nil, frame)
		powerTextFrame:SetAllPoints(frame)
		powerTextFrame:SetFrameLevel(32)
		powerTextFrame.text = powerTextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		powerTextFrame.text:Hide()

		frame.powerText = powerTextFrame
	end
end

function Power:UpdateSettings(frame, settings)
	if frame.frameType == "boss" then
		return
	end

	UpdateSettingsCache(settings)

	if frame.dataProvider == addon.Frames.DataProvider.Live then
		UpdateEvents()
	end

	local cachedSettings = settingsCache[settings]
	local text = frame.powerText.text
	local scaledPositionX = frame.dataProvider:Scale(frame, cachedSettings.positionX)
	local scaledPositionY = frame.dataProvider:Scale(frame, cachedSettings.positionY)
	local scaledFontSize = frame.dataProvider:ScaleFont(frame, cachedSettings.size)

	text:ClearAllPoints()
	text:SetPoint(
		cachedSettings.anchor,
		frame.powerText,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledPositionX),
		addon.Utilities:ToUI(scaledPositionY)
	)

	text:SetFont(cachedSettings.font, scaledFontSize, cachedSettings.outline)
	text:SetShadowColor(0, 0, 0, 0.9)
	text:SetShadowOffset(1, -1)

	self:UpdateState(frame, settings)
end

function Power:UpdateState(frame, settings)
	if frame.frameType == "boss" then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	local cachedSettings = settingsCache[settings]

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.powerText ~= true then
		frame.powerText.text:Hide()
		return
	end

	if not cachedSettings.enabled then
		frame.powerText.text:Hide()
		return
	end

	if cachedSettings.healerOnly and not frame.dataProvider:IsHealer(frame) then
		frame.powerText.text:Hide()
		return
	end

	local text, powerToken = frame.dataProvider:GetFormattedPower(frame, cachedSettings.format)
	if powerToken == nil then
		frame.powerText.text:Hide()
		return
	end

	frame.powerText.text:SetText(text)
	UpdateColor(frame, cachedSettings, powerToken)
	frame.powerText.text:Show()
end

function Power:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "powerTextSettingsChanged",
		stateReason = "powerStateChanged",
	})
end
