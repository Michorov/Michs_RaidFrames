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

	local result = {
		font = addon.Styles.Fonts:Resolve(statusText.lsmFont),
		size = statusText.size or 16,
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

	frame.statusText.text:SetFont(cachedSettings.font, scaledFontSize, "")
end

function StatusText:UpdateState(frame)
	local text = frame.statusText.text

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.statusText ~= true then
		text:Hide()
		return
	end

	local unit = frame.unit

	if type(unit) ~= "string" or unit == "" or not UnitExists(unit) then
		text:Hide()
		return
	end

	if UnitIsConnected(unit) == false then
		text:SetText("Offline")
		text:Show()
	elseif UnitIsGhost(unit) then
		text:SetText("Ghost")
		text:Show()
	elseif UnitIsDead(unit) then
		text:SetText("Dead")
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
