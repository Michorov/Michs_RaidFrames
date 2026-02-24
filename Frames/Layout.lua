local _, addon = ...

addon.Frames = addon.Frames or {}
local Frames = addon.Frames

local ARENA_RAID_MAX_UNITS = 3

local function UpdatePartyLayout(group, settings)
    local position = settings.position or {}
    local size = settings.size or {}
    local spacing = settings.spacing or {}

    local xPx = addon.Utilities:ToPixels(position.x or 0)
    local yPx = addon.Utilities:ToPixels(position.y or 0)

    local frameWidthPx = addon.Utilities:ToPixels(size.width or 128)
    local frameHeightPx = addon.Utilities:ToPixels(size.height or 64)
    local spacingYPx = addon.Utilities:ToPixels(spacing.y or 0)

    if (frameWidthPx % 2) ~= 0 then frameWidthPx = frameWidthPx + 1 end
    if (frameHeightPx % 2) ~= 0 then frameHeightPx = frameHeightPx + 1 end

    local frameCount = #group.frames
    local totalHeightPx = 0
    if frameCount > 0 then
        totalHeightPx = (frameCount * frameHeightPx) + ((frameCount - 1) * spacingYPx)
    end

    local containerWidthPx = frameWidthPx
    local containerHeightPx = math.max(frameHeightPx, totalHeightPx)

    if (containerWidthPx % 2) ~= 0 then containerWidthPx = containerWidthPx + 1 end
    if (containerHeightPx % 2) ~= 0 then containerHeightPx = containerHeightPx + 1 end

    group.container:ClearAllPoints()
    group.container:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        addon.Utilities:FromPixels(xPx),
        addon.Utilities:FromPixels(yPx)
    )
    group.container:SetSize(
        addon.Utilities:FromPixels(containerWidthPx),
        addon.Utilities:FromPixels(containerHeightPx)
    )

    for frameIndex, frame in ipairs(group.frames) do
        local offsetYPx = (frameIndex - 1) * (frameHeightPx + spacingYPx)

        frame:ClearAllPoints()
        frame:SetPoint(
            "TOPLEFT",
            group.container,
            "TOPLEFT",
            0,
            -addon.Utilities:FromPixels(offsetYPx)
        )
        frame:SetSize(
            addon.Utilities:FromPixels(frameWidthPx),
            addon.Utilities:FromPixels(frameHeightPx)
        )
    end
end

local function UpdateRaidLayout(group, settings)
    local position = settings.position or {}
    local size = settings.size or {}
    local spacing = settings.spacing or {}

    local xPx = addon.Utilities:ToPixels(position.x or 0)
    local yPx = addon.Utilities:ToPixels(position.y or 0)

    local frameWidthPx = addon.Utilities:ToPixels(size.width or 112)
    local frameHeightPx = addon.Utilities:ToPixels(size.height or 56)
    local spacingXPx = addon.Utilities:ToPixels(spacing.x or 0)
    local spacingYPx = addon.Utilities:ToPixels(spacing.y or 0)

    if (frameWidthPx % 2) ~= 0 then frameWidthPx = frameWidthPx + 1 end
    if (frameHeightPx % 2) ~= 0 then frameHeightPx = frameHeightPx + 1 end

    local _, instanceType = IsInInstance()
    local isArena = (instanceType == "arena")
    local maxFrames = isArena and ARENA_RAID_MAX_UNITS or 40

    -- Use capped count for BOTH container geometry and frame positioning
    local frameCount = math.min(#group.frames, maxFrames)
    local unitsPerColumn = 5

    local columnCount = math.max(1, math.ceil(frameCount / unitsPerColumn))
    local rowCount = math.max(1, math.min(unitsPerColumn, frameCount))

    local containerWidthPx = (columnCount * frameWidthPx) + ((columnCount - 1) * spacingXPx)
    local containerHeightPx = (rowCount * frameHeightPx) + ((rowCount - 1) * spacingYPx)

    if (containerWidthPx % 2) ~= 0 then containerWidthPx = containerWidthPx + 1 end
    if (containerHeightPx % 2) ~= 0 then containerHeightPx = containerHeightPx + 1 end

    group.container:ClearAllPoints()
    group.container:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        addon.Utilities:FromPixels(xPx),
        addon.Utilities:FromPixels(yPx)
    )
    group.container:SetSize(
        addon.Utilities:FromPixels(containerWidthPx),
        addon.Utilities:FromPixels(containerHeightPx)
    )

    for frameIndex = 1, frameCount do
        local frame = group.frames[frameIndex]

        local columnIndex = math.floor((frameIndex - 1) / unitsPerColumn)
        local rowIndex = (frameIndex - 1) % unitsPerColumn

        local offsetXPx = columnIndex * (frameWidthPx + spacingXPx)
        local offsetYPx = rowIndex * (frameHeightPx + spacingYPx)

        frame:ClearAllPoints()
        frame:SetPoint(
            "TOPLEFT",
            group.container,
            "TOPLEFT",
            addon.Utilities:FromPixels(offsetXPx),
            -addon.Utilities:FromPixels(offsetYPx)
        )
        frame:SetSize(
            addon.Utilities:FromPixels(frameWidthPx),
            addon.Utilities:FromPixels(frameHeightPx)
        )
    end
end

function Frames:UpdateLayout(group, settings)
    if not group or not group.container then
        return
    end

    settings = settings or {}

    if group.type == "party" then
        UpdatePartyLayout(group, settings)
    else
        UpdateRaidLayout(group, settings)
    end
end