local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ClickCasting = addon.Frames.ClickCasting or {}

local ClickCasting = addon.Frames.ClickCasting

local MODIFIERS = {
	"",
	"shift-",
	"ctrl-",
	"alt-",
	"ctrl-shift-",
	"alt-shift-",
	"alt-ctrl-",
	"alt-ctrl-shift-",
}

local BUTTONS = {
	"1",
	"2",
	"3",
	"4",
	"5",
}

local function RouteClicks(frame)
	for _, modifier in ipairs(MODIFIERS) do
		for _, button in ipairs(BUTTONS) do
			frame:SetAttribute(modifier .. "type" .. button, "click")
			frame:SetAttribute(modifier .. "clickbutton" .. button, frame.ClickCastingButton)
		end
	end
end

local function ClearLocalBinds(frame)
	for _, modifier in ipairs(MODIFIERS) do
		for _, button in ipairs(BUTTONS) do
			frame:SetAttribute(modifier .. "type" .. button, nil)
			frame:SetAttribute(modifier .. "clickbutton" .. button, nil)

			frame.ClickCastingButton:SetAttribute(modifier .. "type" .. button, nil)
			frame.ClickCastingButton:SetAttribute(modifier .. "spell" .. button, nil)
			frame.ClickCastingButton:SetAttribute(modifier .. "macro" .. button, nil)
		end
	end
end

local function UpdateExternalBinds(frame, source)
	local clickCastFrames = _G.ClickCastFrames
	if not clickCastFrames then
		return
	end

	if source == "external" then
		clickCastFrames[frame] = true
	else
		clickCastFrames[frame] = nil
	end
end

local function UpdateLocalBinds(frame, settings)
	local specID = addon.Utilities:GetPlayerSpecID()
	local specSettings = settings.specs[specID]

	RouteClicks(frame)

	for i = 1, 10 do
		local binding = specSettings.bindings[i]
		local type = binding.type
		local action = binding.action
		local button = binding.button
		local modifier = binding.modifier or ""

		if type and type ~= "" and action and action ~= "" and button and button ~= "" then
			if type == "action" and (action == "target" or action == "togglemenu") then
				frame.ClickCastingButton:SetAttribute(modifier .. "type" .. button, action)
			elseif type == "spell" then
				frame.ClickCastingButton:SetAttribute(modifier .. "type" .. button, "spell")
				frame.ClickCastingButton:SetAttribute(modifier .. "spell" .. button, action)
			elseif type == "macro" then
				frame.ClickCastingButton:SetAttribute(modifier .. "type" .. button, "macro")
				frame.ClickCastingButton:SetAttribute(modifier .. "macro" .. button, action)
			end
		end
	end
end

function ClickCasting:CreateClickCastingButton(frame)
	if frame.ClickCastingButton then
		return frame.ClickCastingButton
	end

	local frameName = frame:GetName()
	local buttonName = frameName and (frameName .. "ClickCastingButton") or nil
	local button = CreateFrame("Button", buttonName, frame, "SecureActionButtonTemplate")

	button:SetPoint("CENTER", frame, "CENTER", 0, 0)
	button:SetSize(1, 1)
	button:SetAlpha(0)
	button:EnableMouse(false)
	button:RegisterForClicks("AnyUp")
	button:SetAttribute("useparent-unit", true)
	button:SetAttribute("useparent-unitsuffix", true)
	button:SetAttribute("useOnKeyDown", false)

	frame.ClickCastingButton = button

	return button
end

function ClickCasting:UpdateClickCastBindsForFrame(frame, settings)
	if InCombatLockdown() then
		return
	end

	ClearLocalBinds(frame)
	UpdateExternalBinds(frame, settings.source)

	if settings.source == "local" then
		UpdateLocalBinds(frame, settings)
	end
end
