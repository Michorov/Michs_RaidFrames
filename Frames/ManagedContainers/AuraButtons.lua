local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.AuraButtons = addon.Frames.ManagedContainers.AuraButtons or {}

local AuraButtons = addon.Frames.ManagedContainers.AuraButtons

local function CreateBorderTexture(parent)
	local texture = parent:CreateTexture(nil, "ARTWORK")
	texture:SetColorTexture(0, 0, 0, 1)
	return texture
end

function AuraButtons:Initialize(button, container)
	container.auraButtons = container.auraButtons or {}
	container.auraButtons[button] = true

	button:EnableMouse(false)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(button)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon = icon
	button:SetIcon(icon)

	local buttonFrameLevel = button:GetFrameLevel()

	local border = CreateFrame("Frame", nil, button)
	border:SetAllPoints(button)
	border:SetFrameLevel(buttonFrameLevel + 2)
	border.edges = {
		top = CreateBorderTexture(border),
		bottom = CreateBorderTexture(border),
		left = CreateBorderTexture(border),
		right = CreateBorderTexture(border),
	}
	button.border = border

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(button)
	cooldown:SetReverse(true)
	cooldown:SetFrameLevel(buttonFrameLevel + 1)
	button.cooldown = cooldown
	button:SetDurationCooldown(cooldown)

	local textLayer = CreateFrame("Frame", nil, button)
	textLayer:SetAllPoints(button)
	textLayer:SetFrameLevel(buttonFrameLevel + 20)
	button.textLayer = textLayer

	for _, region in ipairs({ cooldown:GetRegions() }) do
		if region and region.GetObjectType and region:GetObjectType() == "FontString" then
			region:SetParent(textLayer)
			region:ClearAllPoints()
			region:SetPoint("CENTER", cooldown, "CENTER")
			break
		end
	end

	local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	count:SetTextColor(1, 1, 1, 1)
	count:SetParent(textLayer)
	count:SetDrawLayer("OVERLAY", 7)
	button.count = count
	button:SetApplicationCount(count, {})
end

local function ApplyIconInsets(button, cachedSettings)
	local scaledBorderSizePx = math.max(1, addon.Utilities:Scale(cachedSettings.borderSizePx))

	button.icon:ClearAllPoints()
	button.icon:SetPoint(
		"TOPLEFT",
		button,
		"TOPLEFT",
		addon.Utilities:ToUI(scaledBorderSizePx),
		-addon.Utilities:ToUI(scaledBorderSizePx)
	)
	button.icon:SetPoint(
		"BOTTOMRIGHT",
		button,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(scaledBorderSizePx),
		addon.Utilities:ToUI(scaledBorderSizePx)
	)
end

function AuraButtons:ApplyIconSettings(button, cachedSettings)
	local scaledIconSizePx = addon.Utilities:Scale(cachedSettings.iconSizePx)

	button:SetSize(addon.Utilities:ToUI(scaledIconSizePx), addon.Utilities:ToUI(scaledIconSizePx))
end

function AuraButtons:ApplyBorderColor(button, color)
	if not button or not button.border or not color then
		return
	end

	for _, texture in pairs(button.border.edges) do
		texture:SetColorTexture(color.r, color.g, color.b, color.a or 1)
	end
end

function AuraButtons:ApplyBorderSettings(button, cachedSettings)
	local scaledBorderSizePx = math.max(1, addon.Utilities:Scale(cachedSettings.borderSizePx))
	local borderSize = addon.Utilities:ToUI(scaledBorderSizePx)
	local border = button.border
	local edges = border.edges

	ApplyIconInsets(button, cachedSettings)

	edges.top:ClearAllPoints()
	edges.top:SetPoint("TOPLEFT", border, "TOPLEFT")
	edges.top:SetPoint("TOPRIGHT", border, "TOPRIGHT")
	edges.top:SetHeight(borderSize)

	edges.bottom:ClearAllPoints()
	edges.bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
	edges.bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
	edges.bottom:SetHeight(borderSize)

	edges.left:ClearAllPoints()
	edges.left:SetPoint("TOPLEFT", border, "TOPLEFT")
	edges.left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
	edges.left:SetWidth(borderSize)

	edges.right:ClearAllPoints()
	edges.right:SetPoint("TOPRIGHT", border, "TOPRIGHT")
	edges.right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
	edges.right:SetWidth(borderSize)

	self:ApplyBorderColor(button, { r = 0, g = 0, b = 0, a = 1 })
end

function AuraButtons:ApplyCooldownSettings(button, cachedSettings)
	button.cooldown:SetHideCountdownNumbers(not cachedSettings.showCooldown)

	if cachedSettings.showCooldown and button.cooldown.SetCountdownFont then
		local scaledSize = addon.Utilities:ScaleFont(cachedSettings.cooldownFontSize)
		local fontName = "MRF_CooldownFont_" .. tostring(scaledSize)
		local cooldownFont = _G[fontName]
		if not cooldownFont then
			cooldownFont = CreateFont(fontName)
		end
		cooldownFont:SetFont("Fonts\\FRIZQT__.TTF", scaledSize, "OUTLINE")
		button.cooldown:SetCountdownFont(fontName)
	end
end

function AuraButtons:ApplyCountSettings(button, cachedSettings)
	local scaledStacksFontSize = addon.Utilities:ScaleFont(cachedSettings.stacksFontSize)
	local scaledBorderSizePx = math.max(1, addon.Utilities:Scale(cachedSettings.borderSizePx))

	button.count:SetFont("Fonts\\FRIZQT__.TTF", scaledStacksFontSize, "OUTLINE")
	button.count:ClearAllPoints()
	button.count:SetAlpha(cachedSettings.showStacks and 1 or 0)
	button.count:SetPoint(
		"BOTTOMRIGHT",
		button,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(scaledBorderSizePx - 2),
		addon.Utilities:ToUI(scaledBorderSizePx - 2)
	)
end
