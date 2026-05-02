local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.GroupStatus = addon.Frames.Widgets.Indicators.GroupStatus or {}

local GroupStatus = addon.Frames.Widgets.Indicators.GroupStatus

local settingsCache = setmetatable({}, { __mode = "k" })

local LEADER_ICON = "Interface\\GroupFrame\\UI-Group-LeaderIcon"
local ASSISTANT_ICON = "Interface\\GroupFrame\\UI-Group-AssistantIcon"

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local groupStatus = indicators.groupStatus or {}

	local result = {
		enabled = groupStatus.enabled == true,
		showLeader = groupStatus.showLeader ~= false,
		showAssistant = groupStatus.showAssistant ~= false,
		anchor = groupStatus.anchor or "TOPLEFT",
		sizePx = addon.Utilities:ToPixels(groupStatus.size or 16),
		offsetXPx = addon.Utilities:ToPixels(groupStatus.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(groupStatus.offsetY or 0),
	}

	settingsCache[settings] = result
end

function GroupStatus:Ensure(frame)
	if not frame.groupStatus then
		local container = CreateFrame("Frame", nil, frame)
		container:SetFrameLevel(33)
		container.texture = container:CreateTexture(nil, "OVERLAY")
		container.texture:SetAllPoints(container)
		container:Hide()
		frame.groupStatus = container
	end
end

function GroupStatus:UpdateSettings(frame, settings)
	local container = frame.groupStatus

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	local sizePx = addon.Utilities:Scale(cachedSettings.sizePx)
	local offsetX = addon.Utilities:Scale(cachedSettings.offsetXPx)
	local offsetY = addon.Utilities:Scale(cachedSettings.offsetYPx)

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

function GroupStatus:UpdateState(frame, settings)
	local container = frame.groupStatus

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.groupStatus ~= true then
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

	local unit = frame.unit
	if type(unit) ~= "string" or unit == "" or not UnitExists(unit) then
		container:Hide()
		return
	end

	local texturePath
	if UnitIsGroupLeader(unit) and cachedSettings.showLeader then
		texturePath = LEADER_ICON
	elseif UnitIsGroupAssistant(unit) and cachedSettings.showAssistant then
		texturePath = ASSISTANT_ICON
	end

	if not texturePath then
		container:Hide()
		return
	end

	container.texture:SetTexCoord(0, 1, 0, 1)
	container.texture:SetTexture(texturePath)
	container:Show()
end

function GroupStatus:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "groupStatusSettingsChanged",
		stateReason = "groupStatusStateChanged",
	})
end
