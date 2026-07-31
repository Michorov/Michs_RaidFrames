local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Texts = addon.Options.Pages.Texts or {}
addon.Options.Pages.Texts.StatusText = addon.Options.Pages.Texts.StatusText or {}

local StatusText = addon.Options.Pages.Texts.StatusText

local function FormatInteger(value)
	return string.format("%d", value)
end

function StatusText:Create(page)
	local subpage = page:RegisterSubPage("statusText", { titleKey = "Status" })

	local fontRow = subpage:CreateRow(4)
	fontRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local fontDropdown = fontRow:CreateControl("Dropdown", { labelKey = "Font" })
	fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions(nil, true))
	fontDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.statusText.lsmFont
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.statusText.lsmFont = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("statusTextSettingsChanged")
		end,
	})

	local sizeSlider = fontRow:CreateControl("Slider", { labelKey = "Font Size" })
	sizeSlider:SetMinMaxValues(6, 32)
	sizeSlider:SetStep(1)
	sizeSlider:SetValueFormatter(FormatInteger)
	sizeSlider:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.texts.statusText.size
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.texts.statusText.size = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("statusTextSettingsChanged")
		end,
	})

	subpage:SetStateUpdater(function(profile, mode)
		local settings = profile[mode].widgets.texts.statusText
		fontDropdown:SetOptions(addon.Styles.Fonts:GetOptions(settings.lsmFont, true))
	end)

	return subpage
end
