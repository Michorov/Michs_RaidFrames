local addonName = ... or "Michs_OptionsUILib"
local OptionsUILib = LibStub("MichsOptionsUILib-1.0", true)
if not OptionsUILib then
	return
end

local Theme = OptionsUILib.Theme

Theme.colors = Theme.colors or {}
Theme.fonts = Theme.fonts or {}
Theme.registeredFonts = Theme.registeredFonts or {}

Theme.colors.background = { 0.05, 0.07, 0.09, 0.96 }
Theme.colors.border = { 0.15, 0.17, 0.20, 1 }
Theme.colors.controlBackground = { 0.04, 0.05, 0.07, 1 }
Theme.colors.controlHoverOverlay = { 1, 1, 1, 0.03 }
Theme.colors.buttonBackground = { 0.12, 0.12, 0.14, 1 }
Theme.colors.buttonBackgroundHover = { 0.18, 0.18, 0.22, 1 }
Theme.colors.brand = { 0.96, 0.66, 0.31, 1 }

Theme.colors.text = Theme.colors.text or {}
Theme.colors.text.primary = { 0.85, 0.85, 0.88, 1 }
Theme.colors.text.secondary = { 0.72, 0.74, 0.78, 1 }
Theme.colors.text.placeholder = { 0.50, 0.52, 0.56, 1 }
Theme.colors.text.highlight = { 0.88, 0.89, 0.92, 1 }
Theme.colors.text.success = { 0.00, 1.00, 0.00, 1 }
Theme.colors.text.warning = { 1.00, 0.78, 0.24, 1 }
Theme.colors.text.danger = { 1.00, 0.32, 0.32, 1 }

local fontPath = "Interface\\AddOns\\" .. addonName .. "\\Libs\\MichsOptionsUILib-1.0\\Media\\Fonts\\"

Theme.fonts.default = "Fonts\\ARIALN.TTF"
Theme.fonts.title = fontPath .. "Philosopher-Bold.ttf"
Theme.fonts.koKR = "Fonts\\2002.TTF"
Theme.fonts.zhCN = "Fonts\\ARKai_C.ttf"
Theme.fonts.zhTW = "Fonts\\bHEI00M.ttf"

Theme.fontPreloadText = {
	default = "cache",
	title = "cache",
	koKR = "캐시",
	zhCN = "缓存",
	zhTW = "快取",
}

setmetatable(Theme.registeredFonts, { __mode = "k" })

function Theme:GetColor(colorKey, opacity)
	local color = self.colors[colorKey]
	if not color then
		return 1, 1, 1, opacity or 1
	end

	return color[1], color[2], color[3], opacity or color[4]
end

function Theme:GetTextColor(colorKey, opacity)
	local color = self.colors.text and self.colors.text[colorKey]
	if not color then
		return 1, 1, 1, opacity or 1
	end

	return color[1], color[2], color[3], opacity or color[4]
end

function Theme:SetActiveLocale(locale)
	self.activeLocale = locale
end

function Theme:GetActiveLocale()
	return self.activeLocale or GetLocale() or "enUS"
end

function Theme:GetFont(fontStyle)
	if fontStyle == "title" then
		return self.fonts.title
	end

	return self.fonts[self:GetActiveLocale()] or self.fonts.default
end

function Theme:ApplyFont(fontString, size, flags, fontStyle)
	if not fontString then
		return false
	end

	local resolvedSize = size or 12
	local resolvedFlags = flags or ""

	self.registeredFonts[fontString] = {
		size = resolvedSize,
		flags = resolvedFlags,
		fontStyle = fontStyle,
	}

	return fontString:SetFont(self:GetFont(fontStyle), resolvedSize, resolvedFlags)
end

function Theme:RefreshFonts()
	for fontString, settings in pairs(self.registeredFonts) do
		self:ApplyFont(fontString, settings.size, settings.flags, settings.fontStyle)
	end
end

function Theme:PreloadFonts()
	if self.fontPreloadFrame then
		return
	end

	local frame = CreateFrame("Frame")
	frame:Hide()

	for fontKey, font in pairs(self.fonts) do
		local text = frame:CreateFontString(nil, "OVERLAY")
		text:SetFont(font, 12, "")
		text:SetText(self.fontPreloadText[fontKey] or self.fontPreloadText.default)
	end

	self.fontPreloadFrame = frame
end

local preloadFrame = CreateFrame("Frame")
preloadFrame:SetScript("OnEvent", function(self)
	Theme:PreloadFonts()
	self:UnregisterEvent("PLAYER_LOGIN")
end)

if IsLoggedIn and IsLoggedIn() then
	Theme:PreloadFonts()
else
	preloadFrame:RegisterEvent("PLAYER_LOGIN")
end
