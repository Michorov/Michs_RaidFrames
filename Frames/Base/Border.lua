local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Border = addon.Frames.Base.Border or {}

local Border = addon.Frames.Base.Border

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local border = (settings and settings.border) or {}
	local color = border.color or {}

	local result = {
		thicknessPx = math.max(1, addon.Utilities:ToPixels(border.thicknessPx or 1)),
		color = {
			r = color.r or 0,
			g = color.g or 0,
			b = color.b or 0,
			a = color.a or 1,
		},
	}

	settingsCache[settings] = result
end

function Border:Ensure(frame)
	local border = frame.border

	if not border then
		border = CreateFrame("Frame", nil, frame)
		border:SetAllPoints(frame)
		border:SetFrameLevel(frame:GetFrameLevel() + 20)

		border.top = border:CreateTexture(nil, "OVERLAY", nil, 0)
		border.bottom = border:CreateTexture(nil, "OVERLAY", nil, 0)
		border.left = border:CreateTexture(nil, "OVERLAY", nil, 0)
		border.right = border:CreateTexture(nil, "OVERLAY", nil, 0)

		frame.border = border
	end
end

function Border:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local border = frame.border

	local scaledThickness = addon.Utilities:Scale(cachedSettings.thicknessPx)
	local uiThickness = addon.Utilities:ToUI(scaledThickness)

	border.left:ClearAllPoints()
	border.left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
	border.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
	border.left:SetWidth(uiThickness)

	border.right:ClearAllPoints()
	border.right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
	border.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
	border.right:SetWidth(uiThickness)

	border.top:ClearAllPoints()
	border.top:SetPoint("TOPLEFT", border.left, "TOPRIGHT", 0, 0)
	border.top:SetPoint("TOPRIGHT", border.right, "TOPLEFT", 0, 0)
	border.top:SetHeight(uiThickness)

	border.bottom:ClearAllPoints()
	border.bottom:SetPoint("BOTTOMLEFT", border.left, "BOTTOMRIGHT", 0, 0)
	border.bottom:SetPoint("BOTTOMRIGHT", border.right, "BOTTOMLEFT", 0, 0)
	border.bottom:SetHeight(uiThickness)

	local color = cachedSettings.color
	border.top:SetColorTexture(color.r, color.g, color.b, color.a)
	border.bottom:SetColorTexture(color.r, color.g, color.b, color.a)
	border.left:SetColorTexture(color.r, color.g, color.b, color.a)
	border.right:SetColorTexture(color.r, color.g, color.b, color.a)

	for _, tex in ipairs({ border.top, border.bottom, border.left, border.right }) do
		if tex.SetSnapToPixelGrid then
			tex:SetSnapToPixelGrid(true)
		end
		if tex.SetTexelSnappingBias then
			tex:SetTexelSnappingBias(0)
		end
	end
end

function Border:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "borderSettingsChanged",
	})
end
