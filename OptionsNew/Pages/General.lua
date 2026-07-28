local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.General = addon.OptionsNew.Pages.General or {}

local General = addon.OptionsNew.Pages.General

local function GetLanguageOptions()
	local options = {
		{
			value = nil,
			textKey = "Automatic",
		},
	}

	for _, locale in ipairs(addon.Locale:GetAvailableLocales()) do
		options[#options + 1] = {
			value = locale,
			text = addon.Locale:GetLocaleDisplayName(locale),
		}
	end

	return options
end

function General:Create(panel)
	local page = panel:RegisterPage("general", {
		titleKey = "General",
		showHeader = true,
	})
	local subpage = page:RegisterSubPage("general", { titleKey = "General" })

	local languageDropdown = subpage:CreateControl("Dropdown", { labelKey = "Language" })
	languageDropdown:SetLayoutWidth(174)
	languageDropdown:SetOptions(GetLanguageOptions())
	languageDropdown:SetOnValueChanged(function(_, value)
		addon.Locale:SetLocaleOverride(value)
	end)

	local showSoloPartyFrameCheckbox = subpage:CreateControl("Checkbox", { labelKey = "Show Solo Party Frame" })
	showSoloPartyFrameCheckbox:BindValue({
		get = function(profile)
			return profile.core.showSoloPartyFrame
		end,
		set = function(profile, _, value)
			profile.core.showSoloPartyFrame = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("soloFrameChanged")
		end,
	})

	local hideBlizzardPartyRaidFramesCheckbox = subpage:CreateControl(
		"Checkbox",
		{ labelKey = "Hide Blizzard Party/Raid Frames" }
	)
	hideBlizzardPartyRaidFramesCheckbox:BindValue({
		get = function(profile)
			return profile.core.hideBlizzardRaidFrames
		end,
		set = function(profile, _, value)
			profile.core.hideBlizzardRaidFrames = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local hideBlizzardRaidFrameManagerCheckbox = subpage:CreateControl(
		"Checkbox",
		{ labelKey = "Hide Blizzard Raid Frame Manager" }
	)
	hideBlizzardRaidFrameManagerCheckbox:BindValue({
		get = function(profile)
			return profile.core.hideBlizzardRaidFrameManager
		end,
		set = function(profile, _, value)
			profile.core.hideBlizzardRaidFrameManager = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
		end,
	})

	local globalScaleSlider = subpage:CreateControl("Slider", { labelKey = "Global Scale" })
	globalScaleSlider:SetMinMaxValues(0.5, 2.0)
	globalScaleSlider:SetStep(0.01)
	globalScaleSlider:SetValueFormatter(function(value)
		return string.format("%.0f%%", value * 100)
	end)
	globalScaleSlider:SetValueParser("percent")
	globalScaleSlider:BindValue({
		get = function(profile)
			return profile.core.uiScale
		end,
		set = function(profile, _, value)
			profile.core.uiScale = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("layoutChanged")
			addon.Modules:RequestUpdateSettings()
		end,
	})

	local outOfRangeAlphaSlider = subpage:CreateControl("Slider", { labelKey = "Out of Range Alpha" })
	outOfRangeAlphaSlider:SetMinMaxValues(0, 1)
	outOfRangeAlphaSlider:SetStep(0.05)
	outOfRangeAlphaSlider:SetValueFormatter(function(value)
		return string.format("%.0f%%", value * 100)
	end)
	outOfRangeAlphaSlider:SetValueParser("percent")
	outOfRangeAlphaSlider:BindValue({
		get = function(profile)
			return profile.core.outOfRangeAlpha
		end,
		set = function(profile, _, value)
			profile.core.outOfRangeAlpha = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("outOfRangeAlphaSettingChanged")
		end,
	})

	subpage:SetStateUpdater(function()
		languageDropdown:SetOptions(GetLanguageOptions())
		languageDropdown:SetValue(addon.Locale:GetLocaleOverride())
	end)

	languageDropdown:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)
	showSoloPartyFrameCheckbox:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, -72)
	hideBlizzardPartyRaidFramesCheckbox:SetLayoutPoint("TOPLEFT", showSoloPartyFrameCheckbox, "BOTTOMLEFT", 0, -12)
	hideBlizzardRaidFrameManagerCheckbox:SetLayoutPoint("TOPLEFT", hideBlizzardPartyRaidFramesCheckbox, "BOTTOMLEFT", 0, -12)
	globalScaleSlider:SetLayoutPoint("TOPLEFT", showSoloPartyFrameCheckbox, "TOPLEFT", 291, 0)
	outOfRangeAlphaSlider:SetLayoutPoint("TOPLEFT", globalScaleSlider, "BOTTOMLEFT", 0, -12)

	return page
end
