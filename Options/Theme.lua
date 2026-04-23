local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Theme = addon.Options.Theme or {}

local Theme = addon.Options.Theme

Theme.colors = Theme.colors or {}
Theme.fonts = Theme.fonts or {}
Theme.registeredFonts = Theme.registeredFonts or {}

Theme.colors.brand = { 0.96, 0.66, 0.31, 1 }
Theme.colors.panelBackground = { 0.05, 0.07, 0.09, 0.96 }
Theme.colors.border = { 0.15, 0.17, 0.20, 1 }
Theme.colors.controlBackground = { 0.04, 0.05, 0.07, 1 }
Theme.colors.controlHoverOverlay = { 1, 1, 1, 0.03 }
Theme.colors.buttonBackground = { 0.12, 0.12, 0.14, 1 }
Theme.colors.buttonBackgroundHover = { 0.18, 0.18, 0.22, 1 }

function Theme:GetColor(colorKey, opacity)
	local color = self.colors[colorKey]
	if not color then
		return 1, 1, 1, opacity or 1
	end

	return color[1], color[2], color[3], opacity or color[4]
end

Theme.colors.text = Theme.colors.text or {}
Theme.colors.text.primary = { 0.85, 0.85, 0.88, 1 }
Theme.colors.text.secondary = { 0.72, 0.74, 0.78, 1 }
Theme.colors.text.placeholder = { 0.50, 0.52, 0.56, 1 }
Theme.colors.text.highlight = { 0.88, 0.89, 0.92, 1 }
Theme.colors.text.success = { 0.00, 1.00, 0.00, 1 }
Theme.colors.text.warning = { 1.00, 0.78, 0.24, 1 }
Theme.colors.text.danger = { 1.00, 0.32, 0.32, 1 }

function Theme:GetTextColor(colorKey, opacity)
	local color = self.colors.text and self.colors.text[colorKey]
	if not color then
		return 1, 1, 1, opacity or 1
	end

	return color[1], color[2], color[3], opacity or color[4]
end

Theme.fonts.arialNarrow = "Fonts\\ARIALN.TTF"
Theme.fonts.philosopherBold = "Interface\\AddOns\\Michs_RaidFrames\\Media\\Fonts\\Philosopher-Bold.ttf"
Theme.fonts.korean = "Fonts\\2002.TTF"
Theme.fonts.chineseSimplified = "Fonts\\ARKai_C.ttf"
Theme.fonts.chineseTraditional = "Fonts\\bHEI00M.ttf"

Theme.localeFontFallbacks = Theme.localeFontFallbacks
	or {
		koKR = {
			Theme.fonts.korean,
			"Fonts\\K_Pagetext.TTF",
			Theme.fonts.arialNarrow,
		},
		zhCN = {
			Theme.fonts.chineseSimplified,
			"Fonts\\ARHei.TTF",
			Theme.fonts.arialNarrow,
		},
		zhTW = {
			Theme.fonts.chineseTraditional,
			"Fonts\\bLEI00D.ttf",
			Theme.fonts.arialNarrow,
		},
	}

setmetatable(Theme.registeredFonts, { __mode = "k" })

function Theme:GetActiveLocale()
	if addon.Locale and addon.Locale.GetCurrentLocale then
		return addon.Locale:GetCurrentLocale()
	end

	return GetLocale() or "enUS"
end

function Theme:GetFontCandidates(fontKey)
	local localeFonts = self.localeFontFallbacks[self:GetActiveLocale()]
	if localeFonts then
		return localeFonts
	end

	return {
		self.fonts[fontKey] or self.fonts.arialNarrow,
		self.fonts.arialNarrow,
		STANDARD_TEXT_FONT,
	}
end

function Theme:ApplyFont(fontString, fontKey, size, flags)
	if not fontString then
		return false
	end

	local resolvedFontKey = fontKey or "arialNarrow"
	local resolvedSize = size or 12
	local resolvedFlags = flags or ""

	self.registeredFonts[fontString] = {
		fontKey = resolvedFontKey,
		size = resolvedSize,
		flags = resolvedFlags,
	}

	for _, fontPath in ipairs(self:GetFontCandidates(resolvedFontKey)) do
		if fontPath and fontString:SetFont(fontPath, resolvedSize, resolvedFlags) then
			return true
		end
	end

	return false
end

function Theme:RefreshFonts()
	for fontString, settings in pairs(self.registeredFonts) do
		self:ApplyFont(fontString, settings.fontKey, settings.size, settings.flags)
	end
end
