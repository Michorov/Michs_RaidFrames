local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}
addon.Options.Pages.Auras.Dispels = addon.Options.Pages.Auras.Dispels or {}

local Dispels = addon.Options.Pages.Auras.Dispels

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

local function ResolveBoolean(value, defaultValue)
	if value == nil then
		return defaultValue
	end

	return value == true
end

local function GetModeDefaults()
	return {
		enabled = true,
		showOnlyPlayerDispellable = true,
	}
end

local function ShowCombatLockMessage()
	print("|cffff9900Mich's RaidFrames:|r " .. L["Dispel settings are disabled during combat."])
end

local function ApplyModeSetting(updateFn, settingsReason, notifyState)
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

	addon.UpdateScheduler:Notify(settingsReason or "dispelsSettingsChanged")
	if notifyState then
		addon.UpdateScheduler:Notify("aurasStateChanged")
	end
end

function Dispels:Ensure(parent)
	if subpage then
		return subpage
	end

	subpage = CreateFrame("Frame", nil, parent)

	subpage.enabledCheckbox = addon.Options.Controls.Checkbox:Create(subpage, L["Enabled"])
	subpage.enabledCheckbox:SetLayoutWidth(174)
	subpage.enabledCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.enabled = checked == true
		end, "dispelsSettingsChanged")
	end)

	subpage.showOnlyPlayerDispellableCheckbox =
		addon.Options.Controls.Checkbox:Create(subpage, L["Only Dispellable By Me"])
	subpage.showOnlyPlayerDispellableCheckbox:SetLayoutWidth(174)
	subpage.showOnlyPlayerDispellableCheckbox:SetOnValueChanged(function(_, checked)
		ApplyModeSetting(function(section)
			section.widgets = section.widgets or {}
			section.widgets.icons = section.widgets.icons or {}
			section.widgets.icons.dispels = section.widgets.icons.dispels or {}
			section.widgets.icons.dispels.showOnlyPlayerDispellable = checked == true
		end, "dispelsSettingsChanged")
	end)

	subpage.controls = {
		enabledCheckbox = subpage.enabledCheckbox,
		showOnlyPlayerDispellableCheckbox = subpage.showOnlyPlayerDispellableCheckbox,
	}

	function subpage:UpdateLocale()
		self.enabledCheckbox:SetText(L["Enabled"])
		self.showOnlyPlayerDispellableCheckbox:SetText(L["Only Dispellable By Me"])
	end

	function subpage:UpdateLayout()
		local controls = self.controls
		local firstRowOffsetPx = 0
		local secondColumnOffsetPx = addon.Utilities:ToPixels(204)

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.enabledCheckbox:ClearAllPoints()
		controls.enabledCheckbox:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -addon.Utilities:ToUI(firstRowOffsetPx))

		controls.showOnlyPlayerDispellableCheckbox:ClearAllPoints()
		controls.showOnlyPlayerDispellableCheckbox:SetPoint(
			"TOPLEFT",
			self,
			"TOPLEFT",
			addon.Utilities:ToUI(secondColumnOffsetPx),
			-addon.Utilities:ToUI(firstRowOffsetPx)
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
		local widgets = section.widgets or {}
		local icons = widgets.icons or {}
		local dispels = icons.dispels or {}

		controls.enabledCheckbox:SetChecked(ResolveBoolean(dispels.enabled, defaults.enabled))
		controls.showOnlyPlayerDispellableCheckbox:SetChecked(
			ResolveBoolean(dispels.showOnlyPlayerDispellable, defaults.showOnlyPlayerDispellable)
		)
	end

	subpage:UpdateLocale()

	return subpage
end
