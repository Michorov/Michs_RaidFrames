local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Bars = addon.Frames.Widgets.Bars or {}
addon.Frames.Widgets.Bars.Absorbs = addon.Frames.Widgets.Bars.Absorbs or {}

local Absorbs = addon.Frames.Widgets.Bars.Absorbs

local function GetAbsorbSettings(settings)
	local absorbs = settings and settings.widgets and settings.widgets.bars and settings.widgets.bars.absorbs or {}
	local color = absorbs.color or {}

	return {
		texture = absorbs.texture or "Interface\\Buttons\\WHITE8x8",
		color = {
			r = color.r or 0.2,
			g = color.g or 0.8,
			b = color.b or 1.0,
			a = color.a or 0.5,
		},
	}
end

local function GetClampedAbsorb(frame, unit)
	if not frame or not unit then
		return nil
	end

	if CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction then
		frame.absorbCalculator = frame.absorbCalculator or CreateUnitHealPredictionCalculator()
		local calc = frame.absorbCalculator

		if calc.SetAbsorbClampMode then
			pcall(calc.SetAbsorbClampMode, calc, 0)
		end

		UnitGetDetailedHealPrediction(unit, nil, calc)

		if calc.GetAbsorbs then
			local ok, value = pcall(calc.GetAbsorbs, calc)
			if ok then
				return value
			end
		end
		if calc.GetTotalAbsorbs then
			local ok, value = pcall(calc.GetTotalAbsorbs, calc)
			if ok then
				return value
			end
		end
	end

	if UnitGetTotalAbsorbs then
		return UnitGetTotalAbsorbs(unit)
	end

	return nil
end

function Absorbs:Ensure(frame)
	if not frame then
		return
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not widgetsOverlay then
		return
	end

	if not frame.absorbBar then
		local bar = CreateFrame("StatusBar", nil, widgetsOverlay)
		bar:SetFrameStrata(widgetsOverlay:GetFrameStrata())
		bar:SetFrameLevel(widgetsOverlay:GetFrameLevel() + 5)
		bar:SetOrientation("HORIZONTAL")
		bar:SetReverseFill(true)
		bar:Hide()
		frame.absorbBar = bar
	end

	local bar = frame.absorbBar
	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", widgetsOverlay, "TOPLEFT", 0, 0)
	bar:SetPoint("BOTTOMRIGHT", widgetsOverlay, "BOTTOMRIGHT", 0, 0)
end

function Absorbs:UpdateSettings(frame, settings)
	local absorbSettings = GetAbsorbSettings(settings)
	local bar = frame and frame.absorbBar
	if not bar then
		return
	end

	bar:SetStatusBarTexture(absorbSettings.texture)
	bar:SetStatusBarColor(
		absorbSettings.color.r,
		absorbSettings.color.g,
		absorbSettings.color.b,
		absorbSettings.color.a
	)
end

function Absorbs:UpdateState(frame)
	local bar = frame and frame.absorbBar
	if not bar then
		return
	end

	local unit = frame.unit
	if not UnitExists(unit) or UnitCanAttack("player", unit) then
		bar:Hide()
		return
	end

	local maxHealth = UnitHealthMax(unit)
	if not maxHealth or maxHealth <= 0 then
		bar:Hide()
		return
	end

	local absorbValue = GetClampedAbsorb(frame, unit)
	if absorbValue == nil then
		bar:Hide()
		return
	end

	bar:SetMinMaxValues(0, maxHealth)
	bar:SetValue(absorbValue)
	bar:Show()
end
