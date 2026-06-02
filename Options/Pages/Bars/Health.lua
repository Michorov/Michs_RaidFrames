local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}
addon.Options.Pages.Bars.Health = addon.Options.Pages.Bars.Health or {}

local Health = addon.Options.Pages.Bars.Health

local subpage
local L = addon.L

local function GetModeDefaults(mode)
	if mode == "raid" then
		return {
			healthClassColor = true,
			healthColor = { r = 0.12, g = 0.12, b = 0.12, a = 1.0 },
		}
	end

	return {
		healthClassColor = true,
		healthColor = { r = 0.12, g = 0.12, b = 0.12, a = 1.0 },
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Health settings are disabled during combat."])
end

local function ApplyModeSetting(updateFn, notifyEvent)
	if InCombatLockdown() then
		ShowCombatLockMessage()
		if subpage and subpage.UpdateState then
			subpage:UpdateState(addon.Database:GetProfile())
		end
		return
	end

	local profile = addon.Database:GetProfile()
	local mode = addon.Options.State:GetMode()

	profile[mode] = profile[mode] or {}
	updateFn(profile[mode], mode)

	addon.UpdateScheduler:Notify(notifyEvent)
end

function Health:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.useClassColorCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Use Class Color"])
	subpage.useClassColorCheckbox:SetLayoutWidth(174)
	subpage.useClassColorCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.health = section.health or {}
			section.health.classColor = checked == true
		end, "healthSettingsChanged")
	end)

	subpage.healthColorPicker = addon.Options.Controls.ColorPicker:Create(subpage, L["Health Color"])
	subpage.healthColorPicker:SetLayoutWidth(190)
	subpage.healthColorPicker:SetHasOpacity(true)
	subpage.healthColorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.health = section.health or {}
			section.health.color = { r = r, g = g, b = b, a = a }
		end, "healthSettingsChanged")
	end)

	subpage.controls = {
		useClassColorCheckbox = subpage.useClassColorCheckbox,
		healthColorPicker = subpage.healthColorPicker,
	}

	function subpage:UpdateLocale()
		self.useClassColorCheckbox:SetText(L["Use Class Color"])
		self.healthColorPicker:SetLabel(L["Health Color"])
	end

	function subpage:UpdateLayout()
		local controls = self.controls
		local columnGapPx = addon.Utilities:ToPixels(30)
		local threeColumnSlotWidthPx = addon.Utilities:ToPixels(174)
		local threeColumnSecondOffsetPx = threeColumnSlotWidthPx + columnGapPx
		local sliderHeightPx = addon.Utilities:ToPixels(34)
		local colorPickerSizePx = addon.Utilities:ToPixels(controls.healthColorPicker.layoutValues.pickerSize)
		local colorPickerOffsetPx =
			addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - colorPickerSizePx) / 2))
		local checkboxHeightPx = addon.Utilities:ToPixels(controls.useClassColorCheckbox.layoutValues.height)
		local checkboxOffsetPx = addon.Utilities:RoundToNearestInt(math.max(0, (sliderHeightPx - checkboxHeightPx) / 2))

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.useClassColorCheckbox:ClearAllPoints()
		controls.useClassColorCheckbox:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(checkboxOffsetPx))

		controls.healthColorPicker:ClearAllPoints()
		controls.healthColorPicker:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(threeColumnSecondOffsetPx),
			-addon.Utilities:ToUI(colorPickerOffsetPx)
		)
	end

	function subpage:UpdateState(profile)
		if not profile then
			return
		end

		local controls = self.controls
		local mode = addon.Options.State:GetMode()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults(mode)
		local health = section.health or {}
		local healthColor = health.color or defaults.healthColor
		local healthClassColor = health.classColor
		if healthClassColor == nil then
			healthClassColor = defaults.healthClassColor
		end

		controls.useClassColorCheckbox:SetChecked(healthClassColor == true)
		controls.healthColorPicker:SetColor(healthColor.r, healthColor.g, healthColor.b, healthColor.a)
	end

	subpage:UpdateLocale()

	return subpage
end
