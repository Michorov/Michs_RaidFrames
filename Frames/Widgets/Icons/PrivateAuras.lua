local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Icons = addon.Frames.Widgets.Icons or {}
addon.Frames.Widgets.Icons.PrivateAuras = addon.Frames.Widgets.Icons.PrivateAuras or {}

local PrivateAuras = addon.Frames.Widgets.Icons.PrivateAuras

local function GetPrivateAurasSettings(settings)
	local privateAuras = settings and settings.widgets and settings.widgets.icons and settings.widgets.icons.privateAuras
		or {}

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

local function EnsurePrivateAuraAnchors(frame, privateAuraSettings)
	local container = frame and frame.privateAurasContainer
	if not container then
		return
	end

	local unit = frame.unit

	local iconSizePx = addon.Utilities:Scale(privateAuraSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(privateAuraSettings.spacingPx)

	if not unit or not C_UnitAuras or not C_UnitAuras.AddPrivateAuraAnchor then
		container:Hide()
		return
	end

	frame.privateAurasAnchorIDs = frame.privateAurasAnchorIDs or {}

	RemovePrivateAuraAnchors(frame)

	local iconSize = addon.Utilities:ToUI(iconSizePx)

	for auraIndex = 1, privateAuraSettings.maxIcons do
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
					offsetX = addon.Utilities:ToUI(xOffsetPx),
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

	local privateAuraSettings = GetPrivateAurasSettings(settings)

	local iconSizePx = addon.Utilities:Scale(privateAuraSettings.iconSizePx)
	local spacingPx = addon.Utilities:Scale(privateAuraSettings.spacingPx)
	local offsetXPx = addon.Utilities:Scale(privateAuraSettings.offsetXPx)
	local offsetYPx = addon.Utilities:Scale(privateAuraSettings.offsetYPx)

	local widthPx = (privateAuraSettings.maxIcons * iconSizePx) + ((privateAuraSettings.maxIcons - 1) * spacingPx)
	local heightPx = iconSizePx

	container:ClearAllPoints()
	container:SetPoint(
		privateAuraSettings.anchor,
		container:GetParent(),
		privateAuraSettings.relativeAnchor,
		addon.Utilities:ToUI(offsetXPx),
		addon.Utilities:ToUI(offsetYPx)
	)
	container:SetSize(addon.Utilities:ToUI(widthPx), addon.Utilities:ToUI(heightPx))

	EnsurePrivateAuraAnchors(frame, privateAuraSettings)
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
