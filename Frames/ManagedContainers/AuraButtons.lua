local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ManagedContainers = addon.Frames.ManagedContainers or {}
addon.Frames.ManagedContainers.AuraButtons = addon.Frames.ManagedContainers.AuraButtons or {}

local AuraButtons = addon.Frames.ManagedContainers.AuraButtons

local function CreateBorderTexture(parent, fromPoint, toPoint)
	local texture = parent:CreateTexture(nil, "ARTWORK")
	texture:SetColorTexture(0, 0, 0, 1)
	texture:SetPoint(fromPoint, parent, fromPoint)
	texture:SetPoint(toPoint, parent, toPoint)

	return texture
end

function AuraButtons:ApplyTooltipSettings(button, cachedSettings)
	local enabled = cachedSettings.showTooltips == true

	if button.SetMouseClickEnabled then
		button:SetMouseClickEnabled(false)
	end

	if button.SetMouseMotionEnabled then
		button:SetMouseMotionEnabled(enabled == true)
	elseif button.EnableMouse then
		button:EnableMouse(enabled == true)
	end
end

function AuraButtons:Initialize(button, container)
	container.auraButtons = container.auraButtons or {}
	container.auraButtons[button] = true

	AuraButtons:ApplyTooltipSettings(button, { showTooltips = false })

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
		top = CreateBorderTexture(border, "TOPLEFT", "TOPRIGHT"),
		bottom = CreateBorderTexture(border, "BOTTOMLEFT", "BOTTOMRIGHT"),
		left = CreateBorderTexture(border, "TOPLEFT", "BOTTOMLEFT"),
		right = CreateBorderTexture(border, "TOPRIGHT", "BOTTOMRIGHT"),
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
	textLayer:SetFrameLevel(buttonFrameLevel + 3)
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

function AuraButtons:ApplyBorderSettings(button, cachedSettings)
	local scaledBorderSizePx = math.max(1, addon.Utilities:Scale(cachedSettings.borderSizePx))
	local borderSize = addon.Utilities:ToUI(scaledBorderSizePx)
	local border = button.border
	local edges = border.edges

	ApplyIconInsets(button, cachedSettings)

	edges.top:SetHeight(borderSize)
	edges.bottom:SetHeight(borderSize)
	edges.left:SetWidth(borderSize)
	edges.right:SetWidth(borderSize)

	if button.SetHitRectInsets then
		button:SetHitRectInsets(borderSize, borderSize, borderSize, borderSize)
	end
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
		cooldownFont:SetFont(addon.Utilities:GetGameFontNormalPath(), scaledSize, "OUTLINE")
		button.cooldown:SetCountdownFont(fontName)
	end
end

function AuraButtons:ApplyCountSettings(button, cachedSettings)
	local scaledStacksFontSize = addon.Utilities:ScaleFont(cachedSettings.stacksFontSize)
	local scaledBorderSizePx = math.max(1, addon.Utilities:Scale(cachedSettings.borderSizePx))

	button.count:SetFont(addon.Utilities:GetGameFontNormalPath(), scaledStacksFontSize, "OUTLINE")
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
