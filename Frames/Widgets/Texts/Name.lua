local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.Name = addon.Frames.Widgets.Texts.Name or {}

local Name = addon.Frames.Widgets.Texts.Name

local function GetNameSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local texts = widgets.texts or {}
	local name = texts.name or {}

	local position = name.position or {}
	local color = name.color or {}

	return {
		anchor = name.anchor or "TOPLEFT",
		x = position.x or 2,
		y = position.y or -2,
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
end

local function GetNameColor(frame, nameSettings)
	if nameSettings.classColor then
		return addon.Utilities:GetUnitClassColor(frame and frame.unit, nameSettings.color)
	end

	local c = nameSettings.color
	return c.r, c.g, c.b, c.a
end

local function ApplyNameSettings(frame, nameText, settings)
	local nameSettings = GetNameSettings(settings)

	nameText:ClearAllPoints()
	nameText:SetPoint(nameSettings.anchor, frame, nameSettings.anchor, nameSettings.x, nameSettings.y)

	local fontFlags = nameSettings.outline
	if fontFlags == "NONE" then
		fontFlags = ""
	end
	nameText:SetFont(nameSettings.font, nameSettings.size, fontFlags)

	local r, g, b, a = GetNameColor(frame, nameSettings)
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

	ApplyNameSettings(frame, frame.nameText, settings)
end

function Name:UpdateSettings(frame, settings)
	local nameText = frame and frame.nameText
	if not nameText then
		return
	end

	ApplyNameSettings(frame, nameText, settings)
end

function Name:UpdateState(frame, settings)
	local nameSettings = GetNameSettings(settings)

	local nameText = frame and frame.nameText
	if not nameText then
		return
	end

	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		nameText:SetText("")
		return
	end

	nameText:SetText(UnitName(unit) or "")

	local r, g, b, a = GetNameColor(frame, nameSettings)
	nameText:SetTextColor(r, g, b, a)
end
