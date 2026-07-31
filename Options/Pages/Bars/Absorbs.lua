local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}
addon.Options.Pages.Bars.Absorbs = addon.Options.Pages.Bars.Absorbs or {}

local Absorbs = addon.Options.Pages.Bars.Absorbs

local textureOptions = {
	{ value = "Flat", textKey = "Flat" },
	{ value = "Striped", textKey = "Striped" },
}

function Absorbs:Create(page)
	local subpage = page:RegisterSubPage("absorbs", { titleKey = "Absorbs" })

	local row = subpage:CreateRow(4)
	row:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local textureDropdown = row:CreateControl("Dropdown", { labelKey = "Texture" })
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
