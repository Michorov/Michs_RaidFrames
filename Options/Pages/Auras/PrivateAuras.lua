local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.PrivateAuras = addon.Options.Pages.Auras.PrivateAuras or {}

local PrivateAuras = addon.Options.Pages.Auras.PrivateAuras

local subpage
local L = addon.L

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

local function GetModeDefaults(mode)
	if mode == "raid" then
		return {
			offsetX = 2,
			offsetY = 2,
			iconSize = 16,
			spacing = 1,
			maxIcons = 3,
		}
	end

	return {
		offsetX = 2,
		offsetY = 2,
		iconSize = 20,
		spacing = 1,
		maxIcons = 3,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Private Auras settings are disabled during combat."])
end

local function ApplyModeSetting(updateFn)
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

	addon.UpdateScheduler:Notify("privateAurasSettingsChanged")
end

local function FormatInteger(value)
	return string.format("%d", value)
end

local function ConfigureIntegerSlider(slider, minValue, maxValue, step)
	slider:SetMinMaxValues(minValue, maxValue)
	slider:SetStep(step or 1)
	slider:SetValueFormatter(FormatInteger)
end

function PrivateAuras:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.offsetXSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset X"])
	subpage.offsetXSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetXSlider, -200, 200, 1)
	subpage.offsetXSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.privateAuras = section.widgets.icons.privateAuras or {}
			section.widgets.icons.privateAuras.offsetX = value
		end)
	end)

	subpage.offsetYSlider = addon.Options.Controls.Slider:Create(subpage, L["Offset Y"])
	subpage.offsetYSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.offsetYSlider, -200, 200, 1)
	subpage.offsetYSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.privateAuras = section.widgets.icons.privateAuras or {}
			section.widgets.icons.privateAuras.offsetY = value
		end)
	end)

	subpage.iconSizeSlider = addon.Options.Controls.Slider:Create(subpage, L["Icon Size"])
	subpage.iconSizeSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.iconSizeSlider, 8, 64, 1)
	subpage.iconSizeSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.privateAuras = section.widgets.icons.privateAuras or {}
			section.widgets.icons.privateAuras.iconSize = value
		end)
	end)

	subpage.spacingSlider = addon.Options.Controls.Slider:Create(subpage, L["Spacing"])
	subpage.spacingSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.spacingSlider, 0, 20, 1)
	subpage.spacingSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.privateAuras = section.widgets.icons.privateAuras or {}
			section.widgets.icons.privateAuras.spacing = value
		end)
	end)

	subpage.maxIconsSlider = addon.Options.Controls.Slider:Create(subpage, L["Max Icons"])
	subpage.maxIconsSlider:SetLayoutWidth(174)
	ConfigureIntegerSlider(subpage.maxIconsSlider, 1, 10, 1)
	subpage.maxIconsSlider:SetOnValueChanged(function(_, value)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.privateAuras = section.widgets.icons.privateAuras or {}
			section.widgets.icons.privateAuras.maxIcons = value
		end)
	end)

	subpage.controls = {
		offsetXSlider = subpage.offsetXSlider,
		offsetYSlider = subpage.offsetYSlider,
		iconSizeSlider = subpage.iconSizeSlider,
		spacingSlider = subpage.spacingSlider,
		maxIconsSlider = subpage.maxIconsSlider,
	}

	function subpage:UpdateLocale()
		self.offsetXSlider:SetLabel(L["Offset X"])
		self.offsetYSlider:SetLabel(L["Offset Y"])
		self.iconSizeSlider:SetLabel(L["Icon Size"])
		self.spacingSlider:SetLabel(L["Spacing"])
		self.maxIconsSlider:SetLabel(L["Max Icons"])
	end

	function subpage:UpdateLayout()
		local controls = self.controls
		local rowStepPx = addon.Utilities:ToPixels(50)
		local columnGapPx = addon.Utilities:ToPixels(30)
		local columnWidthPx = addon.Utilities:ToPixels(174)
		local secondColumnOffsetPx = columnWidthPx + columnGapPx
		local thirdColumnOffsetPx = (columnWidthPx * 2) + (columnGapPx * 2)
		local firstRowOffsetPx = 0
		local secondRowOffsetPx = rowStepPx

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.offsetXSlider:ClearAllPoints()
		controls.offsetXSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(firstRowOffsetPx))

		controls.offsetYSlider:ClearAllPoints()
		controls.offsetYSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(firstRowOffsetPx)
		)

		controls.spacingSlider:ClearAllPoints()
		controls.spacingSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(thirdColumnOffsetPx),
			-addon.Utilities:ToUI(firstRowOffsetPx)
		)

		controls.iconSizeSlider:ClearAllPoints()
		controls.iconSizeSlider:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(secondRowOffsetPx))

		controls.maxIconsSlider:ClearAllPoints()
		controls.maxIconsSlider:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(secondRowOffsetPx)
		)
	end

	function subpage:UpdateState(profile)
		if not profile then
			return
		end

		local controls = self.controls
		local mode = GetModeKey()
		local section = profile[mode] or {}
		local defaults = GetModeDefaults(mode)
		local widgets = section.widgets or {}
		local icons = widgets.icons or {}
		local privateAuras = icons.privateAuras or {}

		controls.offsetXSlider:SetValueSilently(privateAuras.offsetX or defaults.offsetX)
		controls.offsetYSlider:SetValueSilently(privateAuras.offsetY or defaults.offsetY)
		controls.iconSizeSlider:SetValueSilently(privateAuras.iconSize or defaults.iconSize)
		controls.spacingSlider:SetValueSilently(privateAuras.spacing or defaults.spacing)
		controls.maxIconsSlider:SetValueSilently(privateAuras.maxIcons or defaults.maxIcons)
	end

	subpage:UpdateLocale()

	return subpage
end
