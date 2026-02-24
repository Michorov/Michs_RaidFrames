local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.ReadyCheck = addon.Frames.Widgets.Indicators.ReadyCheck or {}

local ReadyCheck = addon.Frames.Widgets.Indicators.ReadyCheck

local READY_CHECK_HOLD = 5

local function GetReadyCheckSettings(settings)
	return settings and settings.widgets and settings.widgets.indicators and settings.widgets.indicators.readyCheck
end

local function GetTextureForStatus(status, rcSettings)
	local textures = (rcSettings and rcSettings.textures) or {}
	if status == "ready" then
		return textures.ready or "Interface\\RaidFrame\\ReadyCheck-Ready"
	end
	if status == "notready" then
		return textures.notReady or "Interface\\RaidFrame\\ReadyCheck-NotReady"
	end
	if status == "waiting" then
		return textures.waiting or "Interface\\RaidFrame\\ReadyCheck-Waiting"
	end
	return nil
end

function ReadyCheck:Ensure(frame)
	if not frame then
		return
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not widgetsOverlay then
		return
	end

	if not frame.readyCheckIcon then
		local icon = widgetsOverlay:CreateTexture(nil, "ARTWORK")
		icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
		icon:SetTexCoord(0, 1, 0, 1)
		icon:Hide()
		frame.readyCheckIcon = icon
	end
end

function ReadyCheck:UpdateSettings(frame, settings)
	local icon = frame and frame.readyCheckIcon
	if not icon then
		return
	end

	local rcSettings = GetReadyCheckSettings(settings) or {}
	local sizePx = rcSettings.size or 36
	local alpha = rcSettings.alpha or 1
	local anchor = rcSettings.anchor or "CENTER"
	local relativeAnchor = rcSettings.relativeAnchor or "CENTER"
	local offsetX = rcSettings.offsetX or 0
	local offsetY = rcSettings.offsetY or 0

	icon:ClearAllPoints()
	icon:SetPoint(
		anchor,
		icon:GetParent(),
		relativeAnchor,
		addon.Utilities:FromPixels(offsetX),
		addon.Utilities:FromPixels(offsetY)
	)
	icon:SetSize(addon.Utilities:FromPixels(sizePx), addon.Utilities:FromPixels(sizePx))
	icon:SetAlpha(alpha)
end

function ReadyCheck:UpdateState(frame, settings)
	local icon = frame and frame.readyCheckIcon
	if not icon then
		return
	end

	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		icon:Hide()
		return
	end

	local status = GetReadyCheckStatus(unit)
	if not status then
		local lastFinishedTime = self.lastFinishedAt or 0
		if (GetTime() - lastFinishedTime) > READY_CHECK_HOLD then
			icon:Hide()
		else
			icon:Show()
		end
		return
	end

	local rcSettings = GetReadyCheckSettings(settings)
	local tex = GetTextureForStatus(status, rcSettings)
	if not tex then
		icon:Hide()
		return
	end

	icon:SetTexture(tex)
	icon:Show()
end
