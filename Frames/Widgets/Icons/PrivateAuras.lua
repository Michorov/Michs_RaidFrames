local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.PrivateAuras = addon.Frames.Widgets.Icons.PrivateAuras or {}

local PrivateAuras = addon.Frames.Widgets.Icons.PrivateAuras

local function GetPrivateAurasSettings(settings)
	return settings and settings.widgets and settings.widgets.icons and settings.widgets.icons.privateAuras
end

local function RemovePrivateAuraAnchors(frame)
	if not frame or not frame.privateAurasAnchorIDs or not C_UnitAuras or not C_UnitAuras.RemovePrivateAuraAnchor then
		return
	end

	for i = 1, #frame.privateAurasAnchorIDs do
		local anchorID = frame.privateAurasAnchorIDs[i]
		if anchorID then
			pcall(C_UnitAuras.RemovePrivateAuraAnchor, anchorID)
		end
	end

	wipe(frame.privateAurasAnchorIDs)
end

local function EnsurePrivateAuraAnchors(frame, settings)
	local container = frame and frame.privateAurasContainer
	if not container then
		return
	end

	local unit = frame.unit
	local privateAuraSettings = GetPrivateAurasSettings(settings) or {}

	local maxIcons = math.max(1, privateAuraSettings.maxIcons)
	local iconSizePx = privateAuraSettings.iconSize
	local spacingPx = privateAuraSettings.spacing

	if not unit or not C_UnitAuras or not C_UnitAuras.AddPrivateAuraAnchor then
		container:Hide()
		return
	end

	frame.privateAurasAnchorIDs = frame.privateAurasAnchorIDs or {}

	RemovePrivateAuraAnchors(frame)

	local iconSize = addon.Utilities:FromPixels(iconSizePx)

	for auraIndex = 1, maxIcons do
		local xOffsetPx = (auraIndex - 1) * (iconSizePx + spacingPx)

		local ok, anchorID = pcall(C_UnitAuras.AddPrivateAuraAnchor, {
			unitToken = unit,
			auraIndex = auraIndex,
			parent = container,
			showCountdownFrame = true,
			showCountdownNumbers = false,
			durationAnchor = nil,
			iconInfo = {
				iconWidth = iconSize,
				iconHeight = iconSize,
				borderScale = 1.0,
				iconAnchor = {
					point = "LEFT",
					relativeTo = container,
					relativePoint = "LEFT",
					offsetX = addon.Utilities:FromPixels(xOffsetPx),
					offsetY = 0,
				},
			},
		})

		if ok and anchorID then
			table.insert(frame.privateAurasAnchorIDs, anchorID)
		end
	end

	container:SetShown(#frame.privateAurasAnchorIDs > 0)
end

function PrivateAuras:UpdateSettings(frame, settings)
	local container = frame and frame.privateAurasContainer
	if not container then
		return
	end

	local privateAuraSettings = GetPrivateAurasSettings(settings) or {}

	local maxIcons = math.max(1, privateAuraSettings.maxIcons)
	local iconSizePx = privateAuraSettings.iconSize
	local spacingPx = privateAuraSettings.spacing

	local anchor = privateAuraSettings.anchor
	local relativeAnchor = privateAuraSettings.relativeAnchor
	local offsetXPx = privateAuraSettings.offsetX
	local offsetYPx = privateAuraSettings.offsetY

	local widthPx = (maxIcons * iconSizePx) + ((maxIcons - 1) * spacingPx)
	local heightPx = iconSizePx

	container:ClearAllPoints()
	container:SetPoint(
		anchor,
		container:GetParent(),
		relativeAnchor,
		addon.Utilities:FromPixels(offsetXPx),
		addon.Utilities:FromPixels(offsetYPx)
	)
	container:SetSize(addon.Utilities:FromPixels(widthPx), addon.Utilities:FromPixels(heightPx))

	EnsurePrivateAuraAnchors(frame, settings)
end

function PrivateAuras:Ensure(frame, settings)
	if not frame then
		return
	end

	local widgetsOverlay = frame.widgetsOverlay
	if not widgetsOverlay then
		return
	end

	if not frame.privateAurasContainer then
		frame.privateAurasContainer = addon.Frames.Widgets.Icons.Factory:CreateContainer(frame, "privateAurasContainer")
	end
end
