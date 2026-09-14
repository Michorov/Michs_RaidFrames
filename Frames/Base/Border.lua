local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Border = addon.Frames.Base.Border or {}

local Border = addon.Frames.Base.Border

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local border = (settings and settings.border) or {}

	local result = {
		showBorder = (border.thicknessPx or 1) > 0,
	}

	settingsCache[settings] = result
end

function Border:Ensure(frame)
	local border = frame.border

	if not border then
		border = CreateFrame("Frame", nil, frame)
		border:SetAllPoints(frame)
		border:SetFrameLevel(25)

		border.top = border:CreateTexture(nil, "OVERLAY", nil, 0)
		border.bottom = border:CreateTexture(nil, "OVERLAY", nil, 0)
		border.left = border:CreateTexture(nil, "OVERLAY", nil, 0)
		border.right = border:CreateTexture(nil, "OVERLAY", nil, 0)

		for _, texture in ipairs({ border.top, border.bottom, border.left, border.right }) do
			texture:SetColorTexture(0, 0, 0, 1)
		end

		frame.border = border
	end
end

function Border:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	local border = frame.border

	if not cachedSettings.showBorder then
		border:Hide()
		return
	end

	local uiThickness = addon.Utilities:ToUI(frame.dataProvider:Scale(frame, addon.Utilities:ToPixels(1)))

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

	for _, tex in ipairs({ border.top, border.bottom, border.left, border.right }) do
		if tex.SetSnapToPixelGrid then
			tex:SetSnapToPixelGrid(true)
		end
		if tex.SetTexelSnappingBias then
			tex:SetTexelSnappingBias(0)
		end
	end

	border:Show()
end

function Border:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "borderSettingsChanged",
	})
end
