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
	return settings and settings.widgets and settings.widgets.indicators and settings.widgets.indicators.dispels
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
		frame.dispelsContainer = addon.Frames.Widgets.Icons.Factory:CreateContainer(frame, "dispelsContainer")
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

	local dispelSettings = GetDispelsSettings(settings) or {}
	local anchor = dispelSettings.anchor or "TOPRIGHT"
	local relativeAnchor = dispelSettings.relativeAnchor or "TOPRIGHT"
	local offsetX = dispelSettings.offsetX or -1
	local offsetY = dispelSettings.offsetY or -1
	local iconSizePx = dispelSettings.iconSize or 14
	local spacingPx = dispelSettings.spacing or 1
	local alpha = dispelSettings.alpha or 1

	local widthPx = (#ORDER * iconSizePx) + ((#ORDER - 1) * spacingPx)
	local heightPx = iconSizePx

	container:ClearAllPoints()
	container:SetPoint(
		anchor,
		container:GetParent(),
		relativeAnchor,
		addon.Utilities:FromPixels(offsetX),
		addon.Utilities:FromPixels(offsetY)
	)
	container:SetSize(addon.Utilities:FromPixels(widthPx), addon.Utilities:FromPixels(heightPx))

	for i = 1, #ORDER do
		local dispelType = ORDER[i]
		local icon = container.typeIcons and container.typeIcons[dispelType]
		if icon then
			icon:SetSize(addon.Utilities:FromPixels(iconSizePx), addon.Utilities:FromPixels(iconSizePx))
			icon:SetAlpha(alpha)
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

	local dispelSettings = GetDispelsSettings(settings) or {}
	local iconSizePx = dispelSettings.iconSize or 14
	local spacingPx = dispelSettings.spacing or 1

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
				local xPx = -((shown - 1) * (iconSizePx + spacingPx))
				icon:ClearAllPoints()
				icon:SetPoint("TOPRIGHT", container, "TOPRIGHT", addon.Utilities:FromPixels(xPx), 0)
				icon:SetAtlas(atlas, false)
				icon:Show()
			end
		end
	end

	container:SetShown(shown > 0)
end
