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
	icon:SetAtlas(ATLAS_BY_TYPE[dispelType], true)
	icon:Hide()
	return icon
end

local function IsSafeTableKey(v)
	if type(v) ~= "number" and type(v) ~= "string" then
		return false
	end
	if issecretvalue and issecretvalue(v) then
		return false
	end
	return true
end

local function CollectActiveTypesFromBucket(unit)
	local bucket = addon.AuraHandler and addon.AuraHandler:GetBucketForUnit(unit)

	local dispellable = bucket and bucket.dispellable
	if not dispellable then
		return nil
	end

	local active = {}

	for auraInstanceID in pairs(dispellable) do
		if IsSafeTableKey(auraInstanceID) then
			local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
			if aura then
				local dispelType = aura.dispelType
				if dispelType == 1 then
					active.Magic = true
				elseif dispelType == 4 then
					active.Poison = true
				elseif dispelType == 2 then
					active.Curse = true
				elseif dispelType == 3 then
					active.Disease = true
				elseif dispelType == 11 or dispelType == 9 then
					active.Bleed = true
				end
			end
		end
	end

	return active
end

function Dispels:Ensure(frame, settings)
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

	local s = GetDispelsSettings(settings) or {}
	local anchor = s.anchor or "TOPRIGHT"
	local relativeAnchor = s.relativeAnchor or "TOPRIGHT"
	local offsetX = s.offsetX or -1
	local offsetY = s.offsetY or -1
	local iconSizePx = s.iconSize or 14
	local spacingPx = s.spacing or 1
	local alpha = s.alpha or 1

	-- fixed 5 slots width; compact packing handled in UpdateState
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

	local s = GetDispelsSettings(settings) or {}
	local iconSizePx = s.iconSize or 14
	local spacingPx = s.spacing or 1

	local active = CollectActiveTypesFromBucket(unit)
	if not active then
		for i = 1, #ORDER do
			local icon = container.typeIcons[ORDER[i]]
			if icon then
				icon:Hide()
			end
		end
		container:Hide()
		return
	end

	-- Compact right-to-left packing with no gaps.
	local shown = 0
	for i = 1, #ORDER do
		local dispelType = ORDER[i]
		local icon = container.typeIcons[dispelType]
		if icon then
			if active[dispelType] then
				local xPx = -(shown * (iconSizePx + spacingPx))
				icon:ClearAllPoints()
				icon:SetPoint("TOPRIGHT", container, "TOPRIGHT", addon.Utilities:FromPixels(xPx), 0)
				icon:Show()
				shown = shown + 1
			else
				icon:Hide()
			end
		end
	end

	-- Hide any remaining icons that were previously shown
	for i = shown + 1, #ORDER do
		local icon = container.typeIcons[ORDER[i]]
		if icon then
			icon:Hide()
		end
	end

	container:SetShown(shown > 0)
end
