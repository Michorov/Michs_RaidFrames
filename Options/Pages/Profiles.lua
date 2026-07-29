local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Profiles = addon.Options.Pages.Profiles or {}

local OptionsUILib = LibStub("MichsOptionsUILib-1.0")
local Profiles = addon.Options.Pages.Profiles
local L = addon.L

local bodyWidth = 576
local actionButtonWidth = 88
local actionButtonHeight = 24

local function PrintProfileMsg(message)
	print("|cffff9900Mich's RaidFrames:|r " .. message)
end

local function GetDisplayProfileName(name)
	if name == "Default" then
		return L["Default"]
	end

	return name
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
			options[#options + 1] = {
				value = value,
				text = GetDisplayProfileName(text),
			}
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
			textKey = "Use Active",
			textColor = { OptionsUILib.Theme:GetTextColor("placeholder") },
		},
	}

	for _, option in ipairs(BuildProfileOptions(true)) do
		options[#options + 1] = {
			value = option.value,
			text = option.text,
		}
	end

	return options
end

local function GetSpecDisplayName(specEntry)
	if not specEntry then
		return ""
	end

	return addon.Locale:GetSpecializationDisplayName(specEntry.specID, specEntry.fallbackName or specEntry.name)
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
			entries[#entries + 1] = {
				specID = specID,
				fallbackName = specName,
			}
		end
	end

	return entries
end

local function CreateProfileFromInput(panel, controls)
	local name = Trim(controls.newProfileInput:GetText())

	if name == "" then
		PrintProfileMsg(L["Enter a profile name first."])
		return
	end

	if addon.Database:HasProfile(name) then
		PrintProfileMsg((L["Profile '%s' already exists."]):format(name))
		return
	end

	addon.Database:SetProfile(name)
	addon.Database:SetBaseProfileName(name)
	addon.Database:ApplyProfileForCurrentSpec()
	controls.newProfileInput:SetText("")
	panel:UpdateState()
	PrintProfileMsg((L["Created '%s' and set it as the active profile."]):format(name))
end

local function CopyProfileFromInput(panel, controls)
	local source = controls.copyFromDropdown:GetValue()
	local name = Trim(controls.copyProfileInput:GetText())

	if not source or source == "" then
		PrintProfileMsg(L["Select a source profile."])
		return
	end

	if name == "" then
		PrintProfileMsg(L["Enter a new profile name."])
		return
	end

	if addon.Database:HasProfile(name) then
		PrintProfileMsg((L["Profile '%s' already exists."]):format(name))
		return
	end

	addon.Database:SetProfile(name)
	addon.Database:CopyProfile(source)
	addon.Database:SetBaseProfileName(name)
	addon.Database:ApplyProfileForCurrentSpec()

	controls.copyProfileInput:SetText("")
	controls.copyFromDropdown:SetValue(nil)
	panel:UpdateState()

	PrintProfileMsg((L["Created '%s' by copying '%s' and set it as the active profile."]):format(name, source))
end

local function DeleteSelectedProfile(panel, controls)
	local target = controls.deleteProfileDropdown:GetValue()

	if not target or target == "" then
		PrintProfileMsg(L["Select a profile to delete."])
		return
	end

	if target == "Default" then
		PrintProfileMsg(L["Default profile cannot be deleted."])
		return
	end

	if not addon.Database:HasProfile(target) then
		PrintProfileMsg((L["Profile '%s' does not exist."]):format(target))
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
	controls.deleteProfileDropdown:SetValue(nil)
	panel:UpdateState()

	PrintProfileMsg((L["Deleted profile '%s'."]):format(target))
end

local function UpdateState(subpage, controls)
	local options = BuildProfileOptions(true)
	local specOptions = BuildSpecProfileOptions()
	local deleteOptions = BuildProfileOptions(false)
	local currentCopySource = controls.copyFromDropdown:GetValue()
	local currentDeleteTarget = controls.deleteProfileDropdown:GetValue()

	controls.activeProfileDropdown:SetOptions(options)
	controls.activeProfileDropdown:SetValue(addon.Database:GetBaseProfileName() or "Default")

	controls.copyFromDropdown:SetOptions(options)
	if currentCopySource and addon.Database:HasProfile(currentCopySource) then
		controls.copyFromDropdown:SetValue(currentCopySource)
	else
		controls.copyFromDropdown:SetValue(nil)
	end

	controls.deleteProfileDropdown:SetOptions(deleteOptions)
	if currentDeleteTarget and addon.Database:HasProfile(currentDeleteTarget) then
		controls.deleteProfileDropdown:SetValue(currentDeleteTarget)
	else
		controls.deleteProfileDropdown:SetValue(nil)
	end

	for _, specEntry in ipairs(subpage.specEntries or {}) do
		specEntry.dropdown:SetLabel(GetSpecDisplayName(specEntry))
		specEntry.dropdown:SetOptions(specOptions)
		specEntry.dropdown:SetValue(addon.Database:GetSpecProfileName(specEntry.specID))
	end
end

local function CreateSectionTitle(subpage, textKey)
	local title = subpage:CreateControl("Label", { textKey = textKey })
	title:SetTextColor(OptionsUILib.Theme:GetColor("brand"))
	title:SetLayoutSize(bodyWidth, 16)

	return title
end

function Profiles:Create(panel)
	local page = panel:RegisterPage("profiles", {
		titleKey = "Profiles",
		sidebarPlacement = "bottom",
	})
	local subpage = page:RegisterSubPage("profiles", { titleKey = "Profiles" })

	subpage.activeSectionTitle = CreateSectionTitle(subpage, "Active Profile")
	subpage.specOverridesSectionTitle = CreateSectionTitle(subpage, "Override Active per Specialization")
	subpage.createSectionTitle = CreateSectionTitle(subpage, "Create New Profile")
	subpage.copySectionTitle = CreateSectionTitle(subpage, "Copy Profile")
	subpage.deleteSectionTitle = CreateSectionTitle(subpage, "Delete Profile")

	local controls = {}
	local activeProfileDropdown = subpage:CreateControl("Dropdown", "")
	activeProfileDropdown:SetLayoutWidth(200)
	activeProfileDropdown:SetLabelVisible(false)
	activeProfileDropdown:SetPlaceholderKey("Select...")
	activeProfileDropdown:SetOnValueChanged(function(_, value)
		local currentProfile = addon.Database:GetBaseProfileName() or "Default"

		if value and value ~= currentProfile then
			addon.Database:SetBaseProfileName(value)
			addon.Database:ApplyProfileForCurrentSpec()
			panel:UpdateState()
		end
	end)

	local newProfileInput = subpage:CreateControl("Input", "")
	newProfileInput:SetLayoutWidth(200)
	newProfileInput:SetLabelVisible(false)
	newProfileInput:SetPlaceholderKey("New Profile Name")
	newProfileInput:SetOnEnterPressed(function()
		CreateProfileFromInput(panel, controls)
	end)

	local createProfileButton = subpage:CreateControl("Button", { textKey = "Create" })
	createProfileButton:SetLayoutSize(actionButtonWidth, actionButtonHeight)
	createProfileButton:SetOnClick(function()
		CreateProfileFromInput(panel, controls)
	end)

	local copyFromDropdown = subpage:CreateControl("Dropdown", "")
	copyFromDropdown:SetLayoutWidth(200)
	copyFromDropdown:SetLabelVisible(false)
	copyFromDropdown:SetPlaceholderKey("Select...")

	local copyProfileInput = subpage:CreateControl("Input", "")
	copyProfileInput:SetLayoutWidth(200)
	copyProfileInput:SetLabelVisible(false)
	copyProfileInput:SetPlaceholderKey("New Profile Name")
	copyProfileInput:SetOnEnterPressed(function()
		CopyProfileFromInput(panel, controls)
	end)

	local copyProfileButton = subpage:CreateControl("Button", { textKey = "Copy" })
	copyProfileButton:SetLayoutSize(actionButtonWidth, actionButtonHeight)
	copyProfileButton:SetOnClick(function()
		CopyProfileFromInput(panel, controls)
	end)

	local deleteProfileDropdown = subpage:CreateControl("Dropdown", "")
	deleteProfileDropdown:SetLayoutWidth(200)
	deleteProfileDropdown:SetLabelVisible(false)
	deleteProfileDropdown:SetPlaceholderKey("Select...")

	local deleteProfileButton = subpage:CreateControl("Button", { textKey = "Delete" })
	deleteProfileButton:SetLayoutSize(actionButtonWidth, actionButtonHeight)
	deleteProfileButton:SetOnClick(function()
		DeleteSelectedProfile(panel, controls)
	end)

	subpage.specEntries = BuildPlayerSpecEntries()
	for _, specEntry in ipairs(subpage.specEntries) do
		local dropdown = subpage:CreateControl("Dropdown", GetSpecDisplayName(specEntry))
		dropdown:SetLayoutWidth(140)
		dropdown:SetPlaceholderKey("Use Active")
		dropdown:SetOnValueChanged(function(_, value)
			local specName = GetSpecDisplayName(specEntry)

			if value == nil then
				addon.Database:ClearSpecProfileName(specEntry.specID)
				PrintProfileMsg((L["%s will use the active profile."]):format(specName))
			else
				addon.Database:SetSpecProfileName(specEntry.specID, value)
				PrintProfileMsg((L["%s will use profile '%s'."]):format(specName, value))
			end

			if addon.Utilities:GetPlayerSpecID() == specEntry.specID then
				addon.Database:ApplyProfileForCurrentSpec()
				panel:UpdateState()
			end
		end)

		specEntry.dropdown = dropdown
	end

	controls.activeProfileDropdown = activeProfileDropdown
	controls.newProfileInput = newProfileInput
	controls.createProfileButton = createProfileButton
	controls.copyFromDropdown = copyFromDropdown
	controls.copyProfileInput = copyProfileInput
	controls.copyProfileButton = copyProfileButton
	controls.deleteProfileDropdown = deleteProfileDropdown
	controls.deleteProfileButton = deleteProfileButton

	subpage.activeSectionTitle:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)
	activeProfileDropdown:SetLayoutPoint("TOPLEFT", subpage.activeSectionTitle, "BOTTOMLEFT", 0, -10)

	local contentTopAnchor = activeProfileDropdown

	if #subpage.specEntries > 0 then
		subpage.specOverridesSectionTitle:SetLayoutPoint("TOPLEFT", activeProfileDropdown, "BOTTOMLEFT", 0, -24)

		for index, specEntry in ipairs(subpage.specEntries) do
			if index == 1 then
				specEntry.dropdown:SetLayoutPoint("TOPLEFT", subpage.specOverridesSectionTitle, "BOTTOMLEFT", 0, -10)
			else
				specEntry.dropdown:SetLayoutPoint("TOPLEFT", subpage.specEntries[index - 1].dropdown, "TOPRIGHT", 8, 0)
			end
		end

		contentTopAnchor = subpage.specEntries[1].dropdown
	else
		subpage.specOverridesSectionTitle:Hide()
	end

	subpage.createSectionTitle:SetLayoutPoint("TOPLEFT", contentTopAnchor, "BOTTOMLEFT", 0, -24)
	newProfileInput:SetLayoutPoint("TOPLEFT", subpage.createSectionTitle, "BOTTOMLEFT", 0, -10)
	createProfileButton:SetLayoutPoint("TOPLEFT", newProfileInput.field, "TOPRIGHT", 1, 0)

	subpage.copySectionTitle:SetLayoutPoint("TOPLEFT", newProfileInput, "BOTTOMLEFT", 0, -24)
	copyFromDropdown:SetLayoutPoint("TOPLEFT", subpage.copySectionTitle, "BOTTOMLEFT", 0, -10)
	copyProfileInput:SetLayoutPoint("TOPLEFT", copyFromDropdown, "TOPRIGHT", 1, 0)
	copyProfileButton:SetLayoutPoint("TOPLEFT", copyProfileInput, "TOPRIGHT", 1, 0)

	subpage.deleteSectionTitle:SetLayoutPoint("TOPLEFT", copyFromDropdown, "BOTTOMLEFT", 0, -24)
	deleteProfileDropdown:SetLayoutPoint("TOPLEFT", subpage.deleteSectionTitle, "BOTTOMLEFT", 0, -10)
	deleteProfileButton:SetLayoutPoint("TOPLEFT", deleteProfileDropdown, "TOPRIGHT", 1, 0)

	subpage:SetStateUpdater(function()
		UpdateState(subpage, controls)
	end)

	return page
end
