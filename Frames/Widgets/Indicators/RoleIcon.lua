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

local function ApplyRoleAtlas(icon, role)
	if role == "TANK" then
		icon:SetAtlas("groupfinder-icon-role-large-tank")
	elseif role == "HEALER" then
		icon:SetAtlas("groupfinder-icon-role-large-heal")
	elseif role == "DAMAGER" then
		icon:SetAtlas("groupfinder-icon-role-large-dps")
	else
		return false
	end

	return true
end

function RoleIcon:Ensure(frame)
	if not frame then
		return
	end

	local topWidgetsOverlay = frame.topWidgetsOverlay
	if not topWidgetsOverlay then
		return
	end

	if not frame.roleIcon then
		local icon = topWidgetsOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
		icon:Hide()
		frame.roleIcon = icon
	end
end

function RoleIcon:UpdateSettings(frame, settings)
	local icon = frame and frame.roleIcon
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

function RoleIcon:UpdateState(frame, settings)
	local icon = frame and frame.roleIcon
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

	local provider = frame and frame.dataProvider
	if not provider or type(provider.GetRole) ~= "function" then
		icon:Hide()
		return
	end

	local role = provider:GetRole(frame)
	if role ~= "TANK" and role ~= "HEALER" and role ~= "DAMAGER" then
		icon:Hide()
		return
	end

	icon:SetTexCoord(0, 1, 0, 1)
	ApplyRoleAtlas(icon, role)
	icon:Show()
end

function RoleIcon:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "roleIconSettingsChanged",
		stateReason = "roleIconStateChanged",
	})
end
