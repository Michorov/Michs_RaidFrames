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
	header.title:SetTextColor(theme:GetColor("brand"))

	header.closeButton = addon.Options.Controls.Button:Create(header, "X")
	header.closeButton:SetLayoutSize(24, 24)
	header.closeButton:SetLayoutBorderSize(0)
	header.closeButton.text:SetFont(theme.fonts.arialNarrow, 16, "")
	header.closeButton.text:SetTextColor(theme:GetTextColor("secondary"))
	header.closeButton:SetBackdropColor(0, 0, 0, 0)

	header.closeButton:SetOnClick(function()
		addon.Options:Close()
	end)

	header.closeButton:SetScript("OnEnter", function(self)
		self.text:SetTextColor(theme:GetColor("brand"))
	end)

	header.closeButton:SetScript("OnLeave", function(self)
		self.text:SetTextColor(theme:GetTextColor("secondary"))
	end)

	header.controls = {
		header.closeButton,
	}

	self:UpdateLayout()

	return header
end

function Header:UpdateLayout()
	if not header then
		return
	end

	for _, control in ipairs(header.controls or {}) do
		if control.UpdateLayout then
			control:UpdateLayout()
		end
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
	header.closeButton:SetPoint(
		"TOPRIGHT",
		header,
		"TOPRIGHT",
		addon.Utilities:ToUI(addon.Utilities:ToPixels(-8)),
		addon.Utilities:ToUI(addon.Utilities:ToPixels(-8))
	)
end
