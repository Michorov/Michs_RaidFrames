local _, addon = ...

addon.Frames = addon.Frames or {}
local Frames = addon.Frames

function Frames:CreateGroup(groupType)
	if type(groupType) ~= "string" or groupType == "" then
		error("Frames:CreateGroup requires a non-empty group type", 2)
	end

	local groupName = "MRF_" .. groupType .. "Group"
	local group = CreateFrame("Frame", groupName, UIParent, "SecureHandlerStateTemplate")
	group.name = groupName

	group:SetSize(1, 1)
	group:ClearAllPoints()
	group:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	return group
end

function Frames:CreateFrame(group, unit, unitIndex)
	if not group then
		error("Frames:CreateFrame requires group", 2)
	end

	if type(unit) ~= "string" or unit == "" then
		error("Frames:CreateFrame requires non-empty unit", 2)
	end

	local frameName = group.name .. "_Frame" .. unitIndex
	local frame = CreateFrame("Button", frameName, group, "SecureUnitButtonTemplate")
	frame.unit = unit
	frame.dataProvider = addon.Frames.DataProvider.Live

	frame:SetAttribute("unit", unit)
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "togglemenu")
	frame:RegisterForClicks("AnyUp")

	frame:SetScript("OnEnter", function(self)
		if not self.unit then
			return
		end
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		GameTooltip:SetUnit(self.unit)
		GameTooltip:Show()
	end)

	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	frame:SetSize(1, 1)

	RegisterUnitWatch(frame)

	return frame
end

function Frames:CreateTestGroup(groupType)
	if type(groupType) ~= "string" or groupType == "" then
		error("Frames:CreateTestGroup requires a non-empty group type", 2)
	end

	local groupName = "MRF_Test" .. groupType .. "Group"
	local group = CreateFrame("Frame", groupName, UIParent)
	group.name = groupName

	group:SetSize(1, 1)
	group:ClearAllPoints()
	group:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	return group
end

function Frames:CreateTestFrame(group, frameIndex)
	if not group then
		error("Frames:CreateTestFrame requires group", 2)
	end

	local frameName = group.name .. "_Frame" .. frameIndex
	local frame = CreateFrame("Button", frameName, group)

	frame.unit = nil

	frame.testIndex = frameIndex
	frame.testClassIndex = math.random(1, 13)
	frame.testHealthIndex = math.random(1, 8)
	frame.testPowerIndex = math.random(1, 8)
	frame.testAbsorbIndex = math.random(1, 8)
	frame.testHealAbsorbIndex = math.random(1, 8)

	frame.dataProvider = addon.Frames.DataProvider.Test

	frame:RegisterForClicks("AnyUp")
	frame:SetSize(1, 1)

	return frame
end
