local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}
addon.Options.Pages.Bars.HealAbsorbs = addon.Options.Pages.Bars.HealAbsorbs or {}

local HealAbsorbs = addon.Options.Pages.Bars.HealAbsorbs

local textureOptions = {
	{ value = "Flat", textKey = "Flat" },
	{ value = "Striped", textKey = "Striped" },
}

function HealAbsorbs:Create(page)
	local subpage = page:RegisterSubPage("healAbsorbs", { titleKey = "Heal Absorbs" })

	local row = subpage:CreateRow(4)
	row:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local textureDropdown = row:CreateControl("Dropdown", { labelKey = "Texture" })
	textureDropdown:SetOptions(textureOptions)
	textureDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.bars.healAbsorbs.texture
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.bars.healAbsorbs.texture = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healAbsorbsSettingsChanged")
		end,
	})

	local colorPicker = row:CreateControl("ColorPicker", { labelKey = "Heal Absorb Color" })
	colorPicker:SetHasOpacity(true)
	colorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].widgets.bars.healAbsorbs.color
		end,
		set = function(profile, mode, value)
			profile[mode].widgets.bars.healAbsorbs.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healAbsorbsSettingsChanged")
		end,
	})

	return subpage
end
