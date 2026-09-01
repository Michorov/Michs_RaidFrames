local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.RoleIcon = addon.Frames.Widgets.Indicators.RoleIcon or {}

local RoleIcon = addon.Frames.Widgets.Indicators.RoleIcon

local settingsCache = setmetatable({}, { __mode = "k" })
local eventsRegistered = nil

local EVENTS = {
	"PLAYER_ROLES_ASSIGNED",
}

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local roleIcon = indicators.roleIcon or {}

	local result = {
		enabled = roleIcon.enabled == true,
		showTank = roleIcon.showTank ~= false,
		showHealer = roleIcon.showHealer ~= false,
		showDps = roleIcon.showDps ~= false,
		anchor = roleIcon.anchor or "TOPLEFT",
		sizePx = addon.Utilities:ToPixels(roleIcon.size or 16),
		offsetXPx = addon.Utilities:ToPixels(roleIcon.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(roleIcon.offsetY or 0),
	}

	settingsCache[settings] = result
end

local function UpdateEvents()
	local profile = addon.Database:GetProfile()
	local partyRoleIcon = profile.party.widgets.indicators.roleIcon
	local raidRoleIcon = addon.FrameRegistry:ResolveRaidSettings(profile).widgets.indicators.roleIcon
	local shouldRegister = partyRoleIcon.enabled == true or raidRoleIcon.enabled == true

	if eventsRegistered == shouldRegister then
		return
	end

	eventsRegistered = shouldRegister

	for _, event in ipairs(EVENTS) do
		if shouldRegister then
			addon.EventHandler:RegisterTrackedEvent(event, RoleIcon)
		else
			addon.EventHandler:UnregisterTrackedEvent(event, RoleIcon)
		end
	end
end

local function ApplyRoleAtlas(texture, role)
	if role == "TANK" then
		texture:SetAtlas("groupfinder-icon-role-large-tank")
	elseif role == "HEALER" then
		texture:SetAtlas("groupfinder-icon-role-large-heal")
	elseif role == "DAMAGER" then
		texture:SetAtlas("groupfinder-icon-role-large-dps")
	else
		return false
	end

	return true
end

local function IsRoleEnabled(cachedSettings, role)
	if role == "TANK" then
		return cachedSettings.showTank
	end

	if role == "HEALER" then
		return cachedSettings.showHealer
	end

	if role == "DAMAGER" then
		return cachedSettings.showDps
	end

	return false
end

function RoleIcon:Ensure(frame)
	if not frame.roleIcon then
		local container = CreateFrame("Frame", nil, frame)
		container:SetFrameLevel(32)
		container.texture = container:CreateTexture(nil, "OVERLAY")
		container.texture:SetAllPoints(container)
		container:Hide()
		frame.roleIcon = container
	end
end

function RoleIcon:UpdateSettings(frame, settings)
	local container = frame.roleIcon

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

function RoleIcon:UpdateState(frame, settings)
	local container = frame.roleIcon

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.roleIcon ~= true then
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
	if not provider or type(provider.GetRole) ~= "function" then
		container:Hide()
		return
	end

	local role = provider:GetRole(frame)
	if role ~= "TANK" and role ~= "HEALER" and role ~= "DAMAGER" then
		container:Hide()
		return
	end

	if frame.frameType ~= "preview" and not IsRoleEnabled(cachedSettings, role) then
		container:Hide()
		return
	end

	container.texture:SetTexCoord(0, 1, 0, 1)
	ApplyRoleAtlas(container.texture, role)
	container:Show()
end

function RoleIcon:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "roleIconSettingsChanged",
		stateReason = "roleIconStateChanged",
	})
end
