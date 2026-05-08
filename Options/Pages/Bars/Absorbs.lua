local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}
addon.Options.Pages.Bars.Absorbs = addon.Options.Pages.Bars.Absorbs or {}

local Absorbs = addon.Options.Pages.Bars.Absorbs

local subpage
local L = addon.L

local textureOptions = {
	{ value = "Flat", text = L["Flat"] },
	{ value = "Striped", text = L["Striped"] },
}

local function UpdateTextureOptions()
	textureOptions[1].text = L["Flat"]
	textureOptions[2].text = L["Striped"]
end

local function GetControllerState()
	local content = addon.Options.Sections.Content
	if content and content.GetControllerState then
		return content:GetControllerState()
	end

	addon.Options.ControllerState = addon.Options.ControllerState
		or {
			mode = "party",
			subpages = {
				auras = "buffs",
				texts = "name",
				indicators = "readyCheck",
				bars = "health",
			},
		}

	return addon.Options.ControllerState
end

local function GetModeKey()
	local state = GetControllerState()
	return state.mode == "raid" and "raid" or "party"
end

local function GetModeDefaults()
	return {
		texture = "Flat",
		color = { r = 0.2, g = 0.8, b = 1.0, a = 0.5 },
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Absorbs settings are disabled during combat."])
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
	local mode = GetModeKey()

	profile[mode] = profile[mode] or {}
	updateFn(profile[mode], mode)

	addon.UpdateScheduler:Notify(notifyEvent)
end

function Absorbs:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.textureDropdown = addon.Options.Controls.Dropdown:Create(subpage, L["Shield Texture"])
	subpage.textureDropdown:SetLayoutWidth(174)
	subpage.textureDropdown:SetOptions(textureOptions)
	subpage.textureDropdown:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.bars = section.widgets.bars or {}
			section.widgets.bars.absorbs = section.widgets.bars.absorbs or {}
			section.widgets.bars.absorbs.texture = value
		end, "absorbsSettingsChanged")
	end)

	subpage.colorPicker = addon.Options.Controls.ColorPicker:Create(subpage, L["Shield Color"])
	subpage.colorPicker:SetLayoutWidth(190)
	subpage.colorPicker:SetHasOpacity(true)
	subpage.colorPicker:SetOnValueChanged(function(_, r, g, b, a)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.bars = section.widgets.bars or {}
			section.widgets.bars.absorbs = section.widgets.bars.absorbs or {}
			section.widgets.bars.absorbs.color = { r = r, g = g, b = b, a = a }
		end, "absorbsSettingsChanged")
	end)

	subpage.controls = {
		textureDropdown = subpage.textureDropdown,
		colorPicker = subpage.colorPicker,
	}

	function subpage:UpdateLocale()
		UpdateTextureOptions()
		self.textureDropdown:SetLabel(L["Shield Texture"])
		self.textureDropdown:SetOptions(textureOptions)
		self.colorPicker:SetLabel(L["Shield Color"])
	end

	function subpage:UpdateLayout()
		local controls = self.controls
		local columnGapPx = addon.Utilities:ToPixels(30)
		local threeColumnSlotWidthPx = addon.Utilities:ToPixels(174)
		local threeColumnSecondOffsetPx = threeColumnSlotWidthPx + columnGapPx
		local fieldTopInsetPx = addon.Utilities:ToPixels(
			controls.textureDropdown.layoutValues.labelHeight + controls.textureDropdown.layoutValues.labelSpacing
		)
		local fieldHeightPx = addon.Utilities:ToPixels(controls.textureDropdown.layoutValues.fieldHeight)
		local colorPickerSizePx = addon.Utilities:ToPixels(controls.colorPicker.layoutValues.pickerSize)
		local colorPickerOffsetPx = fieldTopInsetPx
			+ addon.Utilities:RoundToNearestInt(math.max(0, (fieldHeightPx - colorPickerSizePx) / 2))

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.textureDropdown:ClearAllPoints()
		controls.textureDropdown:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)

		controls.colorPicker:ClearAllPoints()
		controls.colorPicker:SetPoint(
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
		local mode = GetModeKey()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults()
		local widgetBars = ((section.widgets or {}).bars or {})
		local absorbs = widgetBars.absorbs or {}
		local color = absorbs.color or defaults.color

		controls.textureDropdown:SetOptions(textureOptions)
		controls.textureDropdown:SetValue(absorbs.texture or defaults.texture)
		controls.colorPicker:SetColor(color.r, color.g, color.b, color.a)
	end

	subpage:UpdateLocale()

	return subpage
end
