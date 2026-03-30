local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.RoleIcon = addon.Frames.Widgets.Indicators.RoleIcon or {}

local RoleIcon = addon.Frames.Widgets.Indicators.RoleIcon

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local roleIcon = indicators.roleIcon or {}

	local result = {
		enabled = roleIcon.enabled == true,
		anchor = roleIcon.anchor or "TOPLEFT",
		sizePx = addon.Utilities:ToPixels(roleIcon.size or 16),
		offsetXPx = addon.Utilities:ToPixels(roleIcon.offsetX or 0),
		offsetYPx = addon.Utilities:ToPixels(roleIcon.offsetY or 0),
	}

	settingsCache[settings] = result
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

function RoleIcon:UpdateState(frame, settings)
	local container = frame.roleIcon

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
