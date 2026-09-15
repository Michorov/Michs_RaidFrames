local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Border = addon.Frames.Base.Border or {}

local Border = addon.Frames.Base.Border

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	local borderSizePx = addon.Utilities.PixelPerfect:Scale(1)

	local result = {
		showBorder = settings.border.thicknessPx > 0,
		borderSizeUI = addon.Utilities.PixelPerfect:ToUI(borderSizePx),
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

		border.left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
		border.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)

		border.right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
		border.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)

		border.top:SetPoint("TOPLEFT", border.left, "TOPRIGHT", 0, 0)
		border.top:SetPoint("TOPRIGHT", border.right, "TOPLEFT", 0, 0)

		border.bottom:SetPoint("BOTTOMLEFT", border.left, "BOTTOMRIGHT", 0, 0)
		border.bottom:SetPoint("BOTTOMRIGHT", border.right, "BOTTOMLEFT", 0, 0)

		border.top:SetColorTexture(0, 0, 0, 1)
		border.bottom:SetColorTexture(0, 0, 0, 1)
		border.left:SetColorTexture(0, 0, 0, 1)
		border.right:SetColorTexture(0, 0, 0, 1)

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

	border.left:SetWidth(cachedSettings.borderSizeUI)
	border.right:SetWidth(cachedSettings.borderSizeUI)
	border.top:SetHeight(cachedSettings.borderSizeUI)
	border.bottom:SetHeight(cachedSettings.borderSizeUI)

	border:Show()
end

function Border:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "borderSettingsChanged",
	})
end
