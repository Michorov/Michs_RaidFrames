local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.Factory = addon.Frames.Widgets.Icons.Factory or {}

local Factory = addon.Frames.Widgets.Icons.Factory

local function ToSuffixFromKey(key)
	return (key:gsub("^%l", string.upper))
end

function Factory:CreateContainer(frame, key, frameLevelDelta)
	if not frame or not key then
		return nil
	end

	if frame[key] then
		return frame[key]
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not widgetsOverlay then
		return nil
	end

	local frameName
	if frame.GetName and frame:GetName() then
		frameName = frame:GetName() .. "_" .. ToSuffixFromKey(key)
	end

	local container = CreateFrame("Frame", frameName, widgetsOverlay)
	container:SetFrameStrata(widgetsOverlay:GetFrameStrata())
	container:SetFrameLevel(widgetsOverlay:GetFrameLevel() + (frameLevelDelta or 15))
	container.icons = container.icons or {}

	return container
end

function Factory:CreateIcon(container, iconFrameLevelDelta)
	if not container then
		return nil
	end

	local icon = CreateFrame("Frame", nil, container)
	icon:EnableMouse(false)
	icon:SetFrameStrata(container:GetFrameStrata())
	icon:SetFrameLevel(container:GetFrameLevel() + (iconFrameLevelDelta or 1))

	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	icon.cooldown:SetAllPoints(icon)
	icon.cooldown:SetReverse(true)
	icon.cooldown:SetHideCountdownNumbers(true)
	icon.cooldown:SetFrameStrata(container:GetFrameStrata())
	icon.cooldown:SetFrameLevel(icon:GetFrameLevel() + 2)

	icon.border = CreateFrame("Frame", nil, icon, "BackdropTemplate")
	icon.border:SetAllPoints(icon)
	icon.border:SetFrameStrata(container:GetFrameStrata())
	icon.border:SetFrameLevel(icon:GetFrameLevel() + 3)

	icon.textLayer = CreateFrame("Frame", nil, icon)
	icon.textLayer:SetAllPoints(icon)
	icon.textLayer:SetFrameStrata(container:GetFrameStrata())
	icon.textLayer:SetFrameLevel(icon:GetFrameLevel() + 20)

	icon.countText = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	icon.countText:SetText("")
	icon.countText:SetParent(icon.textLayer)
	icon.countText:SetDrawLayer("OVERLAY", 7)

	icon:Hide()
	return icon
end
