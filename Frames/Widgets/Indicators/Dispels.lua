local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.Dispels = addon.Frames.Widgets.Indicators.Dispels or {}

local Dispels = addon.Frames.Widgets.Indicators.Dispels

local ORDER = { "Magic", "Poison", "Curse", "Disease", "Bleed" }

local ATLAS_BY_TYPE = {
	Magic = "RaidFrame-Icon-DebuffMagic",
	Poison = "RaidFrame-Icon-DebuffPoison",
	Curse = "RaidFrame-Icon-DebuffCurse",
	Disease = "RaidFrame-Icon-DebuffDisease",
	Bleed = "RaidFrame-Icon-DebuffBleed",
}

local function GetDispelsSettings(settings)
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local dispels = indicators.dispels or {}

	return {
		anchor = dispels.anchor or "TOPRIGHT",
		relativeAnchor = dispels.relativeAnchor or "TOPRIGHT",
		growDirection = dispels.growDirection or "LEFT",
		offsetXPx = addon.Utilities:ToPixels(dispels.offsetX or -1),
		offsetYPx = addon.Utilities:ToPixels(dispels.offsetY or -1),
		iconSizePx = addon.Utilities:ToPixels(dispels.iconSize or 14),
		spacingPx = addon.Utilities:ToPixels(dispels.spacing or 1),
		alpha = dispels.alpha or 1,
	}
end

local function CreateTypeIcon(container, dispelType)
	local icon = container:CreateTexture(nil, "ARTWORK")
	icon:SetAtlas(ATLAS_BY_TYPE[dispelType], false)
	icon:Hide()
	return icon
end

function Dispels:Ensure(frame)
	if not frame then
		return
	end

	if not frame.dispelsContainer then
		frame.dispelsContainer = addon.Frames.Managers.IconManager:CreateContainer(frame, "dispelsContainer")
	end

	local container = frame.dispelsContainer
	if not container then
		return
	end

	container.typeIcons = container.typeIcons or {}

	for i = 1, #ORDER do
		local dispelType = ORDER[i]
		if not container.typeIcons[dispelType] then
			container.typeIcons[dispelType] = CreateTypeIcon(container, dispelType)
		end
	end
end

function Dispels:UpdateSettings(frame, settings)
	local container = frame and frame.dispelsContainer
	if not container then
		return
	end

	local dispelSettings = GetDispelsSettings(settings)

	local offsetX = addon.Utilities:Scale(dispelSettings.offsetXPx)
	local offsetY = addon.Utilities:Scale(dispelSettings.offsetYPx)
	local iconSizePx = addon.Utilities:Scale(dispelSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(dispelSettings.spacingPx)

	local widthPx = (#ORDER * iconSizePx) + ((#ORDER - 1) * spacingPx)
	local heightPx = iconSizePx

	container:ClearAllPoints()
	container:SetPoint(
		dispelSettings.anchor,
		container:GetParent(),
		dispelSettings.relativeAnchor,
		addon.Utilities:ToUI(offsetX),
		addon.Utilities:ToUI(offsetY)
	)
	container:SetSize(addon.Utilities:ToUI(widthPx), addon.Utilities:ToUI(heightPx))

	for i = 1, #ORDER do
		local dispelType = ORDER[i]
		local icon = container.typeIcons and container.typeIcons[dispelType]
		if icon then
			icon:SetSize(addon.Utilities:ToUI(iconSizePx), addon.Utilities:ToUI(iconSizePx))
			icon:SetAlpha(dispelSettings.alpha)
		end
	end
end

function Dispels:UpdateState(frame, settings)
	local container = frame and frame.dispelsContainer
	if not container or not container.typeIcons then
		return
	end

	local unit = frame.unit
	if not unit or not UnitExists(unit) then
		for i = 1, #ORDER do
			local icon = container.typeIcons[ORDER[i]]
			if icon then
				icon:Hide()
			end
		end
		container:Hide()
		return
	end

	local dispelSettings = GetDispelsSettings(settings)

	local iconSizePx = addon.Utilities:Scale(dispelSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(dispelSettings.spacingPx)

	local bucket = addon.AuraHandler and addon.AuraHandler:GetBucketForUnit(unit)
	local dispellable = bucket and bucket.dispellable

	if not dispellable or #dispellable == 0 then
		for i = 1, #ORDER do
			local icon = container.typeIcons[ORDER[i]]
			if icon then
				icon:Hide()
			end
		end
		container:Hide()
		return
	end

	for i = 1, #ORDER do
		local icon = container.typeIcons[ORDER[i]]
		if icon then
			icon:Hide()
		end
	end

	local shown = 0
	for i = 1, #dispellable do
		if shown >= #ORDER then
			break
		end

		local data = dispellable[i]
		local atlas = data and data.atlas
		if atlas then
			shown = shown + 1
			local icon = container.typeIcons[ORDER[shown]]
			if icon then
				local stepPx = iconSizePx + spacingPx
				local xPx
				if dispelSettings.growDirection == "RIGHT" then
					xPx = (shown - 1) * stepPx
				else
					xPx = -((shown - 1) * stepPx)
				end

				local point, relativePoint
				if dispelSettings.growDirection == "RIGHT" then
					point, relativePoint = "TOPLEFT", "TOPLEFT"
				else
					point, relativePoint = "TOPRIGHT", "TOPRIGHT"
				end

				icon:ClearAllPoints()
				icon:SetPoint(point, container, relativePoint, addon.Utilities:ToUI(xPx), 0)
				icon:SetAtlas(atlas, false)
				icon:Show()
			end
		end
	end

	container:SetShown(shown > 0)
end

function Dispels:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "dispelsSettingsChanged",
		stateReason = "aurasStateChanged",
	})
end
