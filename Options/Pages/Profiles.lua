local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Profiles = addon.Options.Pages.Profiles or {}

local Profiles = addon.Options.Pages.Profiles

local page
local theme = addon.Options.Theme

local function PrintProfileMsg(message)
	print("|cffff9900Mich's RaidFrames:|r " .. message)
end

local function Trim(text)
	if type(text) ~= "string" then
		return ""
	end

	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function BuildProfileOptions(includeDefault)
	local options = {}
	local profileNames = addon.Database:GetProfileNames() or {}

	for value, text in pairs(profileNames) do
		if includeDefault or value ~= "Default" then
			table.insert(options, {
				value = value,
				text = text,
			})
		end
	end

	table.sort(options, function(a, b)
		return string.lower(a.text) < string.lower(b.text)
	end)

	return options
end

local function CreateProfileFromInput()
	if not page or not page.newProfileInput then
		return
	end

	local name = Trim(page.newProfileInput:GetText())

	if name == "" then
		PrintProfileMsg("Enter a profile name first.")
		return
	end

	if addon.Database:HasProfile(name) then
		PrintProfileMsg("Profile '" .. name .. "' already exists.")
		return
	end

	addon.Database:SetProfile(name)
	page.newProfileInput:SetText("")
	PrintProfileMsg("Created and switched to '" .. name .. "'.")
end

local function CopyProfileFromInput()
	if not page or not page.copyFromDropdown or not page.copyProfileInput then
		return
	end

	if InCombatLockdown() then
		PrintProfileMsg("Layout changes are disabled during combat.")
		return
	end

	local source = page.copyFromDropdown:GetValue()
	local name = Trim(page.copyProfileInput:GetText())

	if not source or source == "" then
		PrintProfileMsg("Select a source profile.")
		return
	end

	if name == "" then
		PrintProfileMsg("Enter a new profile name.")
		return
	end

	if addon.Database:HasProfile(name) then
		PrintProfileMsg("Profile '" .. name .. "' already exists.")
		return
	end

	addon.Database:SetProfile(name)
	addon.Database:CopyProfile(source)

	page.copyProfileInput:SetText("")
	page.copyFromDropdown:SetValue(nil)

	PrintProfileMsg("Created '" .. name .. "' by copying '" .. source .. "'.")
end

local function DeleteSelectedProfile()
	if not page or not page.deleteProfileDropdown then
		return
	end

	if InCombatLockdown() then
		PrintProfileMsg("Layout changes are disabled during combat.")
		return
	end

	local target = page.deleteProfileDropdown:GetValue()

	if not target or target == "" then
		PrintProfileMsg("Select a profile to delete.")
		return
	end

	if target == "Default" then
		PrintProfileMsg("Default profile cannot be deleted.")
		return
	end

	if not addon.Database:HasProfile(target) then
		PrintProfileMsg("Profile '" .. target .. "' does not exist.")
		return
	end

	local current = addon.Database:GetCurrentProfileName()
	if current == target then
		addon.Database:SetProfile("Default")
	end

	addon.Database:DeleteProfile(target)
	page.deleteProfileDropdown:SetValue(nil)

	PrintProfileMsg("Deleted profile '" .. target .. "'.")
end

local function UpdateLayout()
	if not page then
		return
	end

	local layout = addon.Options.Sections.Content:GetLayout()
	local pagePaddingPx = layout.paddingPx
	local sectionSpacingPx = addon.Utilities:ToPixels(24)
	local sectionControlOffsetPx = addon.Utilities:ToPixels(10)
	local controlWidthPx = addon.Utilities:ToPixels(200)
	local controlGapPx = addon.Utilities:ToPixels(1)
	local buttonWidthPx = addon.Utilities:ToPixels(48)
	local buttonHeightPx = addon.Utilities:ToPixels(24)

	page.activeSectionTitle:ClearAllPoints()
	page.activeSectionTitle:SetPoint(
		"TOPLEFT",
		page,
		"TOPLEFT",
		addon.Utilities:ToUI(pagePaddingPx),
		-addon.Utilities:ToUI(pagePaddingPx)
	)

	page.activeProfileDropdown:SetWidth(addon.Utilities:ToUI(controlWidthPx))
	page.activeProfileDropdown:ClearAllPoints()
	page.activeProfileDropdown:SetPoint(
		"TOPLEFT",
		page.activeSectionTitle,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionControlOffsetPx)
	)

	page.createSectionTitle:ClearAllPoints()
	page.createSectionTitle:SetPoint(
		"TOPLEFT",
		page.activeProfileDropdown,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionSpacingPx)
	)

	page.newProfileInput:SetWidth(addon.Utilities:ToUI(controlWidthPx))
	page.newProfileInput:ClearAllPoints()
	page.newProfileInput:SetPoint(
		"TOPLEFT",
		page.createSectionTitle,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionControlOffsetPx)
	)

	page.createProfileButton:ClearAllPoints()
	page.createProfileButton:SetSize(addon.Utilities:ToUI(buttonWidthPx), addon.Utilities:ToUI(buttonHeightPx))
	page.createProfileButton:SetPoint(
		"TOPLEFT",
		page.newProfileInput.field,
		"TOPRIGHT",
		addon.Utilities:ToUI(controlGapPx),
		0
	)

	page.copySectionTitle:ClearAllPoints()
	page.copySectionTitle:SetPoint(
		"TOPLEFT",
		page.newProfileInput,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionSpacingPx)
	)

	page.copyFromDropdown:SetWidth(addon.Utilities:ToUI(controlWidthPx))
	page.copyFromDropdown:ClearAllPoints()
	page.copyFromDropdown:SetPoint(
		"TOPLEFT",
		page.copySectionTitle,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionControlOffsetPx)
	)

	page.copyProfileInput:SetWidth(addon.Utilities:ToUI(controlWidthPx))
	page.copyProfileInput:ClearAllPoints()
	page.copyProfileInput:SetPoint("TOPLEFT", page.copyFromDropdown, "TOPRIGHT", addon.Utilities:ToUI(controlGapPx), 0)

	page.copyProfileButton:ClearAllPoints()
	page.copyProfileButton:SetSize(addon.Utilities:ToUI(buttonWidthPx), addon.Utilities:ToUI(buttonHeightPx))
	page.copyProfileButton:SetPoint("TOPLEFT", page.copyProfileInput, "TOPRIGHT", addon.Utilities:ToUI(controlGapPx), 0)

	page.deleteSectionTitle:ClearAllPoints()
	page.deleteSectionTitle:SetPoint(
		"TOPLEFT",
		page.copyFromDropdown,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionSpacingPx)
	)

	page.deleteProfileDropdown:SetWidth(addon.Utilities:ToUI(controlWidthPx))
	page.deleteProfileDropdown:ClearAllPoints()
	page.deleteProfileDropdown:SetPoint(
		"TOPLEFT",
		page.deleteSectionTitle,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionControlOffsetPx)
	)

	page.deleteProfileButton:ClearAllPoints()
	page.deleteProfileButton:SetSize(addon.Utilities:ToUI(buttonWidthPx), addon.Utilities:ToUI(buttonHeightPx))
	page.deleteProfileButton:SetPoint(
		"TOPLEFT",
		page.deleteProfileDropdown,
		"TOPRIGHT",
		addon.Utilities:ToUI(controlGapPx),
		0
	)
end

local function UpdateState(profile)
	if not page then
		return
	end

	local options = BuildProfileOptions(true)
	local deleteOptions = BuildProfileOptions(false)
	local currentCopySource = page.copyFromDropdown:GetValue()
	local currentDeleteTarget = page.deleteProfileDropdown:GetValue()

	page.activeProfileDropdown:SetOptions(options)
	page.activeProfileDropdown:SetValue(addon.Database:GetCurrentProfileName() or "Default")

	page.copyFromDropdown:SetOptions(options)

	if currentCopySource and addon.Database:HasProfile(currentCopySource) then
		page.copyFromDropdown:SetValue(currentCopySource)
	else
		page.copyFromDropdown:SetValue(nil)
	end

	page.deleteProfileDropdown:SetOptions(deleteOptions)

	if currentDeleteTarget and addon.Database:HasProfile(currentDeleteTarget) then
		page.deleteProfileDropdown:SetValue(currentDeleteTarget)
	else
		page.deleteProfileDropdown:SetValue(nil)
	end
end

function Profiles:Ensure(parent)
	if page then
		return page
	end

	page = CreateFrame("Frame", nil, parent)

	page.activeSectionTitle = page:CreateFontString(nil, "OVERLAY")
	page.activeSectionTitle:SetJustifyH("LEFT")
	page.activeSectionTitle:SetFont(theme.fonts.arialNarrow, 14, "")
	page.activeSectionTitle:SetTextColor(
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4]
	)
	page.activeSectionTitle:SetText("Active Profile")

	page.createSectionTitle = page:CreateFontString(nil, "OVERLAY")
	page.createSectionTitle:SetJustifyH("LEFT")
	page.createSectionTitle:SetFont(theme.fonts.arialNarrow, 14, "")
	page.createSectionTitle:SetTextColor(
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4]
	)
	page.createSectionTitle:SetText("Create New Profile")

	page.copySectionTitle = page:CreateFontString(nil, "OVERLAY")
	page.copySectionTitle:SetJustifyH("LEFT")
	page.copySectionTitle:SetFont(theme.fonts.arialNarrow, 14, "")
	page.copySectionTitle:SetTextColor(
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4]
	)
	page.copySectionTitle:SetText("Copy Profile")

	page.deleteSectionTitle = page:CreateFontString(nil, "OVERLAY")
	page.deleteSectionTitle:SetJustifyH("LEFT")
	page.deleteSectionTitle:SetFont(theme.fonts.arialNarrow, 14, "")
	page.deleteSectionTitle:SetTextColor(
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4]
	)
	page.deleteSectionTitle:SetText("Delete Profile")

	page.activeProfileDropdown = addon.Options.Controls.Dropdown:Create(page, "")
	page.activeProfileDropdown:SetLabelVisible(false)
	page.activeProfileDropdown:SetOnValueChanged(function(_, value)
		local currentProfile = addon.Database:GetCurrentProfileName() or "Default"

		if value and value ~= currentProfile then
			addon.Database:SetProfile(value)
		end
	end)

	page.newProfileInput = addon.Options.Controls.Input:Create(page, "")
	page.newProfileInput:SetLabelVisible(false)
	page.newProfileInput:SetPlaceholder("New Profile Name")

	page.createProfileButton = addon.Options.Controls.Button:Create(page, "Create")
	page.createProfileButton:SetOnClick(function()
		CreateProfileFromInput()
	end)

	page.copyFromDropdown = addon.Options.Controls.Dropdown:Create(page, "")
	page.copyFromDropdown:SetLabelVisible(false)

	page.copyProfileInput = addon.Options.Controls.Input:Create(page, "")
	page.copyProfileInput:SetLabelVisible(false)
	page.copyProfileInput:SetPlaceholder("New Profile Name")

	page.copyProfileButton = addon.Options.Controls.Button:Create(page, "Copy")
	page.copyProfileButton:SetOnClick(function()
		CopyProfileFromInput()
	end)

	page.deleteProfileDropdown = addon.Options.Controls.Dropdown:Create(page, "")
	page.deleteProfileDropdown:SetLabelVisible(false)

	page.deleteProfileButton = addon.Options.Controls.Button:Create(page, "Delete")
	page.deleteProfileButton:SetOnClick(function()
		DeleteSelectedProfile()
	end)

	function page:UpdateLayout()
		--UpdateLayout()
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
