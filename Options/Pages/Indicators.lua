local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Indicators = addon.Options.Pages.Indicators or {}

local Indicators = addon.Options.Pages.Indicators

local page
local theme = addon.Options.Theme

local subpageOptions = {
	{ value = "readyCheck", text = "Ready Check" },
	{ value = "raidMarker", text = "Raid Marker" },
	{ value = "roleIcon", text = "Role Indicator" },
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
	local subpageKey = (state.subpages or {}).indicators or subpageOptions[1].value

	for _, option in ipairs(subpageOptions) do
		if option.value == subpageKey then
			return subpageKey
		end
	end

	return subpageOptions[1].value
end

function Indicators:Ensure(parent)
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
	page.header.title:SetText("Indicators")

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
		state.subpages.indicators = value
		if page and page.SetActiveSubpage then
			page:SetActiveSubpage(value, addon.Database:GetProfile())
		end
	end)

	local readyCheckSubpage = addon.Options.Pages.Indicators.ReadyCheck:Ensure(page.body)
	local raidMarkerSubpage = addon.Options.Pages.Indicators.RaidMarker:Ensure(page.body)
	local roleIndicatorSubpage = addon.Options.Pages.Indicators.RoleIndicator:Ensure(page.body)

	page.subpages = {
		readyCheck = readyCheckSubpage,
		raidMarker = raidMarkerSubpage,
		roleIcon = roleIndicatorSubpage,
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

		state.subpages.indicators = activeSubpageKey

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
