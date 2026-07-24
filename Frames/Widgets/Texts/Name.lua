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
		font = name.font or "Fonts\\ARIALN.TTF",
		size = name.size or 12,
		outline = addon.Utilities:NormalizeFontOutline(name.outline),
		truncate = name.truncate == true,
		maxLength = name.maxLength or 12,
	}

	settingsCache[settings] = result
end

local function ApplyNameColor(fontString, frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]
	local c = cachedSettings.color

	if not cachedSettings.classColor then
		fontString:SetTextColor(c.r, c.g, c.b, c.a)
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
		fontString:SetTextColor(classColor:GetRGBA())
	else
		fontString:SetTextColor(c.r, c.g, c.b, c.a)
	end
end

function Name:Ensure(frame)
	if not frame.nameText then
		local nameFrame = CreateFrame("Frame", nil, frame)
		nameFrame:SetAllPoints(frame)
		nameFrame:SetFrameLevel(30)
		nameFrame.text = nameFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

		frame.nameText = nameFrame
	end
end

function Name:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local nameText = frame.nameText.text

	local scaledPositionX = addon.Utilities:Scale(cachedSettings.positionX)
	local scaledPositionY = addon.Utilities:Scale(cachedSettings.positionY)
	local scaledFontSize = addon.Utilities:ScaleFont(cachedSettings.size)

	nameText:ClearAllPoints()
	nameText:SetPoint(
		cachedSettings.anchor,
		frame.nameText,
		cachedSettings.anchor,
		addon.Utilities:ToUI(scaledPositionX),
		addon.Utilities:ToUI(scaledPositionY)
	)

	nameText:SetFont(cachedSettings.font, scaledFontSize, cachedSettings.outline)
	nameText:SetShadowColor(0, 0, 0, 0.9)
	nameText:SetShadowOffset(1, -1)
	ApplyNameColor(nameText, frame, settings)
end

local function ApplyNameState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.name ~= true then
		frame.nameText.text:SetText("")
		frame.nameText:Hide()
		return
	end

	local name = frame.dataProvider:GetName(frame) or ""

	if cachedSettings.truncate then
		local maxLength = cachedSettings.maxLength
		if maxLength > 0 and #name > maxLength then
			name = name:sub(1, maxLength):gsub("%s+$", "") .. ".."
		end
	end

	frame.nameText.text:SetText(name)
	ApplyNameColor(frame.nameText.text, frame, settings)
	frame.nameText:Show()
end

function Name:UpdateState(frame, settings)
	ApplyNameState(frame, settings)

	C_Timer.After(0.25, function()
		ApplyNameState(frame, settings)
	end)
end

function Name:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "nameSettingsChanged",
		stateReason = "nameStateChanged",
	})
end
