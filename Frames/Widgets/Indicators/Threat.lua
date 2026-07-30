local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.Threat = addon.Frames.Widgets.Indicators.Threat or {}

local Threat = addon.Frames.Widgets.Indicators.Threat

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local threat = indicators.threat or {}
	local border = (settings and settings.border) or {}

	settingsCache[settings] = {
		enabled = threat.enabled == true,
		borderSizePx = addon.Utilities:ToPixels(threat.borderSize or 2),
		frameBorderSizePx = addon.Utilities:ToPixels(border.thicknessPx or 1),
	}
end

local function ApplyThreatColor(container, threatStatus)
	local r, g, b = 1, 0, 0

	if GetThreatStatusColor then
		local threatR, threatG, threatB = GetThreatStatusColor(threatStatus)
		if threatR ~= nil and threatG ~= nil and threatB ~= nil then
			r, g, b = threatR, threatG, threatB
		end
	end

	container.top:SetColorTexture(r, g, b, 1)
	container.bottom:SetColorTexture(r, g, b, 1)
	container.left:SetColorTexture(r, g, b, 1)
	container.right:SetColorTexture(r, g, b, 1)
end

function Threat:Ensure(frame)
	if not frame.threat then
		local container = CreateFrame("Frame", nil, frame)
		container:SetAllPoints(frame)
		container:SetFrameLevel(23)

		container.top = container:CreateTexture(nil, "OVERLAY", nil, 0)
		container.bottom = container:CreateTexture(nil, "OVERLAY", nil, 0)
		container.left = container:CreateTexture(nil, "OVERLAY", nil, 0)
		container.right = container:CreateTexture(nil, "OVERLAY", nil, 0)

		for _, texture in ipairs({ container.top, container.bottom, container.left, container.right }) do
			if texture.SetSnapToPixelGrid then
				texture:SetSnapToPixelGrid(true)
			end
			if texture.SetTexelSnappingBias then
				texture:SetTexelSnappingBias(0)
			end
		end

		container:Hide()
		frame.threat = container
	end
end

function Threat:UpdateSettings(frame, settings)
	local container = frame.threat

	UpdateSettingsCache(settings)
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled or cachedSettings.borderSizePx <= 0 then
		container:Hide()
		return
	end

	local scaledBorderSizePx = math.max(1, frame.dataProvider:Scale(frame, cachedSettings.borderSizePx))
	local uiBorderSize = addon.Utilities:ToUI(scaledBorderSizePx)
	local scaledFrameBorderSizePx = frame.dataProvider:Scale(frame, cachedSettings.frameBorderSizePx)
	local insetPx = scaledFrameBorderSizePx > 0 and scaledFrameBorderSizePx or 0
	local inset = addon.Utilities:ToUI(insetPx)

	container.left:ClearAllPoints()
	container.left:SetPoint("TOPLEFT", container, "TOPLEFT", inset, -inset)
	container.left:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", inset, inset)
	container.left:SetWidth(uiBorderSize)

	container.right:ClearAllPoints()
	container.right:SetPoint("TOPRIGHT", container, "TOPRIGHT", -inset, -inset)
	container.right:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -inset, inset)
	container.right:SetWidth(uiBorderSize)

	container.top:ClearAllPoints()
	container.top:SetPoint("TOPLEFT", container.left, "TOPRIGHT", 0, 0)
	container.top:SetPoint("TOPRIGHT", container.right, "TOPLEFT", 0, 0)
	container.top:SetHeight(uiBorderSize)

	container.bottom:ClearAllPoints()
	container.bottom:SetPoint("BOTTOMLEFT", container.left, "BOTTOMRIGHT", 0, 0)
	container.bottom:SetPoint("BOTTOMRIGHT", container.right, "BOTTOMLEFT", 0, 0)
	container.bottom:SetHeight(uiBorderSize)
end

function Threat:UpdateState(frame, settings)
	local container = frame.threat

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.threat ~= true then
		container:Hide()
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled or cachedSettings.borderSizePx <= 0 then
		container:Hide()
		return
	end

	local threatStatus = frame.dataProvider:GetThreatStatus(frame)
	if type(threatStatus) ~= "number" or threatStatus <= 0 then
		container:Hide()
		return
	end

	ApplyThreatColor(container, threatStatus)
	container:Show()
end

function Threat:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "threatSettingsChanged",
		stateReason = "threatStateChanged",
	})
end
