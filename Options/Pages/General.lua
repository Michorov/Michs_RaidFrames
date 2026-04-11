local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.General = addon.Options.Pages.General or {}

local General = addon.Options.Pages.General

local page
local theme = addon.Options.Theme

local function ParsePercentOrRaw(control, text)
	local sanitizedText = (text or ""):gsub("%s+", ""):gsub(",", ".")
	local hasPercent = sanitizedText:find("%%") ~= nil
	local numericText = sanitizedText:gsub("%%", "")
	local number = tonumber(numericText)

	if not number then
		return nil
	end

	local _, maxValue = control.slider:GetMinMaxValues()

	if hasPercent or number > maxValue then
		return number / 100
	end

	return number
end

local function UpdateLayout()
	if not page then
		return
	end

	local controls = page.controls

	page.header:SetHeight(addon.Utilities:ToUI(addon.Utilities:ToPixels(32)))

	page.body:SetPoint("TOPLEFT", page.header, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(addon.Utilities:ToPixels(16)))
	page.body:SetPoint("TOPRIGHT", page.header, "BOTTOMRIGHT", 0, -addon.Utilities:ToUI(addon.Utilities:ToPixels(16)))

	for _, control in pairs(controls) do
		if control.UpdateLayout then
			control:UpdateLayout()
		end
	end

	controls.showSoloPartyFrameCheckbox:ClearAllPoints()
	controls.showSoloPartyFrameCheckbox:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)

	controls.hideBlizzardPartyRaidFramesCheckbox:ClearAllPoints()
	controls.hideBlizzardPartyRaidFramesCheckbox:SetPoint(
		"TOPLEFT",
		controls.showSoloPartyFrameCheckbox,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(addon.Utilities:ToPixels(12))
	)

	controls.hideBlizzardRaidFrameManagerCheckbox:ClearAllPoints()
	controls.hideBlizzardRaidFrameManagerCheckbox:SetPoint(
		"TOPLEFT",
		controls.hideBlizzardPartyRaidFramesCheckbox,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(addon.Utilities:ToPixels(12))
	)

	controls.globalScaleSlider:ClearAllPoints()
	controls.globalScaleSlider:SetPoint(
		"TOPLEFT",
		controls.showSoloPartyFrameCheckbox,
		"TOPLEFT",
		addon.Utilities:ToUI(addon.Utilities:ToPixels(291)),
		0
	)

	controls.outOfRangeAlphaSlider:ClearAllPoints()
	controls.outOfRangeAlphaSlider:SetPoint(
		"TOPLEFT",
		controls.globalScaleSlider,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(addon.Utilities:ToPixels(16))
	)
end

local function UpdateState(profile)
	if not page or not profile or not profile.core then
		return
	end

	local controls = page.controls

	controls.showSoloPartyFrameCheckbox:SetChecked(profile.core.showSoloPartyFrame == true)
	controls.hideBlizzardPartyRaidFramesCheckbox:SetChecked(profile.core.hideBlizzardRaidFrames == true)
	controls.hideBlizzardRaidFrameManagerCheckbox:SetChecked(profile.core.hideBlizzardRaidFrameManager == true)
	controls.globalScaleSlider:SetValueSilently(profile.core.uiScale or 1)
	controls.outOfRangeAlphaSlider:SetValueSilently(profile.core.outOfRangeAlpha or 1)
end

function General:Ensure(parent)
	if page then
		return page
	end

	page = CreateFrame("Frame", nil, parent)
	page.header = CreateFrame("Frame", nil, page)
	page.header:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
	page.header:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)

	page.body = CreateFrame("Frame", nil, page)
	page.body:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
	page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

	page.header.title = page.header:CreateFontString(nil, "OVERLAY")
	page.header.title:SetPoint("LEFT", page.header, "LEFT", 0, 0)
	page.header.title:SetJustifyH("LEFT")
	page.header.title:SetFont(theme.fonts.arialNarrow, 20, "")
	page.header.title:SetTextColor(theme:GetTextColor("highlight"))
	page.header.title:SetText("General")

	local showSoloPartyFrameCheckbox = addon.Options.Controls.Checkbox:Create(page.body, "Show Solo Party Frame")
	showSoloPartyFrameCheckbox:SetChecked(false)
	showSoloPartyFrameCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.showSoloPartyFrame = checked
		addon.UpdateScheduler:Notify("soloFrameChanged")
	end)

	local hideBlizzardPartyRaidFramesCheckbox =
		addon.Options.Controls.Checkbox:Create(page.body, "Hide Blizzard Party/Raid Frames")
	hideBlizzardPartyRaidFramesCheckbox:SetChecked(false)
	hideBlizzardPartyRaidFramesCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrames = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	local hideBlizzardRaidFrameManagerCheckbox =
		addon.Options.Controls.Checkbox:Create(page.body, "Hide Blizzard Raid Frame Manager")
	hideBlizzardRaidFrameManagerCheckbox:SetChecked(false)
	hideBlizzardRaidFrameManagerCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrameManager = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	local globalScaleSlider = addon.Options.Controls.Slider:Create(page.body, "Global Scale")
	globalScaleSlider:SetMinMaxValues(0.5, 2.0)
	globalScaleSlider:SetStep(0.01)
	globalScaleSlider:SetValueFormatter(function(value)
		return string.format("%.0f%%", value * 100)
	end)
	globalScaleSlider:SetValueParser(ParsePercentOrRaw)
	globalScaleSlider:SetOnValueChanged(function(_, value)
		local profile = addon.Database:GetProfile()
		profile.core.uiScale = value
		addon.UpdateScheduler:Notify("layoutChanged")
		addon.Modules:RequestUpdateSettings()
	end)

	local outOfRangeAlphaSlider = addon.Options.Controls.Slider:Create(page.body, "Out of Range Alpha")
	outOfRangeAlphaSlider:SetMinMaxValues(0, 1)
	outOfRangeAlphaSlider:SetStep(0.05)
	outOfRangeAlphaSlider:SetValueFormatter(function(value)
		return string.format("%.0f%%", value * 100)
	end)
	outOfRangeAlphaSlider:SetValueParser(ParsePercentOrRaw)
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

	function page:UpdateLayout()
		UpdateLayout()
	end

	function page:UpdateState(profile)
		UpdateState(profile)
	end

	addon.Options.Data:RegisterForUpdates(page, function(profile)
		page:UpdateState(profile)
	end)

	page:UpdateLayout()
	page:UpdateState(addon.Database:GetProfile())

	return page
end
