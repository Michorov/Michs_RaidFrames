local _, addon = ...

addon.Options = addon.Options or {}
addon.Options.Sections = addon.Options.Sections or {}
addon.Options.Sections.Preview = addon.Options.Sections.Preview or {}

local Preview = addon.Options.Sections.Preview

local preview
local L = addon.L
local theme = addon.Options.Theme

local layoutValues = {
	outerInset = 8,
	titleInset = 10,
	titleHeight = 24,
	bodyTopGap = 10,
	frameGap = 24,
}

local function GetBodySize()
	local bodyWidthPx = addon.Utilities:ToPixels(preview.body:GetWidth())
	local bodyHeightPx = addon.Utilities:ToPixels(preview.body:GetHeight())

	if bodyWidthPx <= 0 then
		bodyWidthPx = addon.Utilities:ToPixels(200)
	end

	if bodyHeightPx <= 0 then
		bodyHeightPx = addon.Utilities:ToPixels(360)
	end

	return bodyWidthPx, bodyHeightPx
end

local function PositionPreviewFrame(frame, widthPx, topOffsetPx, bodyWidthPx)
	if not frame or widthPx <= 0 then
		return
	end

	local offsetXPx = addon.Utilities:RoundToNearestInt((bodyWidthPx - widthPx) / 2)

	frame:ClearAllPoints()
	frame:SetPoint(
		"TOPLEFT",
		preview.body,
		"TOPLEFT",
		addon.Utilities:ToUI(offsetXPx),
		-addon.Utilities:ToUI(topOffsetPx)
	)
end

local function GetFrameTopOffset(frame, heightPx, bodyHeightPx)
	if not preview.partyFrame or not preview.raidFrame then
		return addon.Utilities:RoundToNearestInt(math.max(0, (bodyHeightPx - heightPx) / 2))
	end

	local frameGapPx = addon.Utilities:ToPixels(layoutValues.frameGap)
	local slotHeightPx = addon.Utilities:RoundToNearestInt(math.max(0, (bodyHeightPx - frameGapPx) / 2))
	local slotOffsetPx = addon.Utilities:RoundToNearestInt(math.max(0, (slotHeightPx - heightPx) / 2))

	if frame == preview.raidFrame then
		return slotHeightPx + frameGapPx + slotOffsetPx
	end

	return slotOffsetPx
end

function Preview:Ensure(parent)
	if preview then
		return preview
	end

	preview = CreateFrame("Frame", nil, parent)
	preview.children = {}

	preview.leftBorder = preview:CreateTexture(nil, "OVERLAY")
	preview.leftBorder:SetColorTexture(theme:GetColor("border"))

	preview.title = preview:CreateFontString(nil, "OVERLAY")
	preview.title:SetJustifyH("CENTER")
	theme:ApplyFont(preview.title, "arialNarrow", 20, "")
	preview.title:SetTextColor(theme:GetTextColor("highlight"))

	preview.body = CreateFrame("Frame", nil, preview)
	preview.partyFrame, preview.raidFrame = addon.FrameRegistry:CreatePreviewFrames(preview.body)

	self:UpdateLocale()
	self:UpdateLayout()

	return preview
end

function Preview:UpdateLocale()
	if not preview then
		return
	end

	preview.title:SetText(L["Preview"])

	for _, child in pairs(preview.children) do
		if child.UpdateLocale then
			child:UpdateLocale()
		end
	end
end

function Preview:UpdateFrameLayout(frame, settings)
	if not preview or not frame then
		return
	end

	local frameWidthPx, frameHeightPx = addon.Frames:UpdatePreviewFrameLayout(frame, settings)
	local bodyWidthPx, bodyHeightPx = GetBodySize()
	local topOffsetPx = GetFrameTopOffset(frame, frameHeightPx, bodyHeightPx)

	PositionPreviewFrame(frame, frameWidthPx, topOffsetPx, bodyWidthPx)
end

function Preview:UpdateLayout()
	if not preview then
		return
	end

	local outerInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.outerInset))
	local titleInset = addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.titleInset))
	local titleHeight = addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.titleHeight))
	local bodyTopGap = addon.Utilities:ToUI(addon.Utilities:ToPixels(layoutValues.bodyTopGap))

	preview.leftBorder:ClearAllPoints()
	preview.leftBorder:SetPoint("TOPLEFT", preview, "TOPLEFT", 0, -outerInset)
	preview.leftBorder:SetPoint("BOTTOMLEFT", preview, "BOTTOMLEFT", 0, outerInset)
	preview.leftBorder:SetWidth(addon.Utilities:ToUI(addon.Utilities:ToPixels(1)))

	preview.title:ClearAllPoints()
	preview.title:SetPoint("TOPLEFT", preview, "TOPLEFT", titleInset, -titleInset)
	preview.title:SetPoint("TOPRIGHT", preview, "TOPRIGHT", -titleInset, -titleInset)
	preview.title:SetHeight(titleHeight)

	preview.body:ClearAllPoints()
	preview.body:SetPoint("TOPLEFT", preview.title, "BOTTOMLEFT", 0, -bodyTopGap)
	preview.body:SetPoint("TOPRIGHT", preview.title, "BOTTOMRIGHT", 0, -bodyTopGap)
	preview.body:SetPoint("BOTTOMLEFT", preview, "BOTTOMLEFT", titleInset, titleInset)
	preview.body:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", -titleInset, titleInset)

	local profile = addon.Database:GetProfile()
	self:UpdateFrameLayout(preview.partyFrame, profile.party or {})
	self:UpdateFrameLayout(preview.raidFrame, profile.raid or {})

	for _, child in pairs(preview.children) do
		if child.UpdateLayout then
			child:UpdateLayout()
		end
	end
end
