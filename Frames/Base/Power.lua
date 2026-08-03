local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Power = addon.Frames.Base.Power or {}

local Power = addon.Frames.Base.Power

local settingsCache = setmetatable({}, { __mode = "k" })
local powerEventsRegistered = nil

local POWER_UNIT_EVENTS = {
	"UNIT_POWER_UPDATE",
	"UNIT_MAXPOWER",
	"UNIT_DISPLAYPOWER",
}

local POWER_COLORS = {
	MANA = { r = 0.00, g = 0.45, b = 1.00, a = 1.0 },
	RAGE = { r = 0.90, g = 0.20, b = 0.20, a = 1.0 },
	FOCUS = { r = 1.00, g = 0.50, b = 0.25, a = 1.0 },
	ENERGY = { r = 1.00, g = 0.90, b = 0.20, a = 1.0 },
	COMBO_POINTS = { r = 1.00, g = 0.96, b = 0.41, a = 1.0 },
	RUNIC_POWER = { r = 0.00, g = 0.82, b = 1.00, a = 1.0 },
	INSANITY = { r = 0.40, g = 0.00, b = 0.80, a = 1.0 },
	MAELSTROM = { r = 0.00, g = 0.50, b = 1.00, a = 1.0 },
	LUNAR_POWER = { r = 0.30, g = 0.52, b = 0.90, a = 1.0 },
	HOLY_POWER = { r = 0.95, g = 0.90, b = 0.60, a = 1.0 },
	ARCANE_CHARGES = { r = 0.10, g = 0.10, b = 0.98, a = 1.0 },
	FURY = { r = 0.79, g = 0.26, b = 0.99, a = 1.0 },
	PAIN = { r = 1.00, g = 0.61, b = 0.00, a = 1.0 },
	ESSENCE = { r = 0.00, g = 0.80, b = 0.85, a = 1.0 },
}

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local power = (settings and settings.power) or {}
	local profile = addon.Database:GetProfile()
	local core = (profile and profile.core) or {}
	local texture = power.lsmTexture

	if texture == -1 then
		texture = core.lsmTexture
	end

	texture = texture or "M-SolidDarker"

	local result = {
		enabled = power.enabled == true,
		healerOnly = power.healerOnly == true,
		texture = texture,
		heightPx = addon.Utilities:ToPixels(power.height or 4),
		borderThicknessPx = addon.Utilities:ToPixels(power.borderThicknessPx or 1),
	}

	settingsCache[settings] = result
end

local function IsPowerEnabled(settings)
	return settings and settings.power and settings.power.enabled == true
end

local function RefreshPowerUnitEvents()
	local profile = addon.Database:GetProfile()
	local shouldRegister = IsPowerEnabled(profile.party) or IsPowerEnabled(addon.FrameRegistry:ResolveRaidSettings(profile))

	if powerEventsRegistered == shouldRegister then
		return
	end

	powerEventsRegistered = shouldRegister

	for _, event in ipairs(POWER_UNIT_EVENTS) do
		if shouldRegister then
			addon.EventHandler:RegisterTrackedUnitEvent(event)
		else
			addon.EventHandler:UnregisterTrackedUnitEvent(event)
		end
	end
end

local function IsPowerBarEnabled(frame, cachedSettings)
	if not cachedSettings.enabled then
		return false
	end

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.power ~= true then
		return false
	end

	if cachedSettings.healerOnly then
		return frame.dataProvider:IsHealer(frame)
	end

	return true
end

function Power:Ensure(frame)
	if not frame.powerBar then
		local powerBar = CreateFrame("StatusBar", nil, frame)
		powerBar:SetFrameLevel(20)
		powerBar:SetOrientation("HORIZONTAL")
		powerBar:SetMinMaxValues(0, 1)
		powerBar:SetValue(0)

		powerBar.background = powerBar:CreateTexture(nil, "BACKGROUND")
		powerBar.background:SetAllPoints(powerBar)

		powerBar.border = CreateFrame("Frame", nil, powerBar, BackdropTemplateMixin and "BackdropTemplate")
		powerBar.border:SetFrameLevel(powerBar:GetFrameLevel() + 1)
		powerBar.border:SetAllPoints(powerBar)

		powerBar:ClearAllPoints()
		powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
		powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
		powerBar:SetHeight(1)
		powerBar:Hide()

		frame.powerBar = powerBar
	end
end

function Power:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)

	if frame.dataProvider == addon.Frames.DataProvider.Live then
		RefreshPowerUnitEvents()
	end

	local cachedSettings = settingsCache[settings]

	local powerBar = frame.powerBar
	local scaledHeightPx = math.max(1, frame.dataProvider:Scale(frame, cachedSettings.heightPx))
	local scaledBorderPx = frame.dataProvider:Scale(frame, cachedSettings.borderThicknessPx)

	powerBar:SetStatusBarTexture(addon.Styles.Textures:Fetch(cachedSettings.texture))
	powerBar:SetHeight(addon.Utilities:ToUI(scaledHeightPx))

	powerBar.background:SetColorTexture(0.04, 0.04, 0.04, 1)

	if scaledBorderPx > 0 then
		powerBar.border:SetBackdrop({
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = addon.Utilities:ToUI(scaledBorderPx),
		})
		powerBar.border:SetBackdropBorderColor(0, 0, 0, 1)
		powerBar.border:Show()
	else
		powerBar.border:Hide()
	end
end

function Power:UpdateState(frame, settings)
	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end

	local cachedSettings = settingsCache[settings]
	local powerBar = frame.powerBar

	if not IsPowerBarEnabled(frame, cachedSettings) then
		powerBar:Hide()
		return
	end

	local current, max, powerToken = frame.dataProvider:GetPower(frame)
	if current == nil or max == nil or powerToken == nil then
		powerBar:Hide()
		return
	end

	if type(powerToken) == "string" then
		powerToken = powerToken:gsub("^POWER_TYPE_", "")
	end

	local color = POWER_COLORS[powerToken] or POWER_COLORS.MANA
	powerBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
	powerBar:SetMinMaxValues(0, max)
	powerBar:SetValue(current)
	powerBar:Show()
end

function Power:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "powerSettingsChanged",
		stateReason = "powerStateChanged",
	})
end
