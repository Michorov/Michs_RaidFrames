local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.PrivateAuras = addon.Frames.Widgets.Icons.PrivateAuras or {}

local PrivateAuras = addon.Frames.Widgets.Icons.PrivateAuras

local TEST_PRIVATE_AURA_SAMPLES = {
	{ spellID = 407221, dispelType = "Magic", duration = 8 },
	{ spellID = 418720, dispelType = "Curse", duration = 12 },
	{ spellID = 421828, dispelType = "Disease", duration = 6 },
	{ spellID = 428970, dispelType = "Poison", duration = 10 },
	{ spellID = 406317, dispelType = "None", duration = 14 },
}

local DEBUFF_DISPLAY_INFO = AuraUtil and AuraUtil.GetDebuffDisplayInfoTable and AuraUtil.GetDebuffDisplayInfoTable()
	or nil

local function GetPrivateAurasSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local icons = widgets.icons or {}
	local privateAuras = icons.privateAuras or {}

	return {
		anchor = privateAuras.anchor or "LEFT",
		relativeAnchor = privateAuras.relativeAnchor or "LEFT",
		offsetXPx = addon.Utilities:ToPixels(privateAuras.offsetX or 2),
		offsetYPx = addon.Utilities:ToPixels(privateAuras.offsetY or 2),
		maxIcons = math.max(1, privateAuras.maxIcons or 3),
		iconSizePx = addon.Utilities:ToPixels(privateAuras.iconSize or 20),
		spacingPx = addon.Utilities:ToPixels(privateAuras.spacing or 1),
	}
end

local function CreateTestPrivateAuraPreviewIcon(container)
	local icon = CreateFrame("Frame", nil, container)
	icon:SetFrameLevel(container:GetFrameLevel() + 1)
	icon:Hide()

	icon.texture = icon:CreateTexture(nil, "ARTWORK")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	icon.cooldown:SetAllPoints(icon)
	icon.cooldown:SetReverse(true)
	icon.cooldown:SetDrawBling(false)
	icon.cooldown:SetDrawEdge(false)
	icon.cooldown:SetHideCountdownNumbers(true)
	icon.cooldown:SetFrameLevel(icon:GetFrameLevel() + 1)

	icon.borderFrame = CreateFrame("Frame", nil, icon)
	icon.borderFrame:SetAllPoints(icon)
	icon.borderFrame:SetFrameLevel(icon:GetFrameLevel() + 2)

	icon.border = icon.borderFrame:CreateTexture(nil, "OVERLAY")
	icon.border:SetPoint("CENTER")
	icon.border:SetDrawLayer("OVERLAY", 1)

	return icon
end

local function GetTestPrivateAuraTexture(sample)
	if not sample then
		return "Interface\\Icons\\INV_Misc_QuestionMark"
	end

	local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(sample.spellID) or nil
	return texture or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function ApplyTestPrivateAuraBorder(icon, iconSize)
	local displayInfo = DEBUFF_DISPLAY_INFO and DEBUFF_DISPLAY_INFO[icon.dispelType or "None"]
	if not displayInfo and DEBUFF_DISPLAY_INFO then
		displayInfo = DEBUFF_DISPLAY_INFO.None
	end

	local atlas = displayInfo and (displayInfo.dispelAtlas or displayInfo.basicAtlas) or nil
	if atlas and icon.border.SetAtlas then
		local borderScale = iconSize / 32 * 2
		local borderSize = iconSize + (5 * borderScale)
		icon.border:SetAtlas(atlas)
		icon.border:SetSize(borderSize, borderSize)
		icon.border:Show()
	else
		icon.border:Hide()
	end
end

local function ApplyTestPrivateAuraCooldown(icon, duration)
	local expirationTime = GetTime() + duration

	if icon.cooldown.SetCooldownFromExpirationTime then
		icon.cooldown:SetCooldownFromExpirationTime(expirationTime, duration)
	else
		icon.cooldown:SetCooldown(expirationTime - duration, duration)
	end

	icon.cooldown:Show()
end

local function EnsureTestPrivateAuraPreview(frame, privateAuraSettings)
	local container = frame.privateAurasContainer
	if not container then
		return
	end

	frame.privateAurasPreviewIcons = frame.privateAurasPreviewIcons or {}

	local previewIcons = frame.privateAurasPreviewIcons
	local iconSizePx = addon.Utilities:Scale(privateAuraSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(privateAuraSettings.spacingPx)
	local iconSize = addon.Utilities:ToUI(iconSizePx)

	for auraIndex = 1, privateAuraSettings.maxIcons do
		local icon = previewIcons[auraIndex]
		if not icon then
			icon = CreateTestPrivateAuraPreviewIcon(container)
			previewIcons[auraIndex] = icon
		end

		local sample = TEST_PRIVATE_AURA_SAMPLES[((auraIndex - 1) % #TEST_PRIVATE_AURA_SAMPLES) + 1]
		local xOffsetPx = (auraIndex - 1) * (iconSizePx + spacingPx)

		icon.dispelType = sample.dispelType

		icon:ClearAllPoints()
		icon:SetPoint("LEFT", container, "LEFT", addon.Utilities:ToUI(xOffsetPx), 0)
		icon:SetSize(iconSize, iconSize)

		icon.texture:SetTexture(GetTestPrivateAuraTexture(sample))
		ApplyTestPrivateAuraBorder(icon, iconSize)
		ApplyTestPrivateAuraCooldown(icon, sample.duration)
		icon:Show()
	end

	for auraIndex = privateAuraSettings.maxIcons + 1, #previewIcons do
		local icon = previewIcons[auraIndex]
		if icon then
			icon:Hide()
		end
	end

	container:Show()
end

local function EnsurePrivateAuraAnchors(frame, privateAuraSettings)
	local container = frame.privateAurasContainer
	if not container then
		return
	end

	local unit = frame.unit

	frame.privateAurasAnchorIDs = frame.privateAurasAnchorIDs or {}

	if frame.privateAurasAnchoredUnit == unit and #frame.privateAurasAnchorIDs > 0 then
		return
	end

	if C_UnitAuras and C_UnitAuras.RemovePrivateAuraAnchor then
		for _, anchorID in ipairs(frame.privateAurasAnchorIDs) do
			C_UnitAuras.RemovePrivateAuraAnchor(anchorID)
		end
	end
	wipe(frame.privateAurasAnchorIDs)
	frame.privateAurasAnchoredUnit = nil

	local iconSizePx = addon.Utilities:Scale(privateAuraSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(privateAuraSettings.spacingPx)

	if not unit or not C_UnitAuras or not C_UnitAuras.AddPrivateAuraAnchor then
		container:Hide()
		return
	end

	local iconSize = addon.Utilities:ToUI(iconSizePx)

	for auraIndex = 1, privateAuraSettings.maxIcons do
		local xOffsetPx = (auraIndex - 1) * (iconSizePx + spacingPx)

		local anchorID = C_UnitAuras.AddPrivateAuraAnchor({
			unitToken = unit,
			auraIndex = auraIndex,
			parent = container,
			showCountdownFrame = true,
			showCountdownNumbers = false,
			isContainer = false,
			durationAnchor = nil,
			iconInfo = {
				iconWidth = iconSize,
				iconHeight = iconSize,
				borderScale = 1.0,
				iconAnchor = {
					point = "LEFT",
					relativeTo = container,
					relativePoint = "LEFT",
					offsetX = addon.Utilities:ToUI(xOffsetPx),
					offsetY = 0,
				},
			},
		})

		if anchorID then
			table.insert(frame.privateAurasAnchorIDs, anchorID)
		end
	end

	local anchored = #frame.privateAurasAnchorIDs > 0
	container:SetShown(anchored)
	if anchored then
		frame.privateAurasAnchoredUnit = unit
	end
end

function PrivateAuras:Ensure(frame)
	if not frame.privateAurasContainer then
		frame.privateAurasContainer =
			addon.Frames.Managers.IconManager:CreateContainer(frame, "privateAurasContainer", 45)
	end

	if frame.previewWidgetVisibility then
		local frameStrata = frame.GetFrameStrata and frame:GetFrameStrata()
		if frameStrata then
			frame.privateAurasContainer:SetFrameStrata(frameStrata)
		end
	else
		frame.privateAurasContainer:SetFrameStrata("HIGH")
	end

	frame.privateAurasContainer:SetFrameLevel(100)
end

local function ApplyContainerLayout(frame, privateAuraSettings)
	local container = frame.privateAurasContainer

	local iconSizePx = addon.Utilities:Scale(privateAuraSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(privateAuraSettings.spacingPx)
	local offsetXPx = addon.Utilities:Scale(privateAuraSettings.offsetXPx)
	local offsetYPx = addon.Utilities:Scale(privateAuraSettings.offsetYPx)

	local widthPx = (privateAuraSettings.maxIcons * iconSizePx) + ((privateAuraSettings.maxIcons - 1) * spacingPx)
	local heightPx = iconSizePx

	container:ClearAllPoints()
	container:SetPoint(
		privateAuraSettings.anchor,
		frame,
		privateAuraSettings.relativeAnchor,
		addon.Utilities:ToUI(offsetXPx),
		addon.Utilities:ToUI(offsetYPx)
	)
	container:SetSize(addon.Utilities:ToUI(widthPx), addon.Utilities:ToUI(heightPx))
end

function PrivateAuras:UpdateSettings(frame, settings)
	local privateAuraSettings = GetPrivateAurasSettings(settings)

	ApplyContainerLayout(frame, privateAuraSettings)

	if frame.previewWidgetVisibility then
		if frame.previewWidgetVisibility.privateAuras ~= true then
			frame.privateAurasContainer:Hide()
			return
		end

		EnsureTestPrivateAuraPreview(frame, privateAuraSettings)
		return
	end

	EnsurePrivateAuraAnchors(frame, privateAuraSettings)
end

function PrivateAuras:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "privateAurasSettingsChanged",
	})
end
