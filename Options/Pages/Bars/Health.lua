local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Pages = addon.Options.Pages or {}
addon.Options.Pages.Bars = addon.Options.Pages.Bars or {}
addon.Options.Pages.Bars.Health = addon.Options.Pages.Bars.Health or {}

local Health = addon.Options.Pages.Bars.Health

local colorModeOptions = {
	{ value = true, textKey = "Class Color" },
	{ value = false, textKey = "Static" },
}

function Health:Create(page)
	local subpage = page:RegisterSubPage("health", { titleKey = "Health" })

	local textureRow = subpage:CreateRow(4)
	textureRow:SetLayoutPoint("TOPLEFT", subpage.frame, "TOPLEFT", 0, 0)

	local textureDropdown = textureRow:CreateControl("Dropdown", { labelKey = "Texture" })
	textureDropdown:SetOptions(addon.Styles.Textures:GetOptions(nil, true))
	textureDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].health.lsmTexture
		end,
		set = function(profile, mode, value)
			profile[mode].health.lsmTexture = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthSettingsChanged")
		end,
	})

	local colorRow = subpage:CreateRow(4)
	colorRow:SetLayoutPoint("TOPLEFT", textureRow.frame, "BOTTOMLEFT", 0, -24)

	local colorModeDropdown = colorRow:CreateControl("Dropdown", { labelKey = "Color" })
	colorModeDropdown:SetOptions(colorModeOptions)
	colorModeDropdown:BindValue({
		get = function(profile, mode)
			return profile[mode].health.classColor
		end,
		set = function(profile, mode, value)
			profile[mode].health.classColor = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthSettingsChanged")
		end,
	})

	local healthColorPicker = colorRow:CreateControl("ColorPicker", { labelKey = "Health Color" })
	healthColorPicker:SetHasOpacity(true)
	healthColorPicker:BindValue({
		get = function(profile, mode)
			return profile[mode].health.color
		end,
		set = function(profile, mode, value)
			profile[mode].health.color = value
		end,
		onChange = function()
			addon.UpdateScheduler:Notify("healthSettingsChanged")
		end,
	})

	subpage:SetStateUpdater(function(profile, mode)
		local settings = profile[mode].health
		textureDropdown:SetOptions(addon.Styles.Textures:GetOptions(settings.lsmTexture, true))
	end)

	return subpage
end
