local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Texts = addon.Frames.Widgets.Texts or {}
addon.Frames.Widgets.Texts.StatusText = addon.Frames.Widgets.Texts.StatusText or {}

local StatusText = addon.Frames.Widgets.Texts.StatusText

function StatusText:Ensure(frame)
	if not frame.statusText then
		local statusFrame = CreateFrame("Frame", nil, frame)
		statusFrame:SetAllPoints(frame)
		statusFrame:SetFrameLevel(31)

		local text = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("CENTER", statusFrame, "CENTER", 0, 0)
		text:SetFont("Fonts\\FRIZQT__.TTF", addon.Utilities:ScaleFont(16), "NONE")
		text:SetTextColor(0.55, 0.55, 0.55, 1)
		text:SetShadowColor(0, 0, 0, 0.9)
		text:SetShadowOffset(1, -1)
		text:Hide()

		statusFrame.text = text
		frame.statusText = statusFrame
	end
end

function StatusText:UpdateState(frame)
	local text = frame.statusText.text
	local unit = frame.unit

	if not UnitExists(unit) then
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
		stateReason = "statusStateChanged",
	})
end
