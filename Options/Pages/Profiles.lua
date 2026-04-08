local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Profiles = addon.Options.Pages.Profiles or {}

local Profiles = addon.Options.Pages.Profiles

local page
local theme = addon.Options.Theme

local function BuildProfileOptions()
	local options = {}
	local profileNames = addon.Database:GetProfileNames() or {}

	for value, text in pairs(profileNames) do
		table.insert(options, {
			value = value,
			text = text,
		})
	end

	table.sort(options, function(a, b)
		return string.lower(a.text) < string.lower(b.text)
	end)

	return options
end

function Profiles:Ensure(parent)
	if page then
		return page
	end

	page = CreateFrame("Frame", nil, parent)

	page.title = page:CreateFontString(nil, "OVERLAY")
	page.title:SetJustifyH("LEFT")
	page.title:SetFont(theme.fonts.arialNarrow, 18, "")
	page.title:SetTextColor(0.85, 0.85, 0.88, 1)
	page.title:SetText("Profiles")

	page.activeProfileDropdown = addon.Options.Controls.Dropdown:Create(page, "Active Profile")
	page.activeProfileDropdown:SetOnValueChanged(function(_, value)
		local currentProfile = addon.Database:GetCurrentProfileName() or "Default"

		if value and value ~= currentProfile then
			addon.Database:SetProfile(value)
		end
	end)

	addon.Options.Data:RegisterForUpdates(Profiles, function(profile)
		Profiles:UpdateState(profile)
	end)

	self:UpdateLayout()
	self:UpdateState(addon.Database:GetProfile())

	return page
end

function Profiles:UpdateLayout()
	if not page then
		return
	end

	local layout = addon.Options.Sections.Content:GetLayout()
	local pagePadding = layout.padding
	local firstControlOffset = addon.Utilities:ToUI(addon.Utilities:ToPixels(12))
	local twoColumnControlWidth = layout.twoColumn.controlWidth

	page.title:ClearAllPoints()
	page.title:SetPoint("TOPLEFT", page, "TOPLEFT", pagePadding, -pagePadding)

	page.activeProfileDropdown:SetWidth(twoColumnControlWidth)
	page.activeProfileDropdown:ClearAllPoints()
	page.activeProfileDropdown:SetPoint("TOPLEFT", page.title, "BOTTOMLEFT", 0, -firstControlOffset)
end

function Profiles:UpdateState(profile)
	if not page then
		return
	end

	page.activeProfileDropdown:SetOptions(BuildProfileOptions())
	page.activeProfileDropdown:SetValue(addon.Database:GetCurrentProfileName() or "Default")
end
