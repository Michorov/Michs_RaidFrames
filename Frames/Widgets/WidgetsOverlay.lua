local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Overlay = addon.Frames.Widgets.Overlay or {}

local Overlay = addon.Frames.Widgets.Overlay

function Overlay:Ensure(frame)
	if not frame then
		return
	end

	if not frame.widgetsOverlay then
		local widgetsOverlay = CreateFrame("Frame", nil, frame)
		widgetsOverlay:SetAllPoints(frame)
		widgetsOverlay:SetFrameStrata(frame:GetFrameStrata())
		widgetsOverlay:SetFrameLevel(frame:GetFrameLevel() + 10)
		widgetsOverlay:EnableMouse(false)

		frame.widgetsOverlay = widgetsOverlay
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not frame.textLayer then
		local textLayer = CreateFrame("Frame", nil, widgetsOverlay)
		textLayer:SetAllPoints(widgetsOverlay)
		textLayer:SetFrameStrata(widgetsOverlay:GetFrameStrata())
		textLayer:SetFrameLevel(widgetsOverlay:GetFrameLevel() + 10)
		frame.textLayer = textLayer
	end
end

function Overlay:Init()
	addon.Modules:Register({
		module = self,
	})
end
