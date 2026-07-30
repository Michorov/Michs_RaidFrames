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
	if not frame.raidMarker then
		local container = CreateFrame("Frame", nil, frame)
		container:SetFrameLevel(35)
		container.texture = container:CreateTexture(nil, "OVERLAY")
		container.texture:SetAllPoints(container)
		container.texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		container:Hide()
		frame.raidMarker = container
	end
end

function RaidMarker:UpdateSettings(frame, settings)
	local container = frame.raidMarker

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	local sizePx = frame.dataProvider:Scale(frame, cachedSettings.sizePx)
	local offsetX = frame.dataProvider:Scale(frame, cachedSettings.offsetXPx)
	local offsetY = frame.dataProvider:Scale(frame, cachedSettings.offsetYPx)

	container:ClearAllPoints()
	container:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.anchor,
		addon.Utilities:ToUI(offsetX),
		addon.Utilities:ToUI(offsetY)
	)
	container:SetSize(addon.Utilities:ToUI(sizePx), addon.Utilities:ToUI(sizePx))
end

function RaidMarker:UpdateState(frame, settings)
	local container = frame.raidMarker

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.raidMarker ~= true then
		container:Hide()
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	local provider = frame.dataProvider
	if not provider then
		container:Hide()
		return
	end

	local raidTargetIndex = provider:GetRaidTargetIndex(frame)
	if not raidTargetIndex or not container.texture.SetSpriteSheetCell then
		container:Hide()
		return
	end

	container.texture:SetSpriteSheetCell(raidTargetIndex, 4, 4, 64, 64)
	container:Show()
end

function RaidMarker:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "raidMarkerSettingsChanged",
		stateReason = "raidMarkerStateChanged",
	})
end
