local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.Base = addon.Frames.Base or {}
addon.Frames.Base.Background = addon.Frames.Base.Background or {}

local Background = addon.Frames.Base.Background

local function GetBackgroundColor(settings)
    local background = (settings and settings.background) or {}
    local color = background.color or {}

    return color.r or 0.12, color.g or 0.12, color.b or 0.12, color.a or 1.0
end

function Background:Ensure(frame)
    if not frame then
        return nil
    end

    local background = frame.background

    if not background then
        background = frame:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        frame.background = background
    end
end

function Background:UpdateSettings(frame, settings)
    local background = frame and frame.background
    if not background then
        return
    end

    local r, g, b, a = GetBackgroundColor(settings)
    background:SetColorTexture(r, g, b, a)
    background:Show()
end

function Background:Init()
	addon.Modules:Register({
		module = self,
		settingsReason = "backgroundSettingsChanged",
	})
end
