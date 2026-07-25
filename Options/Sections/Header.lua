local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.Header = addon.Options.Sections.Header or {}

local Header = addon.Options.Sections.Header

local header
local L = addon.L
local theme = addon.Options.Theme

function Header:Ensure(parent)
	if header then
		return header
	end

	header = CreateFrame("Frame", nil, parent)

	header.title = header:CreateFontString(nil, "OVERLAY")
	header.title:SetJustifyH("LEFT")
	theme:ApplyFont(header.title, "philosopherBold", 22, "")
	header.title:SetText(L["Mich's Raid Frames"])
	header.title:SetTextColor(theme:GetColor("brand"))

	local closeButton = addon.Options.Controls.Button:Create(header, "X")
	closeButton:SetLayoutSize(24, 24)
	closeButton:SetLayoutBorderSize(0)
	closeButton:SetFontSize(16)
	closeButton.text:SetTextColor(theme:GetTextColor("secondary"))
	closeButton:SetBackdropColor(0, 0, 0, 0)

	closeButton:SetOnClick(function()
		addon.Options:Close()
	end)

	closeButton:SetScript("OnEnter", function(self)
		self.text:SetTextColor(theme:GetColor("brand"))
	end)

	closeButton:SetScript("OnLeave", function(self)
		self.text:SetTextColor(theme:GetTextColor("secondary"))
	end)

	header.controls = {
		closeButton = closeButton,
	}

	self:UpdateLocale()
	self:UpdateLayout()

	return header
end

function Header:UpdateLocale()
	if not header then
		return
	end

	header.title:SetText(L["Mich's Raid Frames"])
end

function Header:UpdateLayout()
	if not header then
		return
	end

	for _, control in pairs(header.controls or {}) do
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

	header.controls.closeButton:ClearAllPoints()
	header.controls.closeButton:SetPoint(
		"TOPRIGHT",
		header,
		"TOPRIGHT",
		addon.Utilities:ToUI(addon.Utilities:ToPixels(-8)),
		addon.Utilities:ToUI(addon.Utilities:ToPixels(-8))
	)
end
