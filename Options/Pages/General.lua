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

function General:Ensure(parent)
	if page then
		return page
	end

	page = CreateFrame("Frame", nil, parent)

	page.title = page:CreateFontString(nil, "OVERLAY")
	page.title:SetJustifyH("LEFT")
	page.title:SetFont(theme.fonts.arialNarrow, 18, "")
	page.title:SetTextColor(0.85, 0.85, 0.88, 1)
	page.title:SetText("General")

	page.showSoloPartyFrameCheckbox = addon.Options.Controls.Checkbox:Create(page, "Show Solo Party Frame")
	page.showSoloPartyFrameCheckbox:SetChecked(false)
	page.showSoloPartyFrameCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.showSoloPartyFrame = checked
		addon.UpdateScheduler:Notify("soloFrameChanged")
	end)

	page.hideBlizzardPartyRaidFramesCheckbox =
		addon.Options.Controls.Checkbox:Create(page, "Hide Blizzard Party/Raid Frames")
	page.hideBlizzardPartyRaidFramesCheckbox:SetChecked(false)
	page.hideBlizzardPartyRaidFramesCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrames = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	page.hideBlizzardRaidFrameManagerCheckbox =
		addon.Options.Controls.Checkbox:Create(page, "Hide Blizzard Raid Frame Manager")
	page.hideBlizzardRaidFrameManagerCheckbox:SetChecked(false)
	page.hideBlizzardRaidFrameManagerCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrameManager = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	page.globalScaleSlider = addon.Options.Controls.Slider:Create(page, "Global Scale")
	page.globalScaleSlider:SetMinMaxValues(0.5, 2.0)
	page.globalScaleSlider:SetStep(0.01)
	page.globalScaleSlider:SetValueFormatter(function(value)
		return string.format("%.0f%%", value * 100)
	end)
	page.globalScaleSlider:SetValueParser(ParsePercentOrRaw)
	page.globalScaleSlider:SetOnValueChanged(function(_, value)
		local profile = addon.Database:GetProfile()
		profile.core.uiScale = value
		addon.UpdateScheduler:Notify("layoutChanged")
		addon.Modules:RequestUpdateSettings()
	end)

	page.outOfRangeAlphaSlider = addon.Options.Controls.Slider:Create(page, "Out of Range Alpha")
	page.outOfRangeAlphaSlider:SetMinMaxValues(0, 1)
	page.outOfRangeAlphaSlider:SetStep(0.05)
	page.outOfRangeAlphaSlider:SetValueFormatter(function(value)
		return string.format("%.0f%%", value * 100)
	end)
	page.outOfRangeAlphaSlider:SetValueParser(ParsePercentOrRaw)
	page.outOfRangeAlphaSlider:SetOnValueChanged(function(_, value)
		local profile = addon.Database:GetProfile()
		profile.core.outOfRangeAlpha = value
		addon.UpdateScheduler:Notify("outOfRangeAlphaSettingChanged")
	end)

	addon.Options.Data:RegisterForUpdates(General, function(profile)
		General:UpdateState(profile)
	end)

	self:UpdateLayout()
	self:UpdateState(addon.Database:GetProfile())

	return page
end

function General:UpdateLayout()
	if not page then
		return
	end

	local layout = addon.Options.Sections.Content:GetLayout()
	local pagePadding = layout.padding
	local firstControlOffset = addon.Utilities:ToUI(addon.Utilities:ToPixels(12))
	local rowSpacing = addon.Utilities:ToUI(addon.Utilities:ToPixels(8))
	local rightColumnOffset = layout.twoColumn.startX[2] - layout.twoColumn.startX[1]
	local twoColumnWidth = layout.twoColumn.controlWidth

	page.title:ClearAllPoints()
	page.title:SetPoint("TOPLEFT", page, "TOPLEFT", pagePadding, -pagePadding)

	page.showSoloPartyFrameCheckbox:SetWidth(twoColumnWidth)
	page.showSoloPartyFrameCheckbox:ClearAllPoints()
	page.showSoloPartyFrameCheckbox:SetPoint("TOPLEFT", page.title, "BOTTOMLEFT", 0, -firstControlOffset)

	page.hideBlizzardPartyRaidFramesCheckbox:SetWidth(twoColumnWidth)
	page.hideBlizzardPartyRaidFramesCheckbox:ClearAllPoints()
	page.hideBlizzardPartyRaidFramesCheckbox:SetPoint(
		"TOPLEFT",
		page.showSoloPartyFrameCheckbox,
		"BOTTOMLEFT",
		0,
		-rowSpacing
	)

	page.hideBlizzardRaidFrameManagerCheckbox:SetWidth(twoColumnWidth)
	page.hideBlizzardRaidFrameManagerCheckbox:ClearAllPoints()
	page.hideBlizzardRaidFrameManagerCheckbox:SetPoint(
		"TOPLEFT",
		page.hideBlizzardPartyRaidFramesCheckbox,
		"BOTTOMLEFT",
		0,
		-rowSpacing
	)

	page.globalScaleSlider:ClearAllPoints()
	page.globalScaleSlider:SetPoint(
		"TOPLEFT",
		page.showSoloPartyFrameCheckbox,
		"TOPLEFT",
		rightColumnOffset,
		0
	)

	page.outOfRangeAlphaSlider:ClearAllPoints()
	page.outOfRangeAlphaSlider:SetPoint("TOPLEFT", page.globalScaleSlider, "BOTTOMLEFT", 0, -rowSpacing)
end

function General:UpdateState(profile)
	if not page or not profile or not profile.core then
		return
	end

	page.showSoloPartyFrameCheckbox:SetChecked(profile.core.showSoloPartyFrame == true)
	page.hideBlizzardPartyRaidFramesCheckbox:SetChecked(profile.core.hideBlizzardRaidFrames == true)
	page.hideBlizzardRaidFrameManagerCheckbox:SetChecked(profile.core.hideBlizzardRaidFrameManager == true)
	page.globalScaleSlider:SetValueSilently(profile.core.uiScale or 1)
	page.outOfRangeAlphaSlider:SetValueSilently(profile.core.outOfRangeAlpha or 1)
end
