local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Profiles = addon.OptionsNew.Pages.Profiles or {}

local OptionsUILib = LibStub("MichsOptionsUILib-1.0")
local Profiles = addon.OptionsNew.Pages.Profiles
local L = addon.L

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
			text = L["Use Active"],
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

local function RefreshProfilesPage()
	addon.OptionsNew:RefreshProfile()
end

local function CreateProfileFromInput(controls)
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
	RefreshProfilesPage()
	PrintProfileMsg((L["Created '%s' and set it as the active profile."]):format(name))
end

local function CopyProfileFromInput(controls)
	if InCombatLockdown() then
		PrintProfileMsg(L["Layout changes are disabled during combat."])
		return
	end

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
	RefreshProfilesPage()

	PrintProfileMsg((L["Created '%s' by copying '%s' and set it as the active profile."]):format(name, source))
end

local function DeleteSelectedProfile(controls)
	if InCombatLockdown() then
		PrintProfileMsg(L["Layout changes are disabled during combat."])
		return
	end

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
	RefreshProfilesPage()

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
		specEntry.dropdown:SetOptions(specOptions)
		specEntry.dropdown:SetValue(addon.Database:GetSpecProfileName(specEntry.specID))
	end
end

local function CreateSectionTitle(subpage, text)
	local title = subpage:CreateControl("Label", text)
	title:SetTextColor(OptionsUILib.Theme:GetColor("brand"))
	title:SetLayoutSize(240, 16)

	return title
end

function Profiles:Create(panel)
	local page = panel:RegisterPage("profiles", {
		title = L["Profiles"],
		sidebarPlacement = "bottom",
	})
	local subpage = page:RegisterSubPage("profiles", { title = L["Profiles"] })

	subpage.activeSectionTitle = CreateSectionTitle(subpage, L["Active Profile"])
	subpage.specOverridesSectionTitle = CreateSectionTitle(subpage, L["Override Active per Specialization"])
	subpage.createSectionTitle = CreateSectionTitle(subpage, L["Create New Profile"])
	subpage.copySectionTitle = CreateSectionTitle(subpage, L["Copy Profile"])
	subpage.deleteSectionTitle = CreateSectionTitle(subpage, L["Delete Profile"])

	local controls = {}
	local activeProfileDropdown = subpage:CreateControl("Dropdown", "")
	activeProfileDropdown:SetLayoutWidth(200)
	activeProfileDropdown:SetLabelVisible(false)
	activeProfileDropdown:SetOnValueChanged(function(_, value)
		local currentProfile = addon.Database:GetBaseProfileName() or "Default"

		if value and value ~= currentProfile then
			addon.Database:SetBaseProfileName(value)
			addon.Database:ApplyProfileForCurrentSpec()
			RefreshProfilesPage()
		end
	end)

	local newProfileInput = subpage:CreateControl("Input", "")
	newProfileInput:SetLayoutWidth(200)
	newProfileInput:SetLabelVisible(false)
	newProfileInput:SetPlaceholder(L["New Profile Name"])
	newProfileInput:SetOnEnterPressed(function()
		CreateProfileFromInput(controls)
	end)

	local createProfileButton = subpage:CreateControl("Button", L["Create"])
	createProfileButton:SetLayoutSize(actionButtonWidth, actionButtonHeight)
	createProfileButton:SetOnClick(function()
		CreateProfileFromInput(controls)
	end)

	local copyFromDropdown = subpage:CreateControl("Dropdown", "")
	copyFromDropdown:SetLayoutWidth(200)
	copyFromDropdown:SetLabelVisible(false)

	local copyProfileInput = subpage:CreateControl("Input", "")
	copyProfileInput:SetLayoutWidth(200)
	copyProfileInput:SetLabelVisible(false)
	copyProfileInput:SetPlaceholder(L["New Profile Name"])
	copyProfileInput:SetOnEnterPressed(function()
		CopyProfileFromInput(controls)
	end)

	local copyProfileButton = subpage:CreateControl("Button", L["Copy"])
	copyProfileButton:SetLayoutSize(actionButtonWidth, actionButtonHeight)
	copyProfileButton:SetOnClick(function()
		CopyProfileFromInput(controls)
	end)

	local deleteProfileDropdown = subpage:CreateControl("Dropdown", "")
	deleteProfileDropdown:SetLayoutWidth(200)
	deleteProfileDropdown:SetLabelVisible(false)

	local deleteProfileButton = subpage:CreateControl("Button", L["Delete"])
	deleteProfileButton:SetLayoutSize(actionButtonWidth, actionButtonHeight)
	deleteProfileButton:SetOnClick(function()
		DeleteSelectedProfile(controls)
	end)

	subpage.specEntries = BuildPlayerSpecEntries()
	for _, specEntry in ipairs(subpage.specEntries) do
		local dropdown = subpage:CreateControl("Dropdown", GetSpecDisplayName(specEntry))
		dropdown:SetLayoutWidth(140)
		dropdown:SetPlaceholder(L["Use Active"])
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
				RefreshProfilesPage()
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

	addon.OptionsNew:RegisterForProfileUpdates("profiles", function()
		UpdateState(subpage, controls)
	end)
	UpdateState(subpage, controls)

	return page
end
