local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.Content = addon.Options.Sections.Content or {}

local Content = addon.Options.Sections.Content

local content
local activePage = "general"

local pageModules = {
	general = addon.Options.Pages.General,
	layout = addon.Options.Pages.Layout,
	texts = addon.Options.Pages.Texts,
	auras = addon.Options.Pages.Auras,
	indicators = addon.Options.Pages.Indicators,
	profiles = addon.Options.Pages.Profiles,
}

local pageFrames = {}

local function EnsurePage(pageKey)
	local pageModule = pageModules[pageKey]
	if not pageModule or not content then
		return nil
	end

	local pageFrame = pageFrames[pageKey]
	if pageFrame then
		return pageFrame
	end

	pageFrame = pageModule:Ensure(content)
	pageFrame:ClearAllPoints()
	pageFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	pageFrame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
	pageFrame:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
	pageFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
	pageFrame:Hide()

	pageFrames[pageKey] = pageFrame

	return pageFrame
end

function Content:Ensure(parent)
	if content then
		return content
	end

	content = CreateFrame("Frame", nil, parent)

	EnsurePage(activePage)
	self:UpdateLayout()

	return content
end

function Content:UpdateLayout()
	if not content then
		return
	end

	for pageKey, pageFrame in pairs(pageFrames) do
		pageFrame:ClearAllPoints()
		pageFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		pageFrame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
		pageFrame:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
		pageFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

		local pageModule = pageModules[pageKey]
		if pageModule and pageModule.UpdateLayout then
			pageModule:UpdateLayout()
		end
	end
end

function Content:SetActivePage(pageKey)
	if not pageModules[pageKey] then
		return
	end

	for key, pageFrame in pairs(pageFrames) do
		pageFrame:SetShown(key == pageKey)
	end

	local pageFrame = EnsurePage(pageKey)
	if pageFrame then
		pageFrame:Show()
	end

	activePage = pageKey
end

function Content:GetActivePage()
	return activePage
end
