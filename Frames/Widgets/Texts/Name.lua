local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.Name = addon.Frames.Widgets.Texts.Name or {}

local Name = addon.Frames.Widgets.Texts.Name

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local texts = widgets.texts or {}
	local name = texts.name or {}
	local position = name.position or {}
	local color = name.color or {}
	local profile = addon.Database:GetProfile()
	local core = (profile and profile.core) or {}
	local font = name.lsmFont

	if font == -1 then
		font = core.lsmFont
	end

	local result = {
		anchor = name.anchor or "TOPLEFT",
		positionX = addon.Utilities:ToPixels(position.x or 2),
		positionY = addon.Utilities:ToPixels(position.y or -2),
		classColor = name.classColor == true,
		color = {
			r = color.r or 1,
			g = color.g or 1,
			b = color.b or 1,
			a = color.a or 1,
		},
		font = addon.Styles.Fonts:Fetch(font),
		size = name.size or 12,
		outline = addon.Utilities:NormalizeFontOutline(name.outline),
		truncate = name.truncate == true,
		maxLength = name.maxLength or 12,
	}

	settingsCache[settings] = result
end

local function ApplyNameColor(text, frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]
	local c = cachedSettings.color

	if not cachedSettings.classColor then
		text:SetTextColor(c.r, c.g, c.b, c.a)
		return
	end

	local classToken

	if frame.previewWidgetVisibility then
		classToken = select(2, UnitClass("player"))
	else
		local unit = frame and frame.unit
		if unit and UnitExists(unit) then
			classToken = select(2, UnitClass(unit))
		end
	end

	local classColor = classToken and C_ClassColor.GetClassColor(classToken)
	if classColor then
		text:SetTextColor(classColor:GetRGBA())
	else
		text:SetTextColor(c.r, c.g, c.b, c.a)
	end
end

local function StopRetry(name)
	if name.retryTicker then
		name.retryTicker:Cancel()
	end

	name.retryTicker = nil
end

local function StartRetry(frame)
	local name = frame.name

	if name.retryTicker then
		return
	end

	name.retryTicker = C_Timer.NewTicker(0.25, function()
		local unit = frame.unit
		if frame.name ~= name or not unit then
			StopRetry(name)
			return
		end

		addon.UpdateScheduler:Notify("nameStateChanged", unit)
	end)
end

function Name:Ensure(frame)
	if not frame.name then
		local name = CreateFrame("Frame", nil, frame)
		name:SetAllPoints(frame)
		name:SetFrameLevel(30)
		name.text = name:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

		frame.name = name
	end
end

function Name:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local text = frame.name.text

	local scaledPositionX = frame.dataProvider:Scale(frame, cachedSettings.positionX)
	local scaledPositionY = frame.dataProvider:Scale(frame, cachedSettings.positionY)
	local scaledFontSize = frame.dataProvider:ScaleFont(frame, cachedSettings.size)

	text:ClearAllPoints()
	text:SetPoint(
		cachedSettings.anchor,
		frame.name,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledPositionX),
		addon.Utilities:ToUI(scaledPositionY)
	)

	text:SetFont(cachedSettings.font, scaledFontSize, cachedSettings.outline)
	text:SetShadowColor(0, 0, 0, 0.9)
	text:SetShadowOffset(1, -1)
	ApplyNameColor(text, frame, settings)
end

function Name:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	local name = frame.name

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.name ~= true then
		name.text:SetText("")
		StopRetry(name)
		name:Hide()
		return
	end

	local rosterKey = frame.RosterKey
	local rawName = frame.dataProvider:GetName(frame)
	local isValidName = type(rawName) == "string" and rawName ~= "" and rawName ~= UNKNOWNOBJECT

	local displayName

	if isValidName then
		displayName = rawName

		if cachedSettings.truncate then
			local maxLength = cachedSettings.maxLength
			if maxLength > 0 and #displayName > maxLength then
				displayName = displayName:sub(1, maxLength):gsub("%s+$", "") .. ".."
			end
		end

		name.cachedRosterKey = rosterKey
		name.cachedName = displayName

		StopRetry(name)
	elseif rosterKey and name.cachedRosterKey == rosterKey and name.cachedName then
		displayName = name.cachedName

		StartRetry(frame)
	else
		displayName = ""

		if frame.unit then
			StartRetry(frame)
		else
			StopRetry(name)
		end
	end

	name.text:SetText(displayName)
	ApplyNameColor(name.text, frame, settings)
	name:Show()
end

function Name:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "nameSettingsChanged",
		stateReason = "nameStateChanged",
	})
end
