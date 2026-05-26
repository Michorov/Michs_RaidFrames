local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.Content = addon.Options.Sections.Content or {}

local Content = addon.Options.Sections.Content

local content
local activePage = "general"

local controllerState = addon.Options.ControllerState
	or {
		mode = "party",
		subpages = {
			auras = "buffs",
			texts = "name",
			indicators = "readyCheck",
			bars = "health",
		},
	}

addon.Options.ControllerState = controllerState

function Content:Ensure(parent)
	if content then
		return content
	end

	content = CreateFrame("Frame", nil, parent)

	local general = addon.Options.Pages.General:Ensure(content)
	local layout = addon.Options.Pages.Layout:Ensure(content)
	local frames = addon.Options.Pages.Frames:Ensure(content)
	local bars = addon.Options.Pages.Bars:Ensure(content)
	local texts = addon.Options.Pages.Texts:Ensure(content)
	local auras = addon.Options.Pages.Auras:Ensure(content)
	local indicators = addon.Options.Pages.Indicators:Ensure(content)
	local profiles = addon.Options.Pages.Profiles:Ensure(content)

	content.pages = {
		general = general,
		layout = layout,
		frames = frames,
		bars = bars,
		texts = texts,
		auras = auras,
		indicators = indicators,
		profiles = profiles,
	}

	for pageKey, pageFrame in pairs(content.pages) do
		pageFrame:ClearAllPoints()
		pageFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
		pageFrame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
		pageFrame:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
		pageFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
		pageFrame:SetShown(pageKey == activePage)
	end

	self:UpdateLayout()

	return content
end

function Content:UpdateLocale()
	if not content then
		return
	end

	for _, page in pairs(content.pages or {}) do
		if page.UpdateLocale then
			page:UpdateLocale()
		end
	end
end

function Content:UpdateLayout()
	if not content then
		return
	end

	for _, page in pairs(content.pages) do
		page:ClearAllPoints()
		page:SetPoint(
			"TOPLEFT",
			content,
			"TOPLEFT",
			addon.Utilities:ToUI(addon.Utilities:ToPixels(32)),
			-addon.Utilities:ToUI(addon.Utilities:ToPixels(32))
		)
		page:SetPoint(
			"TOPRIGHT",
			content,
			"TOPRIGHT",
			-addon.Utilities:ToUI(addon.Utilities:ToPixels(32)),
			-addon.Utilities:ToUI(addon.Utilities:ToPixels(32))
		)
		page:SetPoint(
			"BOTTOMLEFT",
			content,
			"BOTTOMLEFT",
			addon.Utilities:ToUI(addon.Utilities:ToPixels(32)),
			addon.Utilities:ToUI(addon.Utilities:ToPixels(32))
		)
		page:SetPoint(
			"BOTTOMRIGHT",
			content,
			"BOTTOMRIGHT",
			-addon.Utilities:ToUI(addon.Utilities:ToPixels(32)),
			addon.Utilities:ToUI(addon.Utilities:ToPixels(32))
		)

		page:UpdateLayout()
	end
end

function Content:SetActivePage(pageKey)
	activePage = pageKey

	if not content or not content.pages or not content.pages[pageKey] then
		return
	end

	addon.Options.Controls.Dropdown:CloseOpenDropdown()

	for key, pageFrame in pairs(content.pages) do
		pageFrame:SetShown(key == pageKey)
	end

	local page = content.pages[pageKey]
	if page.UpdateLayout then
		page:UpdateLayout()
	end

	if page.UpdateState then
		page:UpdateState(addon.Database:GetProfile())
	end

	if addon.Options.Sections.Preview and addon.Options.Sections.Preview.SetActivePage then
		addon.Options.Sections.Preview:SetActivePage(pageKey)
	end
end

function Content:GetActivePage()
	return activePage
end

function Content:SetMode(mode)
	controllerState.mode = mode == "raid" and "raid" or "party"

	if addon.Options.Sections.Preview and addon.Options.Sections.Preview.SetMode then
		addon.Options.Sections.Preview:SetMode(controllerState.mode)
	end

	if addon.FrameRegistry and addon.FrameRegistry.GetActiveTestMode then
		local activeTestMode = addon.FrameRegistry:GetActiveTestMode()
		if activeTestMode and activeTestMode ~= controllerState.mode then
			addon.FrameRegistry:ToggleTestMode(controllerState.mode)
		end
	end

	if addon.Options.Sections.StatusBar and addon.Options.Sections.StatusBar.UpdateState then
		addon.Options.Sections.StatusBar:UpdateState()
	end
end

function Content:GetControllerState()
	return controllerState
end
