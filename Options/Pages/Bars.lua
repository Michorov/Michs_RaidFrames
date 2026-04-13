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

function Bars:Ensure(parent)
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
	page.header.title:SetText("Bars")

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
	end)

	page.subpageDropdown = addon.Options.Controls.Dropdown:Create(page.header, "")
	page.subpageDropdown:SetLayoutWidth(150)
	page.subpageDropdown:SetLabelVisible(false)
	page.subpageDropdown:SetOptions(subpageOptions)
	page.subpageDropdown:SetOnValueChanged(function(_, value)
		local state = GetControllerState()
		state.subpages.bars = value
	end)

	page.description = page.body:CreateFontString(nil, "OVERLAY")
	page.description:SetPoint("TOPLEFT", page.body, "TOPLEFT", 0, 0)
	page.description:SetJustifyH("LEFT")
	page.description:SetFont(theme.fonts.arialNarrow, 12, "")
	page.description:SetTextColor(theme:GetTextColor("secondary"))
	page.description:SetText("Testing controls for the Bars page live here for now.")

	page.opacityTestColorPicker = addon.Options.Controls.ColorPicker:Create(page.body, "Background Color")
	page.opacityTestColorPicker:SetLayoutWidth(200)
	page.opacityTestColorPicker:SetHasOpacity(true)
	page.opacityTestColorPicker:SetColor(1, 0.62, 0.24, 0.65)

	page.noOpacityTestColorPicker = addon.Options.Controls.ColorPicker:Create(page.body, "Health Color")
	page.noOpacityTestColorPicker:SetLayoutWidth(200)
	page.noOpacityTestColorPicker:SetHasOpacity(false)
	page.noOpacityTestColorPicker:SetColor(0.20, 0.85, 0.35, 1)

	page.controls = {
		modeToggle = page.modeToggle,
		subpageDropdown = page.subpageDropdown,
		opacityTestColorPicker = page.opacityTestColorPicker,
		noOpacityTestColorPicker = page.noOpacityTestColorPicker,
	}

	function page:UpdateLayout()
		local controls = self.controls
		local headerHeightPx = addon.Utilities:ToPixels(32)
		local firstControlOffsetPx = addon.Utilities:ToPixels(16)
		local headerControlGapPx = addon.Utilities:ToPixels(8)
		local bodyRowSpacingPx = addon.Utilities:ToPixels(16)

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

		controls.opacityTestColorPicker:ClearAllPoints()
		controls.opacityTestColorPicker:SetPoint(
			"TOPLEFT",
			self.description,
			"BOTTOMLEFT",
			0,
			-addon.Utilities:ToUI(bodyRowSpacingPx)
		)

		controls.noOpacityTestColorPicker:ClearAllPoints()
		controls.noOpacityTestColorPicker:SetPoint(
			"TOPLEFT",
			controls.opacityTestColorPicker,
			"BOTTOMLEFT",
			0,
			-addon.Utilities:ToUI(bodyRowSpacingPx)
		)
	end

	function page:UpdateState(profile)
		local state = GetControllerState()

		self.modeToggle:SetValue(state.mode or "party")
		self.subpageDropdown:SetOptions(subpageOptions)
		self.subpageDropdown:SetValue(state.subpages.bars or subpageOptions[1].value)
	end

	page:UpdateLayout()
	page:UpdateState(addon.Database:GetProfile())

	return page
end
