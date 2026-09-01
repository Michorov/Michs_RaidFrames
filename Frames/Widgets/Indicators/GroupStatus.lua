local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.GroupStatus = addon.Frames.Widgets.Indicators.GroupStatus or {}

local GroupStatus = addon.Frames.Widgets.Indicators.GroupStatus

local settingsCache = setmetatable({}, { __mode = "k" })
local eventsRegistered = nil

local EVENTS = {
	"PARTY_LEADER_CHANGED",
}

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

local function UpdateEvents()
	local profile = addon.Database:GetProfile()
	local partyGroupStatus = profile.party.widgets.indicators.groupStatus
	local raidGroupStatus = addon.FrameRegistry:ResolveRaidSettings(profile).widgets.indicators.groupStatus
	local shouldRegister = partyGroupStatus.enabled == true or raidGroupStatus.enabled == true

	if eventsRegistered == shouldRegister then
		return
	end

	eventsRegistered = shouldRegister

	for _, event in ipairs(EVENTS) do
		if shouldRegister then
			addon.EventHandler:RegisterTrackedEvent(event, GroupStatus)
		else
			addon.EventHandler:UnregisterTrackedEvent(event, GroupStatus)
		end
	end
end

function GroupStatus:Ensure(frame)
	if frame.frameType == "boss" then
		return
	end

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
	if frame.frameType == "boss" then
		return
	end

	local container = frame.groupStatus

	UpdateSettingsCache(settings)

	if frame.dataProvider == addon.Frames.DataProvider.Live then
		UpdateEvents()
	end

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

function GroupStatus:UpdateState(frame, settings)
	if frame.frameType == "boss" then
		return
	end

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

	local provider = frame.dataProvider
	if not provider then
		container:Hide()
		return
	end

	local texturePath
	local status = provider:GetGroupStatus(frame)
	if status == "leader" and (frame.frameType == "preview" or cachedSettings.showLeader) then
		texturePath = LEADER_ICON
	elseif status == "assistant" and (frame.frameType == "preview" or cachedSettings.showAssistant) then
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
