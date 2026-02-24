local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.StatusText = addon.Frames.Widgets.Texts.StatusText or {}

local StatusText = addon.Frames.Widgets.Texts.StatusText

function StatusText:Ensure(frame)
	if not frame then
		return
	end

	local textLayer = frame.textLayer
	if not textLayer then
		return
	end

	if not frame.statusText then
		local statusText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		statusText:SetPoint("CENTER", textLayer, "CENTER", 0, 0)
		statusText:SetFont("Fonts\\FRIZQT__.TTF", 16, "NONE")
		statusText:SetTextColor(0.55, 0.55, 0.55, 1)
		statusText:SetShadowColor(0, 0, 0, 0.9)
		statusText:SetShadowOffset(1, -1)
		statusText:SetText("Dead")
		statusText:Hide()

		frame.statusText = statusText
	end

	self:UpdateState(frame)
end

function StatusText:UpdateState(frame)
	local statusText = frame and frame.statusText
	if not statusText then
		return
	end

	local unit = frame.unit
	if not UnitExists(unit) then
		statusText:Hide()
		return
	end

	if UnitIsConnected(unit) == false then
		statusText:SetText("Offline")
		statusText:Show()
	elseif UnitIsGhost(unit) then
		statusText:SetText("Ghost")
		statusText:Show()
	elseif UnitIsDead(unit) then
		statusText:SetText("Dead")
		statusText:Show()
	else
		statusText:Hide()
	end
end
