local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Bars = addon.Frames.Widgets.Bars or {}
addon.Frames.Widgets.Bars.HealAbsorbs = addon.Frames.Widgets.Bars.HealAbsorbs or {}

local HealAbsorbs = addon.Frames.Widgets.Bars.HealAbsorbs

local function GetHealAbsorbSettings(settings)
	local healAbsorbs = settings and settings.widgets and settings.widgets.bars and settings.widgets.bars.healAbsorbs
		or {}
	local color = healAbsorbs.color or {}

	return {
		texture = healAbsorbs.texture or "Interface\\Buttons\\WHITE8x8",
		color = {
			r = color.r or 1,
			g = color.g or 0,
			b = color.b or 0,
			a = color.a or 0.5,
		},
	}
end

local function GetClampedHealAbsorb(frame, unit)
	if not frame or not unit then
		return nil
	end

	-- Preferred path: prediction calculator (secret-safe)
	if CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction then
		frame.healAbsorbCalculator = frame.healAbsorbCalculator or CreateUnitHealPredictionCalculator()
		local calc = frame.healAbsorbCalculator

		if calc.SetHealAbsorbClampMode then
			pcall(calc.SetHealAbsorbClampMode, calc, 0)
		end

		UnitGetDetailedHealPrediction(unit, nil, calc)

		if calc.GetHealAbsorbs then
			local ok, value = pcall(calc.GetHealAbsorbs, calc)
			if ok then
				return value
			end
		end
	end

	-- Fallback
	if UnitGetTotalHealAbsorbs then
		return UnitGetTotalHealAbsorbs(unit)
	end

	return nil
end

function HealAbsorbs:Ensure(frame)
	if not frame then
		return
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not widgetsOverlay then
		return
	end

	if not frame.healAbsorbBar then
		local bar = CreateFrame("StatusBar", nil, widgetsOverlay)
		bar:SetFrameStrata(widgetsOverlay:GetFrameStrata())
		bar:SetFrameLevel(widgetsOverlay:GetFrameLevel() + 4)
		bar:SetOrientation("HORIZONTAL")
		bar:SetReverseFill(false)
		bar:Hide()
		frame.healAbsorbBar = bar
	end
end

function HealAbsorbs:UpdateSettings(frame, settings)
	local healAbsorbSettings = GetHealAbsorbSettings(settings)
	local bar = frame and frame.healAbsorbBar
	if not bar then
		return
	end

	local healthBar = frame.healthBar
	local healthTex = healthBar and healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
	if healthTex then
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", healthTex, "TOPLEFT", 0, 0)
		bar:SetPoint("BOTTOMRIGHT", healthTex, "BOTTOMRIGHT", 0, 0)
	end

	bar:SetStatusBarTexture(healAbsorbSettings.texture)
	bar:SetStatusBarColor(
		healAbsorbSettings.color.r,
		healAbsorbSettings.color.g,
		healAbsorbSettings.color.b,
		healAbsorbSettings.color.a
	)
end

function HealAbsorbs:UpdateState(frame)
	local bar = frame and frame.healAbsorbBar
	if not frame or not bar then
		return
	end

	local unit = frame.unit
	if not UnitExists(unit) or UnitCanAttack("player", unit) then
		bar:Hide()
		return
	end

	local currentHealth = UnitHealth(unit)
	if currentHealth == nil then
		bar:Hide()
		return
	end

	local healAbsorbValue = GetClampedHealAbsorb(frame, unit)
	if healAbsorbValue == nil then
		bar:Hide()
		return
	end

	bar:SetMinMaxValues(0, currentHealth)
	bar:SetValue(healAbsorbValue)
	bar:Show()
end

function HealAbsorbs:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "healAbsorbsSettingsChanged",
		stateReason = "healAbsorbsStateChanged",
	})
end
