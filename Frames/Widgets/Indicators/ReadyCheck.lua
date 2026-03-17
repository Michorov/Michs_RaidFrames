local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.ReadyCheck = addon.Frames.Widgets.Indicators.ReadyCheck or {}

local ReadyCheck = addon.Frames.Widgets.Indicators.ReadyCheck

local READY_CHECK_HOLD = 5

local function GetReadyCheckSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local readyCheck = indicators.readyCheck or {}
	local textures = readyCheck.textures or {}

	return {
		enabled = readyCheck.enabled ~= false,
		sizePx = addon.Utilities:ToPixels(readyCheck.size or 36),
		anchor = readyCheck.anchor or "CENTER",
		offsetXPx = addon.Utilities:ToPixels(readyCheck.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(readyCheck.offsetY or 0),
		readyTexture = textures.ready or "Interface\\RaidFrame\\ReadyCheck-Ready",
		notReadyTexture = textures.notReady or "Interface\\RaidFrame\\ReadyCheck-NotReady",
		waitingTexture = textures.waiting or "Interface\\RaidFrame\\ReadyCheck-Waiting",
	}
end

local function GetTextureForStatus(status, settings)
	if status == "ready" then
		return settings.readyTexture
	end
	if status == "notready" then
		return settings.notReadyTexture
	end
	if status == "waiting" then
		return settings.waitingTexture
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

	local rcSettings = GetReadyCheckSettings(settings)
	if not rcSettings.enabled then
		icon:Hide()
		return
	end

	local sizePx = addon.Utilities:Scale(rcSettings.sizePx)
	local offsetX = addon.Utilities:Scale(rcSettings.offsetXPx)
	local offsetY = addon.Utilities:Scale(rcSettings.offsetYPx)

	icon:ClearAllPoints()
	icon:SetPoint(
		rcSettings.anchor,
		icon:GetParent(),
		rcSettings.anchor,
		addon.Utilities:ToUI(offsetX),
		addon.Utilities:ToUI(offsetY)
	)
	icon:SetSize(addon.Utilities:ToUI(sizePx), addon.Utilities:ToUI(sizePx))
	icon:SetAlpha(1)
end

function ReadyCheck:UpdateState(frame, settings)
	local icon = frame and frame.readyCheckIcon
	if not icon then
		return
	end

	local rcSettings = GetReadyCheckSettings(settings)
	if not rcSettings.enabled then
		icon:Hide()
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

	local tex = GetTextureForStatus(status, rcSettings)
	if not tex then
		icon:Hide()
		return
	end

	icon:SetTexture(tex)
	icon:Show()
end

function ReadyCheck:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "readyCheckSettingsChanged",
		stateReason = "readyCheckStateChanged",
	})
end
