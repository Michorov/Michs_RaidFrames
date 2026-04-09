local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}

local Auras = addon.Options.Pages.Auras

local page
local theme = addon.Options.Theme

local subpageOptions = {
	{ value = "buffs", text = "Buffs" },
	{ value = "debuffs", text = "Debuffs" },
	{ value = "dispels", text = "Dispels" },
	{ value = "bigDefensive", text = "Big Defensive" },
	{ value = "privateAuras", text = "Private Auras" },
	{ value = "raidBuffReminder", text = "Raid Buff Reminder" },
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

function Auras:Ensure(parent)
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
	page.title:SetText("Auras")

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
		state.subpages.auras = value
	end)

	page.description = page.body:CreateFontString(nil, "OVERLAY")
	page.description:SetJustifyH("LEFT")
	page.description:SetFont(theme.fonts.arialNarrow, 12, "")
	page.description:SetTextColor(0.65, 0.65, 0.68, 1)
	page.description:SetText("Aura settings will go here.")

	self:UpdateLayout()
	self:UpdateState(addon.Database:GetProfile())

	return page
end

function Auras:UpdateLayout()
	if not page then
		return
	end

	local layout = addon.Options.Sections.Content:GetLayout()
	local pagePadding = layout.padding
	local headerControlGap = addon.Utilities:ToUI(addon.Utilities:ToPixels(8))
	local headerControlWidth = addon.Utilities:ToUI(addon.Utilities:ToPixels(150))
	local headerRowHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(24))
	local toggleWidth = addon.Utilities:ToUI(addon.Utilities:ToPixels(112))
	local firstControlOffset = addon.Utilities:ToUI(addon.Utilities:ToPixels(12))

	page.headerRow:ClearAllPoints()
	page.headerRow:SetPoint("TOPLEFT", page, "TOPLEFT", pagePadding, -pagePadding)
	page.headerRow:SetPoint("TOPRIGHT", page, "TOPRIGHT", -pagePadding, -pagePadding)
	page.headerRow:SetHeight(headerRowHeight)

	page.title:ClearAllPoints()
	page.title:SetPoint("LEFT", page.headerRow, "LEFT", 0, 0)

	page.modeToggle:SetWidth(toggleWidth)
	page.modeToggle:ClearAllPoints()
	page.modeToggle:SetPoint("RIGHT", page.headerRow, "RIGHT", 0, 0)

	page.subpageDropdown:SetWidth(headerControlWidth)
	page.subpageDropdown:ClearAllPoints()
	page.subpageDropdown:SetPoint("RIGHT", page.modeToggle, "LEFT", -headerControlGap, 0)

	page.body:ClearAllPoints()
	page.body:SetPoint("TOPLEFT", page.headerRow, "BOTTOMLEFT", 0, -firstControlOffset)
	page.body:SetPoint("TOPRIGHT", page.headerRow, "BOTTOMRIGHT", 0, -firstControlOffset)
	page.body:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", pagePadding, 0)
	page.body:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -pagePadding, 0)

	page.description:ClearAllPoints()
	page.description:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)
end

function Auras:UpdateState(profile)
	if not page then
		return
	end

	local state = GetControllerState()

	page.modeToggle:SetValue(state.mode or "party")
	page.subpageDropdown:SetOptions(subpageOptions)
	page.subpageDropdown:SetValue(state.subpages.auras or subpageOptions[1].value)
end
