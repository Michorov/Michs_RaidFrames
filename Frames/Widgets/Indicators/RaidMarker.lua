local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.RaidMarker = addon.Frames.Widgets.Indicators.RaidMarker or {}

local RaidMarker = addon.Frames.Widgets.Indicators.RaidMarker

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local raidMarker = indicators.raidMarker or {}

	local result = {
		enabled = raidMarker.enabled == true,
		anchor = raidMarker.anchor or "TOP",
		sizePx = addon.Utilities:ToPixels(raidMarker.size or 18),
		offsetXPx = addon.Utilities:ToPixels(raidMarker.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(raidMarker.offsetY or 0),
	}

	settingsCache[settings] = result
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
		icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		icon:Hide()
		frame.raidMarker = icon
	end
end

function RaidMarker:UpdateSettings(frame, settings)
	local icon = frame and frame.raidMarker
	if not icon then
		return
	end

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		icon:Hide()
		return
	end

	local sizePx = addon.Utilities:Scale(cachedSettings.sizePx)
	local offsetX = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local offsetY = addon.Utilities:Scale(cachedSettings.offsetYPx)

	icon:ClearAllPoints()
	icon:SetPoint(
		cachedSettings.anchor,
		icon:GetParent(),
		cachedSettings.anchor,
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

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		icon:Hide()
		return
	end

	local unit = frame and frame.unit
	if not unit or not UnitExists(unit) then
		icon:Hide()
		return
	end

	local raidTargetIndex = GetRaidTargetIndex(unit)
	if not raidTargetIndex or not icon.SetSpriteSheetCell then
		icon:Hide()
		return
	end

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
