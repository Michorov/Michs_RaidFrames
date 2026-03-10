local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Power = addon.Frames.Base.Power or {}

local Power = addon.Frames.Base.Power

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

local function GetPowerSettings(settings)
	local power = (settings and settings.power) or {}
	local backgroundColor = power.backgroundColor or {}

	return {
		enabled = power.enabled == true,
		healerOnly = power.healerOnly == true,
		texture = power.texture or "Interface\\Buttons\\WHITE8x8",

		heightPx = addon.Utilities:ToPixels(power.height or 4),
		borderEnabled = power.borderEnabled ~= false,
		borderThicknessPx = addon.Utilities:ToPixels(power.borderThicknessPx or 1),

		backgroundColor = {
			r = backgroundColor.r or 0,
			g = backgroundColor.g or 0,
			b = backgroundColor.b or 0,
			a = backgroundColor.a or 0.5,
		},
	}
end

function Power:Ensure(frame)
	if not frame then
		return
	end

	local powerBar = frame.powerBar
	if not powerBar then
		powerBar = CreateFrame("StatusBar", nil, frame)
		powerBar:SetFrameStrata(frame:GetFrameStrata())
		powerBar:SetFrameLevel(frame:GetFrameLevel() + 3)
		powerBar:SetOrientation("HORIZONTAL")
		powerBar:SetMinMaxValues(0, 1)
		powerBar:SetValue(0)

		frame.powerBar = powerBar
	end

	if not powerBar.background then
		powerBar.background = powerBar:CreateTexture(nil, "BACKGROUND")
		powerBar.background:SetAllPoints(powerBar)
	end

	if not powerBar.border then
		powerBar.border = CreateFrame("Frame", nil, powerBar, BackdropTemplateMixin and "BackdropTemplate")
		powerBar.border:SetAllPoints(powerBar)
	end

	powerBar:ClearAllPoints()
	powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	powerBar:SetHeight(1)
	powerBar:Hide()
end

function Power:UpdateSettings(frame, settings)
	local powerBar = frame and frame.powerBar
	if not powerBar then
		return
	end

	local powerSettings = GetPowerSettings(settings)

	local scaledHeightPx = math.max(1, addon.Utilities:Scale(powerSettings.heightPx))
	local scaledBorderPx = math.max(1, addon.Utilities:Scale(powerSettings.borderThicknessPx))

	powerBar:SetStatusBarTexture(powerSettings.texture)

	if frame.border and frame.border.GetFrameLevel then
		powerBar:SetFrameLevel(frame.border:GetFrameLevel() - 1)
	else
		powerBar:SetFrameLevel(frame:GetFrameLevel() + 19)
	end

	powerBar:ClearAllPoints()
	powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	powerBar:SetHeight(addon.Utilities:ToUI(scaledHeightPx))

	if powerBar.background then
		local c = powerSettings.backgroundColor
		powerBar.background:SetAllPoints(powerBar)
		powerBar.background:SetColorTexture(c.r, c.g, c.b, c.a)
		powerBar.background:Show()
	end

	if powerBar.border then
		if powerSettings.borderEnabled then
			powerBar.border:ClearAllPoints()
			powerBar.border:SetAllPoints(powerBar)
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

	local showBar = powerSettings.enabled

	local provider = frame and frame.dataProvider
	if showBar and powerSettings.healerOnly then
		if provider and type(provider.IsHealer) == "function" then
			showBar = provider:IsHealer(frame)
		else
			showBar = false
		end
	end

	if showBar then
		powerBar:Show()
	else
		powerBar:Hide()
	end
end

function Power:UpdateState(frame, settings)
	local powerBar = frame and frame.powerBar
	if not powerBar then
		return
	end

	local powerSettings = GetPowerSettings(settings)
	if not powerSettings.enabled then
		return
	end

	local provider = frame and frame.dataProvider
	if not provider or type(provider.GetPower) ~= "function" then
		return
	end

	local current, max, powerToken = provider:GetPower(frame)
	if current == nil or max == nil or powerToken == nil then
		powerBar:Hide()
		return
	end

	if type(powerToken) == "string" then
		powerToken = powerToken:gsub("^POWER_TYPE_", "")
	end

	local c = POWER_COLORS[powerToken] or POWER_COLORS.MANA
	powerBar:SetStatusBarColor(c.r, c.g, c.b, c.a)

	powerBar:SetMinMaxValues(0, max)
	powerBar:SetValue(current)
end

function Power:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "powerSettingsChanged",
		stateReason = "powerStateChanged",
	})
end
