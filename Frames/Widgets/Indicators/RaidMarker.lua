local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.RaidMarker = addon.Frames.Widgets.Indicators.RaidMarker or {}

local RaidMarker = addon.Frames.Widgets.Indicators.RaidMarker

local function GetRaidMarkerSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local raidMarker = indicators.raidMarker or {}

	return {
		enabled = raidMarker.enabled == true,
		anchor = raidMarker.anchor or "TOP",
		sizePx = addon.Utilities:ToPixels(raidMarker.size or 18),
		offsetXPx = addon.Utilities:ToPixels(raidMarker.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(raidMarker.offsetY or 0),
	}
end

function RaidMarker:Ensure(frame)
	if not frame then
		return
	end

	local topWidgetsOverlay = frame.topWidgetsOverlay
	if not topWidgetsOverlay then
		return
	end

	if not frame.raidMarker then
		local icon = topWidgetsOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
		icon:Hide()
		frame.raidMarker = icon
	end
end

function RaidMarker:UpdateSettings(frame, settings)
	local icon = frame and frame.raidMarker
	if not icon then
		return
	end

	local markerSettings = GetRaidMarkerSettings(settings)
	if not markerSettings.enabled then
		icon:Hide()
		return
	end

	local sizePx = addon.Utilities:Scale(markerSettings.sizePx)
	local offsetX = addon.Utilities:Scale(markerSettings.offsetXPx)
	local offsetY = addon.Utilities:Scale(markerSettings.offsetYPx)

	icon:ClearAllPoints()
	icon:SetPoint(
		markerSettings.anchor,
		icon:GetParent(),
		markerSettings.anchor,
		addon.Utilities:ToUI(offsetX),
		addon.Utilities:ToUI(offsetY)
	)
	icon:SetSize(addon.Utilities:ToUI(sizePx), addon.Utilities:ToUI(sizePx))
end

function RaidMarker:UpdateState(frame, settings)
	local icon = frame and frame.raidMarker
	if not icon then
		return
	end

	local markerSettings = GetRaidMarkerSettings(settings)
	if not markerSettings.enabled then
		icon:Hide()
		return
	end

	local unit = frame and frame.unit
	if type(unit) ~= "string" or unit == "" or not UnitExists(unit) then
		icon:Hide()
		return
	end

	local raidTargetIndex = GetRaidTargetIndex(unit)
	if not raidTargetIndex or not icon.SetSpriteSheetCell then
		icon:Hide()
		return
	end

	icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	icon:SetSpriteSheetCell(raidTargetIndex, 4, 4, 64, 64)
	icon:Show()
end

function RaidMarker:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "raidMarkerSettingsChanged",
		stateReason = "raidMarkerStateChanged",
	})
end
