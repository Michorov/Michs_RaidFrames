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
	page.headerRow = CreateFrame("Frame", nil, page)
	page.body = CreateFrame("Frame", nil, page)

	page.title = page.headerRow:CreateFontString(nil, "OVERLAY")
	page.title:SetJustifyH("LEFT")
	page.title:SetFont(theme.fonts.arialNarrow, 20, "")
	page.title:SetTextColor(0.88, 0.89, 0.92, 1)
	page.title:SetText("General")

	page.showSoloPartyFrameCheckbox = addon.Options.Controls.Checkbox:Create(page.body, "Show Solo Party Frame")
	page.showSoloPartyFrameCheckbox:SetChecked(false)
	page.showSoloPartyFrameCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.showSoloPartyFrame = checked
		addon.UpdateScheduler:Notify("soloFrameChanged")
	end)

	page.hideBlizzardPartyRaidFramesCheckbox =
		addon.Options.Controls.Checkbox:Create(page.body, "Hide Blizzard Party/Raid Frames")
	page.hideBlizzardPartyRaidFramesCheckbox:SetChecked(false)
	page.hideBlizzardPartyRaidFramesCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrames = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	page.hideBlizzardRaidFrameManagerCheckbox =
		addon.Options.Controls.Checkbox:Create(page.body, "Hide Blizzard Raid Frame Manager")
	page.hideBlizzardRaidFrameManagerCheckbox:SetChecked(false)
	page.hideBlizzardRaidFrameManagerCheckbox:SetOnValueChanged(function(_, checked)
		local profile = addon.Database:GetProfile()
		profile.core.hideBlizzardRaidFrameManager = checked
		addon.UpdateScheduler:Notify("layoutChanged")
	end)

	page.globalScaleSlider = addon.Options.Controls.Slider:Create(page.body, "Global Scale")
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

	page.outOfRangeAlphaSlider = addon.Options.Controls.Slider:Create(page.body, "Out of Range Alpha")
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
	local pagePaddingPx = layout.paddingPx
	local headerRowHeightPx = addon.Utilities:ToPixels(24)
	local firstControlOffsetPx = addon.Utilities:ToPixels(24)
	local rowSpacingPx = addon.Utilities:ToPixels(8)
	local rightColumnOffsetPx = layout.twoColumn.startXPx[2] - layout.twoColumn.startXPx[1]
	local twoColumnWidthPx = layout.twoColumn.controlWidthPx

	page.headerRow:ClearAllPoints()
	page.headerRow:SetPoint("TOPLEFT", page, "TOPLEFT", addon.Utilities:ToUI(pagePaddingPx), -addon.Utilities:ToUI(pagePaddingPx))
	page.headerRow:SetPoint("TOPRIGHT", page, "TOPRIGHT", -addon.Utilities:ToUI(pagePaddingPx), -addon.Utilities:ToUI(pagePaddingPx))
	page.headerRow:SetHeight(addon.Utilities:ToUI(headerRowHeightPx))

	page.title:ClearAllPoints()
	page.title:SetPoint("LEFT", page.headerRow, "LEFT", 0, 0)

	page.body:ClearAllPoints()
	page.body:SetPoint("TOPLEFT", page.headerRow, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))
	page.body:SetPoint("TOPRIGHT", page.headerRow, "BOTTOMRIGHT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))
	page.body:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", addon.Utilities:ToUI(pagePaddingPx), 0)
	page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -addon.Utilities:ToUI(pagePaddingPx), 0)

	page.showSoloPartyFrameCheckbox:SetWidth(addon.Utilities:ToUI(twoColumnWidthPx))
	page.showSoloPartyFrameCheckbox:ClearAllPoints()
	page.showSoloPartyFrameCheckbox:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)

	page.hideBlizzardPartyRaidFramesCheckbox:SetWidth(addon.Utilities:ToUI(twoColumnWidthPx))
	page.hideBlizzardPartyRaidFramesCheckbox:ClearAllPoints()
	page.hideBlizzardPartyRaidFramesCheckbox:SetPoint(
		"TOPLEFT",
		page.showSoloPartyFrameCheckbox,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(rowSpacingPx)
	)

	page.hideBlizzardRaidFrameManagerCheckbox:SetWidth(addon.Utilities:ToUI(twoColumnWidthPx))
	page.hideBlizzardRaidFrameManagerCheckbox:ClearAllPoints()
	page.hideBlizzardRaidFrameManagerCheckbox:SetPoint(
		"TOPLEFT",
		page.hideBlizzardPartyRaidFramesCheckbox,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(rowSpacingPx)
	)

	page.globalScaleSlider:ClearAllPoints()
	page.globalScaleSlider:SetPoint(
		"TOPLEFT",
		page.showSoloPartyFrameCheckbox,
		"TOPLEFT",
		addon.Utilities:ToUI(rightColumnOffsetPx),
		0
	)

	page.outOfRangeAlphaSlider:ClearAllPoints()
	page.outOfRangeAlphaSlider:SetPoint("TOPLEFT", page.globalScaleSlider, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(rowSpacingPx))
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
