local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Managers = addon.Frames.Managers or {}
addon.Frames.Managers.IconManager = addon.Frames.Managers.IconManager or {}

local IconManager = addon.Frames.Managers.IconManager
local issecretvalue = issecretvalue

local function ToSuffixFromKey(key)
	return (key:gsub("^%l", string.upper))
end

function IconManager:CreateContainer(frame, key, level)
	if not frame or not key then
		return nil
	end

	if frame[key] then
		return frame[key]
	end

	local frameName
	if frame.GetName and frame:GetName() then
		frameName = frame:GetName() .. "_" .. ToSuffixFromKey(key)
	end

	local container = CreateFrame("Frame", frameName, frame)
	container:SetFrameLevel(level)
	container.icons = {}

	return container
end

function IconManager:HideIcons(container, maxIcons)
	if not container or not container.icons then
		return
	end

	for i = 1, maxIcons do
		local icon = container.icons[i]
		if icon then
			icon:Hide()
		end
	end

	container:SetShown(false)
end

function IconManager:CreateIcon(container, iconFrameLevelDelta)
	if not container then
		return nil
	end

	local icon = CreateFrame("Frame", nil, container)
	icon:EnableMouse(false)
	icon:SetFrameLevel(container:GetFrameLevel() + (iconFrameLevelDelta or 1))

	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	icon.border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
	icon.border:SetAllPoints(icon)
	icon.border:SetFrameLevel(icon:GetFrameLevel() + 2)

	icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	icon.cooldown:SetAllPoints(icon)
	icon.cooldown:SetReverse(true)
	icon.cooldown:SetHideCountdownNumbers(true)
	icon.cooldown:SetFrameLevel(icon:GetFrameLevel() + 1)

	icon.textLayer = CreateFrame("Frame", nil, icon)
	icon.textLayer:SetAllPoints(icon)
	icon.textLayer:SetFrameLevel(icon:GetFrameLevel() + 20)

	for _, region in ipairs({ icon.cooldown:GetRegions() }) do
		if region and region.GetObjectType and region:GetObjectType() == "FontString" then
			region:SetParent(icon.textLayer)
			region:ClearAllPoints()
			region:SetPoint("CENTER", icon.cooldown, "CENTER")
			break
		end
	end

	icon.countText = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	icon.countText:SetText("")
	icon.countText:SetParent(icon.textLayer)
	icon.countText:SetDrawLayer("OVERLAY", 7)

	icon:Hide()
	return icon
end

local function ApplyTextureInsets(icon, settings)
	local scaledBorderSizePx = math.max(1, addon.Utilities:Scale(settings.borderSizePx))

	icon.texture:ClearAllPoints()
	icon.texture:SetPoint(
		"TOPLEFT",
		icon,
		"TOPLEFT",
		addon.Utilities:ToUI(scaledBorderSizePx),
		-addon.Utilities:ToUI(scaledBorderSizePx)
	)
	icon.texture:SetPoint(
		"BOTTOMRIGHT",
		icon,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(scaledBorderSizePx),
		addon.Utilities:ToUI(scaledBorderSizePx)
	)
end

function IconManager:ApplyIconSizeSettings(icon, settings)
	local scaledIconSizePx = addon.Utilities:Scale(settings.iconSizePx)
	icon:SetSize(addon.Utilities:ToUI(scaledIconSizePx), addon.Utilities:ToUI(scaledIconSizePx))
end

function IconManager:ApplyEvenIconSizeSettings(icon, settings)
	local scaledIconSizePx = addon.Utilities:ScaleEven(settings.iconSizePx)
	icon:SetSize(addon.Utilities:ToUI(scaledIconSizePx), addon.Utilities:ToUI(scaledIconSizePx))
end

function IconManager:ApplyBorderColor(icon, color)
	if not icon or not icon.border or not color then
		return
	end

	icon.border:SetBackdropBorderColor(color.r, color.g, color.b, color.a or 1)
end

function IconManager:ApplyBorderSettings(icon, settings)
	local scaledBorderSizePx = math.max(1, addon.Utilities:Scale(settings.borderSizePx))

	ApplyTextureInsets(icon, settings)

	icon.border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = addon.Utilities:ToUI(scaledBorderSizePx),
	})

	self:ApplyBorderColor(icon, { r = 0, g = 0, b = 0, a = 1 })
end

function IconManager:ApplyCountSettings(icon, settings)
	local scaledFontSize = addon.Utilities:ScaleFont(settings.stacksFontSize)
	local scaledBorderSizePx = math.max(1, addon.Utilities:Scale(settings.borderSizePx))

	icon.countText:SetFont("Fonts\\FRIZQT__.TTF", scaledFontSize, "OUTLINE")
	icon.countText:ClearAllPoints()
	icon.countText:SetTextColor(1, 1, 1, 1)
	icon.countText:SetShown(settings.showStacks)
	icon.countText:SetPoint(
		"BOTTOMRIGHT",
		icon,
		"BOTTOMRIGHT",
		-addon.Utilities:ToUI(scaledBorderSizePx - 2),
		addon.Utilities:ToUI(scaledBorderSizePx - 2)
	)
end

function IconManager:ApplyCooldownSettings(icon, settings)
	if icon.cooldown and icon.cooldown.SetHideCountdownNumbers then
		icon.cooldown:SetHideCountdownNumbers(not settings.showCooldown)
	end

	if settings.showCooldown and icon.cooldown and icon.cooldown.SetCountdownFont then
		local scaledSize = addon.Utilities:ScaleFont(settings.cooldownFontSize)
		local fontName = "MRF_CooldownFont_" .. tostring(scaledSize)
		local cooldownFont = _G[fontName]
		if not cooldownFont then
			cooldownFont = CreateFont(fontName)
		end
		cooldownFont:SetFont("Fonts\\FRIZQT__.TTF", scaledSize, "OUTLINE")
		icon.cooldown:SetCountdownFont(fontName)
	end
end

function IconManager:ApplyIconState(icon, state)
	if not icon then
		return
	end

	if icon.texture then
		local currentTexture = icon.texture:GetTexture()
		local currentTextureIsSecret = issecretvalue and issecretvalue(currentTexture)
		local newTextureIsSecret = issecretvalue and issecretvalue(state.texture)

		if currentTextureIsSecret or newTextureIsSecret or currentTexture ~= state.texture then
			icon.texture:SetTexture(state.texture)
		end
	end

	if icon.countText then
		icon.countText:SetText(state.countText or "")
	end

	if icon.cooldown then
		if state.durationObject and icon.cooldown.SetCooldownFromDurationObject then
			icon.cooldown:SetCooldownFromDurationObject(state.durationObject)
		end

		if icon.cooldown.SetShownFromBoolean then
			icon.cooldown:SetShownFromBoolean(state.hasExpiration, true, false)
		else
			icon.cooldown:Show()
		end
	end

	icon:Show()
end
