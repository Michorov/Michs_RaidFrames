local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Background = addon.Frames.Base.Background or {}

local Background = addon.Frames.Base.Background

local settingsCache = setmetatable({}, { __mode = "k" })

local function UpdateSettingsCache(settings)
	settingsCache[settings] = nil

	local background = (settings and settings.background) or {}
	local color = background.color or {}

	local result = {
		color = {
			r = color.r or 0.12,
			g = color.g or 0.12,
			b = color.b or 0.12,
			a = color.a or 1.0,
		},
	}

	settingsCache[settings] = result
end

function Background:Ensure(frame)
	local background = frame.background

	if not background then
		background = frame:CreateTexture(nil, "BACKGROUND")
		background:SetAllPoints()
		frame.background = background
	end
end

function Background:UpdateSettings(frame, settings)
	UpdateSettingsCache(settings)
	local color = settingsCache[settings].color

	frame.background:SetColorTexture(color.r, color.g, color.b, color.a)
end

function Background:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "backgroundSettingsChanged",
	})
end
