local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}

local Bars = addon.Options.Pages.Bars

local page
local theme = addon.Options.Theme

local subpageOptions = {
	{ value = "absorbs", text = "Absorbs" },
	{ value = "healAbsorbs", text = "Heal Absorbs" },
	{ value = "buffOverlay", text = "Buff Overlay" },
}

local function GetControllerState()
	local content = addon.Options.Sections.Content
	if content and content.GetControllerState then
		return content:GetControllerState()
	end

	addon.Options.ControllerState = addon.Options.ControllerState or {
		mode = "party",
		subpages = {
			auras = "buffs",
			texts = "name",
			indicators = "readyCheck",
			bars = "absorbs",
		},
	}

	return addon.Options.ControllerState
end

function Bars:Ensure(parent)
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
	page.title:SetText("Bars")

	page.modeToggle = addon.Options.Controls.SegmentedToggle:Create(
		page.headerRow,
		{ value = "party", text = "Party" },
		{ value = "raid", text = "Raid" }
	)
	page.modeToggle:SetOnValueChanged(function(_, value)
		local state = GetControllerState()
		state.mode = value
	end)

	page.subpageDropdown = addon.Options.Controls.Dropdown:Create(page.headerRow, "")
	page.subpageDropdown:SetLabelVisible(false)
	page.subpageDropdown:SetOptions(subpageOptions)
	page.subpageDropdown:SetOnValueChanged(function(_, value)
		local state = GetControllerState()
		state.subpages.bars = value
	end)

	page.description = page.body:CreateFontString(nil, "OVERLAY")
	page.description:SetJustifyH("LEFT")
	page.description:SetFont(theme.fonts.arialNarrow, 12, "")
	page.description:SetTextColor(0.65, 0.65, 0.68, 1)
	page.description:SetText("Testing controls for the Bars page live here for now.")

	page.opacityTestColorPicker = addon.Options.Controls.ColorPicker:Create(page.body, "Background Color")
	page.opacityTestColorPicker:SetHasOpacity(true)
	page.opacityTestColorPicker:SetColor(1, 0.62, 0.24, 0.65)

	page.noOpacityTestColorPicker = addon.Options.Controls.ColorPicker:Create(page.body, "Health Color")
	page.noOpacityTestColorPicker:SetHasOpacity(false)
	page.noOpacityTestColorPicker:SetColor(0.20, 0.85, 0.35, 1)

	self:UpdateLayout()
	self:UpdateState(addon.Database:GetProfile())

	return page
end

function Bars:UpdateLayout()
	if not page then
		return
	end

	local layout = addon.Options.Sections.Content:GetLayout()
	local pagePaddingPx = layout.paddingPx
	local headerControlGapPx = addon.Utilities:ToPixels(8)
	local headerControlWidthPx = addon.Utilities:ToPixels(150)
	local headerRowHeightPx = addon.Utilities:ToPixels(24)
	local toggleWidthPx = addon.Utilities:ToPixels(112)
	local firstControlOffsetPx = addon.Utilities:ToPixels(12)
	local bodyRowSpacingPx = addon.Utilities:ToPixels(16)
	local testControlWidthPx = layout.twoColumn.controlWidthPx

	page.headerRow:ClearAllPoints()
	page.headerRow:SetPoint("TOPLEFT", page, "TOPLEFT", addon.Utilities:ToUI(pagePaddingPx), -addon.Utilities:ToUI(pagePaddingPx))
	page.headerRow:SetPoint("TOPRIGHT", page, "TOPRIGHT", -addon.Utilities:ToUI(pagePaddingPx), -addon.Utilities:ToUI(pagePaddingPx))
	page.headerRow:SetHeight(addon.Utilities:ToUI(headerRowHeightPx))

	page.title:ClearAllPoints()
	page.title:SetPoint("LEFT", page.headerRow, "LEFT", 0, 0)

	page.modeToggle:SetWidth(addon.Utilities:ToUI(toggleWidthPx))
	page.modeToggle:ClearAllPoints()
	page.modeToggle:SetPoint("RIGHT", page.headerRow, "RIGHT", 0, 0)

	page.subpageDropdown:SetWidth(addon.Utilities:ToUI(headerControlWidthPx))
	page.subpageDropdown:ClearAllPoints()
	page.subpageDropdown:SetPoint("RIGHT", page.modeToggle, "LEFT", -addon.Utilities:ToUI(headerControlGapPx), 0)

	page.body:ClearAllPoints()
	page.body:SetPoint("TOPLEFT", page.headerRow, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))
	page.body:SetPoint("TOPRIGHT", page.headerRow, "BOTTOMRIGHT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))
	page.body:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", addon.Utilities:ToUI(pagePaddingPx), 0)
	page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -addon.Utilities:ToUI(pagePaddingPx), 0)

	page.description:ClearAllPoints()
	page.description:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)

	page.opacityTestColorPicker:SetWidth(addon.Utilities:ToUI(testControlWidthPx))
	page.opacityTestColorPicker:ClearAllPoints()
	page.opacityTestColorPicker:SetPoint("TOPLEFT", page.description, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(bodyRowSpacingPx))

	page.noOpacityTestColorPicker:SetWidth(addon.Utilities:ToUI(testControlWidthPx))
	page.noOpacityTestColorPicker:ClearAllPoints()
	page.noOpacityTestColorPicker:SetPoint(
		"TOPLEFT",
		page.opacityTestColorPicker,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(bodyRowSpacingPx)
	)
end

function Bars:UpdateState(profile)
	if not page then
		return
	end

	local state = GetControllerState()

	page.modeToggle:SetValue(state.mode or "party")
	page.subpageDropdown:SetOptions(subpageOptions)
	page.subpageDropdown:SetValue(state.subpages.bars or subpageOptions[1].value)
end
