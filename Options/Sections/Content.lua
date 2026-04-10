local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.Content = addon.Options.Sections.Content or {}

local Content = addon.Options.Sections.Content

local content
local activePage = "general"

local controllerState = addon.Options.ControllerState or {
	mode = "party",
	subpages = {
		auras = "buffs",
		texts = "name",
		indicators = "readyCheck",
		bars = "absorbs",
	},
}

addon.Options.ControllerState = controllerState

local layout = {
	paddingPx = addon.Utilities:ToPixels(32),
	innerWidthPx = addon.Utilities:ToPixels(582),
	columnGapPx = addon.Utilities:ToPixels(30),
	twoColumn = {
		slotWidthPx = addon.Utilities:ToPixels(276),
		controlWidthPx = addon.Utilities:ToPixels(200),
		startXPx = { 0, addon.Utilities:ToPixels(306) },
	},
	threeColumn = {
		slotWidthPx = addon.Utilities:ToPixels(174),
		controlWidthPx = addon.Utilities:ToPixels(150),
		startXPx = { 0, addon.Utilities:ToPixels(204), addon.Utilities:ToPixels(408) },
	},
}

local pageModules = {
	general = addon.Options.Pages.General,
	layout = addon.Options.Pages.Layout,
	bars = addon.Options.Pages.Bars,
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

	local pagePaddingPx = addon.Utilities:ToPixels(32)
	local columnGapPx = addon.Utilities:ToPixels(30)
	local contentWidthPx = addon.Utilities:ToPixels(content:GetWidth())

	if not contentWidthPx or contentWidthPx <= 0 then
		return
	end

	local innerWidthPx = contentWidthPx - (pagePaddingPx * 2)
	local twoColumnWidthPx = addon.Utilities:RoundToNearestInt((innerWidthPx - columnGapPx) / 2)
	local threeColumnWidthPx = addon.Utilities:RoundToNearestInt((innerWidthPx - (columnGapPx * 2)) / 3)

	layout.paddingPx = pagePaddingPx
	layout.innerWidthPx = innerWidthPx
	layout.columnGapPx = columnGapPx

	layout.twoColumn.slotWidthPx = twoColumnWidthPx
	layout.twoColumn.controlWidthPx = addon.Utilities:ToPixels(200)
	layout.twoColumn.startXPx[1] = 0
	layout.twoColumn.startXPx[2] = twoColumnWidthPx + columnGapPx

	layout.threeColumn.slotWidthPx = threeColumnWidthPx
	layout.threeColumn.controlWidthPx = addon.Utilities:ToPixels(150)
	layout.threeColumn.startXPx[1] = 0
	layout.threeColumn.startXPx[2] = threeColumnWidthPx + columnGapPx
	layout.threeColumn.startXPx[3] = (threeColumnWidthPx * 2) + (columnGapPx * 2)
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

	local pageModule = pageModules[pageKey]
	if pageModule and pageModule.UpdateState then
		pageModule:UpdateState(addon.Database:GetProfile())
	end

	activePage = pageKey
end

function Content:GetActivePage()
	return activePage
end

function Content:GetLayout()
	return layout
end

function Content:GetControllerState()
	return controllerState
end
