local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.General = addon.Options.Pages.General or {}

local General = addon.Options.Pages.General

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

	local textureDropdown = subpage:CreateControl("Dropdown", { labelKey = "Global Texture" })
	textureDropdown:SetLayoutWidth(174)
	textureDropdown:SetOptions(addon.Styles.Textures:GetOptions())
	textureDropdown:BindValue({
		get = function(profile)
			return profile.core.lsmTexture
		end,
		set = function(profile, _, value)
			profile.core.lsmTexture = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthSettingsChanged")
		end,
	})

	local fontDropdown = subpage:CreateControl("Dropdown", { labelKey = "Global Font" })
	fontDropdown:SetLayoutWidth(174)
	fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions())
	fontDropdown:BindValue({
		get = function(profile)
			return profile.core.lsmFont
		end,
		set = function(profile, _, value)
			profile.core.lsmFont = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("nameSettingsChanged")
		end,
	})

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

	local hideBlizzardPartyRaidFramesCheckbox =
		subpage:CreateControl("Checkbox", { labelKey = "Hide Blizzard Party/Raid Frames" })
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

	local hideBlizzardRaidFrameManagerCheckbox =
		subpage:CreateControl("Checkbox", { labelKey = "Hide Blizzard Raid Frame Manager" })
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
		textureDropdown:SetOptions(addon.Styles.Textures:GetOptions(addon.Database:GetProfile().core.lsmTexture))
		fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions(addon.Database:GetProfile().core.lsmFont))
	end)

	languageDropdown:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)
	textureDropdown:SetLayoutPoint("TOPLEFT", languageDropdown, "BOTTOMLEFT", 0, -32)
	fontDropdown:SetLayoutPoint("TOPLEFT", textureDropdown, "TOPLEFT", 291, 0)
	showSoloPartyFrameCheckbox:SetLayoutPoint("TOPLEFT", textureDropdown, "BOTTOMLEFT", 0, -32)
	hideBlizzardPartyRaidFramesCheckbox:SetLayoutPoint("TOPLEFT", showSoloPartyFrameCheckbox, "BOTTOMLEFT", 0, -12)
	hideBlizzardRaidFrameManagerCheckbox:SetLayoutPoint(
		"TOPLEFT",
		hideBlizzardPartyRaidFramesCheckbox,
		"BOTTOMLEFT",
		0,
		-12
	)
	globalScaleSlider:SetLayoutPoint("TOPLEFT", showSoloPartyFrameCheckbox, "TOPLEFT", 291, 0)
	outOfRangeAlphaSlider:SetLayoutPoint("TOPLEFT", globalScaleSlider, "BOTTOMLEFT", 0, -12)

	return page
end
