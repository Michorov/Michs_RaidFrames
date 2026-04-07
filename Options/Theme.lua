local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Theme = addon.Options.Theme or {}

local Theme = addon.Options.Theme

Theme.colors = Theme.colors or {}
Theme.fonts = Theme.fonts or {}

Theme.colors.brand = { 0.96, 0.66, 0.31, 1 }
Theme.colors.panelBackground = { 0.05, 0.07, 0.09, 0.96 }
Theme.colors.border = { 0.15, 0.17, 0.20, 1 }

Theme.fonts.arialNarrow = "Fonts\\ARIALN.TTF"
Theme.fonts.philosopherBold = "Interface\\AddOns\\Michs_RaidFrames\\Media\\Fonts\\Philosopher-Bold.ttf"
