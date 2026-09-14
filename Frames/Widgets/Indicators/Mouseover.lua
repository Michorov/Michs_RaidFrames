local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Widgets = addon.Frames.Widgets or {}
addon.Frames.Widgets.Indicators = addon.Frames.Widgets.Indicators or {}
addon.Frames.Widgets.Indicators.Mouseover = addon.Frames.Widgets.Indicators.Mouseover or {}

local Mouseover = addon.Frames.Widgets.Indicators.Mouseover

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil
	local widgets = (settings and settings.widgets) or {}
	local indicators = widgets.indicators or {}
	local mouseover = indicators.mouseover or {}
	local border = (settings and settings.border) or {}
	local color = mouseover.color or {}

	settingsCache[settings] = {
		enabled = mouseover.enabled == true,
		color = { r = color.r or 1, g = color.g or 0.95, b = color.b or 0.7, a = color.a or 1 },
		frameBorderSizePx = addon.Utilities:ToPixels(border.thicknessPx or 1),
	}
end

function Mouseover:Ensure(frame)
	if frame.frameType == "boss" then
		return
	end

	if not frame.mouseover then
		local container = CreateFrame("Frame", nil, frame)
		container:SetAllPoints(frame)
		container:SetFrameLevel(24)
		container:EnableMouse(false)

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
		frame.mouseover = container

		if frame.frameType ~= "preview" then
			local function RequestUpdate()
				addon.UpdateScheduler:Notify("mouseoverStateChanged", frame.unit)
			end

			frame:HookScript("OnEnter", RequestUpdate)
			frame:HookScript("OnLeave", RequestUpdate)
			frame:HookScript("OnShow", RequestUpdate)
			frame:HookScript("OnHide", function()
				container:Hide()
			end)
			container:SetScript("OnUpdate", function()
				if not frame:IsMouseOver() then
					RequestUpdate()
				end
			end)
		end
	end
end

function Mouseover:UpdateSettings(frame, settings)
	if frame.frameType == "boss" then
		return
	end

	local container = frame.mouseover

	UpdateSettingsCache(settings)

	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	local scaledBorderSizePx = math.max(1, frame.dataProvider:Scale(frame, addon.Utilities:ToPixels(1)))
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

	local color = cachedSettings.color
	for _, texture in ipairs({ container.top, container.bottom, container.left, container.right }) do
		texture:SetColorTexture(color.r, color.g, color.b, color.a)
	end

	self:UpdateState(frame, settings)
end

function Mouseover:UpdateState(frame, settings)
	if frame.frameType == "boss" then
		return
	end

	local container = frame.mouseover

	if frame.previewWidgetVisibility and frame.previewWidgetVisibility.mouseover ~= true then
		container:Hide()
		return
	end

	if not settingsCache[settings] then
		UpdateSettingsCache(settings)
	end
	local cachedSettings = settingsCache[settings]

	if not cachedSettings.enabled then
		container:Hide()
		return
	end

	container:SetShown(frame.frameType == "preview" or (frame:IsVisible() and frame:IsMouseOver()))
end

function Mouseover:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "mouseoverSettingsChanged",
		stateReason = "mouseoverStateChanged",
	})
end
