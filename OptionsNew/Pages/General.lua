local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.General = addon.OptionsNew.Pages.General or {}

local OptionsUILib = LibStub("MichsOptionsUILib-1.0")
local General = addon.OptionsNew.Pages.General
local L = addon.L

local function UpdateState(page, profile)
	if not profile or not profile.core then
		return
	end

	local controls = page.controls

	controls.showSoloPartyFrameCheckbox:SetChecked(profile.core.showSoloPartyFrame == true)
	controls.hideBlizzardPartyRaidFramesCheckbox:SetChecked(profile.core.hideBlizzardRaidFrames == true)
	controls.hideBlizzardRaidFrameManagerCheckbox:SetChecked(profile.core.hideBlizzardRaidFrameManager == true)
	controls.globalScaleSlider:SetValueSilently(profile.core.uiScale or 1)
	controls.outOfRangeAlphaSlider:SetValueSilently(profile.core.outOfRangeAlpha or 1)
end

local function UpdateLayout(page)
	local controls = page.controls

	for _, control in pairs(controls) do
		if control.UpdateLayout then
			control:UpdateLayout()
		end
	end

	controls.showSoloPartyFrameCheckbox:SetLayoutPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)
	controls.hideBlizzardPartyRaidFramesCheckbox:SetLayoutPoint(
		"TOPLEFT",
		controls.showSoloPartyFrameCheckbox,
		"BOTTOMLEFT",
		0,
		-12
	)
	controls.hideBlizzardRaidFrameManagerCheckbox:SetLayoutPoint(
		"TOPLEFT",
		controls.hideBlizzardPartyRaidFramesCheckbox,
		"BOTTOMLEFT",
		0,
		-12
	)
	controls.globalScaleSlider:SetLayoutPoint("TOPLEFT", controls.showSoloPartyFrameCheckbox, "TOPLEFT", 291, 0)
	controls.outOfRangeAlphaSlider:SetLayoutPoint("TOPLEFT", controls.globalScaleSlider, "BOTTOMLEFT", 0, -12)
end

function General:Create(panel)
	local page = panel:RegisterPage("general", {
		title = L["General"],
		type = "canvas",
		showHeader = true,
	})

	local PP = panel.instance.PP

	local showSoloPartyFrameCheckbox = OptionsUILib.Controls.Checkbox:Create(page.body, PP, L["Show Solo Party Frame"])
	showSoloPartyFrameCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.showSoloPartyFrame = checked
		addon.UpdateScheduler:Notify("soloFrameChanged")
	end)

	local hideBlizzardPartyRaidFramesCheckbox =
		OptionsUILib.Controls.Checkbox:Create(page.body, PP, L["Hide Blizzard Party/Raid Frames"])
	hideBlizzardPartyRaidFramesCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrames = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	local hideBlizzardRaidFrameManagerCheckbox =
		OptionsUILib.Controls.Checkbox:Create(page.body, PP, L["Hide Blizzard Raid Frame Manager"])
	hideBlizzardRaidFrameManagerCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrameManager = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	local globalScaleSlider = OptionsUILib.Controls.Slider:Create(page.body, PP, L["Global Scale"])
	globalScaleSlider:SetMinMaxValues(0.5, 2.0)
	globalScaleSlider:SetStep(0.01)
	globalScaleSlider:SetValueFormatter(function(value)
		return string.format("%.0f%%", value * 100)
	end)
	globalScaleSlider:SetValueParser("percent")
	globalScaleSlider:SetOnValueChanged(function(_, value)
		local profile = addon.Database:GetProfile()
		profile.core.uiScale = value
		addon.UpdateScheduler:Notify("layoutChanged")
		addon.Modules:RequestUpdateSettings()
	end)

	local outOfRangeAlphaSlider = OptionsUILib.Controls.Slider:Create(page.body, PP, L["Out of Range Alpha"])
	outOfRangeAlphaSlider:SetMinMaxValues(0, 1)
	outOfRangeAlphaSlider:SetStep(0.05)
	outOfRangeAlphaSlider:SetValueFormatter(function(value)
		return string.format("%.0f%%", value * 100)
	end)
	outOfRangeAlphaSlider:SetValueParser("percent")
	outOfRangeAlphaSlider:SetOnValueChanged(function(_, value)
		local profile = addon.Database:GetProfile()
		profile.core.outOfRangeAlpha = value
		addon.UpdateScheduler:Notify("outOfRangeAlphaSettingChanged")
	end)

	page.controls = {
		showSoloPartyFrameCheckbox = showSoloPartyFrameCheckbox,
		hideBlizzardPartyRaidFramesCheckbox = hideBlizzardPartyRaidFramesCheckbox,
		hideBlizzardRaidFrameManagerCheckbox = hideBlizzardRaidFrameManagerCheckbox,
		globalScaleSlider = globalScaleSlider,
		outOfRangeAlphaSlider = outOfRangeAlphaSlider,
	}

	page:RegisterForUpdate(UpdateLayout)
	addon.OptionsNew:RegisterForProfileUpdates("general", function(profile)
		UpdateState(page, profile)
	end)
	UpdateState(page, addon.Database:GetProfile())

	return page
end
