local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Auras = addon.Options.Pages.Auras or {}

local Auras = addon.Options.Pages.Auras

local page
local theme = addon.Options.Theme

function Auras:Ensure(parent)
	if page then
		return page
	end

	page = CreateFrame("Frame", nil, parent)

	page.title = page:CreateFontString(nil, "OVERLAY")
	page.title:SetJustifyH("LEFT")
	page.title:SetFont(theme.fonts.arialNarrow, 18, "")
	page.title:SetTextColor(0.85, 0.85, 0.88, 1)
	page.title:SetText("Auras")

	page.description = page:CreateFontString(nil, "OVERLAY")
	page.description:SetJustifyH("LEFT")
	page.description:SetFont(theme.fonts.arialNarrow, 12, "")
	page.description:SetTextColor(0.65, 0.65, 0.68, 1)
	page.description:SetText("Aura settings will go here.")

	self:UpdateLayout()

	return page
end

function Auras:UpdateLayout()
	if not page then
		return
	end

	page.title:ClearAllPoints()
	page.title:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -16)

	page.description:ClearAllPoints()
	page.description:SetPoint("TOPLEFT", page.title, "BOTTOMLEFT", 0, -8)
end
