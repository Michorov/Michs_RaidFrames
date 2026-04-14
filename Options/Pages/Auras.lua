local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}

local Auras = addon.Options.Pages.Auras

local page
local theme = addon.Options.Theme

local subpageOptions = {
	{ value = "buffs", text = "Buffs" },
	{ value = "buffFilters", text = "Buffs - Filters" },
	{ value = "buffOverlay", text = "Buffs - Overlay" },
	{ value = "buffCustomIcons", text = "Buffs - Custom Icons" },
	{ value = "debuffs", text = "Debuffs" },
	{ value = "dispels", text = "Dispels" },
	{ value = "bigDefensive", text = "Big Defensive" },
	{ value = "privateAuras", text = "Private Auras" },
	{ value = "raidBuffReminder", text = "Raid Buff Reminder" },
}

local specHeaderSubpages = {
	buffFilters = true,
	buffOverlay = true,
	buffCustomIcons = true,
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
				bars = "health",
			},
		}

	return addon.Options.ControllerState
end

local function GetActiveSubpageKey()
	local state = GetControllerState()
	local subpageKey = (state.subpages or {}).auras or subpageOptions[1].value

	for _, option in ipairs(subpageOptions) do
		if option.value == subpageKey then
			return subpageKey
		end
	end

	return subpageOptions[1].value
end

function Auras:Ensure(parent)
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
	page.header.title:SetText("Auras")

	page.modeToggle = addon.Options.Controls.SegmentedToggle:Create(
		page.header,
		{ value = "party", text = "Party" },
		{ value = "raid", text = "Raid" }
	)
	page.modeToggle:SetLayoutSize(112, 24)
	page.modeToggle:SetPoint("RIGHT", page.header, "RIGHT", 0, 0)
	page.modeToggle:SetOnValueChanged(function(_, value)
		local state = GetControllerState()
		state.mode = value
		if page and page.UpdateLayout then
			page:UpdateLayout()
		end
		if page and page.UpdateState then
			page:UpdateState(addon.Database:GetProfile())
		end
	end)

	page.subpageDropdown = addon.Options.Controls.Dropdown:Create(page.header, "")
	page.subpageDropdown:SetLayoutWidth(174)
	page.subpageDropdown:SetLabelVisible(false)
	page.subpageDropdown:SetOptions(subpageOptions)
	page.subpageDropdown:SetOnValueChanged(function(_, value)
		local state = GetControllerState()
		state.subpages.auras = value
		if page and page.SetActiveSubpage then
			page:SetActiveSubpage(value, addon.Database:GetProfile())
		end
	end)

	local buffsSubpage = addon.Options.Pages.Auras.Buffs:Ensure(page.body)
	local buffFiltersSubpage = addon.Options.Pages.Auras.BuffFilters:Ensure(page.body)
	local buffOverlaySubpage = addon.Options.Pages.Auras.BuffOverlay:Ensure(page.body)
	local buffCustomIconsSubpage = addon.Options.Pages.Auras.BuffCustomIcons:Ensure(page.body)
	local debuffsSubpage = addon.Options.Pages.Auras.Debuffs:Ensure(page.body)
	local dispelsSubpage = addon.Options.Pages.Auras.Dispels:Ensure(page.body)
	local bigDefensiveSubpage = addon.Options.Pages.Auras.BigDefensive:Ensure(page.body)
	local privateAurasSubpage = addon.Options.Pages.Auras.PrivateAuras:Ensure(page.body)
	local raidBuffReminderSubpage = addon.Options.Pages.Auras.RaidBuffReminder:Ensure(page.body)

	page.subpages = {
		buffs = buffsSubpage,
		buffFilters = buffFiltersSubpage,
		buffOverlay = buffOverlaySubpage,
		buffCustomIcons = buffCustomIconsSubpage,
		debuffs = debuffsSubpage,
		dispels = dispelsSubpage,
		bigDefensive = bigDefensiveSubpage,
		privateAuras = privateAurasSubpage,
		raidBuffReminder = raidBuffReminderSubpage,
	}

	for subpageKey, subpage in pairs(page.subpages) do
		subpage:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)
		subpage:SetPoint("TOPRIGHT", page.body, "TOPRIGHT", 0, 0)
		subpage:SetPoint("BOTTOMLEFT", page.body, "BOTTOMLEFT", 0, 0)
		subpage:SetPoint("BOTTOMRIGHT", page.body, "BOTTOMRIGHT", 0, 0)
		subpage:SetShown(subpageKey == GetActiveSubpageKey())
	end

	page.controls = {
		modeToggle = page.modeToggle,
		subpageDropdown = page.subpageDropdown,
	}

	function page:UpdateHeaderTitle()
		local activeSubpageKey = GetActiveSubpageKey()
		local title = "Auras"
		local activeSubpage = self.subpages and self.subpages[activeSubpageKey]
		local specName = activeSubpage and activeSubpage.activeSpecName or nil

		if specHeaderSubpages[activeSubpageKey] and specName then
			title = "Auras - " .. specName
		end

		self.header.title:SetText(title)
	end

	function page:SetActiveSubpage(subpageKey, profile)
		local state = GetControllerState()
		state.subpages = state.subpages or {}

		local activeSubpageKey = subpageOptions[1].value
		for _, option in ipairs(subpageOptions) do
			if option.value == subpageKey then
				activeSubpageKey = subpageKey
				break
			end
		end

		state.subpages.auras = activeSubpageKey

		for key, subpage in pairs(self.subpages) do
			subpage:SetShown(key == activeSubpageKey)
		end

		local activeSubpage = self.subpages[activeSubpageKey]
		if activeSubpage and activeSubpage.UpdateLayout then
			activeSubpage:UpdateLayout()
		end

		if activeSubpage and activeSubpage.UpdateState then
			activeSubpage:UpdateState(profile)
		end

		self:UpdateHeaderTitle()
	end

	function page:UpdateLayout()
		local controls = self.controls
		local headerHeightPx = addon.Utilities:ToPixels(32)
		local firstControlOffsetPx = addon.Utilities:ToPixels(16)
		local headerControlGapPx = addon.Utilities:ToPixels(8)

		self.header:SetHeight(addon.Utilities:ToUI(headerHeightPx))

		self.body:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))
		self.body:SetPoint("TOPRIGHT", self.header, "BOTTOMRIGHT", 0, -addon.Utilities:ToUI(firstControlOffsetPx))

		for _, control in pairs(controls) do
			if control.UpdateLayout then
				control:UpdateLayout()
			end
		end

		controls.subpageDropdown:ClearAllPoints()
		controls.subpageDropdown:SetPoint(
			"RIGHT",
			controls.modeToggle,
			"LEFT",
			-addon.Utilities:ToUI(headerControlGapPx),
			0
		)

		for _, subpage in pairs(self.subpages) do
			if subpage.UpdateLayout then
				subpage:UpdateLayout()
			end
		end
	end

	function page:UpdateState(profile)
		local state = GetControllerState()
		local activeSubpageKey = GetActiveSubpageKey()

		self.modeToggle:SetValue(state.mode or "party")
		self.subpageDropdown:SetOptions(subpageOptions)
		self.subpageDropdown:SetValue(activeSubpageKey)
		self:SetActiveSubpage(activeSubpageKey, profile)
		self:UpdateHeaderTitle()
	end

	addon.Options.Data:RegisterForUpdates(page, function(profile)
		page:UpdateState(profile)
	end)

	for _, subpage in pairs(page.subpages) do
		local registeredSubpage = subpage
		addon.Options.Data:RegisterForUpdates(registeredSubpage, function(profile)
			if registeredSubpage.UpdateState then
				registeredSubpage:UpdateState(profile)
			end
		end)
	end

	page:UpdateLayout()
	page:UpdateState(addon.Database:GetProfile())

	return page
end
