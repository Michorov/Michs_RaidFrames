local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Border = addon.Frames.Base.Border or {}

local Border = addon.Frames.Base.Border

local function GetBorderSettings(settings)
	settings = settings or {}
	local border = settings.border or {}
	local color = border.color or {}

	local thicknessPx = border.thicknessPx or 1
	local r = color.r or 0
	local g = color.g or 0
	local b = color.b or 0
	local a = color.a or 1

	return thicknessPx, r, g, b, a
end

function Border:Ensure(frame)
	if not frame then
		return nil
	end

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
	local border = frame and frame.border
	if not border then
		return
	end

	local thicknessPx, r, g, b, a = GetBorderSettings(settings)
	local tPx = math.max(1, addon.Utilities:ToPixels(thicknessPx))
	local t = addon.Utilities:FromPixels(tPx)

	border.left:ClearAllPoints()
	border.left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
	border.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
	border.left:SetWidth(t)

	border.right:ClearAllPoints()
	border.right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
	border.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
	border.right:SetWidth(t)

	border.top:ClearAllPoints()
	border.top:SetPoint("TOPLEFT", border.left, "TOPRIGHT", 0, 0)
	border.top:SetPoint("TOPRIGHT", border.right, "TOPLEFT", 0, 0)
	border.top:SetHeight(t)

	border.bottom:ClearAllPoints()
	border.bottom:SetPoint("BOTTOMLEFT", border.left, "BOTTOMRIGHT", 0, 0)
	border.bottom:SetPoint("BOTTOMRIGHT", border.right, "BOTTOMLEFT", 0, 0)
	border.bottom:SetHeight(t)

	border.top:SetColorTexture(r, g, b, a)
	border.bottom:SetColorTexture(r, g, b, a)
	border.left:SetColorTexture(r, g, b, a)
	border.right:SetColorTexture(r, g, b, a)

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
