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
			r = color.r or 0,
			g = color.g or 0,
			b = color.b or 0,
			a = color.a or 1,
		},
		font = name.font or "Fonts\\FRIZQT__.TTF",
		size = name.size or 12,
		outline = name.outline or "NONE",
	}

	settingsCache[settings] = result
end

local function GetNameColor(frame, nameSettings)
	if nameSettings.classColor then
		local provider = frame and frame.dataProvider
		return provider:GetClassColor(frame, nameSettings.color)
	end

	local c = nameSettings.color
	return c.r, c.g, c.b, c.a
end

local function ApplyNameSettings(frame, nameText, cachedSettings)
	local scaledPositionX = addon.Utilities:Scale(cachedSettings.positionX)
	local scaledPositionY = addon.Utilities:Scale(cachedSettings.positionY)
	local scaledFontSize = addon.Utilities:ScaleFont(cachedSettings.size)

	nameText:ClearAllPoints()
	nameText:SetPoint(
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

	nameText:SetFont(cachedSettings.font, scaledFontSize, fontFlags)

	local r, g, b, a = GetNameColor(frame, cachedSettings)
	nameText:SetTextColor(r, g, b, a)
end

function Name:Ensure(frame, settings)
	if not frame then
		return nil
	end

	local textLayer = frame.textLayer
	if not textLayer then
		return
	end

	if not frame.nameText then
		frame.nameText = textLayer:CreateFontString(nil, "OVERLAY")
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	ApplyNameSettings(frame, frame.nameText, cachedSettings)
end

function Name:UpdateSettings(frame, settings)
	local nameText = frame and frame.nameText
	if not nameText then
		return
	end

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	ApplyNameSettings(frame, nameText, cachedSettings)
end

function Name:UpdateState(frame, settings)
	local nameText = frame and frame.nameText
	if not nameText then
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	local provider = frame and frame.dataProvider

	local name = provider:GetName(frame) or ""
	nameText:SetText(name)

	local r, g, b, a = GetNameColor(frame, cachedSettings)
	nameText:SetTextColor(r, g, b, a)
end

function Name:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "nameSettingsChanged",
		stateReason = "nameStateChanged",
	})
end
