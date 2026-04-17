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

local function RefreshProfilesPage()
	if addon.Options and addon.Options.Data and addon.Options.Data.RefreshProfile then
		addon.Options.Data:RefreshProfile()
	end
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

local function BuildSpecProfileOptions()
	local options = {
		{
			value = nil,
			text = "Use Active",
			textColor = { theme:GetTextColor("placeholder") },
			fontFlags = "ITALIC",
		},
	}

	for _, option in ipairs(BuildProfileOptions(true)) do
		table.insert(options, {
			value = option.value,
			text = option.text,
		})
	end

	return options
end

local function BuildPlayerSpecEntries()
	local entries = {}
	local _, _, classID = UnitClass("player")

	if
		not classID
		or not C_SpecializationInfo
		or not C_SpecializationInfo.GetNumSpecializationsForClassID
		or not GetSpecializationInfoForClassID
	then
		return entries
	end

	local specCount = C_SpecializationInfo.GetNumSpecializationsForClassID(classID) or 0

	for specIndex = 1, specCount do
		local specID, specName = GetSpecializationInfoForClassID(classID, specIndex)
		if specID and specName then
			table.insert(entries, {
				specID = specID,
				name = specName,
			})
		end
	end

	return entries
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
	addon.Database:SetBaseProfileName(name)
	addon.Database:ApplyProfileForCurrentSpec()
	RefreshProfilesPage()
	page.newProfileInput:SetText("")
	PrintProfileMsg("Created '" .. name .. "' and set it as the active profile.")
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
	addon.Database:SetBaseProfileName(name)
	addon.Database:ApplyProfileForCurrentSpec()
	RefreshProfilesPage()

	page.copyProfileInput:SetText("")
	page.copyFromDropdown:SetValue(nil)

	PrintProfileMsg("Created '" .. name .. "' by copying '" .. source .. "' and set it as the active profile.")
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

	local currentSpecID = addon.Utilities:GetPlayerSpecID()
	if currentSpecID and addon.Database:GetSpecProfileName(currentSpecID) == target then
		addon.Database:ClearSpecProfileName(currentSpecID)
	end

	if addon.Database:GetBaseProfileName() == target then
		addon.Database:SetBaseProfileName("Default")
	end

	addon.Database:ApplyProfileForCurrentSpec()
	addon.Database:DeleteProfile(target)
	page.deleteProfileDropdown:SetValue(nil)

	PrintProfileMsg("Deleted profile '" .. target .. "'.")
end

local function UpdateLayout()
	if not page then
		return
	end

	local controls = page.controls
	local specEntries = page.specEntries or {}
	local sectionSpacingPx = addon.Utilities:ToPixels(24)
	local sectionControlOffsetPx = addon.Utilities:ToPixels(10)
	local controlGapPx = addon.Utilities:ToPixels(1)
	local specControlGapPx = addon.Utilities:ToPixels(8)

	for _, control in pairs(controls) do
		if control.UpdateLayout then
			control:UpdateLayout()
		end
	end

	page.activeSectionTitle:ClearAllPoints()
	page.activeSectionTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)

	controls.activeProfileDropdown:ClearAllPoints()
	controls.activeProfileDropdown:SetPoint(
		"TOPLEFT",
		page.activeSectionTitle,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionControlOffsetPx)
	)

	local contentTopAnchor = page.activeProfileDropdown

	if #specEntries > 0 then
		page.specOverridesSectionTitle:ClearAllPoints()
		page.specOverridesSectionTitle:SetPoint(
			"TOPLEFT",
			controls.activeProfileDropdown,
			"BOTTOMLEFT",
			0,
			-addon.Utilities:ToUI(sectionSpacingPx)
		)

		for index, specEntry in ipairs(specEntries) do
			local dropdown = specEntry.dropdown
			dropdown:ClearAllPoints()

			if index == 1 then
				dropdown:SetPoint(
					"TOPLEFT",
					page.specOverridesSectionTitle,
					"BOTTOMLEFT",
					0,
					-addon.Utilities:ToUI(sectionControlOffsetPx)
				)
			else
				dropdown:SetPoint(
					"TOPLEFT",
					specEntries[index - 1].dropdown,
					"TOPRIGHT",
					addon.Utilities:ToUI(specControlGapPx),
					0
				)
			end
		end

		contentTopAnchor = specEntries[1].dropdown
	end

	page.createSectionTitle:ClearAllPoints()
	page.createSectionTitle:SetPoint(
		"TOPLEFT",
		contentTopAnchor,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionSpacingPx)
	)

	controls.newProfileInput:ClearAllPoints()
	controls.newProfileInput:SetPoint(
		"TOPLEFT",
		page.createSectionTitle,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionControlOffsetPx)
	)

	controls.createProfileButton:ClearAllPoints()
	controls.createProfileButton:SetPoint(
		"TOPLEFT",
		controls.newProfileInput.field,
		"TOPRIGHT",
		addon.Utilities:ToUI(controlGapPx),
		0
	)

	page.copySectionTitle:ClearAllPoints()
	page.copySectionTitle:SetPoint(
		"TOPLEFT",
		controls.newProfileInput,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionSpacingPx)
	)

	controls.copyFromDropdown:ClearAllPoints()
	controls.copyFromDropdown:SetPoint(
		"TOPLEFT",
		page.copySectionTitle,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionControlOffsetPx)
	)

	controls.copyProfileInput:ClearAllPoints()
	controls.copyProfileInput:SetPoint(
		"TOPLEFT",
		controls.copyFromDropdown,
		"TOPRIGHT",
		addon.Utilities:ToUI(controlGapPx),
		0
	)

	controls.copyProfileButton:ClearAllPoints()
	controls.copyProfileButton:SetPoint(
		"TOPLEFT",
		controls.copyProfileInput,
		"TOPRIGHT",
		addon.Utilities:ToUI(controlGapPx),
		0
	)

	page.deleteSectionTitle:ClearAllPoints()
	page.deleteSectionTitle:SetPoint(
		"TOPLEFT",
		controls.copyFromDropdown,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionSpacingPx)
	)

	controls.deleteProfileDropdown:ClearAllPoints()
	controls.deleteProfileDropdown:SetPoint(
		"TOPLEFT",
		page.deleteSectionTitle,
		"BOTTOMLEFT",
		0,
		-addon.Utilities:ToUI(sectionControlOffsetPx)
	)

	controls.deleteProfileButton:ClearAllPoints()
	controls.deleteProfileButton:SetPoint(
		"TOPLEFT",
		controls.deleteProfileDropdown,
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
	local specOptions = BuildSpecProfileOptions()
	local deleteOptions = BuildProfileOptions(false)
	local currentCopySource = page.copyFromDropdown:GetValue()
	local currentDeleteTarget = page.deleteProfileDropdown:GetValue()

	page.activeProfileDropdown:SetOptions(options)
	page.activeProfileDropdown:SetValue(addon.Database:GetBaseProfileName() or "Default")

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

	for _, specEntry in ipairs(page.specEntries or {}) do
		specEntry.dropdown:SetOptions(specOptions)
		specEntry.dropdown:SetValue(addon.Database:GetSpecProfileName(specEntry.specID))
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
	page.activeSectionTitle:SetTextColor(theme:GetColor("brand"))
	page.activeSectionTitle:SetText("Active Profile")

	page.createSectionTitle = page:CreateFontString(nil, "OVERLAY")
	page.createSectionTitle:SetJustifyH("LEFT")
	page.createSectionTitle:SetFont(theme.fonts.arialNarrow, 14, "")
	page.createSectionTitle:SetTextColor(theme:GetColor("brand"))
	page.createSectionTitle:SetText("Create New Profile")

	page.copySectionTitle = page:CreateFontString(nil, "OVERLAY")
	page.copySectionTitle:SetJustifyH("LEFT")
	page.copySectionTitle:SetFont(theme.fonts.arialNarrow, 14, "")
	page.copySectionTitle:SetTextColor(theme:GetColor("brand"))
	page.copySectionTitle:SetText("Copy Profile")

	page.deleteSectionTitle = page:CreateFontString(nil, "OVERLAY")
	page.deleteSectionTitle:SetJustifyH("LEFT")
	page.deleteSectionTitle:SetFont(theme.fonts.arialNarrow, 14, "")
	page.deleteSectionTitle:SetTextColor(theme:GetColor("brand"))
	page.deleteSectionTitle:SetText("Delete Profile")

	page.specOverridesSectionTitle = page:CreateFontString(nil, "OVERLAY")
	page.specOverridesSectionTitle:SetJustifyH("LEFT")
	page.specOverridesSectionTitle:SetFont(theme.fonts.arialNarrow, 14, "")
	page.specOverridesSectionTitle:SetTextColor(theme:GetColor("brand"))
	page.specOverridesSectionTitle:SetText("Override Active per Specialization")

	page.activeProfileDropdown = addon.Options.Controls.Dropdown:Create(page, "")
	page.activeProfileDropdown:SetLayoutWidth(200)
	page.activeProfileDropdown:SetLabelVisible(false)
	page.activeProfileDropdown:SetOnValueChanged(function(_, value)
		local currentProfile = addon.Database:GetBaseProfileName() or "Default"

		if value and value ~= currentProfile then
			addon.Database:SetBaseProfileName(value)
			addon.Database:ApplyProfileForCurrentSpec()
		end
	end)

	page.newProfileInput = addon.Options.Controls.Input:Create(page, "")
	page.newProfileInput:SetLayoutWidth(200)
	page.newProfileInput:SetLabelVisible(false)
	page.newProfileInput:SetPlaceholder("New Profile Name")

	page.createProfileButton = addon.Options.Controls.Button:Create(page, "Create")
	page.createProfileButton:SetLayoutSize(48, 24)
	page.createProfileButton:SetOnClick(function()
		CreateProfileFromInput()
	end)

	page.copyFromDropdown = addon.Options.Controls.Dropdown:Create(page, "")
	page.copyFromDropdown:SetLayoutWidth(200)
	page.copyFromDropdown:SetLabelVisible(false)

	page.copyProfileInput = addon.Options.Controls.Input:Create(page, "")
	page.copyProfileInput:SetLayoutWidth(200)
	page.copyProfileInput:SetLabelVisible(false)
	page.copyProfileInput:SetPlaceholder("New Profile Name")

	page.copyProfileButton = addon.Options.Controls.Button:Create(page, "Copy")
	page.copyProfileButton:SetLayoutSize(48, 24)
	page.copyProfileButton:SetOnClick(function()
		CopyProfileFromInput()
	end)

	page.deleteProfileDropdown = addon.Options.Controls.Dropdown:Create(page, "")
	page.deleteProfileDropdown:SetLayoutWidth(200)
	page.deleteProfileDropdown:SetLabelVisible(false)

	page.deleteProfileButton = addon.Options.Controls.Button:Create(page, "Delete")
	page.deleteProfileButton:SetLayoutSize(48, 24)
	page.deleteProfileButton:SetOnClick(function()
		DeleteSelectedProfile()
	end)

	page.specEntries = BuildPlayerSpecEntries()
	for _, specEntry in ipairs(page.specEntries) do
		local dropdown = addon.Options.Controls.Dropdown:Create(page, specEntry.name)
		dropdown:SetLayoutWidth(140)
		dropdown:SetPlaceholder("Use Active")
		dropdown:SetOnValueChanged(function(_, value)
			if value == nil then
				addon.Database:ClearSpecProfileName(specEntry.specID)
				PrintProfileMsg(specEntry.name .. " will use the active profile.")
			else
				addon.Database:SetSpecProfileName(specEntry.specID, value)
				PrintProfileMsg(specEntry.name .. " will use profile '" .. value .. "'.")
			end

			if addon.Utilities:GetPlayerSpecID() == specEntry.specID then
				addon.Database:ApplyProfileForCurrentSpec()
			end
		end)

		specEntry.dropdown = dropdown
	end

	page.controls = {
		activeProfileDropdown = page.activeProfileDropdown,
		newProfileInput = page.newProfileInput,
		createProfileButton = page.createProfileButton,
		copyFromDropdown = page.copyFromDropdown,
		copyProfileInput = page.copyProfileInput,
		copyProfileButton = page.copyProfileButton,
		deleteProfileDropdown = page.deleteProfileDropdown,
		deleteProfileButton = page.deleteProfileButton,
	}

	for _, specEntry in ipairs(page.specEntries) do
		page.controls["specProfile_" .. specEntry.specID] = specEntry.dropdown
	end

	page.controls.specOverridesSectionTitle = page.specOverridesSectionTitle

	function page:UpdateLayout()
		UpdateLayout()
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
