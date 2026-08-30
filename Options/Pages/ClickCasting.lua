local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.ClickCasting = addon.Options.Pages.ClickCasting or {}

local ClickCasting = addon.Options.Pages.ClickCasting
local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)

local sourceOptions = {
	{ value = "blizzard", textKey = "Blizzard Click Casting" },
	{ value = "mrf", textKey = "MRF Click Casting" },
	{ value = "external", textKey = "Other Addon" },
}

function ClickCasting:Create(panel)
	local page = panel:RegisterPage("clickCasting", {
		titleKey = "Click Casting",
		showHeader = true,
	})
	local subpage = page:RegisterSubPage("clickCasting", { titleKey = "Click Casting" })

	local settingsRow = subpage:CreateRow(3)
	settingsRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local sourceDropdown = settingsRow:CreateControl("Dropdown", { labelKey = "Source" })
	sourceDropdown:SetOptions(sourceOptions)
	sourceDropdown:BindValue({
		get = function(profile)
			return profile.core.clickCasting.source
		end,
		set = function(profile, _, value)
			profile.core.clickCasting.source = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("clickCastingSettingsChanged")
		end,
	})

	subpage.pageText = subpage.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	subpage.pageText:SetJustifyH("LEFT")
	subpage.pageText:SetText(panel:Localize("Click Casting page"))
	if OptionsUILib then
		subpage.pageText:SetTextColor(OptionsUILib.Theme:GetTextColor("primary"))
	end

	local baseUpdateLocale = subpage.UpdateLocale
	function subpage:UpdateLocale()
		baseUpdateLocale(self)
		self.pageText:SetText(panel:Localize("Click Casting page"))
	end

	local baseUpdateLayout = subpage.UpdateLayout
	function subpage:UpdateLayout()
		baseUpdateLayout(self)

		local PP = panel.instance.PP
		self.pageText:ClearAllPoints()
		self.pageText:SetPoint("TOPLEFT", settingsRow.frame, "BOTTOMLEFT", 0, PP:ToUIScaled(-16))
		if OptionsUILib then
			OptionsUILib.Theme:ApplyFont(self.pageText, PP:ScaleFont(14), "")
		end
	end

	subpage:UpdateLayout()

	return page
end
