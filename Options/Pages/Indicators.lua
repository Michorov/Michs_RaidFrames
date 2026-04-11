local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}

local Indicators = addon.Options.Pages.Indicators

local page
local theme = addon.Options.Theme

local subpageOptions = {
	{ value = "readyCheck", text = "Ready Check" },
	{ value = "pendingSummon", text = "Pending Summon" },
	{ value = "raidMarker", text = "Raid Marker" },
	{ value = "roleIcon", text = "Role Icon" },
}

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
				bars = "absorbs",
			},
		}

	return addon.Options.ControllerState
end

local function UpdateLayout()
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

	page.headerRow:ClearAllPoints()
	page.headerRow:SetPoint(
		"TOPLEFT",
		page,
		"TOPLEFT",
		addon.Utilities:ToUI(pagePaddingPx),
		-addon.Utilities:ToUI(pagePaddingPx)
	)
	page.headerRow:SetPoint(
		"TOPRIGHT",
		page,
		"TOPRIGHT",
		-addon.Utilities:ToUI(pagePaddingPx),
		-addon.Utilities:ToUI(pagePaddingPx)
	)
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
end

local function UpdateState(profile)
	if not page then
		return
	end

	local state = GetControllerState()

	page.modeToggle:SetValue(state.mode or "party")
	page.subpageDropdown:SetOptions(subpageOptions)
	page.subpageDropdown:SetValue(state.subpages.indicators or subpageOptions[1].value)
end

function Indicators:Ensure(parent)
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
	page.title:SetText("Indicators")

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
		state.subpages.indicators = value
	end)

	page.description = page.body:CreateFontString(nil, "OVERLAY")
	page.description:SetJustifyH("LEFT")
	page.description:SetFont(theme.fonts.arialNarrow, 12, "")
	page.description:SetTextColor(0.65, 0.65, 0.68, 1)
	page.description:SetText("Indicator settings will go here.")

	function page:UpdateLayout()
		--UpdateLayout()
	end

	function page:UpdateState(profile)
		UpdateState(profile)
	end

	page:UpdateLayout()
	page:UpdateState(addon.Database:GetProfile())

	return page
end
