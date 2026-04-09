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
	padding = ToUI(32),
	innerWidth = ToUI(582),
	columnGap = ToUI(30),
	twoColumn = {
		slotWidth = ToUI(276),
		controlWidth = ToUI(200),
		startX = { ToUI(0), ToUI(306) },
	},
	threeColumn = {
		slotWidth = ToUI(174),
		controlWidth = ToUI(150),
		startX = { ToUI(0), ToUI(204), ToUI(408) },
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

	local pagePadding = ToUI(32)
	local columnGap = ToUI(16)
	local contentWidth = content:GetWidth()

	if not contentWidth or contentWidth <= 0 then
		return
	end

	local innerWidth = contentWidth - (pagePadding * 2)
	local columnGap = ToUI(30)
	local twoColumnWidth = (innerWidth - columnGap) / 2
	local threeColumnWidth = (innerWidth - (columnGap * 2)) / 3

	layout.padding = pagePadding
	layout.innerWidth = innerWidth
	layout.columnGap = columnGap

	layout.twoColumn.slotWidth = twoColumnWidth
	layout.twoColumn.controlWidth = ToUI(200)
	layout.twoColumn.startX[1] = ToUI(0)
	layout.twoColumn.startX[2] = twoColumnWidth + columnGap

	layout.threeColumn.slotWidth = threeColumnWidth
	layout.threeColumn.controlWidth = ToUI(150)
	layout.threeColumn.startX[1] = ToUI(0)
	layout.threeColumn.startX[2] = threeColumnWidth + columnGap
	layout.threeColumn.startX[3] = (threeColumnWidth * 2) + (columnGap * 2)
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
