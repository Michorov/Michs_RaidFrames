local _, addon = ...

addon.Frames = addon.Frames or {}
addon.Frames.ClickCasting = addon.Frames.ClickCasting or {}

local ClickCasting = addon.Frames.ClickCasting

local CLICK_CASTING_BINDING_ROWS = 10

local CLICK_CASTING_MODIFIERS = {
	"",
	"shift-",
	"ctrl-",
	"alt-",
	"ctrl-shift-",
	"alt-shift-",
	"alt-ctrl-",
	"alt-ctrl-shift-",
}

local CLICK_CASTING_BUTTONS = {
	"1",
	"2",
	"3",
	"4",
	"5",
}

local CLICK_CASTING_BUTTON_ATTRIBUTES = {
	"type",
	"spell",
	"macro",
	"macrotext",
}

local CLICK_CASTING_FRAME_ATTRIBUTES = {
	"type",
	"clickbutton",
}

local function GetClickCastingButton(frame)
	if not frame then
		return nil
	end

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

local function UpdateCliqueRegistration(frame, source)
	local clickCastFrames = _G.ClickCastFrames
	if not frame or not clickCastFrames then
		return
	end

	if source == "external" then
		clickCastFrames[frame] = true
	else
		clickCastFrames[frame] = nil
	end
end

local function ClearClickCastingBinds(frame)
	if not frame then
		return
	end

	local clickCastingButton = frame.ClickCastingButton

	for _, modifier in ipairs(CLICK_CASTING_MODIFIERS) do
		for _, button in ipairs(CLICK_CASTING_BUTTONS) do
			for _, attribute in ipairs(CLICK_CASTING_FRAME_ATTRIBUTES) do
				frame:SetAttribute(modifier .. attribute .. button, nil)
			end

			for _, attribute in ipairs(CLICK_CASTING_BUTTON_ATTRIBUTES) do
				frame:SetAttribute(modifier .. attribute .. button, nil)

				if clickCastingButton then
					clickCastingButton:SetAttribute(modifier .. attribute .. button, nil)
				end
			end
		end
	end
end

local function RouteFrameClicksToClickCastingButton(frame, clickCastingButton)
	for _, modifier in ipairs(CLICK_CASTING_MODIFIERS) do
		for _, button in ipairs(CLICK_CASTING_BUTTONS) do
			frame:SetAttribute(modifier .. "type" .. button, "click")
			frame:SetAttribute(modifier .. "clickbutton" .. button, clickCastingButton)
		end
	end
end

local function ApplyLocalBinding(clickCastingButton, binding)
	if type(binding) ~= "table" then
		return
	end

	local bindingType = binding.type
	local action = binding.action
	local button = binding.button
	local modifier = binding.modifier or ""

	if not bindingType or bindingType == "" or not action or action == "" or not button or button == "" then
		return
	end

	if bindingType == "action" and (action == "target" or action == "togglemenu") then
		clickCastingButton:SetAttribute(modifier .. "type" .. button, action)
	elseif bindingType == "spell" then
		clickCastingButton:SetAttribute(modifier .. "type" .. button, "spell")
		clickCastingButton:SetAttribute(modifier .. "spell" .. button, action)
	elseif bindingType == "macro" then
		clickCastingButton:SetAttribute(modifier .. "type" .. button, "macro")
		clickCastingButton:SetAttribute(modifier .. "macro" .. button, action)
	end
end

local function UpdateLocalBinds(frame, settings)
	if type(settings) ~= "table" then
		return
	end

	local specID = addon.Utilities:GetPlayerSpecID()
	local specSettings = specID and type(settings.specs) == "table" and settings.specs[specID] or nil
	if type(specSettings) ~= "table" or type(specSettings.bindings) ~= "table" then
		return
	end

	local clickCastingButton = GetClickCastingButton(frame)
	if not clickCastingButton then
		return
	end

	RouteFrameClicksToClickCastingButton(frame, clickCastingButton)

	for i = 1, CLICK_CASTING_BINDING_ROWS do
		ApplyLocalBinding(clickCastingButton, specSettings.bindings[i])
	end
end

function ClickCasting:UpdateClickCastBindsForFrame(frame, settings)
	if not frame or InCombatLockdown() then
		return
	end

	local source = settings and settings.source == "local" and "local" or "external"

	if source == "external" then
		ClearClickCastingBinds(frame)
		UpdateCliqueRegistration(frame, source)
	else
		UpdateCliqueRegistration(frame, source)
		ClearClickCastingBinds(frame)
		UpdateLocalBinds(frame, settings)
	end
end
