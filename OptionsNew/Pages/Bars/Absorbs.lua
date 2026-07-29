local _, addon = ...

addon.OptionsNew = addon.OptionsNew or {}
addon.OptionsNew.Pages = addon.OptionsNew.Pages or {}
addon.OptionsNew.Pages.Bars = addon.OptionsNew.Pages.Bars or {}
addon.OptionsNew.Pages.Bars.Absorbs = addon.OptionsNew.Pages.Bars.Absorbs or {}

local Absorbs = addon.OptionsNew.Pages.Bars.Absorbs

local textureOptions = {
	{ value = "Flat", textKey = "Flat" },
	{ value = "Striped", textKey = "Striped" },
}

function Absorbs:Create(page)
	local subpage = page:RegisterSubPage("absorbs", { titleKey = "Absorbs" })

	local row = subpage:CreateRow(4)
	row:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local textureDropdown = row:CreateControl("Dropdown", { labelKey = "Shield Texture" })
	textureDropdown:SetOptions(textureOptions)
	textureDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.bars.absorbs.texture
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.bars.absorbs.texture = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("absorbsSettingsChanged")
		end,
	})

	local colorPicker = row:CreateControl("ColorPicker", { labelKey = "Shield Color" })
	colorPicker:SetHasOpacity(true)
	colorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.bars.absorbs.color
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.bars.absorbs.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("absorbsSettingsChanged")
		end,
	})

	return subpage
end
