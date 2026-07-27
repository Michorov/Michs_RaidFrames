local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.General = addon.OptionsNew.Pages.General or {}

local General = addon.OptionsNew.Pages.General
local L = addon.L

local function UpdateState(controls, profile)
	if not profile or not profile.core then
		return
	end

	controls.showSoloPartyFrameCheckbox:SetChecked(profile.core.showSoloPartyFrame == true)
	controls.hideBlizzardPartyRaidFramesCheckbox:SetChecked(profile.core.hideBlizzardRaidFrames == true)
	controls.hideBlizzardRaidFrameManagerCheckbox:SetChecked(profile.core.hideBlizzardRaidFrameManager == true)
	controls.globalScaleSlider:SetValueSilently(profile.core.uiScale or 1)
	controls.outOfRangeAlphaSlider:SetValueSilently(profile.core.outOfRangeAlpha or 1)
end

function General:Create(panel)
	local page = panel:RegisterPage("general", {
		title = L["General"],
		showHeader = true,
	})

	local showSoloPartyFrameCheckbox = page:CreateControl("Checkbox", L["Show Solo Party Frame"])
	showSoloPartyFrameCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.showSoloPartyFrame = checked
		addon.UpdateScheduler:Notify("soloFrameChanged")
	end)

	local hideBlizzardPartyRaidFramesCheckbox = page:CreateControl(
		"Checkbox",
		L["Hide Blizzard Party/Raid Frames"]
	)
	hideBlizzardPartyRaidFramesCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrames = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	local hideBlizzardRaidFrameManagerCheckbox = page:CreateControl(
		"Checkbox",
		L["Hide Blizzard Raid Frame Manager"]
	)
	hideBlizzardRaidFrameManagerCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrameManager = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	local globalScaleSlider = page:CreateControl("Slider", L["Global Scale"])
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

	local outOfRangeAlphaSlider = page:CreateControl("Slider", L["Out of Range Alpha"])
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

	showSoloPartyFrameCheckbox:SetLayoutPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)
	hideBlizzardPartyRaidFramesCheckbox:SetLayoutPoint("TOPLEFT", showSoloPartyFrameCheckbox, "BOTTOMLEFT", 0, -12)
	hideBlizzardRaidFrameManagerCheckbox:SetLayoutPoint("TOPLEFT", hideBlizzardPartyRaidFramesCheckbox, "BOTTOMLEFT", 0, -12)
	globalScaleSlider:SetLayoutPoint("TOPLEFT", showSoloPartyFrameCheckbox, "TOPLEFT", 291, 0)
	outOfRangeAlphaSlider:SetLayoutPoint("TOPLEFT", globalScaleSlider, "BOTTOMLEFT", 0, -12)

	local controls = {
		showSoloPartyFrameCheckbox = showSoloPartyFrameCheckbox,
		hideBlizzardPartyRaidFramesCheckbox = hideBlizzardPartyRaidFramesCheckbox,
		hideBlizzardRaidFrameManagerCheckbox = hideBlizzardRaidFrameManagerCheckbox,
		globalScaleSlider = globalScaleSlider,
		outOfRangeAlphaSlider = outOfRangeAlphaSlider,
	}

	addon.OptionsNew:RegisterForProfileUpdates("general", function(profile)
		UpdateState(controls, profile)
	end)
	UpdateState(controls, addon.Database:GetProfile())

	return page
end
