local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.Header = addon.Options.Sections.Header or {}

local Header = addon.Options.Sections.Header

local header
local theme = addon.Options.Theme

function Header:Ensure(parent)
	if header then
		return header
	end

	header = CreateFrame("Frame", nil, parent)

	header.title = header:CreateFontString(nil, "OVERLAY")
	header.title:SetJustifyH("LEFT")
	header.title:SetFont(theme.fonts.philosopherBold, 22, "")
	header.title:SetText("Mich's Raid Frames")
	header.title:SetTextColor(
		theme.colors.brand[1],
		theme.colors.brand[2],
		theme.colors.brand[3],
		theme.colors.brand[4]
	)

	header.closeButton = addon.Options.Controls.Button:Create(header, "X")
	header.closeButton:SetBackdropColor(0, 0, 0, 0)
	header.closeButton.borderTop:Hide()
	header.closeButton.borderBottom:Hide()
	header.closeButton.borderLeft:Hide()
	header.closeButton.borderRight:Hide()
	header.closeButton.text:SetFont(theme.fonts.arialNarrow, 16, "")
	header.closeButton.text:SetTextColor(0.72, 0.74, 0.78, 1)
	header.closeButton:SetScript("OnClick", function()
		addon.Options:Close()
	end)
	header.closeButton:SetScript("OnEnter", function(self)
		self.text:SetTextColor(
			theme.colors.brand[1],
			theme.colors.brand[2],
			theme.colors.brand[3],
			theme.colors.brand[4]
		)
	end)
	header.closeButton:SetScript("OnLeave", function(self)
		self.text:SetTextColor(0.72, 0.74, 0.78, 1)
	end)

	self:UpdateLayout()

	return header
end

function Header:UpdateLayout()
	if not header then
		return
	end

	header.title:ClearAllPoints()
	header.title:SetPoint(
		"TOPLEFT",
		header,
		"TOPLEFT",
		addon.Utilities:ToUI(addon.Utilities:ToPixels(8)),
		addon.Utilities:ToUI(addon.Utilities:ToPixels(-8))
	)

	header.closeButton:ClearAllPoints()
	header.closeButton:SetSize(24, 24)
	header.closeButton:SetPoint(
		"TOPRIGHT",
		header,
		"TOPRIGHT",
		addon.Utilities:ToUI(addon.Utilities:ToPixels(-8)),
		addon.Utilities:ToUI(addon.Utilities:ToPixels(-8))
	)
end
