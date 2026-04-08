local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.Content = addon.Options.Sections.Content or {}

local Content = addon.Options.Sections.Content

local content
local activePage = "general"
local function ToUI(value)
	return addon.Utilities:ToUI(addon.Utilities:ToPixels(value))
end

local layout = {
	padding = ToUI(32),
	innerWidth = ToUI(582),
	columnGap = ToUI(16),
	twoColumn = {
		slotWidth = ToUI(275),
		controlWidth = ToUI(200),
		startX = { ToUI(32), ToUI(323) },
	},
	threeColumn = {
		slotWidth = ToUI(178),
		controlWidth = ToUI(150),
		startX = { ToUI(32), ToUI(226), ToUI(420) },
	},
}

local pageModules = {
	general = addon.Options.Pages.General,
	layout = addon.Options.Pages.Layout,
	texts = addon.Options.Pages.Texts,
	auras = addon.Options.Pages.Auras,
	indicators = addon.Options.Pages.Indicators,
	profiles = addon.Options.Pages.Profiles,
}

local pageFrames = {}

local function UpdateLayoutValues()
	if not content then
		return
	end

	local pagePadding = ToUI(32)
	local columnGap = ToUI(16)
	local contentWidth = content:GetWidth()

	if not contentWidth or contentWidth <= 0 then
		return
	end

	local innerWidth = contentWidth - (pagePadding * 2)
	local twoColumnStep = innerWidth / 2
	local threeColumnStep = innerWidth / 3

	layout.padding = pagePadding
	layout.innerWidth = innerWidth
	layout.columnGap = columnGap

	layout.twoColumn.slotWidth = twoColumnStep - columnGap
	layout.twoColumn.controlWidth = ToUI(200)
	layout.twoColumn.startX[1] = pagePadding
	layout.twoColumn.startX[2] = pagePadding + twoColumnStep

	layout.threeColumn.slotWidth = threeColumnStep - columnGap
	layout.threeColumn.controlWidth = ToUI(150)
	layout.threeColumn.startX[1] = pagePadding
	layout.threeColumn.startX[2] = pagePadding + threeColumnStep
	layout.threeColumn.startX[3] = pagePadding + (threeColumnStep * 2)
end

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

	UpdateLayoutValues()

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

	addon.Options.Controls.Dropdown:CloseOpenDropdown()

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

function Content:GetLayout()
	return layout
end
