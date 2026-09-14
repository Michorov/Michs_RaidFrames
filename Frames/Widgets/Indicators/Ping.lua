local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.Ping = addon.Frames.Widgets.Indicators.Ping or {}

local Ping = addon.Frames.Widgets.Indicators.Ping

local settingsCache = setmetatable({}, { __mode = "k" })
local hookedIcons = setmetatable({}, { __mode = "k" })
local sourcePings = {}
local activePings = {}

local function UpdateSettingsCache(settings)
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local ping = indicators.ping or {}

	settingsCache[settings] = {
		enabled = ping.enabled ~= false,
		sizePx = addon.Utilities:ToPixels(ping.size or 30),
		anchor = ping.anchor or "CENTER",
		offsetXPx = addon.Utilities:ToPixels(ping.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(ping.offsetY or 0),
	}
end

local function ClearPing(icon)
	local ping = sourcePings[icon]
	if not ping then
		return
	end

	sourcePings[icon] = nil
	if activePings[ping.unit] == ping then
		activePings[ping.unit] = nil
		addon.UpdateScheduler:Notify("pingStateChanged", ping.unit)
	end
end

local function ShowPing(icon, textureKit)
	ClearPing(icon)
	
	if issecretvalue(textureKit) or type(textureKit) ~= "string" then
		return
	end

	local unit = icon:GetParent().unit
	if issecretvalue(unit) or type(unit) ~= "string" then
		return
	end
	if unit ~= "player" and not unit:match("^party%d+$") and not unit:match("^raid%d+$") then
		return
	end

	local ping = { unit = unit, textureKit = textureKit }
	sourcePings[icon] = ping
	activePings[unit] = ping
	addon.UpdateScheduler:Notify("pingStateChanged", unit)

	C_Timer.After(15, function()
		if sourcePings[icon] == ping then
			ClearPing(icon)
		end
	end)
end

local function InitializeHooks()
	local function HookPingIcon(blizzardFrame)
		if not blizzardFrame or blizzardFrame:IsForbidden() then
			return
		end

		local name = blizzardFrame:GetName()
		if name and name:match("^NamePlate") then
			return
		end

		local icon = blizzardFrame.pingIconFrame
		if not icon or hookedIcons[icon] or icon:IsForbidden() then
			return
		end

		hookedIcons[icon] = true
		hooksecurefunc(icon, "ShowPing", ShowPing)
		hooksecurefunc(icon, "ClearPing", ClearPing)
	end

	hooksecurefunc("CompactUnitFrame_SetUpFrame", HookPingIcon)

	if CompactPartyFrame then
		CompactPartyFrame:ApplyFunctionToAllFrames("normal", HookPingIcon)
	end
	
	if CompactRaidFrameContainer then
		CompactRaidFrameContainer:ApplyToFrames("normal", HookPingIcon)
	end
end

function Ping:Ensure(frame)
	if frame.frameType == "boss" or frame.ping then
		return
	end

	local container = CreateFrame("Frame", nil, frame)
	container:SetFrameLevel(110)
	container:EnableMouse(false)
	container.background = container:CreateTexture(nil, "BACKGROUND")
	container.background:SetAllPoints(container)
	container.icon = container:CreateTexture(nil, "ARTWORK")
	container.icon:SetAllPoints(container)
	container:Hide()
	frame.ping = container
end

function Ping:UpdateSettings(frame, settings)
	if frame.frameType == "boss" then
		return
	end

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]
	local container = frame.ping
	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	local size = addon.Utilities:ToUI(frame.dataProvider:Scale(frame, cachedSettings.sizePx))
	container:SetSize(size, size)
	container:ClearAllPoints()
	container:SetPoint(
		cachedSettings.anchor,
		frame,
		cachedSettings.anchor,
		addon.Utilities:ToUI(frame.dataProvider:Scale(frame, cachedSettings.offsetXPx)),
		addon.Utilities:ToUI(frame.dataProvider:Scale(frame, cachedSettings.offsetYPx))
	)
end

function Ping:UpdateState(frame, settings)
	if frame.frameType == "boss" then
		return
	end

	local container = frame.ping
	if frame.dataProvider ~= addon.Frames.DataProvider.Live then
		container:Hide()
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local ping = activePings[frame.unit]
	if not settingsCache[settings].enabled or not ping then
		container:Hide()
		return
	end

	container.background:SetAtlas("Ping_Frame_BG_" .. ping.textureKit, false)
	container.icon:SetAtlas("Ping_Frame_" .. ping.textureKit, false)

	container:Show()
end

function Ping:Clear(frame)
	if frame.ping then
		frame.ping:Hide()
	end
end

function Ping:ClearAll()
	wipe(sourcePings)
	wipe(activePings)
	addon.UpdateScheduler:Notify("pingStateChanged")
end

function Ping:Init()
	InitializeHooks()

	addon.Modules:Register({
		module = self,
		settingsReason = "pingSettingsChanged",
		stateReason = "pingStateChanged",
	})
end
